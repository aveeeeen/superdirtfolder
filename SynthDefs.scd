
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

SynthDef(\fmkik, {| out, pan, freq = 40, modrate = 1, index = -1, patk = 0.001, plen = 0.07, prate = 16, amp = 0.9, atk = 0.001, len = 1, curveRate = 4, contour = 1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, 1 * contour));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modrate * (1 + pEnv),
		mul: freq * modrate * index) * modEnv;

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;
	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmkik2, {| out, pan, freq = 21, modrate = 1.5, index = 5, patk = 0.01, plen = 0.1, prate = 4, amp = 0.9, atk = 0.01, len = 1, curveRate = 7, contour = 1|
	var cr = -1.0 * curveRate;
	var env = EnvGen.kr(Env.perc(atk, len, curve: cr), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, 1 * contour));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = LFSaw.ar(
		freq * modrate * (1 + pEnv),
		mul: freq * modrate * index) * (modEnv);

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

SynthDef(\fmsn, {| out, pan, freq = 40, modrate = 3, index = 0.5, patk = 0.01, plen = 0.15, prate = 8, amp = 0.9, atk = 0.01, len = 0.7, noiseamp = 0.5, curveRate = 4|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));

	var mod = Pulse.ar(
		freq * modrate * (1 + pEnv),
		0.5,
		freq * modrate * (1 + modEnv)
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

SynthDef(\fmsn2, {| out, pan, freq = 100, modrate = 3, index = 12, patk = 0.02, plen = 0.2, prate = 8, amp = 0.9, atk = 0.01, len = 1, curveRate = 8, contour = 0.7|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, 1 * contour));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate, curve: -10));
	var mod = LFSaw.ar(
		freq * modrate * (1 + pEnv),
		mul: freq * modrate * index) * (modEnv);

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

