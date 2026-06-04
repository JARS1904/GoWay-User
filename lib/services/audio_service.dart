import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  static AudioService get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playNotificationSound() async {
    try {
      await _audioPlayer.play(
          AssetSource('sounds/Mobile_notification__#4-1780536563586.mp3'));
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
