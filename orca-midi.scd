(

SynthDef(\rev, {|in, out, rev = 0.3, amp = 0, room = 0.8|
	var input, wet;
	input = In.ar(in, 2);
	wet = FreeVerb2.ar(input[0], input[1], mix: rev , room: room, damp: 0.2);
	input = input + (wet * amp);
	ReplaceOut.ar(out, input);
}).add;

SynthDef(\coarse, {|in, out, rate = 0|
	var input;
	input = In.ar(in, 2);
	input = Decimator.ar(input, 44100 / rate);
	ReplaceOut.ar(out, input);
}).add;

SynthDef(\dist, {|in, out, dist = 0|
	var input;
	input = In.ar(in, 2);
	input = input * dist.linlin(0, 1, 1, 8);
	input.clip;
	ReplaceOut.ar(out, input);
}).add;

SynthDef(\clipper, {
	arg in, out;
	var input = In.ar(in, 2);
	input.softclip;
	ReplaceOut.ar(out, input);
}).add;

SynthDef(\mastergain, {
	arg in, out, amp = 1;
	var input = In.ar(in, 2);
	input = input * amp;
	ReplaceOut.ar(out, input);
}).add;

SynthDef(\fold, {
	arg in, out, fold = 1, wet = 0;
	var input = In.ar(in, 2);
	input = input + (input.fold(-1 * (fold), fold) * wet);
	ReplaceOut.ar(out, input);
}).add;

SynthDef(\binshift, {
	arg in, out, rate = 1, shift = 0, wet = 0;
	var input, chainL, chainR, output;
	rate = (rate * 2).round * 0.5;
	input = In.ar(in, 2);

	chainL = FFT(LocalBuf(2048, 1), input[0]);
	chainL = PV_BinShift(chainL, rate, shift);

	chainR = FFT(LocalBuf(2048, 1), input[1]);
	chainR = PV_BinShift(chainR, rate, shift);
	output = (input * (1 - wet)) + ([IFFT(chainL), IFFT(chainR)] * wet);
	ReplaceOut.ar(out, output);
}).add;


)

// Midi setup

(
MIDIClient.init;
MIDIIn.connectAll;

~ch0 = Array.newClear(128);
~ch1 = Array.newClear(128);
~ch2 = Array.newClear(128);
~ch3 = Array.newClear(128);

~ch4 = Array.newClear(128);
~ch5 = Array.newClear(128);
~ch6 = Array.newClear(128);
~ch7 = Array.newClear(128);

~ch8 = Array.newClear(128);
~ch9 = Array.newClear(128);
~ch10 = Array.newClear(128);
~ch11 = Array.newClear(128);

~ch12 = Array.newClear(128);
~ch13 = Array.newClear(128);
~ch14 = Array.newClear(128);
~ch15 = Array.newClear(128);

)


(
~snd = Group.new(s.defaultGroup);
~fx = Group.new(~snd, \addAfter);

~fxbus = Bus.audio(s, 2);
~revbus = Bus.audio(s, 2);
)

(
~rev = Synth(\rev, [
	\out, 0,
	\in, ~revbus,
], ~fx, \addToTail);


~clipper = Synth(\clipper, [
	\in, ~fxbus,
	\out, ~revbus
], ~fx);

~coarse = Synth(\coarse, [
	\out, ~fxbus,
	\in, ~fxbus
], ~fx);

~binshift = Synth(\binshift, [
	\in, ~fxbus,
	\out, ~fxbus
], ~fx);

~dist = Synth(\dist, [
	\in, ~fxbus,
	\out, ~fxbus,
], ~fx);

~fold = Synth(\fold, [
	\in, ~fxbus,
	\out, ~fxbus
], ~fx);

~mastergain = Synth(\mastergain, [
	\in, ~fxbus,
	\out, ~fxbus,
], ~fx);

~mastergain.set(\amp, 0.8);
~rev.set(\rev, 0.4, \room, 0.9, \amp, 0.2);
)

~binshift.set(\shift, 0);
~binshift.set(\rate, 1);

~rev.set(\rev, 0.5, \room, 1.3, \amp, 0.4);

~mastergain.set(\amp, 0.3);

Synth(\skik, [\out, ~fxbus, \len, 1, \amp, 0.5], ~snd);

(
~rev.free;
~dist.free;
~coarse.free;
~binshift.free;
~fold.free;
~clipper.free;
~mastergain.free;
)