SynthDef(\fmfilter, {| out, pan, freq = 40, modrate = 1, index = 1, patk = 0.001, plen = 0.05, prate = 4, amp = 0.9, atk = 0.001, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modrate * (1 + pEnv),
		0,
		freq * modrate * (index));

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp) * env;

	var outnode = RLPF.ar(car , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmpad, {| out, pan, freq = 40, modrate = 0.5, index = 1, patk = 0.001, plen = 0.0001, prate = 4, amp = 0.8, atk = 0.01, len = 4, sust = 1, detune = 0.1, curveRate = 4, cutoff = 2000, q = 0.1|
	var env = EnvGen.kr(Env.adsr(atk, len, sust) , doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modrate * (1 + pEnv),
		0,
		freq * modrate * (index) );

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

SynthDef(\fmsaw, {| out, pan, freq = 40, modrate = 1, index = 1, patk = 0.001, plen = 0.01, prate = 4, amp = 0.9, atk = 0.01, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len, index));
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = LFSaw.ar(
		freq * modrate * (1 + pEnv) ,
		mul: freq * modrate) * modEnv;

	var car = SinOsc.ar(
		freq + mod * (1 + pEnv),
		mul: amp) * env;

	var outnode = RLPF.ar(car , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmperc, {| out, pan, freq = 40, modrate = 2, index = 0.5, patk = 0.0001, plen = 0.05, prate = 4, amp = 0.9, atk = 0.0001, len = 2, curveRate = 4|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modrate * (2 + pEnv),
		0,
		freq * modrate * (index));

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp) * env;
	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmkey, {| out, pan, freq = 40, modrate = 1, index = 2, patk = 0.0001, plen = 0.001, prate = 4, amp = 0.9, atk = 0.0001, len = 4, curveRate = 4, q = 0.1|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = SinOsc.ar(
		freq * modrate * (2 + pEnv),
		mul: freq * modrate * (index));
	var snd = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		mul: amp) * env;
	snd = [FreqShift.ar(snd, 0), FreqShift.ar(snd, 2)];
	snd = RLPF.ar(snd, XLine.kr(12000, 1000, len), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmcp, {| out, pan, freq = 600, modrate = 4, index = 24, patk = 0.001, plen = 0.1, prate = 8, amp = 0.9, atk = 0.0001, len = 0.6, curveRate = 4, q = 0.5|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var fr = 1000;
	var mod = LFSaw.ar(
		fr * modrate * (1 + pEnv),
		mul: fr * modrate * (index));
	var snd = SinOsc.ar(
		(fr + mod) * (1 + pEnv) ,
		mul: amp) * env;

	snd = RLPF.ar(snd, XLine.kr(10000, 6000, 0.5), ( 0.01 + 1 - q ));
	snd = SoftClipAmp.ar(snd, 3);
	// snd = PitchShift.ar(snd, 0.01, 1, 0.2) * 4 ;
	snd = RHPF.ar(snd, freq, 0.5) * XLine.kr(1, 0.001, 1);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\fmhat, {| out, pan, freq = 4000, modrate = 4.1, index = 24.1, patk = 0.001, plen = 0.05, prate = 0, amp = 0.9, atk = 0.0001, len = 2, sust = 0, curveRate = 4, q = 0.5|
	var env = EnvGen.kr(Env.adsr(atk, len, sust), doneAction: 2);
	var fr = 2000;
	var mod = LFSaw.ar(
		fr * modrate,
		mul: fr * modrate * (index));
	var snd = SinOsc.ar(
		(fr + mod),
		mul: 0.7) * env;

	snd = RHPF.ar(snd, freq, 0.3);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, env)
	)
}).add;

SynthDef(\wub, {|out, pan, freq = 80, index = 32, modrate = 1, len = 1, sust = 1, cutoff = 9000, q = 0.1|
	var snd;
	var env = EnvGen.ar(Env.adsr(decayTime:len, sustainLevel: sust), doneAction: 2);
	var n = 16;
	var partials = Array.fill(n, {|i| 2 * i * (freq) });
	snd = Mix.fill(n, {|i|
		SinOsc.ar((partials[i] * modrate) + (0.1 * Rand(0.1 , 10))) * SinOsc.ar(freq / 2, mul: freq * index ) * 1 / n;
	});
	snd = snd * env;
	snd = [LPF.ar(snd/n, SinOsc.ar(1.3, mul: 500,add: 1000), 0.3), LPF.ar(snd/n, SinOsc.ar(0.7, mul: 700,add: 1300), 0.3)];
	snd = SoftClipAmp.ar(snd);
	snd = RLPF.ar(
		snd,
		100 + EnvGen.ar(Env.perc( releaseTime: len,level: cutoff)),
		( 0.01 + 1 - q )
	);
	snd = snd * 0.6;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan)
	);
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



SynthDef(\mplk, {| out, pan, freq = 440, atk = 0.01, len = 4, amp = 0.9, prate = 8 , plen = 0.01, stereorate = 3, q = 0.8 |
	var snd;
	var basefreqs = [472, 953, 1423, 2378, 2920, 3401, 3877, 4332];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	});
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	snd = Klang.ar(`[ratio, Array.fill(basefreqs.size, {|i| (1 / basefreqs.size) ** 0.6}), nil], freq);
	snd = snd / basefreqs.size * env;
	snd = snd + SinOsc.ar(freq * (1 + pEnv), mul: 0.2);
	snd = snd * 6.dbamp;
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 2)];
	snd = RLPF.ar(snd, XLine.kr(12000, 1000, len), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, env)
	);
}).add;

SynthDef(\mplk2, {| out, pan, freq = 440, atk = 0.01, len = 4, amp = 0.9, prate = 4 , plen = 0.01, stereorate = 3, q = 0.8 |
	var snd;
	var ratios = [ 1.0, 2.0190677966102, 3.0148305084746, 5.0381355932203, 6.1864406779661, 7.2055084745763, 8.2139830508475, 9.1779661016949 ];
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	snd = Mix.arFill(ratios.size, {|i|
		SinOsc.ar(freq * ratios[i]) * i.linexp(0.01, 0.9, ratios.size, 1);
	});
	snd = snd / ratios.size * env;
	snd = snd + SinOsc.ar(freq * (1 + pEnv), mul: 0.2);
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 2)];
	snd = RLPF.ar(snd, XLine.kr(12000, 1000, len), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, env)
	);
}).add;

)

Synth(\fmcp);

(

	var basefreqs = [472, 953, 1423, 2378, 2920, 3401, 3877, 4332];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	}).postln;

)
