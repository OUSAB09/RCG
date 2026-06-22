import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Procedural Web Audio synthesizer — generates all SFX & a music bed with
/// oscillators so the game ships zero audio asset files (perfect for web).
class SoundEngine {
  web.AudioContext? _ctx;
  web.GainNode? _master; // master output
  web.GainNode? _sfxGain;
  web.GainNode? _musicGain;

  // Continuous engine drone
  web.OscillatorNode? _engineOsc;
  web.OscillatorNode? _engineOsc2;
  web.GainNode? _engineGain;

  // Music sequencer
  bool _musicRunning = false;
  int _musicStep = 0;
  double _nextNoteTime = 0;
  int? _musicTimer;

  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  bool get available => true;

  void _ensure() {
    if (_ctx != null) return;
    final ctx = web.AudioContext();
    _ctx = ctx;
    _master = ctx.createGain()..gain.value = 0.9;
    _master!.connect(ctx.destination);

    _sfxGain = ctx.createGain()..gain.value = 0.8;
    _sfxGain!.connect(_master!);

    _musicGain = ctx.createGain()..gain.value = 0.32;
    _musicGain!.connect(_master!);
  }

  /// Browsers require a user-gesture before audio can start.
  Future<void> resume() async {
    _ensure();
    try {
      await _ctx!.resume().toDart;
    } catch (_) {}
  }

  void setEnabled(bool sfx, bool music) {
    _sfxEnabled = sfx;
    _musicEnabled = music;
    if (!music) stopMusic();
    if (!sfx) stopEngine();
  }

  double get _now => _ctx?.currentTime ?? 0;

  // ---------------- Continuous engine drone ----------------

  void engine(double speedFrac, bool nitro) {
    if (!_sfxEnabled) return;
    _ensure();
    final ctx = _ctx!;
    if (_engineOsc == null) {
      _engineGain = ctx.createGain()..gain.value = 0.0;
      _engineGain!.connect(_sfxGain!);

      _engineOsc = ctx.createOscillator()..type = 'sawtooth';
      _engineOsc2 = ctx.createOscillator()..type = 'square';
      _engineOsc!.connect(_engineGain!);
      _engineOsc2!.connect(_engineGain!);
      _engineOsc!.start();
      _engineOsc2!.start();
    }
    // Map speed to a throaty pitch; nitro shifts up an octave-ish.
    final base = 55 + speedFrac * 150 + (nitro ? 60 : 0);
    final t = _now;
    _engineOsc!.frequency.setTargetAtTime(base, t, 0.08);
    _engineOsc2!.frequency.setTargetAtTime(base * 1.5, t, 0.08);
    final vol = (0.04 + speedFrac * 0.12 + (nitro ? 0.05 : 0)).clamp(0.0, 0.22);
    _engineGain!.gain.setTargetAtTime(vol, t, 0.1);
  }

  void stopEngine() {
    if (_engineGain != null && _ctx != null) {
      _engineGain!.gain.setTargetAtTime(0, _now, 0.06);
    }
  }

  // ---------------- One-shot SFX ----------------