(
MIDIdef.noteOn(\noteOn, { |veloc, num, chan, src|
	if (chan == 0) {
		~ch0[num] = Synth(\skik,[
			\len, veloc.linexp(0, 127, 0.05, 2),
			\amp, 0.8,
			\out, ~fxbus
		], ~snd);
	};
	if (chan == 1) {
		~ch1[num] = Synth(\ssn, [
			\len, veloc.linexp(0, 127, 0.1, 1),
			\out, ~fxbus
		], ~snd);
	};
	if (chan == 2) {
		~ch2[num] = Synth(\shh, [
			\len, veloc.linexp(0, 127, 0.02, 1), \amp, 2,
			\out, ~fxbus
		], ~snd);
	};
	if (chan == 3) {
		~ch3[num] = Synth(\stom, [
			\len, [0.3, 0.9, 4, 0.1].choose, \freq, num.midicps, \pan, rrand(-1, 1), \index, veloc.linexp(0, 127, 1, 64 ),
			\out, ~fxbus,
			\amp, 0.8
		], ~snd);
	};

	if (chan == 4) {
		~ch4[num] = Synth(\fmsaw, [
			\len, 4, \freq, num.midicps, \detune, 1.2,
			\out, ~fxbus,
			\amp, 0.8
		], ~snd);
	};
	if (chan == 5) {
		~ch5[num] = Synth(\mkey, [
			\len, 1, \freq, num.midicps,
			\out, ~fxbus,
			\amp, 0.8
		], ~snd);
	};
	if (chan == 6) {
		~ch6[num] = Synth(\ssub, [
			\len, 2, \freq, num.midicps,
			\out, ~fxbus,
			\amp, 1
		], ~snd);
	};
	if (chan == 7) {
		~ch7[num] = Synth(\detsaw, [
			\len, veloc.linlin(0,127, 0.1, 4),
			\sust, 0.5, \cutoffspd, 0.5,
			\amp, 0.9,
			\freq, num.midicps, \q, 0.9,
			\out, ~fxbus
		], ~snd);
	};
});

MIDIdef.noteOff(\noteOff, { |veloc, num, chan, src|
	if (chan == 0) {
		~ch0[num].set(\gate, 0);
		~ch0[num] = nil;
	};
	if (chan == 1) {
		~ch1[num].set(\gate, 0);
		~ch1[num] = nil;
	};
	if (chan == 2) {
		~ch2[num].set(\gate, 0);
		~ch2[num] = nil;
	};
	if (chan == 3) {
		~ch3[num].set(\gate, 0);
		~ch3[num] = nil;
	};

	if (chan == 4) {
		~ch4[num].set(\gate, 0);
		~ch4[num] = nil;
	};
	if (chan == 5) {
		~ch5[num].set(\gate, 0);
		~ch5[num] = nil;
	};
	if (chan == 6) {
		~ch6[num].set(\gate, 0);
		~ch6[num] = nil;
	};
	if (chan == 7) {
		~ch7[num].set(\gate, 0);
		~ch7[num] = nil;
	};
});

MIDIdef.cc(\control, {
	arg val, knob, chan;

	[val, knob, chan].postln;

	// fold
	if (chan == 15) {

		// rev
		// 0 - 2 (in ORCA)
		if(knob == 64) { ~rev.set(\rev, val.linlin(0, 127, 0, 1) ) };
		if(knob == 65) { ~rev.set(\room, val.linlin(0, 127, 0, 1) ) };
		if(knob == 66) { ~rev.set(\amp, val.linlin(0, 127, 0, 1)) };

		// dist
		// 3
		if(knob == 67) { ~dist.set(\dist, val.linexp(0, 127, 0, 1) )};

		// coarse
		// 4
		if(knob == 68) { ~coarse.set(\rate, val.linexp(0,127, 1, 32)) };

		// fold
		// 5 - 6
		if(knob == 69) { ~fold.set(\fold, val.linexp(0,127, 0.4, 0.01)) };
		if(knob == 70) { ~fold.set(\wet, val.linexp(0,127, 0, 1)) };

		// binshift
		// 7 - 9
		if(knob == 71) { ~binshift.set(\rate, val.linlin(0, 127, 0.5, 2)) };
		if(knob == 72) { ~binshift.set(\shift, val.linexp(0, 127, 0, 24)) };
		if(knob == 73) { ~binshift.set(\wet, val.linlin(0, 127, 0, 1)) };
	};
});
)