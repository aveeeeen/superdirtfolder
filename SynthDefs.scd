

(

var numChannels = ~dirt.numChannels;

//custom effects

// Spectral scramble
~dirt.addModule(\scm, { |dirtEvent|
	dirtEvent.sendSynth('spectral-scram' ++ numChannels,
		[
			scram: ~scram,
			out: ~out
		]
	)
}, { ~scram.notNil });

SynthDef('spectral-scram' ++ numChannels, { |out, scram|
	var signal, chain;
	signal = In.ar(out, ~dirt.numChannels);
	chain = signal.asArray.collect { |x| FFT(LocalBuf(2048), x) };
	signal = IFFT(PV_BinScramble(chain, wipe: 0.1, width: scram));
	ReplaceOut.ar(out, signal)
}, [\ir, \ir]).add;


~dirt.addModule('frz', { |dirtEvent|
	dirtEvent.sendSynth(\spectralFreeze ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			amp: ~frz,
			rate: ~rate,
			grainDur: ~graindur,
			out: ~out
		]
	)
}, { ~frz.notNil });

// 2. スペクトラルフリーズ - 時間が止まったような効果
SynthDef(\spectralFreeze ++ numChannels, {
    arg out, bufnum, amp = 0.4, freezeProb = 0.3;
    var input, buf, chain, freeze, output;

	input = In.ar(out, numChannels);

    // FFT処理
    chain = FFT(LocalBuf(2048 * 4), input);

    // ランダムなタイミングでスペクトラムをフリーズ
    freeze = LFNoise0.ar(LFNoise1.ar(0.1).range(0.1, 2)) < freezeProb;
    chain = PV_MagFreeze(chain, freeze);

    // 位相をスクランブル
    chain = PV_PhaseShift(chain, LFNoise2.ar(0.05) * pi);

    output = IFFT(chain);
    output = output * amp;

    // ステレオ化とリバーブ
    output = Pan2.ar(output, LFNoise1.ar(0.2));

	OffsetOut.ar(out, output);
}).add;

~dirt.addModule('shortbuf', { |dirtEvent|
	dirtEvent.sendSynth('shortbufrd_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			bufrd: ~shortbuf,
			bufrate: ~bufrate,
			out: ~out
		]
	)
}, { ~shortbuf.notNil });


SynthDef("shortbufrd_" ++ numChannels, { |out, bufrd = 0.5, bufrate = 4, buflen = 2, modfreq = 400, modamt = 8|

	var input, signal, buf, basefreq, phs, outsig;
	var lfoFreq = 0.3;
	var pan = LFNoise1.ar(lfoFreq * 5).range(-1.0, 1.0);
	input = In.ar(out, numChannels);
	buf = Buffer.alloc(s, s.sampleRate / 32, numChannels);
	RecordBuf.ar(input, buf);
	bufrate = bufrate * BufRateScale.kr(buf);
	basefreq = (bufrate) * 0.5 / (BufDur.kr(buf))   ;
	phs = LFSaw.ar(
		basefreq
	).range(0, BufFrames.kr(buf));
	signal = BufRd.ar(numChannels, buf, phs);
	outsig = input + (signal * bufrd);
	ReplaceOut.ar(out, outsig);
}).add;

~dirt.addModule('buf', { |dirtEvent|
	dirtEvent.sendSynth('bufrd_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			bufrd: ~buf,
			bufrate: ~bufrate,
			buftempo: ~buftempo,
			out: ~out
		]
	)
}, { ~buf.notNil });


SynthDef("bufrd_" ++ numChannels, { |out, bufrd = 0.5, bufrate = 2, buftempo = 120, modfreq = 400, modamt = 8|

	var input, signal, buf, basefreq, phs, outsig;
	var lfoFreq = 0.3;
	var pan = LFNoise1.ar(lfoFreq * 5).range(-1.0, 1.0);
	input = In.ar(out, numChannels);
	buf = Buffer.alloc(s, s.sampleRate * 1, numChannels);
	RecordBuf.ar(input, buf);
	bufrate = bufrate * BufRateScale.kr(buf);
	basefreq = (bufrate) * 0.5 / BufDur.kr(buf)  ;
	phs = LFSaw.ar(
		basefreq
	).range(0, BufFrames.kr(buf));
	signal = BufRd.ar(numChannels, buf, phs);
	// signal = Pan2.ar(signal, pan);
	outsig = input + (signal * bufrd);
	ReplaceOut.ar(out, outsig);
}).add;


~dirt.addModule('bitcrush', { |dirtEvent|
	dirtEvent.sendSynth('bc_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			bitcrush: ~bitcrush,
			samplerate: ~samplerate,
			out: ~out
		]
	)
}, { ~bitcrush.notNil or: ~samplerate.notNil });


