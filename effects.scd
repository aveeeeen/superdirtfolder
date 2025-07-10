//// custom global effects

(
var numChannels = ~dirt.numChannels;

	SynthDef("cmap_g" ++ numChannels, {
		arg dryBus, effectBus, gate = 1, cmap = 0;
		var input, chainL, chainR, output;
		input = In.ar(dryBus, numChannels);

		chainL = FFT(LocalBuf(2048, 1), input[0]);
		chainL = PV_ConformalMap(chainL, 0, cmap);

		chainR = FFT(LocalBuf(2048, 1), input[1]);
		chainR = PV_ConformalMap(chainR, 0, cmap);
		output = [IFFT(chainL), IFFT(chainR)];

		output = output * EnvGen.kr(Env.asr, gate, doneAction:2);
		DirtPause.ar(output.sum, graceTime:4);

		ReplaceOut.ar(dryBus, output);
	}, [\ir, \ir]).add;

	SynthDef("binshift_g" ++ numChannels, {
		arg dryBus, effectBus, gate = 1, stretch = 1, shift = 0;
		var input, chainL, chainR, output;
		input = In.ar(dryBus, numChannels);

		chainL = FFT(LocalBuf(2048, 1), input[0]);
		chainL = PV_BinShift(chainL, stretch, shift);

		chainR = FFT(LocalBuf(2048, 1), input[1]);
		chainR = PV_BinShift(chainR, stretch, shift);
		output = [IFFT(chainL), IFFT(chainR)];
		output = output * EnvGen.kr(Env.asr, gate, doneAction:2);
		DirtPause.ar(output.sum, graceTime:4);

		ReplaceOut.ar(dryBus, output);
	}, [\ir, \ir]).add;
);

(
~dirt.orbits.do { |x|
	x.globalEffects = x.globalEffects.addFirst(
		GlobalDirtEffect(\cmap_g, [\cmap]),
	);
	x.globalEffects = x.globalEffects.addFirst(
		GlobalDirtEffect(\binshift_g, [\shift, \stretch]),
	);
	x.initNodeTree;
};
);

//// custom effects

(

var numChannels = ~dirt.numChannels;


// Spectral scramble
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

SynthDef("hfsquiz_" ++ numChannels, { |out, hfsquiz = 2, hfsquizFreq = 1000|

	var signal;
	signal = In.ar(out, numChannels);
	//signal = LPF.ar(signal, hftanFreq) + HPF.ar(signal.round(0.5 ** (hftan-1)), hftanFreq);
	signal = LPF.ar(signal, hfsquizFreq) + HPF.ar( Squiz.ar(signal, hfsquiz, 2), hfsquizFreq);
	signal = LPF.ar(signal, 15000);
	ReplaceOut.ar(out, signal);

}).add;

~dirt.addModule('fold', { |dirtEvent|
	dirtEvent.sendSynth('fold_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			fold: ~fold,
			foldrate: ~foldrate,
			out: ~out
		]
	)
}, { ~fold.notNil });

SynthDef("fold_" ++ numChannels, { arg out, fold = 0;
	var input, signal, sigLF, sigHF, chainLF, chainHF;
	var wipe = 0.005;
	input = In.ar(out, numChannels);
	chainLF = FFT({ LocalBuf(2048) } ! 2, input);
	chainHF = FFT({ LocalBuf(2048) } ! 2, input);
	chainLF = PV_BrickWall(chainLF, (1 - wipe) * -1);
	chainHF = PV_BrickWall(chainHF, wipe);
	sigLF = IFFT(chainLF);
	sigHF = IFFT(chainHF);
	sigHF = sigHF.fold2(fold);
	signal = sigLF + sigHF;
	// signal = input.fold(foldrate * -1, foldrate);
	// input = (input * (1 - fold)) + (signal * fold);
	ReplaceOut.ar(out, signal);
}).add;

// SynthDef("fold_" ++ numChannels, { |out, fold = 1, foldrate = 0.3|
// 	var input, signal;
// 	input = In.ar(out, numChannels);
// 	signal = input.fold(foldrate * -1, foldrate);
// 	input = (input * (1 - fold)) + (signal * fold);
// 	ReplaceOut.ar(out, input);
// }).add;

~dirt.addModule('scm', { |dirtEvent|
	dirtEvent.sendSynth('spectral-scram_' ++ numChannels,
		[
			scram: ~bscram,
			out: ~out
		]
	)
}, { ~bscram.notNil });

SynthDef('spectral-scram_' ++ numChannels, { |out, scram|
	var signal, chain;
	signal = In.ar(out, numChannels);
	chain = signal.asArray.collect { |x| FFT(LocalBuf(2048), x) };
	signal = IFFT(PV_BinScramble(chain, wipe: 0.1, width: scram));
	ReplaceOut.ar(out, signal)
}, [\ir, \ir]).add;

