s.boot;

(
SynthDef(\wub, {|out, freq = 80, index = 4, len = 1|
	var snd;
	var n = 16;
	var partials = Array.fill(n, {|i| 2 * i * (freq) });
	snd = Mix.fill(n, {|i|
		SinOsc.ar(partials[i]) * SinOsc.ar(freq / 2, mul: freq * index) * 1 / n;
	});
	snd = Mix([LPF.ar(snd/n, SinOsc.ar(1.3, mul: 1300,add: 1400), 0.3), LPF.ar(snd/n, SinOsc.ar(0.9, mul: 1300,add: 1300), 0.3)]);
	snd = SoftClipAmp.ar(snd);
	snd = LPF.ar(
		snd,
		50 + EnvGen.ar(Env.perc( releaseTime: len,level: 9500), doneAction: 2)
	);
	snd = Pan2.ar(snd, 0.0);
	Out.ar(out, snd);
}).add;
)

Synth(\wub, [freq: 80 , index: 32]);