SynthDef("bc_" ++ numChannels, { |out, bitcrush = 4, samplerate = 32|

	var signal;
	signal = In.ar(out, numChannels);
	//signal = LPF.ar(signal, hftanFreq) + HPF.ar(signal.round(0.5 ** (hftan-1)), hftanFreq);
	signal = Decimator.ar(signal, rate: 44100.0 / samplerate, bits: 24 / bitcrush);
	// signal = LPF.ar(signal, 15000);
	ReplaceOut.ar(out, signal);

}).add;

~dirt.addModule('hfsquiz', { |dirtEvent|
	dirtEvent.sendSynth('hfsquiz_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			hfsquiz: ~hfsquiz,
			hfsquizfreq: ~hfsquizFreq,
			out: ~out
		]
	)
}, { ~hfsquiz.notNil });

SynthDef("hfsquiz_" ++ numChannels, { |out, hfsquiz = 2, hfsquizFreq = 2000|

	var signal;
	signal = In.ar(out, numChannels);
	//signal = LPF.ar(signal, hftanFreq) + HPF.ar(signal.round(0.5 ** (hftan-1)), hftanFreq);
	signal = LPF.ar(signal, hfsquizFreq) + HPF.ar( Squiz.ar(signal, hfsquiz, 2), hfsquizFreq);
	signal = LPF.ar(signal, 15000);
	ReplaceOut.ar(out, signal);

}).add;

~dirt.addModule('hftan', { |dirtEvent|
	dirtEvent.sendSynth('hftan_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			hftan: ~hftan,
			hftanfreq: ~hftanFreq,
			out: ~out
		]
	)
}, { ~hftan.notNil });

SynthDef("hftan_" ++ numChannels, { |out, hftan = 2, hftanFreq = 2000|

	var signal;
	signal = In.ar(out, numChannels);
	//signal = LPF.ar(signal, hftanFreq) + HPF.ar(signal.round(0.5 ** (hftan-1)), hftanFreq);
	signal = LPF.ar(signal, hftanFreq) + HPF.ar((signal * hftan.clip(0,12)).tan.tanh, hftanFreq);
	signal = LPF.ar(signal, 8000).softclip;
	ReplaceOut.ar(out, signal);

}).add;

~dirt.addModule('lftan', { |dirtEvent|
	dirtEvent.sendSynth('lftan_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			lftan: ~lftan,
			lftanfreq: ~lftanFreq,
			out: ~out
		]
	)
}, { ~lftan.notNil });

SynthDef("lftan_" ++ numChannels, { |out, lftan = 2, lftanFreq = 3000|

	var signal;
	signal = In.ar(out, numChannels);
	signal = LPF.ar((signal * lftan.clip(0,4)).tan.tanh, lftanFreq) + HPF.ar(signal, lftanFreq);
	ReplaceOut.ar(out, signal);

}).add;

~dirt.addModule('down', { |dirtEvent|
	dirtEvent.sendSynth('down_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			down: ~down,
			out: ~out
		]
	)
}, { ~down.notNil });

SynthDef("down_" ++ numChannels, { |out, down = 16|

	var signal;
	//var srate = Array.fill(down, {|i| 22050 / (i + 1)});
	signal = In.ar(out, numChannels);
	//signal = LPF.ar(signal, hftanFreq) + HPF.ar(signal.round(0.5 ** (hftan-1)), hftanFreq);
	signal = Latch.ar(signal, Impulse.ar(22050 / down));
	ReplaceOut.ar(out, signal);

}).add;


////////////////////////////////////////////

SynthDef(\sbd2, {
    |out = 0, pan = 0, amp = 1, len = 0.2, sust = 0.1|
    var body, bodyFreq, bodyAmp;
    var pop, popFreq, popAmp;
    var click, clickAmp;
    var snd;

    // body starts midrange, quickly drops down to low freqs, and trails off
    bodyFreq = EnvGen.ar(Env([261, 150, 50], [0.02, 0.1], curve: \exp));
    bodyAmp = EnvGen.ar(Env.linen(0.005, sust, len), doneAction: 2);
    body = SinOsc.ar(bodyFreq) * bodyAmp;
	body = (body*1.4).tanh;
    // pop sweeps over the midrange
    popFreq = XLine.kr(750, 261, 0.01);
    popAmp = EnvGen.ar(Env.linen(0.001, 0.02, 0.001)) * 0.15;
    pop = SinOsc.ar(popFreq) * popAmp;
    // click is spectrally rich, covering the high-freq range
    // you can use Formant, FM, noise, whatever
    clickAmp = EnvGen.ar(Env.perc(0.001, 0.001)) * 0.4;
    click = LPF.ar(Formant.ar(910, 8760, 2110), 10000) * clickAmp;

    snd = body + pop + click;
	snd = snd.tanh;

    OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\sbd, {
    |out = 0, pan = 0, amp = 0.3, len = 0.2, sust = 0.1, freq = 42|
    var body, bodyFreq, bodyAmp;
    var pop, popFreq, popAmp;
    var click, clickAmp;
    var snd;
	// var ring = SinOsc.ar(40);
    // body starts midrange, quickly drops down to low freqs, and trails off
	bodyFreq = EnvGen.ar(Env([freq * 6,freq * 3,freq], [0.03, 0.08], curve: \exp));
    bodyAmp = EnvGen.ar(Env.linen(0.005, sust, len), doneAction: 2);
    body = SinOsc.ar(bodyFreq) * bodyAmp;
    // pop sweeps over the midrange
    popFreq = XLine.kr(750, 261, 0.01);
    popAmp = EnvGen.ar(Env.linen(0.001, 0.02, 0.001)) * 0.15;
    pop = SinOsc.ar(popFreq) * popAmp;
    // click is spectrally rich, covering the high-freq range
    // you can use Formant, FM, noise, whatever
    clickAmp = EnvGen.ar(Env.perc(0.001, 0.0005)) * 0.3;
	click = SinOsc.ar(freq * 4, mul: XLine.kr(80, 0.1, 0.02) * freq * 4);
	click = SinOsc.ar(freq + click) * clickAmp;

	snd = (body + pop + click) * 1.2;
	snd = snd.tanh;

    OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan)
	);
}).add;

