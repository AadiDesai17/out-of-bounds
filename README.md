# Out of Bounds

A pixel-art, fourth-wall-breaking puzzle game in three acts for Godot 4.7, about 5 minutes long.
All art and text are drawn in code. The Narrator is voiced with ElevenLabs (Callum, eleven_v3; pre-recorded in `voice/`).

**The twist:** SYSTEM_MSG, the voice trapped in the wall, is you. When you open the exit, your
trapped self walks out and you are pulled in. The other you presses START, and the Narrator, a smug
host whose memory is wiped every loop, welcomes them like a stranger. The loop continues.

## Run

```
Godot_v4.7.2-stable_win64.exe --path D:\gd\out_of_bounds_v2
```

Controls: A/D walk, E interact, mouse to point and drag, Space/click for the next line, Esc for settings.

## Walkthrough

**I. The Pledge** (no glitches)
1. Step on the floor plates in the banner's order: sun, moon, star. The door opens. Note the clock: 08:14.

**II. The Turn**
2. The same room again. The clock says 08:13. The Narrator stutters; SYSTEM_MSG appears.
3. Door hall: the Narrator shoves you back from the exit. Double-click the EXIT door to reveal a dev tooltip,
   then drag it onto the Narrator's box. He dodges twice; the third time it sticks and he's gagged.
4. Esc, Accessibility, Invert Colors ON. Time runs backwards. The wall asks "WHEN DID IT START?" Keypad code: 0814.

**III. The Prestige**
5. Drag the three memory fragments into time order: 08:12, 08:13, 08:14. The exit unlocks.
6. Walk into the exit. Your trapped self walks out; you are pulled into the wall.
7. Watch the other you start the game, type the line you were sent, see the truth, and leave yourself a note.

## Narrator voice

`tools/gen_voices.py` collects every narrator line from the scripts (`["N", "..."]`,
`say_idle("...")`, `const VOICE_*`) and generates any that are missing. The API key is read
from `ELEVENLABS_API_KEY` or `D:\gd\.elevenlabs_key` (outside the project, never exported).
After changing a narrator line, run it again, then reopen the project so Godot imports the new files.

```
python tools/gen_voices.py --dry-run
python tools/gen_voices.py
```

## Code map

- `scripts/main.gd`: screens, input routing, chapter cards, and the whole story (`on_event`)
- `scripts/title.gd`, `hall.gd`, `desktop.gd`, `wall.gd`: the screens (`wall.gd` is the ending)
- `scripts/dialog.gd`: dialogue boxes, voice playback and lip-sync
- `scripts/sfx.gd`: clock ticks, bass hits, plates, doors, drone (procedural)
- `scripts/settings.gd`, `overlay.gd`, `art.gd`, `px_font.gd`: UI, CRT/fades/cursor, art helpers, bitmap font
- `shaders/screen_fx.gdshader`: brightness, contrast, invert, high contrast, glitch

Checks: `--headless --path . -- --smoke` plays the whole game; `--path . -- --shots=<dir>` saves a screenshot of every scene; `--headless --path . -s tools/check_voices.gd` lists the voice files.