// ~dirt.addModule('binshift', { |dirtEvent|
// 	dirtEvent.sendSynth('binshift_' ++ numChannels,
// 		[
// 			shift: ~shift,
// 			rate: ~stretch,
// 			out: ~out
// 		]
// 	)
// }, { ~shift.notNil or: ~stretch.notNil });
//
//
// SynthDef('binshift_' ++ numChannels, {
// 	arg out, rate = 1, shift = 0;
// 	var input, chainL, chainR, output;
// 	input = In.ar(out, numChannels);
//
// 	chainL = FFT(LocalBuf(2048, 1), input[0]);
// 	chainL = PV_BinShift(chainL, rate, shift);
//
// 	chainR = FFT(LocalBuf(2048, 1), input[1]);
// 	chainR = PV_BinShift(chainR, rate, shift);
// 	output = [IFFT(chainL), IFFT(chainR)];
// 	ReplaceOut.ar(out, output);
// }).add;

// ~dirt.addModule('cmap', { |dirtEvent|
// 	dirtEvent.sendSynth('cmap_' ++ numChannels,
// 		[
// 			cmap: ~cmap,
// 			out: ~out
// 		]
// 	)
// }, { ~cmap.notNil });
//
// SynthDef('cmap_' ++ numChannels, {
// 	arg out, cmap = 0;
// 	var input, chainL, chainR, output;
// 	input = In.ar(out, numChannels);
//
// 	chainL = FFT(LocalBuf(2048, 1), input[0]);
// 	chainL = PV_ConformalMap(chainL, 0, cmap);
//
// 	chainR = FFT(LocalBuf(2048, 1), input[1]);
// 	chainR = PV_ConformalMap(chainR, 0, cmap);
// 	output = [IFFT(chainL), IFFT(chainR)];
// 	ReplaceOut.ar(out, output);
// }).add;

~dirt.addModule('convolution', { |dirtEvent|
	dirtEvent.sendSynth('convolution_' ++ numChannels,
		[
			out: ~out,
			conv: ~conv,
		]
	)
}, { ~conv.notNil });

SynthDef("convolution_" ++ numChannels, { arg out, note, pan = 0, conv = 0;
	var in, kernel, mix;
	kernel = ClipNoise.ar(mul: 0.2);
	in = In.ar(out, numChannels);
	mix = [Convolution.ar(in[0], kernel, 512, 0.5), Convolution.ar(in[1], kernel, 512, 0.5)];
	ReplaceOut.ar(out, Pan2.ar((in * (1.0 - conv)) + (conv * mix), pan));
}).add;

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
    var input, buf, chainL, chainR, freeze, output;

	input = In.ar(out, numChannels);
	chainL = FFT(LocalBuf(2048), input[0]);
	chainR = FFT(LocalBuf(2048), input[1]);

    // ランダムなタイミングでスペクトラムをフリーズ
    freeze = LFNoise0.ar(LFNoise1.ar(0.1).range(0.1, 2)) < freezeProb;
	chainL = PV_MagFreeze(chainL, freeze);
	chainR = PV_MagFreeze(chainR, freeze);

	// 位相をスクランブル
    chainL = PV_PhaseShift(chainL, LFNoise2.ar(0.05) * pi);
	chainR = PV_PhaseShift(chainR, LFNoise2.ar(0.05) * pi);

	output = [IFFT(chainL), IFFT(chainR)];
    output = output * amp;

    // ステレオ化とリバーブ
	// output = Pan2.ar(output, LFNoise1.ar(0.2));

	ReplaceOut.ar(out, output);
}).add;

~dirt.addModule('comb', { |dirtEvent|
	dirtEvent.sendSynth('comb_' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			comb: ~mycomb,
			comblen: ~comblen,
			combrate: ~combrate,
			out: ~out
		]
	)
}, { ~mycomb.notNil });


SynthDef("comb_" ++ numChannels, { arg out, comb = 0, comblen = 1, combrate = 0.1;
	var input;
	input = In.ar(out, numChannels);
	input = CombN.ar(input, 0.2, combrate, comblen, comb) + input;
	ReplaceOut.ar(out, input);
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
	buf = Buffer.alloc(s, s.sampleRate / 8, numChannels);
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

	var input, signal, buf, basefreq, phs, outsig, bufsync;
	var lfoFreq = 0.3;
	var pan = LFNoise1.ar(lfoFreq * 5).range(-1.0, 1.0);
	input = In.ar(out, numChannels);
	buf = Buffer.alloc(s, s.sampleRate, numChannels);
	RecordBuf.ar(input, buf);
	bufrate = bufrate * BufRateScale.kr(buf);
	basefreq = (bufrate) * 0.5 / BufDur.kr(buf) ;
	phs = LFSaw.ar(
		basefreq
	).range(0, BufFrames.kr(buf));
	signal = BufRd.ar(numChannels, buf, phs);
	// signal = Pan2.ar(signal, pan);
	outsig = input + (signal * bufrd);
	ReplaceOut.ar(out, outsig);
}).add;

~dirt.orderModules(['bitcrush', 'hfsquiz', 'fold', 'scm', 'buf', 'shortbuf', 'lpf', 'comb']);
);