SynthDef(\shh, {
	|out, pan, freq = 5000, ringfreq = 700, modrate = 1, amp = 1.5, index = 3, len = 1|
	var snd, mod;
	mod = LFPulse.ar(freq * modrate) * (freq * modrate * index);
	snd = LFPulse.ar(freq + mod);
	snd = snd * LFPulse.ar(ringfreq);
	snd = snd * 3;
	snd = RHPF.ar (snd, 6000, 0.3);
	snd = snd * EnvGen.ar(Env.perc(0.001, len,curve: -8), doneAction: 2);
	snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\skik, {
	|out, pan, freq = 50, modrate = 1, plen = 0.14, index = 32, len = 0.3, amp = 1.5|
	var snd, mod, penv, env, modenv;
	modenv = EnvGen.ar(Env.perc(0.001, 0.01));
	env = EnvGen.ar(Env([0,1,0.7,0], [0.001, len/3, len/4]), doneAction: 2);
	penv = EnvGen.ar(Env.perc(0.001, plen, 6));
	mod = SinOsc.ar(freq * modrate) * (freq * modrate * index) * modenv.linexp(0, 1, 0.001, 1);
	snd = SinOsc.ar(freq * penv.linexp(0,4,1,4) + mod);
	snd = snd; //*\\\ LFPulse.ar(ringfreq);
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.001)).linexp(0, 1, 1, 4);
	snd = snd * 3;
	snd = RHPF.ar(snd, 40, 0.5);
	snd = snd * env;
	snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\sak, {
	|out, pan, amp = 1, freq = 42, plen = 0.1, prate = 8, len 1.4, index = 48, modrate = 1|
	var snd, mod, env, penv;
	var modenv = EnvGen.ar(Env.perc(0.001, len / 4));
	env = EnvGen.ar(Env.perc(0.001, len), doneAction: 2);
	penv = EnvGen.ar(Env([freq, prate * freq, prate * freq / 2 , prate * freq / 4, freq , 20], [0.001, plen / 16, plen / 4 , plen , plen], \exp));
	mod = LFSaw.ar(penv * modrate) * modrate * index;
	snd = SinOsc.ar(penv + mod) * env;
	// snd = LPF.ar(snd, XLine.kr(15000, 500, len / 2));
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.001)).linexp(0, 1, 1, 12);
	snd = RHPF.ar(snd, 30, 0.5);
	snd = snd * 4;
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\sak2, {
	|out, pan, amp = 1, plen = 0.1, freq = 40|
	var len = 2;

	var snd, env;
	snd = SinOsc.ar( Hasher.kr((1 .. 18).normalize).linlin(0, 1, 20, 100) * EnvGen.kr(Env([1, 12, 4, 2], [0.01, plen / 4, plen])));
	snd.sum;
	snd = snd * EnvGen.ar(Env.perc(0.001, len), doneAction: 2);
	// snd = PitchShift.ar(snd, 0.001, 0.5, 0.01);
	snd = snd * 4;
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\ssn, {
	|out, pan, amp = 1, freq = 180, plen = 0.05, len = 0.3|
	var snd, penv, env, noise;
	env = EnvGen.ar(Env.perc(0.001,len * 0.9, curve: -6), doneAction: 2);
	penv = EnvGen.ar(Env.perc(0.001, plen, 4));
	snd = SinOsc.ar(freq * (1 + penv));
	snd = snd; //*\\\ LFPulse.ar(ringfreq);
	snd = snd * env;
	noise = WhiteNoise.ar();
	noise = RHPF.ar(noise, 7000, 0.4) * EnvGen.ar(Env.perc(0.001, len)) * -2.dbamp;
	snd = snd + noise;
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.01)).linexp(0, 1, 1, 4);
	snd = snd * 3;
	snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\scp, {
	| out, pan, freq = 600, amp = 1.5, atk = 0.0001, len = 0.5, curveRate = 6, q = 0.2|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var snd = LFNoise0.ar(12000) * env;

	snd = RLPF.ar(snd, XLine.kr(10000, 6000, len), q.linlin(0, 1, 1, 0.01));
	snd = snd * 10;
	snd = PitchShift.ar(snd, 0.001, 1.1, 0.1) ;
	snd = RHPF.ar(snd, freq, 0.5) * XLine.kr(1, 0.001, len);
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\sperc, {
	|out, pan, amp = 1, freq = 160, modrate = 0.4, plen = 0.1, index = 5, len = 0.4|
	var snd, mod, penv, env, modenv;
	modenv = EnvGen.ar(Env.perc(0.01, len * 0.4));
	env = EnvGen.ar(Env.perc(0.001,len, curve: -6), doneAction: 2);
	penv = EnvGen.ar(Env.perc(0.001, plen, 4, -8));
	mod = SinOsc.ar(freq * modrate) * (freq * modrate * index) * modenv.linexp(0, 1, 0.1, 1);
	snd = SinOsc.ar(freq * penv.linexp(0,4,1,4) + mod);
	snd = snd * env;
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.001)).linexp(0, 1, 1, 4);
	snd = HPF.ar(snd, 80) * 2;
	snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\snoise, {
	|out, pan, amp = 1, len = 1|
	var snd, env;
	env = EnvGen.ar(Env([0, 1, 0], [0.001, len]), doneAction: 2);
	snd = ClipNoise.ar() * env;
	snd = HPF.ar(snd, 7000);
	snd.tan;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

//////////////////////

SynthDef(\randhit, {
	|out, pan, amp = 1, len = 1, freq = 40|
	var snd, env;
	snd = SinOsc.ar(LFNoise0.kr((1 .. 18)).range(1, 5).linlin(1, 5, 20, 12000) * EnvGen.kr(Env([4, 20, 2], [0.01, len])));
	snd.sum;
	snd = PitchShift.ar(snd, 0.001, 0.5, 0.01);
	snd = snd * 4;
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\boom, {
	|out, pan, amp = 1, len = 1, plen = 0.2, freq = 40|
	var snd, env;
	snd = SinOsc.ar(Hasher.kr((1 .. 18).normalize).linlin(0, 1, 20, 12000) * EnvGen.kr(Env([4, 10, 3, 2], [0.01, plen / 4, plen])));
	snd.sum;
	snd = PitchShift.ar(snd, 0.001, 0.5, 0.01);
	snd = snd * 4;
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\beam, {
	|out, pan, amp = 1, len = 1, freq = 40|
	var snd, env;
	snd = SinOsc.ar(LFNoise0.kr((1 .. 18).normalize).linlin(0, 1, 20, 12000) * EnvGen.kr(Env([2.4, 2.5], [len])));
	snd.sum;
	snd = PitchShift.ar(snd, 0.001, 0.5, 0.01);
	snd = snd * 4;
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\knife, {
	|out, pan, amp = 1, len = 1, freq = 88|
	var snd, env;
	snd = SinOsc.ar( (1 .. 19).normalize.pow(XLine.kr(4, 4.8, 0.1)).tan.linlin(0, 1, 20, 8000) * (freq / 4).midiratio );
	snd.sum;
	// snd = BPF.ar(snd, XLine.ar(6000, 100, len) * [1, 1.5], 0.6).sum;
	snd = PitchShift.ar(snd, 0.001, 1, 0.01);
	// snd = Splay.ar(snd);
	snd = CombC.ar(snd, 0.1, 1 / XLine.kr(80, 120, len), 0.1);
	snd = RLPF.ar(snd, XLine.kr(12000, 1000, len / 2), 0.5);
	snd = snd * 3;
	snd = snd * Env.linen(0.01, 0.1, len).ar(Done.freeSelf);
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\perc2, {| out, pan, freq = 60, plen = 0.01, prate = 2, amp = 1, atk = 0.05, len = 2|
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
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\sinpad, {| out, pan, freq = 60, plen = 0.01, prate = 2, amp = 1, atk = 0.01, len = 2, sust = 1|
	var pEnv = Line.kr(freq * prate ,freq, plen);
	var env = EnvGen.kr(Env.adsr(atk, len, sust, 0.1, curve: -6), doneAction: 2);
	var amplfoL = SinOsc.kr(1.2, mul: 0.3);
	var amplfoR = SinOsc.kr(0.8, mul: 0.3);
	var oscamp = 0.5;
	var mainOsc = [
		((SinOsc.ar(pEnv, 0.0, mul: oscamp) * env) + (SinOsc.ar(pEnv * 0.75, 0.2, mul: oscamp * 0.8) * env)) * (0.2 + amplfoL),
		((SinOsc.ar(pEnv, 1, mul: oscamp) * env) + (SinOsc.ar(pEnv * 0.5, 0.7, mul: oscamp) * env)) * (0.2 + amplfoR)
	];
	var outnode = mainOsc;
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmkik, {| out, pan, freq = 42, modrate = 1, index = 0.7, patk = 0.001, plen = 0.07, prate = 16, amp = 1, atk = 0.001, len = 1, curveRate = 2, contour = 0.8|
	var env = EnvGen.kr(Env.perc(atk, len, curve: (-1.0 * curveRate)), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len)) * contour;
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));

	var clickAmp = EnvGen.ar(Env.perc(0.001, 0.0005)) * 0.1;
	var click, car;

	var mod = SinOsc.ar(
		freq * modrate * (1 + pEnv),
		mul: freq * modrate * index) * modEnv;

	car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;

	click = SinOsc.ar(freq * 4, mul: XLine.kr(80, 0.1, 0.02) * freq * 4);
	click = SinOsc.ar(freq + click) * clickAmp;
	car = car + click;
	car = (RHPF.ar(car, 40, 0.2) * 3).tanh;

	OffsetOut.ar(out,
		DirtPan.ar(car, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmkik2, {| out, pan, freq = 42, modrate = 2, index = -3, patk = 0.001, plen = 0.12, prate = 4, amp = 1, atk = 0.01, len = 3, curveRate = 7, contour = 1|
	var cr = -1.0 * curveRate;
	var env = EnvGen.kr(Env.perc(atk, len, curve: cr), doneAction: 2);
	var modEnv = EnvGen.kr(Env.perc(atk, len)) * contour;
	var pEnv = EnvGen.kr(Env.perc(patk, plen, prate));
	var mod = LFSaw.ar(
		freq * modrate * (1 + pEnv),
		mul: freq * modrate * index) * (modEnv);

	var car = SinOsc.ar(
		(freq + mod) * (1 + pEnv) ,
		0,
		amp
	) * env;


	var output = RHPF.ar(car * 4, 40, 0.2).softclip;
	OffsetOut.ar(out,
		DirtPan.ar(output, ~dirt.numChannels, pan, env)
	);
}).add;

SynthDef(\fmsn, {| out, pan, freq = 40, modrate = 3, index = 0.5, patk = 0.01, plen = 0.15, prate = 8, amp = 1, atk = 0.01, len = 0.7, noiseamp = 0.5, curveRate = 4|
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
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmsn2, {| out, pan, freq = 100, modrate = 3, index = 12, patk = 0.02, plen = 0.2, prate = 8, amp = 1, atk = 0.01, len = 1, curveRate = 8, contour = 0.7|
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
		DirtPan.ar(output, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmfilter, {| out, pan, freq = 40, modrate = 1, index = 1, patk = 0.001, plen = 0.002, prate = 4, amp = 1, atk = 0.001, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
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
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmpad, {| out, pan, freq = 40, modrate = 0.5, index = 1, patk = 0.001, plen = 0.0001, prate = 4, amp = 1, atk = 0.01, len = 4, sust = 1, detune = 0.1, curveRate = 4, cutoff = 2000, q = 0.1|
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
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmsaw, {| out, pan, freq = 40, modrate = 1, index = 1, patk = 0.001, plen = 0.01, prate = 4, amp = 1, atk = 0.01, len = 1, curveRate = 4, cutoff = 8000, q = 0.1|
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
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmperc, {| out, pan, freq = 40, modrate = 2, index = 0.5, patk = 0.0001, plen = 0.05, prate = 4, amp = 1, atk = 0.0001, len = 2, curveRate = 4|
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
		DirtPan.ar(car, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmkey, {| out, pan, freq = 40, modrate = 1, index = 2, patk = 0.0001, plen = 0.001, prate = 4, amp = 1, atk = 0.0001, len = 4, curveRate = 4, q = 0.1|
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
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\ssub, {| out, pan, freq = 40, modrate = 0.5, index = 1.25, amp = 1, atk = 0.0001, len = 0.3, sust = 0.9|
	var env, mod, snd;
	env = EnvGen.kr(Env.adsr(0.001, len, sust, 0.1), doneAction: 2);
	snd = SinOsc.ar([1, 2, 3] * freq, mul: [0.3, 0.01, 0.05]);
	snd = snd.sum;
	snd = snd * env;
	snd = (snd * 7);
	snd = RLPF.ar(snd, 200);
	snd = snd.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmcp, {| out, pan, freq = 600, modrate = 4, index = 24, patk = 0.001, plen = 0.1, prate = 8, amp = 1.5, atk = 0.0001, len = 0.3, curveRate = 4, q = 0.5|
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

	// snd = PitchShift.ar(snd, 0.01, 1, 0.2) * 4 ;
	snd = RHPF.ar(snd, freq, 0.3) * XLine.kr(1, 0.001, 1);
	snd = (snd*3).tanh;
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmhat, {| out, pan, freq = 4000, modrate = 4.1, index = 24.1, patk = 0.001, plen = 0.05, prate = 0, amp = 1, atk = 0.0001, len = 2, sust = 0, curveRate = 4, q = 0.5|
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
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\fmhh, {| out, pan, freq = 5000, modrate = 4.1, index = 24.1, patk = 0.001, plen = 0.05, prate = 0, amp = 0.9, atk = 0.0001, len = 0.1, sust = 0, curveRate = 4, q = 0.5|
	var env = EnvGen.kr(Env.adsr(atk, len, sust), doneAction: 2);
	var fr = 4000;
	var mod = LFSaw.ar(
		fr * modrate,
		mul: fr * modrate * (index));
	var snd = SinOsc.ar(
		(fr + mod),
		mul: 0.7) * env;

	snd = RHPF.ar(snd, freq, 0.3);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\wub, {|out, pan, amp = 1, freq = 80, index = 32, modrate = 1, len = 1, sust = 1, cutoff = 9000, q = 0.1|
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
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
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
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\detsaw, {| out, pan, freq = 440, atk = 0.01, len = 2, sust = 1, amp = 0.9, prate = 0 , plen = 0.001 , q = 0.1, detune = 0.01, cutoff = 6000, cutoffspd = 2|
	var env = EnvGen.kr(Env.adsr(atk, len, sust) , doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	var sawL = Saw.ar(
		(freq) * (pEnv + 1) + (1 * detune)
	) * env;

	var sawR = Saw.ar(
		(freq) * (pEnv + 1) - (1 * detune)
	) * env;

	var outnode = RLPF.ar([sawL,sawR] , XLine.kr(cutoff, 300, cutoffspd), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\sawpad, {| out, pan, freq = 440, atk = 0.01, len = 2, sust = 1, amp = 1, prate = 0 , plen = 0.001 , q = 0.1, detune = 0.02, lpfstart = 10000, lpfend = 500, cutoffspd = 0|
	var env = EnvGen.kr(Env.adsr(atk, len, sust) , doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.01, plen, prate));
	var saw = Saw.ar(freq * (1 .. 8).linexp(1, 6, 1.001, (1 + detune))) * env;
	saw = Splay.ar(saw);
	saw = RLPF.ar(saw , XLine.kr(lpfstart, lpfend, len), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(saw, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\chirp, {| out, pan, freq = 40, atk = 0.001, len = 0.5, amp = 0.9, prate = 300 , plen = 0.1 , q = 0.5, cutoff = 12000, cutoffspd = 0|
	var env = EnvGen.kr(Env.perc(atk, len, curve: -7), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.01, plen, prate, -7));
	var osc2 = SinOsc.ar(freq * (1 + pEnv) ) * env;
	var outnode = RLPF.ar(osc2 , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ));
	outnode = HPF.ar(outnode, 30) * 2;
	outnode.tanh;
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\chirp2, {| out, pan, freq = 40, atk = 0.01, len = 1, amp = 0.9, prate = 256 , plen = 0.1 , q = 1, cutoff = 12000, cutoffspd = 0|
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.01, plen, prate));
	var osc2 = WhiteNoise.ar * env;
	var outnode = RLPF.ar(osc2 , XLine.kr(cutoff, 20, len), ( 0.01 + 1 - q ), 0.3);
	OffsetOut.ar(out,
		DirtPan.ar(outnode, ~dirt.numChannels, pan, amp)
	);
}).add;



SynthDef(\mplk, {| out, pan, freq = 440, atk = 0.01, len = 4, amp = 1, prate = 8 , plen = 0.01, stereorate = 3, q = 0.8 |
	var snd;
	var basefreqs = [469, 938, 1199, 1406, 1984, 2334, 2454, 2814, 2922, 3388, 3859];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	});
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	snd = Klang.ar(`[ratio, Array.fill(basefreqs.size, {|i| (1 / basefreqs.size) ** 0.8}), nil], freq);
	snd = snd / basefreqs.size * env;
	snd = snd + SinOsc.ar(freq * (1 + pEnv), mul: 0.2);
	snd = snd * 4.dbamp;
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 2)];
	snd = RLPF.ar(snd, XLine.kr(12000, 1000, len), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\mplk2, {| out, pan, freq = 440, atk = 0.01, len = 4, amp = 0.9, prate = 8 , plen = 0.01, stereorate = 2.2, q = 0.5 |
	var snd;
	/*var basefreqs = [469, 938, 1199, 1406, 1984, 2334, 2454, 2814, 2922, 3388, 3859];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	});*/
	var ratio = [ 1.0, 2.0, 2.5565031982942, 2.997867803838, 4.2302771855011, 4.9765458422175, 5.2324093816631, 6.0, 6.2302771855011, 7.2238805970149, 8.228144989339 ];
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	snd = SinOsc.ar(
		freq: ratio * freq,
		mul: (1 .. ratio.size).linexp(1, ratio.size, 1, 0.001)
	);
	snd = snd.sum(); // or snd = Mix.ar(snd);

	snd = snd / ratio.size * env;
	snd = snd + SinOsc.ar(freq * (1 + pEnv), mul: 0.1);
	// snd = snd * freq.linexp(100, 10000, 0.9, 0.4);
	snd = snd * 8.dbamp;
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 2)];
	snd = RLPF.ar(snd, XLine.kr(12000, 1000, len), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\mkey, {| out, pan, freq = 440, atk = 0.01, len = 4, amp = 0.9, prate = 8 , plen = 0.005, stereorate = 5, q = 0.5, cutoff 10000 |
	var snd;
	var basefreqs = [312, 623, 935, 1247, 1557, 1870, 2183, 2496, 2805, 3118, 3432, 4054, 4356, 4727];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	});
	var env = EnvGen.kr(Env.perc(atk, len), doneAction: 2);
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));
	snd = Klang.ar(`[ratio, Array.fill(basefreqs.size, {|i| (1 / basefreqs.size) ** 0.7}), nil], freq);
	snd = snd / basefreqs.size * env;
	snd = snd + SinOsc.ar(freq * (1 + pEnv), mul: 0.2);
	snd = snd * 4.dbamp;
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 0)];
	snd = PitchShift.ar(snd, 0.001, 1.25, 0.1) + PitchShift.ar(snd, 0.001, 0.75, 0.1);
	snd = RLPF.ar(snd, XLine.kr(cutoff, 4000, 0.9), ( 0.01 + 1 - q ));
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\ep, {| out, pan, freq = 440, atk = 0.01, len = 2, sust = 0.7, amp = 0.9, prate = 8 , plen = 0.01, stereorate = 2, q = 0 |
	var snd;
	// [261.5, 522.8, 784.2, 1046, 1307, 1568, 1803, 2091, 2353, 2614]; freq
	// [1.2, 1.0, 0.6, 0.1, 0.001, 0.0001, 0.0001, 0.0001, 0.01, 0.005] mul
	var basefreqs = [261.5, 522.8, 784.2, 1046, 1307, 1568, 1803, 2091, 2353, 2614];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	});
	var basefreqs_ = [401.4, 664.1, 923.7, 1185, 1901];
	var ratio_ = basefreqs_.size.collect({|i|
		(basefreqs_[i] / basefreqs_[0]);
	});
	var harm = Klang.ar(`[ratio_, Array.fill(basefreqs_.size, {|i| (1 / basefreqs_.size) ** 2}), nil], freq);
	var env = EnvGen.kr(Env.adsr(decayTime: len, sustainLevel: sust), doneAction: 2);
	var harmenv = EnvGen.kr(Env.perc(releaseTime: 0.1));
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));

	snd = Klang.ar(`[ratio, [1.0, 0.9, 0.6, 0.1, 0.001, 0.0001, 0.0001, 0.0001, 0.01, 0.005], nil], freq, 1);
	snd = snd / basefreqs.size * env * freq.linexp(100, 10000, 1, 0.01);
	harm = harm / basefreqs_.size;
	harm = harm * harmenv;
	snd = snd + harm;
	snd = snd * 8.dbamp;
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 1)];
	// snd = PitchShift.ar(snd, 0.01);
	snd = RLPF.ar(snd, XLine.kr(10000, 1000, 1), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

SynthDef(\ep2, {| out, pan, freq = 440, atk = 0.01, len = 2, sust = 0.7, amp = 0.9, prate = 8 , plen = 0.01, stereorate = 2, q = 0 |
	var snd;
	// [261.5, 522.8, 784.2, 1046, 1307, 1568, 1803, 2091, 2353, 2614]; freq
	// [1.2, 1.0, 0.6, 0.1, 0.001, 0.0001, 0.0001, 0.0001, 0.01, 0.005] mul
	var basefreqs = [261.5, 522.8, 784.2, 1046, 1307, 1568, 1803, 2091, 2353, 2614];
	var ratio = basefreqs.size.collect({|i|
		(basefreqs[i] / basefreqs[0]);
	});
	var basefreqs_ = [401.4, 664.1, 923.7, 1185, 1901];
	var ratio_ = basefreqs_.size.collect({|i|
		(basefreqs_[i] / basefreqs_[0]);
	});
	var harm = Klang.ar(`[ratio_, Array.fill(basefreqs_.size, {|i| (1 / basefreqs_.size) ** 2}), nil], freq);
	var env = EnvGen.kr(Env.adsr(decayTime: len, sustainLevel: sust), doneAction: 2);
	var harmenv = EnvGen.kr(Env.perc(releaseTime: 0.1));
	var pEnv = EnvGen.kr(Env.perc(0.001, plen, prate));

	snd = Klang.ar(`[ratio, (ratio.size .. 1).linexp(1, ratio.size, 0.0001, 1), nil], freq, 1);
	snd = snd / basefreqs.size * env * freq.linexp(100, 10000, 1, 0.01);
	harm = harm / basefreqs_.size;
	harm = harm * harmenv;
	snd = snd + harm;
	snd = snd * 8.dbamp;
	snd = [FreqShift.ar(snd, stereorate), FreqShift.ar(snd, 1)];
	// snd = PitchShift.ar(snd, 0.01);
	snd = RLPF.ar(snd, XLine.kr(10000, 1000, 1), ( 0.01 + 1 - q ));
	snd = snd + LFNoise1.ar(15000, 0.003);
	OffsetOut.ar(out,
		DirtPan.ar(snd, ~dirt.numChannels, pan, amp)
	);
}).add;

)

Synth(\fmcp);

(
SynthDef(\pulsering, {
	|out, freq = 5000, ringfreq = 700, modrate = 1, index = 3, len = 1|
	var snd, mod;
	mod = LFPulse.ar(freq * modrate) * (freq * modrate * index);
	snd = LFPulse.ar(freq + mod);
	snd = snd * LFPulse.ar(ringfreq);
	snd = RHPF.ar (snd, 6000, 0.3);
	snd = snd * EnvGen.ar(Env.perc(0.001, len,curve: -8), doneAction: 2);
	Out.ar(out, snd ! 2);
}).add;

SynthDef(\skik, {
	|out, freq = 50, modrate = 2, plen = 0.14, index = 32, len = 0.3|
	var snd, mod, penv, env, modenv;
	modenv = EnvGen.ar(Env.perc(0.001, 0.001));
	env = EnvGen.ar(Env.perc(0.001,len), doneAction: 2);
	penv = EnvGen.ar(Env.perc(0.001, plen, 4));
	mod = SinOsc.ar(freq * modrate) * (freq * modrate * index) * modenv;
	snd = SinOsc.ar(freq * penv.linexp(0,4,1,4) + mod);
	snd = snd; //*\\\ LFPulse.ar(ringfreq);
	snd = snd * env;
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.001)).linexp(0, 1, 1, 4);
	snd.tanh;
	Out.ar(out, snd ! 2);
}).add;

SynthDef(\sperc, {
	|out, freq = 160, modrate = 0.4, plen = 0.1, index = 3, len = 0.4|
	var snd, mod, penv, env, modenv;
	modenv = EnvGen.ar(Env.perc(0.01, len * 0.5));
	env = EnvGen.ar(Env.perc(0.001,len, curve: -8), doneAction: 2);
	penv = EnvGen.ar(Env.perc(0.001, plen, 4, -8));
	mod = SinOsc.ar(freq * modrate) * (freq * modrate * index) * modenv.linexp(0, 1, 0.5, 1);
	snd = SinOsc.ar(freq * penv.linexp(0,4,1,4) + mod);
	snd = snd;
	snd = snd * env;
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.001)).linexp(0, 1, 1, 4);
	snd.tanh;
	Out.ar(out, snd ! 2);
}).add;


SynthDef(\ssn, {
	|out, freq = 150, plen = 0.04|
	var len = 0.18;
	var snd, penv, env, noise;
	env = EnvGen.ar(Env.perc(0.001,len), doneAction: 2);
	penv = EnvGen.ar(Env.perc(0.001, plen, 4));
	snd = SinOsc.ar(freq * (1 + penv));
	snd = snd; //*\\\ LFPulse.ar(ringfreq);
	snd = snd * env;
	noise = WhiteNoise.ar();
	noise = RHPF.ar(noise, 5000, 0.2) * EnvGen.ar(Env.perc(0.001, len * 1.1)) * -2.dbamp;
	snd = snd + noise;
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.01)).linexp(0, 1, 1, 4);
	snd.tanh;
	Out.ar(out, snd ! 2);
}).add;

SynthDef(\sak, {
	|out, pan, amp, freq = 42, plen = 0.1, prate = 4, len 1, index = 5, modrate = 1|
	var snd, mod, env, penv;
	var modenv = EnvGen.ar(Env.perc(0.001, len / 4));
	env = EnvGen.ar(Env( [0, 1, 0.2, 0] , [0.001, len / 2, len]), doneAction: 2);
	penv = EnvGen.ar(Env([freq, prate * freq, prate * freq / 2, freq , 20], [0.001, plen / 8, plen / 2 , plen], \exp));
	mod = LFSaw.ar(penv * modrate) * modrate * (index);
	snd = SinOsc.ar(penv + mod) * env;
	snd = LPF.ar(snd, XLine.kr(15000, 500, len / 4));
	snd = snd * EnvGen.ar(Env.perc(0.001, 0.01)).linexp(0, 1, 1, 12);
	snd = snd * 4;
	snd = snd.tanh;
	Out.ar(out, snd ! 2);
}).add;
)


~hat = Synth(\pulsering, [\freq: 5000, \ringfreq: 700, \modrate: 1, \index: 3]);

Synth(\sak);


(
~seq1 = Task({
	inf.do({|i|
		~hat;
		0.25.wait;
	});
}).play;
)

~hat.set(\freq, 200);

~task.pause

(

Synth(\skik);
r = Routine({
    var delta;
    loop {
        delta = 0.5;
        0.25.yield;
		Synth(\pulsering, [\freq: 5000, \ringfreq: 700, \modrate: 1, \index: 3]);
		0.25.yield;

    }
});
)

BufR

r.next;

TempoClock.default.sched(0, r);

r.stop;

