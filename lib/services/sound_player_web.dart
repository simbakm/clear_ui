import 'dart:html' as html;
import 'dart:js_util' as js_util;

class SoundPlayer {
  static dynamic _context;

  static void prepare() {
    if (_context == null) {
      final ctor = js_util.getProperty(html.window, 'AudioContext') ??
          js_util.getProperty(html.window, 'webkitAudioContext');
      if (ctor != null) {
        _context = js_util.callConstructor(ctor, []);
      }
    }

    if (_context != null) {
      js_util.callMethod(_context, 'resume', []);
    }
  }

  static void playAlert() {
    prepare();
    if (_context == null) return;

    final oscillator = js_util.callMethod(_context, 'createOscillator', []);
    final gain = js_util.callMethod(_context, 'createGain', []);

    js_util.setProperty(oscillator, 'type', 'sine');
    final frequency = js_util.getProperty(oscillator, 'frequency');
    js_util.setProperty(frequency, 'value', 880);

    final gainValue = js_util.getProperty(gain, 'gain');
    js_util.setProperty(gainValue, 'value', 0.1);

    js_util.callMethod(oscillator, 'connect', [gain]);
    final destination = js_util.getProperty(_context, 'destination');
    js_util.callMethod(gain, 'connect', [destination]);

    js_util.callMethod(oscillator, 'start', []);
    final now = js_util.getProperty(_context, 'currentTime') as num;
    js_util.callMethod(oscillator, 'stop', [now + 0.2]);
  }
}
