

(
SynthDef(\eprom, { |out, freq = 32, len = 1, spd = 13.5, indexrate = 4, modrate = 16 |
	var fenv, env, snd, index;
	// fenv = EnvGen.ar(Env([1, 4, 1], [0.001, 0.8], -4));
	index = SinOsc.kr(XLine.kr(100, 1, len / 4)).linlin(-1, 1, 1, indexrate);
	env = EnvGen.ar(Env([0,1,0], [0.0001, len]), doneAction: 2);
	snd = SinOsc.ar(freq + SinOsc.ar(freq * modrate, 2pi).linlin(-1, 1, -80 * index, 80 * index), (2pi));
	snd = snd + SinOsc.ar(freq + SinOsc.ar(freq * modrate, (2pi * spd * (LFNoise1.ar(0.8).linlin(-1,1,1,64) / 64))).linlin(-1, 1, -80 * index, 80 * index), (2pi * 3 * (LFNoise1.kr(2).linlin(-1,1,1, 64) / 64)) );
	snd = snd / 2;
	snd = snd.fold(-0.9,0.9);
	snd = snd.round(0.015);
	snd = Notch.ar(snd, SinOsc.kr(XLine.kr(100, 1, len / 4)).linexp(-1, 1, 20, 10000), 4.5);
	snd = snd * 3;
	snd.tanh;
	snd = snd * env;
	snd = Pan2.ar(snd * 0.8);
	Out.ar(out, snd);
}).add;

);

Synth(\eprom, [\freq, 40, \modrate, 4, \spd, 4, \len, 1, \indexrate, 2]);


{ CombN.ar(WhiteNoise.ar(0.01), 0.01, XLine.kr(0.0001, 0.01, 20), -0.2) }.play;

{LFNoise1.kr(20)}.plot

(
{ var trig, rate, x, sr;
    rate = MouseX.kr(1, 200, 1);
    trig = Impulse.ar(rate);
    sr = SampleRate.ir;
    x = Phasor.ar(trig, rate / sr, 0, 1, [0, MouseY.kr(0, 1)]);
    SinOsc.ar(x * 500 + 500, 0, 0.2)
}.play;
)

t = Signal.chebyFill(512,[12, 0.5, 12, 0.25]).plot;


