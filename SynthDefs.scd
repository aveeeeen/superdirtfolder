
(

SynthDef(\perc2, {| out, pan, freq = 60, plen = 0.01, prate = 2, amp = 0.9, atk = 0.05, release = 2|
	var pEnv = Line.kr(freq * prate ,freq, plen);
	var click_pEnv = Line.kr(1000 ,freq, plen);
	var env = EnvGen.kr(Env.perc(atk, release), doneAction: 2);
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

SynthDef(\fmkik, {| out, pan, freq = 40, modRate = 1, index = 0.5, patk = 0.001, plen = 0.07, prate = 8, amp = 0.9, atk = 0.001, len = 1, curveRate = 4|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modRate * (1 + pEnv),
		0,
		freq * modRate * (1 + modEnv)
	);

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;
	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, env)
	)
}).add;


SynthDef(\fmsn, {| out, pan, freq = 40, modRate = 3, index = 0.5, patk = 0.01, plen = 0.15, prate = 4, amp = 0.9, atk = 0.01, len = 0.7, noiseamp = 0.6, curveRate = 4|
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

SynthDef(\fmfilter, {| out, pan, freq = 40, modRate = 1, index = 1, patk = 0.001, plen = 0.05, prate = 4, amp = 0.9, atk = 0.001, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modRate * (2 + pEnv),
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

)

Synth(\fmkik,[ len: 3, rez: 0.5]);




