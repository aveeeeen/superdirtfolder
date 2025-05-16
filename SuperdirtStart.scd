/*
This is an example startup file. You can load it from your startup file
(to be found in Platform.userAppSupportDir +/+ "startup.scd")
*/

(
s.reboot { // server options are only updated on reboot
    // configure the sound server: here you could add hardware specific options
    // see http://doc.sccode.org/Classes/ServerOptions.html
    s.options.numBuffers = 1024 * 256 * 4; // increase this if you need to load more samples
    s.options.memSize = 8192 * 32; // increase this if you get "alloc failed" messages
    s.options.numWireBufs = 64 * 16 * 2; // increase this if you get "exceeded number of interconnect buffers" messages
    s.options.maxNodes = 1024 * 32 * 2; // increase this if you are getting drop outs and the message "too many nodes"
	s.options.numOutputBusChannels = 2; // set this　to your hardware output channel size, if necessary
    s.options.numInputBusChannels = 2; // set this to your hardware output channel size, if necessary
    // boot the server and start SuperDirt
    s.waitForBoot {
        ~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
		// ~dirt.loadSoundFiles;   // load samples (path containing a wildcard can be passed in)

		~dirt.loadSoundFiles("/home/braveeeeen/Documents/vscode/tidal/samples/elctr_catfish_samples/*");
		~dirt.loadSoundFiles("/home/braveeeeen/Documents/vscode/tidal/samples/tidalsamples/*");
		~dirt.start(57120, 0 ! 12);   // start listening on port 57120, create two busses each sending audio to channel 0


        // for example: ~dirt.loadSoundFiles("/Users/myUserName/Dirt/samples/*");
        // s.sync; // optionally: wait for samples to be read


        // optional, needed for convenient access from sclang:
        (
            ~d1 = ~dirt.orbits[0]; ~d2 = ~dirt.orbits[1]; ~d3 = ~dirt.orbits[2];
            ~d4 = ~dirt.orbits[3]; ~d5 = ~dirt.orbits[4]; ~d6 = ~dirt.orbits[5];
            ~d7 = ~dirt.orbits[6]; ~d8 = ~dirt.orbits[7]; ~d9 = ~dirt.orbits[8];
            ~d10 = ~dirt.orbits[9]; ~d11 = ~dirt.orbits[10]; ~d12 = ~dirt.orbits[11];
        );
    };

    s.latency = 3.0; // increase this if you get "late" messages
};
);

(
SynthDef(\perc2, {| out, pan, freq = 60, pDur = 0.01, pRate = 2, amp = 1, attack = 0.05, release = 2|
	var pEnv = Line.kr(freq * pRate ,freq, pDur);
	var click_pEnv = Line.kr(1000 ,freq, pDur);
	var env = EnvGen.kr(Env.perc(attack, release), doneAction: 2);
	var clickEnv = EnvGen.kr(Env.perc(0.001, 0.005, 0.5));
	var freqmod = pEnv;
	var controlOsc = SinOsc.kr(freq/2, 0.0, amp) * env;
	var click = SinOsc.ar(click_pEnv, 0, 0.5) * clickEnv;
	var mainOsc = SinOsc.ar(freqmod, 0.0, controlOsc) + click;
	var outnode = Clip.ar(mainOsc, -1, 1);
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;
)

Synth(\perc2);

(
SynthDef(\fmperc, {| out, pan, freq = 40, modRate = 2, index = 0.5, pAtk = 0.0001, pDur = 0.05, pRate = 4, amp = 0.8, attack = 0.0001, release = 2, curveRate = 4|
	var env = EnvGen.kr(Env.perc(attack, release, curve: (-1.0 * curveRate)), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(pAtk, pDur, pRate));
	var mod = SinOsc.ar(
		freq * modRate * (2 + pEnv),
		0,
		freq * modRate * (index));

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp) * env;
	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, env)
	)
}).add
)

Synth(\fmkik, [pRate: 4, index: 1, freq: 40, pDur: 0.05, curveRate: 4, modRate: 0.7 , release: 3])