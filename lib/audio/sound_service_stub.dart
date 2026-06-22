/// Non-web fallback for the procedural sound engine.
///
/// On platforms without the Web Audio API this is a silent no-op so the rest
/// of the game can call the same interface unconditionally.
class SoundEngine {
  bool get available => false;

  Future<void> resume() async {}

  void setEnabled(bool sfx, bool music) {}

  void engine(double speedFrac, bool nitro) {}
  void stopEngine() {}

  void pass(int tier) {}
  void nitroStart() {}
  void nitroEnd() {}
  void crash() {}
  void uiTap() {}
  void coin() {}

  void startMusic() {}
  void stopMusic() {}
}
