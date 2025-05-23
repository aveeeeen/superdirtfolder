
(

SynthDef(\perc2, {| out, pan, freq = 60, plen = 0.01, prate = 2, amp = 0.9, atk = 0.05, len = 2|
	var pEnv = Line.kr(freq * prate ,freq, plen);
	var click_pEnv = Line.kr(1000 ,freq, plen);
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
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

SynthDef(\sinpad, {| out, pan, freq = 60, plen = 0.01, prate = 2, amp = 0.9, atk = 0.01, len = 2, sust = 1|
	var pEnv = Line.kr(freq * prate ,freq, plen);
	var env = EnvGen.kr(Env.adsr(atk, len, sust, 0.1, curve: -6), doneAction: 2);
	var amplfoL = SinOsc.kr(1.2, mul: 0.3);
	var amplfoR = SinOsc.kr(0.8, mul: 0.3);
	var oscamp = 0.2;
	var mainOsc = [
		((SinOsc.ar(pEnv, 0.0, mul: oscamp) * env) + (SinOsc.ar(pEnv * 0.75, 0.2, mul: oscamp * 0.8) * env)) * (0.2 + amplfoL),
		((SinOsc.ar(pEnv, 1, mul: oscamp) * env) + (SinOsc.ar(pEnv * 0.5, 0.7, mul: oscamp) * env)) * (0.2 + amplfoR)
	];
	var outnode = mainOsc;
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmkik, {| out, pan, freq = 40, modRate = 1, index = -1, patk = 0.001, plen = 0.07, prate = 16, amp = 0.9, atk = 0.001, len = 1, curveRate = 4, contour = 1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, 1 * contour));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modRate * (1 + pEnv),
		mul: freq * modRate * index) * modEnv;

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;
	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmkik2, {| out, pan, freq = 21, modRate = 1.5, index = 5, patk = 0.01, plen = 0.1, prate = 4, amp = 0.9, atk = 0.01, len = 1, curveRate = 7, contour = 1|
	var cr = -1.0 * curveRate;
	var env = EnvGen.kr(Env.perc(atk, len, curve: cr), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, 1 * contour));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = LFSaw.ar(
		freq * modRate * (1 + pEnv),
		mul: freq * modRate * index) * (modEnv);

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;

	var output = SoftClipAmp.ar(car, 2);
	OffsetOut.ar(out,
		DirtPan.ar(output, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmsn, {| out, pan, freq = 40, modRate = 3, index = 0.5, patk = 0.01, plen = 0.15, prate = 8, amp = 0.9, atk = 0.01, len = 0.7, noiseamp = 0.5, curveRate = 4|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));

	var mod = Pulse.ar(
		freq * modRate * (1 + pEnv),
		0.5,
		freq * modRate * (1 + modEnv)
	);

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;

	var noise = WhiteNoise.ar(noiseamp) * env;

	var outnode = RHPF.ar(car + noise, 100, 0.5);
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmsn2, {| out, pan, freq = 21, modRate = 6, index = 13, patk = 0.02, plen = 0.2, prate = 3, amp = 0.9, atk = 0.01, len = 1, curveRate = 8, contour = 0.7|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, 1 * contour));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate, curve: -10));
	var mod = LFTri.ar(
		freq * modRate * (1 + pEnv),
		mul: freq * modRate * index) * (modEnv);

	var car = LFPulse.ar(
		(freq + mod) * (1 + pEnv) ,
		mul: amp) * env;

	var lpf = RLPF.ar(car, XLine.kr(8000, freq * 16, (len * 0.5)), 0.9);
	var hpf = RHPF.ar(lpf, XLine.kr(20, 200, 0.01), 0.2);
	var output = SoftClipAmp.ar(hpf, 12);
	OffsetOut.ar(out,
		DirtPan.ar(output, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmfilter, {| out, pan, freq = 40, modRate = 1, index = 1, patk = 0.001, plen = 0.05, prate = 4, amp = 0.9, atk = 0.001, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modRate * (1 + pEnv),
		0,
		freq * modRate * (index));

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp) * env;

	var outnode = RLPF.ar(car , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmpad, {| out, pan, freq = 40, modRate = 0.5, index = 1, patk = 0.001, plen = 0.0001, prate = 2, amp = 0.8, atk = 0.001, len = 4, sust = 1, detune = 0.1, curveRate = 4, cutoff = 2000, q = 0.1|
	var env = EnvGen.kr(Env.adsr(atk, len, sust) , doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modRate * (1 + pEnv),
		0,
		freq * modRate * (index) );

	var carL = SinOsc.ar(
		(freq + mod) * (1 + pEnv) + (0.1 * detune),
		0,
		amp) * env;

	var carR = SinOsc.ar(
		(freq + mod) * (1 + pEnv) - (0.1 * detune),
		0,
		amp) * env;

	var outnode = RLPF.ar([carL, carR] , XLine.kr(cutoff, 500, len), ( 0.001 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmsaw, {| out, pan, freq = 40, modRate = 1, index = 1, patk = 0.001, plen = 0.01, prate = 4, amp = 0.9, atk = 0.01, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = LFSaw.ar(
		freq * modRate * (1 + pEnv) ,
		mul: freq * modRate) * modEnv;

	var car = SinOsc.ar(
		freq + mod * (1 + pEnv),
		mul: amp) * env;

	var outnode = RLPF.ar(car , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmperc, {| out, pan, freq = 40, modRate = 2, index = 0.5, patk = 0.0001, plen = 0.05, prate = 4, amp = 0.9, atk = 0.0001, len = 2, curveRate = 4|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
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
}).add;

SynthDef(\modsaw, {| out, pan, freq = 440, atk = 0.01, len = 2, amp = 0.9, prate = 2 , plen = 0.001 , q = 0.1, cutoff = 6000, cutoffspd = 0|
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	var saw = Saw.ar(
		(freq) * (pEnv + 1)
		,SinOsc.kr(freq:SinOsc.kr(freq:SinOsc.kr(freq,0.75), phase: 0.25), phase: 0.5) * 1.3
	) * env;
	var outnode = RLPF.ar(saw , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	);
}).add;

SynthDef(\detsaw, {| out, pan, freq = 440, atk = 0.01, len = 2, sust = 1, amp = 0.9, prate = 0 , plen = 0.001 , q = 0.1, detune = 0.1, cutoff = 6000, cutoffspd = 0|
	var env = EnvGen.kr(Env.adsr(atk, len, sust) , doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	var sawL = Saw.ar(
		(freq) * (pEnv + 1) + (1 * detune)
	) * env;

	var sawR = Saw.ar(
		(freq) * (pEnv + 1) - (1 * detune)
	) * env;

	var outnode = RLPF.ar([sawL,sawR] , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	);
}).add;


SynthDef(\chirp, {| out, pan, freq = 40, atk = 0.001, len = 2, amp = 0.9, prate = 300 , plen = 0.1 , q = 0.5, cutoff = 12000, cutoffspd = 0|
	var env = EnvGen.kr(Env.perc(atk, len, curve: -7), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.01, plen, prate, -7));
	var osc2 = SinOsc.ar(freq * (1 + pEnv) ) * env;
	var outnode = RLPF.ar(osc2 , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	);
}).add;

SynthDef(\chirp2, {| out, pan, freq = 40, atk = 0.01, len = 1, amp = 0.9, prate = 256 , plen = 0.1 , q = 1, cutoff = 12000, cutoffspd = 0|
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.01, plen, prate));
	var osc2 = WhiteNoise.ar * env;
	var outnode = RLPF.ar(osc2 , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ), 0.3);
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	);
}).add;

)

Synth(\fmkik,[ len: 3, rez: 0.5]);