  void _blip({
    required double freq,
    required double freqEnd,
    required double dur,
    String type = 'sine',
    double gain = 0.3,
    double delay = 0,
  }) {
    if (!_sfxEnabled) return;
    _ensure();
    final ctx = _ctx!;
    final t = _now + delay;
    final osc = ctx.createOscillator()..type = type;
    final g = ctx.createGain();
    osc.connect(g);
    g.connect(_sfxGain!);
    osc.frequency.setValueAtTime(freq, t);
    osc.frequency.exponentialRampToValueAtTime(freqEnd.clamp(1, 20000), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.start(t);
    osc.stop(t + dur + 0.02);
  }

  void _noise(double dur, double gain) {
    if (!_sfxEnabled) return;
    _ensure();
    final ctx = _ctx!;
    final t = _now;
    final frames = (ctx.sampleRate * dur).toInt();
    final buffer = ctx.createBuffer(1, frames, ctx.sampleRate);
    final data = buffer.getChannelData(0).toDart;
    for (var i = 0; i < frames; i++) {
      final decay = 1 - i / frames;
      data[i] = (_rand() * 2 - 1) * decay * decay;
    }
    final src = ctx.createBufferSource()..buffer = buffer;
    final g = ctx.createGain()..gain.value = gain;
    final filter = ctx.createBiquadFilter()
      ..type = 'lowpass'
      ..frequency.value = 1200;
    src.connect(filter);
    filter.connect(g);
    g.connect(_sfxGain!);
    src.start(t);
  }

  double _seed = 12345;
  double _rand() {
    _seed = (_seed * 16807) % 2147483647;
    return _seed / 2147483647;
  }

  /// tier: 0 = near miss, 1 = close pass, 2 = extreme.
  void pass(int tier) {
    switch (tier) {
      case 2:
        _blip(freq: 660, freqEnd: 1320, dur: 0.18, type: 'triangle', gain: 0.34);
        _blip(freq: 990, freqEnd: 1980, dur: 0.16, type: 'sine', gain: 0.22, delay: 0.05);
        break;
      case 1:
        _blip(freq: 520, freqEnd: 880, dur: 0.13, type: 'triangle', gain: 0.28);
        break;
      default:
        _blip(freq: 420, freqEnd: 560, dur: 0.09, type: 'sine', gain: 0.22);
    }
  }

  void nitroStart() {
    _blip(freq: 180, freqEnd: 900, dur: 0.45, type: 'sawtooth', gain: 0.3);
    _noise(0.4, 0.15);
  }

  void nitroEnd() {
    _blip(freq: 600, freqEnd: 160, dur: 0.3, type: 'sawtooth', gain: 0.18);
  }

  void crash() {
    _noise(0.6, 0.5);
    _blip(freq: 200, freqEnd: 40, dur: 0.5, type: 'square', gain: 0.4);
  }

  void uiTap() => _blip(freq: 700, freqEnd: 900, dur: 0.05, type: 'sine', gain: 0.18);

  void coin() {
    _blip(freq: 880, freqEnd: 1320, dur: 0.08, type: 'square', gain: 0.2);
    _blip(freq: 1320, freqEnd: 1760, dur: 0.1, type: 'square', gain: 0.18, delay: 0.06);
  }

  // ---------------- Synthwave music bed ----------------

  // A minor pentatonic-ish bass line, looped.
  static const List<double> _bass = [
    55.0, 55.0, 82.4, 55.0, 65.4, 65.4, 49.0, 73.4,
  ];
  static const List<double> _lead = [
    220.0, 0, 261.6, 329.6, 0, 293.7, 220.0, 0,
  ];

  void startMusic() {
    if (!_musicEnabled || _musicRunning) return;
    _ensure();
    _musicRunning = true;
    _musicStep = 0;
    _nextNoteTime = _now + 0.1;
    _musicTimer = web.window.setInterval(
        (() => _scheduleMusic()).toJS, null, 60); // ~16fps scheduler
  }

  void stopMusic() {
    _musicRunning = false;
    if (_musicTimer != null) {
      web.window.clearInterval(_musicTimer!);
      _musicTimer = null;
    }
  }

  void _scheduleMusic() {
    if (!_musicRunning || _ctx == null) return;
    const tempo = 0.28; // seconds per step
    while (_nextNoteTime < _now + 0.2) {
      final i = _musicStep % 8;
      final bass = _bass[i];
      if (bass > 0) _scheduleTone(bass, _nextNoteTime, tempo * 0.95, 'triangle', 0.5);
      final lead = _lead[i];
      if (lead > 0) {
        _scheduleTone(lead, _nextNoteTime, tempo * 0.8, 'sawtooth', 0.18);
        _scheduleTone(lead * 1.5, _nextNoteTime, tempo * 0.8, 'sine', 0.08);
      }
      _nextNoteTime += tempo;
      _musicStep++;
    }
  }

  void _scheduleTone(double freq, double when, double dur, String type, double gain) {
    final ctx = _ctx!;
    final osc = ctx.createOscillator()..type = type;
    final g = ctx.createGain();
    osc.connect(g);
    g.connect(_musicGain!);
    osc.frequency.setValueAtTime(freq, when);
    g.gain.setValueAtTime(0.0001, when);
    g.gain.exponentialRampToValueAtTime(gain, when + 0.02);
    g.gain.exponentialRampToValueAtTime(0.0001, when + dur);
    osc.start(when);
    osc.stop(when + dur + 0.02);
  }
}
