import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';

class SoundPlayer {
  static void prepare() {}

  static void playAlert() {
    SystemSound.play(SystemSoundType.alert);
    FlutterBeep.beep();
  }
}

