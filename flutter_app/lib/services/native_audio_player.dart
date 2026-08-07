import 'package:flutter/services.dart';

class NativeAudioPlayer {
  static const MethodChannel _channel =
      MethodChannel('com.cupwhisper.cupwhisper/audio');

  static Future<void> play(Uint8List bytes) async {
    await _channel.invokeMethod('play', bytes);
  }
}
