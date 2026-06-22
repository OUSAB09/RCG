import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart';

/// Global procedural sound engine. On web it synthesizes SFX & music via the
/// Web Audio API; on other platforms it is a silent no-op.
///
/// Browsers block audio until a user gesture — call [Sound.unlock] from the
/// first tap (e.g. the RACE button) before relying on continuous sounds.
class Sound {
  Sound._();
  static final SoundEngine _engine = SoundEngine();

  static bool get available => _engine.available;

  static Future<void> unlock() => _engine.resume();
  static void configure({required bool sfx, required bool music}) =>
      _engine.setEnabled(sfx, music);

  // Gameplay
  static void engine(double speedFrac, bool nitro) =>
      _engine.engine(speedFrac, nitro);
  static void stopEngine() => _engine.stopEngine();
  static void pass(int tier) => _engine.pass(tier);
  static void nitroStart() => _engine.nitroStart();
  static void nitroEnd() => _engine.nitroEnd();
  static void crash() => _engine.crash();

  // UI / economy
  static void uiTap() => _engine.uiTap();
  static void coin() => _engine.coin();

  // Music
  static void startMusic() => _engine.startMusic();
  static void stopMusic() => _engine.stopMusic();
}
