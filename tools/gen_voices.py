"""Generate the Narrator's voice lines with ElevenLabs text-to-speech.

Collects every narrator line from scripts/*.gd:
  ["N", "..."]            dialogue lines
  say_idle("...")         lingering lines
  const VOICE_xxx := "..." special lines (muffled, ending)
and writes voice/n_<md5[:12]>.mp3 for each, matching dialog.gd's voice_path().
Existing files are skipped, so re-running only pays for new or changed lines.

The API key is read from ELEVENLABS_API_KEY or from ../.elevenlabs_key (outside the
project, so it is never exported with the game).

Usage:  python tools/gen_voices.py [--dry-run] [--force]
"""

import hashlib
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
KEY_FILE = ROOT.parent / ".elevenlabs_key"
OUT = ROOT / "voice"

# "Callum": husky trickster, a smug game-show host. Override with NARRATOR_VOICE_ID.
# eleven_v3 performs the lowercase stage directions in the lines ("[sighs]", "[smug]").
VOICE_ID = os.environ.get("NARRATOR_VOICE_ID", "N2lVS1w4EtoT3dr4eOWO")
MODEL = "eleven_v3"
SETTINGS = {"stability": 0.5}

PATTERNS = [
    r'\["N",\s*"([^"]+)"\]',
    r'say_idle\(\s*"([^"]+)"',
    r'const VOICE_\w+ := "([^"]+)"',
]


def collect() -> list[str]:
    lines = set()
    for f in (ROOT / "scripts").glob("*.gd"):
        src = f.read_text(encoding="utf-8")
        for p in PATTERNS:
            lines.update(re.findall(p, src))
    # Lines with no letters ("...") stay silent.
    return sorted(line for line in lines if re.search(r"[A-Za-z]", line))


def key_for(text: str) -> str:
    return "n_" + hashlib.md5(text.encode("utf-8")).hexdigest()[:12]


def api_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key and KEY_FILE.exists():
        key = KEY_FILE.read_text(encoding="utf-8").strip()
    if not key:
        sys.exit(f"No API key: set ELEVENLABS_API_KEY or create {KEY_FILE}")
    return key


def synth(text: str, key: str) -> bytes:
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}?output_format=mp3_44100_128"
    body = json.dumps({"text": text, "model_id": MODEL, "voice_settings": SETTINGS}).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST", headers={
        "xi-api-key": key,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    })
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def main() -> None:
    dry = "--dry-run" in sys.argv
    force = "--force" in sys.argv
    lines = collect()
    todo = [t for t in lines if force or not (OUT / f"{key_for(t)}.mp3").exists()]
    print(f"{len(lines)} narrator lines, {len(todo)} to generate, {sum(len(t) for t in todo)} characters")
    if dry:
        for t in todo:
            print(f"  {key_for(t)}  {t}")
        return
    key = api_key()
    OUT.mkdir(exist_ok=True)
    for t in todo:
        try:
            audio = synth(t, key)
        except urllib.error.HTTPError as e:
            sys.exit(f"ElevenLabs error {e.code} on {t!r}: {e.read().decode('utf-8', 'replace')[:300]}")
        (OUT / f"{key_for(t)}.mp3").write_bytes(audio)
        print(f"  ok  {key_for(t)}  {t[:60]}")
    manifest = {key_for(t): t for t in lines}
    (OUT / "lines.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
