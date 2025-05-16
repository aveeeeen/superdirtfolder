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
SynthDef(\fmkik, {| out, pan, freq = 40, modRate = 2, index = 0.5, pAtk = 0.0001, pDur = 0.1, pRate = 8, amp = 1.5, attack = 0.0001, dur = 2, curveRate = 4|
	var env = EnvGen.kr(Env.perc(attack, dur, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(attack, dur, index));
	var pEnv = EnvGen.kr(Env.perc(pAtk, pDur, pRate));
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
}).add
)

(
SynthDef(\fmperc, {| out, pan, freq = 40, modRate = 2, index = 0.5, pAtk = 0.0001, pDur = 0.05, pRate = 4, amp = 1.5, attack = 0.0001, release = 2, curveRate = 4|
	var env = EnvGen.kr(Env.perc(attack, release, curve: (-1.0 * curveRate)), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(pAtk, pDur, pRate));
	var mod = SinOsc.ar(
		freq * modRate * (2 + pEnv),
		0,
		freq * modRate * (index)
	);

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;
	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, env)
	)
}).add
)

Synth(\fmkik, [pRate: 4, index: 1, freq: 40, pDur: 0.05, curveRate: 4, modRate: 0.7 , release: 3])
