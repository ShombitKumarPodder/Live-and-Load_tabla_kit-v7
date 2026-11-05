s.boot;
MIDIClient.init;
MIDIIn.connectAll; // Ready for live input
Quarks.install("wslib"); // Run once, then Language > Recompile Class Library

(
// Samples live in the tabla_samples folder beside this script
~tablaDir = thisProcess.nowExecutingPath.dirname +/+ "tabla_samples/";

// The Bol Map page can sit in tabla_samples or beside this script
~bolMapPath = [~tablaDir ++ "tabla_bol_map.html", thisProcess.nowExecutingPath.dirname +/+ "tabla_bol_map.html"]
    .detect { |path| File.exists(path) };

s.waitForBoot {
    var makeKey, evaluateAndPlay, liveMIDIdef, playMIDIFile;

    // ----------------------------------------------------
    // 1. SYNTHDEF (Shared Core)
    // ----------------------------------------------------
    SynthDef(\samplePlayer, { |buf, out = 0, amp = 1.0|
        var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf), doneAction: 2).sum * 0.5; // Stereo file -> mono
        Out.ar(out - 1, sig * amp); // Keep channels as Pd numbers them: 1 = Left, 2 = Right
    }).add;

    // Turns the sound down only when overlapping strokes would go over full volume (clipping)
    SynthDef(\tablaLimiter, {
        ReplaceOut.ar(0, Limiter.ar(In.ar(0, 2), 0.95));
    }).add;

    s.sync;

    if (~limiter.notNil and: { ~limiter.isPlaying }) { ~limiter.free }; // Running this block again replaces the old one
    ~limiter = Synth(\tablaLimiter, target: RootNode(s), addAction: \addToTail); // After every stroke
    ~limiter.register(true);

    // ----------------------------------------------------
    // 2. DICTIONARIES & MAPPING (Shared Core)
    // ----------------------------------------------------
    ~samples = Dictionary.new;
    ~channels = Dictionary.new;

    makeKey = { |notesArray| notesArray.asArray.sort.join("_") };

    ~assignSample = { |notes, filePath, outputChannel|
        var key = makeKey.value(notes);
        ~samples[key] = Buffer.read(s, filePath);
        ~channels[key] = outputChannel;
    };

    // Same as ~assignSample, but for strokes played by both hands together
    ~assignSamples = { |notes, filePaths, outputChannels|
        var key = makeKey.value(notes);
        ~samples[key] = filePaths.collect { |path| Buffer.read(s, path) };
        ~channels[key] = outputChannels;
    };

    // Load your singles & combos once for both modes
	~assignSample.value([78],     ~tablaDir ++ "तुन_दिं.wav",   1); // F#5 (Tun) -> Channel 1
	~assignSample.value([79],     ~tablaDir ++ "ना.wav",   1); // G5 (Na) -> Channel 1
	~assignSample.value([76],     ~tablaDir ++ "ता.wav", 1); // E5 (Ta) -> Channel 1
	~assignSample.value([77],     ~tablaDir ++ "ति.wav",   1); // F5 (ti) -> Channel 1
	~assignSample.value([75],     ~tablaDir ++ "टे.wav",   1); // D#5 (Tte)  -> Channel 1

	~assignSample.value([55],     ~tablaDir ++ "घे.wav",   2); // G3 (Ghe) -> Channel 2
	~assignSample.value([59],     ~tablaDir ++ "गे.wav",   2); // B3 (Ge) -> Channel 2
	~assignSample.value([57],     ~tablaDir ++ "कत.wav",   2); // A3 (Kat) -> Channel 2




	~assignSamples.value([55, 79], [~tablaDir ++ "घे.wav", ~tablaDir ++ "ना.wav"], [2, 1]); //Dha combo -> 2+1
	~assignSamples.value([55, 78], [~tablaDir ++ "घे.wav", ~tablaDir ++ "तुन_दिं.wav"], [2, 1]); //Dhin combo -> 2+1
	~assignSamples.value([55, 76], [~tablaDir ++ "घे.wav", ~tablaDir ++ "ता.wav"], [2, 1]); //Dha written as Ghe + Ta -> 2+1

    s.sync;

    // ----------------------------------------------------
    // 3. SHARED PLAYBACK FUNCTION (The Brain)
    // ----------------------------------------------------
    evaluateAndPlay = { |notes, textDisplay|
        var key = makeKey.value(notes);

        // Play Audio via Dictionary
        if (~samples[key].notNil) {
            ~samples[key].asArray.do { |buf, i|
                Synth(\samplePlayer, [
                    \buf, buf,
                    \out, ~channels[key].asArray[i] ?? 1
                ]);
            };
        } {
            ("Unmapped trigger for notes: " ++ key).postln;
        };

        // Optional Text Display Update (if window exists)
        if (textDisplay.notNil) {
            var bolText = case
                { key == "55_78" } { "धिन" }
                { key == "55_79" } { "धा" }
                { key == "55_76" } { "धा" }
                { key == "55" } { "घे" }
                { key == "57" } { "कत" }
                { key == "59" } { "गे" }
                { key == "75" } { "टे" }
                { key == "76" } { "ता" }
                { key == "77" } { "ति" }
                { key == "78" } { "तुन" }
                { key == "79" } { "ना" }
                { true } { "" };

            if (bolText != "") {
                { textDisplay.string_(bolText) }.defer;
            };
        };

        // Drum animation in the window's drum box (animation only, the page's own sound stays off)
        if (~bolMapStrokes[key].notNil) {
            {
                if (~bolMap.notNil and: { ~bolMap.isClosed.not }) {
                    ~bolMap.runJavaScript("[%].forEach(animateStroke);".format(~bolMapStrokes[key].collect { |id| "'" ++ id ++ "'" }.join(", ")));
                };
            }.defer;
        };
    };

    // Bol Map: the page's names for the strokes to animate, one per hand
    ~bolMapStrokes = Dictionary[
        "79" -> ["na"], "76" -> ["ta"], "78" -> ["tun"], "77" -> ["ti"], "75" -> ["tte"],
        "55" -> ["ghe"], "59" -> ["ge"], "57" -> ["kat"],
        "55_79" -> ["ghe", "na"], "55_78" -> ["ghe", "tun"], "55_76" -> ["ghe", "ta"]
    ];

    // Keeps only the drum box of the page, in light colours, and turns off its number keys (they play the page's own sound)
    ~bolMapTrim = "(() => {
        document.documentElement.dataset.theme = 'light';
        const css = document.createElement('style');
        css.textContent = `
            body { margin: 0; background: #eceef3; }
            .wrap { max-width: none; padding: 0 12px 12px; gap: 0; }
            .wrap > header, .wrap > section, .wrap > footer, #card { display: none !important; }
            .stage-grid { grid-template-columns: minmax(0, 1fr); }`;
        document.head.appendChild(css);
        document.addEventListener('keydown', e => e.stopImmediatePropagation(), true);
        return 'trimmed'; // SuperCollider expects a reply
    })()";

    // GUI Window Setup: bol name on top, the Bol Map's drum box below
    ~openWindow = {
        var hasPage = ~bolMapPath.notNil;
        var width = if (hasPage) { 640 } { 400 };
        var stripH = if (hasPage) { 116 } { 200 };

        ~win = Window("Tabla Master Control", Rect(300, 200, width, if (hasPage) { 566 } { 200 })).front;
        ~win.view.background = Color.new255(236, 238, 243);
        ~textDisplay = StaticText(~win, Rect(20, 0, width - 40, stripH))
            .resize_(2)
            .font_(Font("Sans-Serif", 64, bold: true))
            .align_(\center)
            .string_("Ready");

        if (hasPage) {
            ~bolMap = WebView(~win, Rect(0, stripH, width, 566 - stripH)).resize_(5).visible_(false);
            ~bolMap.onLoadFinished = { |view|
                view.runJavaScript(~bolMapTrim, { view.visible = true }); // Show it once only the drum box is left
            };
            ~bolMap.url = "file://" ++ ~bolMapPath.replace(" ", "%20");
        } {
            ~bolMap = nil;
            "-> tabla_bol_map.html not found in tabla_samples or beside the script, showing the bol name only".postln;
        };
    };
    ~openWindow.value;

    // ----------------------------------------------------
    // 4. MODE A: LIVE MIDI LISTENER (Run this to listen to MuseScore live)
    // ----------------------------------------------------
    ~startLiveMode = {
        // Free any existing listener
        if (~activeMIDIdef.notNil) { ~activeMIDIdef.free; };

        ~activeNotes = List.new;
        ~timer = nil;

        ~activeMIDIdef = MIDIdef.noteOn(\tablaLiveMode, { |vel, num|
            ~activeNotes.add(num);

            if (~timer.isNil) {
                ~timer = SystemClock.sched(0.006, {
                    // Pass notes to our shared evaluation function
                    evaluateAndPlay.value(~activeNotes.copy, ~textDisplay);
                    ~activeNotes.clear;
                    ~timer = nil;
                });
            };
        });

        "-> LIVE MIDI MODE ACTIVATED (Listening to IAC Bus / MuseScore Live)".postln;
    };

    // ----------------------------------------------------
    // 5. MODE B: STATIC MIDI FILE PLAYER (Run this to render a .mid file)
    // ----------------------------------------------------
    ~startFileMode = { |filePath|
        // Turn off live mode listener so they don't conflict
        if (~activeMIDIdef.notNil) { ~activeMIDIdef.free; };

        Routine({
            var midiFile = SimpleMIDIFile.read(filePath);
            var timeGroups = Dictionary.new;
            var sortedTimes, previousTime = 0;

            midiFile.timeMode = \seconds;

            midiFile.noteOnEvents.do { |event|
                var time = event[1].round(0.001);
                var note = event[4];
                if (event[5] > 0) { // A note-on with velocity 0 is the end of a note, not a stroke
                    if (timeGroups[time].isNil) { timeGroups[time] = List.new; };
                    timeGroups[time].add(note);
                };
            };

            sortedTimes = timeGroups.keys.asArray.sort;

            "-> STATIC MIDI FILE MODE STARTING...".postln;

            sortedTimes.do { |time|
                var delta = time - previousTime;
                var notes = timeGroups[time];

                delta.wait;
                evaluateAndPlay.value(notes, ~textDisplay);
                previousTime = time;
            };

            "-> MIDI File Playback Finished.".postln;
        }).play;
    };

    // Default to Live Mode on boot (change this if you prefer)
    ~startLiveMode.value();
};
)

// Bring the window back: reopens it if closed, brings it forward if hidden
(
if (~openWindow.isNil) {
    "-> Run the main block first: click inside it, then Cmd+Return".postln;
} {
    if (~win.isNil or: { ~win.isClosed }) { ~openWindow.value } { ~win.front };
};
)