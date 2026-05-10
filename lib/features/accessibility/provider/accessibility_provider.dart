import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  static const String _keyHighContrast = 'acc_high_contrast';
  static const String _keyVoiceAssist = 'acc_voice_assist';
  static const String _keyTextScale = 'acc_text_scale';

  bool highContrast = false;
  bool voiceAssist = false;
  double textScale = 1.0;

  final FlutterTts flutterTts = FlutterTts();
  bool _ttsReady = false;
  bool _isSpeaking = false;

  Color get appBackground =>
      highContrast ? const Color(0xFF0F0F0F) : const Color(0xFFF6E7F2);

  Color get appBarColor =>
      highContrast ? const Color(0xFF171717) : const Color(0xFFF48FB1);

  Color get surfaceColor =>
      highContrast ? const Color(0xFF1E1E1E) : Colors.white;

  Color get textColor => highContrast ? Colors.white : const Color(0xFF1E1E1E);

  Color get mutedTextColor => highContrast ? Colors.white70 : Colors.black54;

  Color get primaryColor => const Color(0xFFE91E63);

  Color get secondaryColor => const Color(0xFFDDA1E7);

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      highContrast = prefs.getBool(_keyHighContrast) ?? false;
      voiceAssist = prefs.getBool(_keyVoiceAssist) ?? false;
      textScale = prefs.getDouble(_keyTextScale) ?? 1.0;

      try {
        await flutterTts.awaitSpeakCompletion(true);

        final languages = await flutterTts.getLanguages;

        if (languages.contains('es-CO')) {
          await flutterTts.setLanguage('es-CO');
        } else if (languages.contains('es-ES')) {
          await flutterTts.setLanguage('es-ES');
        } else {
          await flutterTts.setLanguage('es');
        }

        await flutterTts.setPitch(1.0);
        await flutterTts.setSpeechRate(0.42);
        await flutterTts.setVolume(1.0);

        _ttsReady = true;
      } catch (_) {
        _ttsReady = false;
      }
    } catch (_) {
      highContrast = false;
      voiceAssist = false;
      textScale = 1.0;
      _ttsReady = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHighContrast, highContrast);
      await prefs.setBool(_keyVoiceAssist, voiceAssist);
      await prefs.setDouble(_keyTextScale, textScale);
    } catch (_) {}
  }

  void setHighContrast(bool value) {
    highContrast = value;
    _save();
    notifyListeners();
  }

  void setVoiceAssist(bool value) {
    voiceAssist = value;
    _save();
    notifyListeners();
  }

  void setTextScale(double scale) {
    textScale = scale;
    _save();
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!voiceAssist || !_ttsReady) return;

    if (_isSpeaking) {
      await flutterTts.stop();
    }

    _isSpeaking = true;

    try {
      await flutterTts.stop();
      await flutterTts.speak(text);
    } catch (_) {
    } finally {
      _isSpeaking = false;
    }
  }
}
