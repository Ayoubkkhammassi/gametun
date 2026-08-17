import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Effets sonores synthétisés en code (aucun fichier audio requis).
/// Génère des petits WAV (bruit/tons courts) et les joue via audioplayers.
class CbSfx {
  static const int _rate = 44100;
  final Map<String, Uint8List> _cache = {};
  bool _muted = false;

  CbSfx() {
    _cache['hit'] = _wav(_hit());
    _cache['cast'] = _wav(_sweep(220, 720, 220, noise: 0.0));
    _cache['buff'] = _wav(_arp([523, 784], 90));
    _cache['tap'] = _wav(_blip(880, 45));
    _cache['elim'] = _wav(_sweep(600, 90, 320, noise: 0.15));
    _cache['win'] = _wav(_arp([523, 659, 784, 1046], 130));
    _cache['lose'] = _wav(_arp([392, 311, 233], 200));
  }

  set muted(bool v) => _muted = v;

  void play(String id) {
    final bytes = _cache[id];
    if (bytes == null || _muted) return;
    final p = AudioPlayer();
    p.onPlayerComplete.listen((_) => p.dispose());
    p.play(BytesSource(bytes), volume: 0.6).catchError((_) => p.dispose());
  }

  // ---- Générateurs de formes d'onde --------------------------------------

  /// Impact : thump sinus grave + bruit blanc à décroissance rapide.
  List<double> _hit() {
    final n = (_rate * 0.16).round();
    final out = List<double>.filled(n, 0);
    final rng = Random();
    for (var i = 0; i < n; i++) {
      final t = i / _rate;
      final env = exp(-t * 26);
      final thump = sin(2 * pi * 90 * t) * env;
      final noise = (rng.nextDouble() * 2 - 1) * env * 0.7;
      out[i] = (thump * 0.6 + noise * 0.4);
    }
    return out;
  }

  /// Balayage de fréquence (sort / élimination).
  List<double> _sweep(double f0, double f1, double ms, {double noise = 0}) {
    final n = (_rate * ms / 1000).round();
    final out = List<double>.filled(n, 0);
    final rng = Random();
    for (var i = 0; i < n; i++) {
      final t = i / n;
      final f = f0 + (f1 - f0) * t;
      final env = sin(pi * t); // fade in/out
      final tone = sin(2 * pi * f * (i / _rate));
      final nz = noise > 0 ? (rng.nextDouble() * 2 - 1) * noise : 0.0;
      out[i] = (tone * (1 - noise) + nz) * env;
    }
    return out;
  }

  /// Arpège de notes (buff / victoire / défaite).
  List<double> _arp(List<double> freqs, double noteMs) {
    final per = (_rate * noteMs / 1000).round();
    final out = <double>[];
    for (final f in freqs) {
      for (var i = 0; i < per; i++) {
        final t = i / per;
        final env = sin(pi * t);
        out.add(sin(2 * pi * f * (i / _rate)) * env * 0.8);
      }
    }
    return out;
  }

  /// Petit "blip" (tap de carte).
  List<double> _blip(double f, double ms) {
    final n = (_rate * ms / 1000).round();
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / n;
      final env = (1 - t);
      out[i] = sin(2 * pi * f * (i / _rate)) * env * 0.7;
    }
    return out;
  }

  // ---- Encodage WAV (PCM mono 16 bits) -----------------------------------

  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final dataLen = n * 2;
    final buf = ByteData(44 + dataLen);
    void s(int off, String str) {
      for (var i = 0; i < str.length; i++) {
        buf.setUint8(off + i, str.codeUnitAt(i));
      }
    }

    s(0, 'RIFF');
    buf.setUint32(4, 36 + dataLen, Endian.little);
    s(8, 'WAVE');
    s(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little); // PCM
    buf.setUint16(22, 1, Endian.little); // mono
    buf.setUint32(24, _rate, Endian.little);
    buf.setUint32(28, _rate * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    s(36, 'data');
    buf.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      buf.setInt16(44 + i * 2, v, Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  void dispose() {}
}
