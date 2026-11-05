TABLA LIVE PLAYER, VERSION 7

MuseScore plays the score. SuperCollider receives the notes, plays the tabla
samples, and shows each bol in one window: the bol name on top, and both drums
below, animating the stroke.

Tested on a Mac only. It uses the Mac's IAC Driver for MIDI.

YOU NEED
- SuperCollider
- MuseScore 4

Keep this folder together. Tabla_live+load_7.scd looks for the tabla_samples
folder beside it, so do not move or rename either one.


WHAT IS IN THIS FOLDER
Tabla_live+load_7.scd          the script
tabla_samples/
  8 .wav files                 one sample per stroke
  Tabla (K.B.).drm             the MuseScore drumset for the tabla
  tabla_bol_map.html           the drum pictures the window animates
  tabla bhamra index.mscz      the index score
  comp copy.mscz               a composition


SET UP ONCE

1. Turn on the IAC Driver
   Open Audio MIDI Setup, choose Window > Show MIDI Studio, double-click
   IAC Driver, and tick "Device is online".

2. Set MuseScore's MIDI output
   In MuseScore, open Preferences > Audio & MIDI and set MIDI output to
   IAC Driver Bus 1. Restart MuseScore.

3. Install wslib in SuperCollider
   Open Tabla_live+load_7.scd. Click on line 4 and press Shift+Return.
   Wait for the install to finish, then run this once:

       thisProcess.recompile;

   If the install fails, git may be missing. Run this in Terminal, then
   try again:

       xcode-select --install

   You do not need to run line 4 again.


PLAY THE SCORE

1. Open Tabla_live+load_7.scd in SuperCollider.
2. Run lines 1, 2 and 3 one at a time with Shift+Return.
3. Click inside lines 6-243 and press Cmd+Return (not Shift+Return).
   The window opens showing "Ready" above the two drums.
4. Open a score from tabla_samples in MuseScore and press Play.

The Tablas track must use MS Basic in MuseScore's Mixer (F10). With another
sound, such as a plugin, no notes reach SuperCollider.
To hear only the tabla samples, turn the Tablas fader down in the Mixer.
The notes still reach SuperCollider.

The script listens to whatever MuseScore plays, so any score that uses the
Tabla (K.B.) drumset works, not only these two.


WRITING DHA AND DHIN
Write them as two notes at the same moment:
  Dha  = ghe + na, or ghe + ta (both are recognised)
  Dhin = ghe + tun
In MuseScore's Percussion panel, click the ghe pad, then hold Shift and click
the second pad.

Any other pair played together is skipped. SuperCollider's post window then
shows "Unmapped trigger for notes: ..." with the note numbers.


IF THE WINDOW STAYS ON "Ready"
- Check that the Tablas sound is MS Basic.
- Check that the post window shows "-> LIVE MIDI MODE ACTIVATED". If not,
  run step 3 again.
- Check that MIDI output still says IAC Driver Bus 1, then restart MuseScore.


IF THE WINDOW CLOSES OR HIDES
Click inside lines 246-252 and press Cmd+Return.


THE DRUM PICTURES
They come from tabla_bol_map.html, which can also be opened on its own in a
web browser as a lesson page. Its Devanagari fonts load from the internet;
offline, plainer fonts are used. If the file is missing, the window shows the
bol name only and everything else still works.


PLAY A MIDI FILE INSTEAD
Export the score from MuseScore as MIDI (File > Export). After step 3 above,
run this with your file's full path:

    ~startFileMode.value("/full/path/to/your_file.mid");
