package com.cupwhisper.cupwhisper

import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cupwhisper.cupwhisper/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "play") {
                val bytes = call.arguments as ByteArray
                playAudio(bytes, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun playAudio(bytes: ByteArray, result: MethodChannel.Result) {
        Thread {
            try {
                val file = File(cacheDir, "cupwhisper_audio_${System.currentTimeMillis()}.mp3")
                file.writeBytes(bytes)

                val mediaPlayer = MediaPlayer()
                mediaPlayer.setDataSource(file.absolutePath)
                mediaPlayer.setOnPreparedListener { it.start() }
                mediaPlayer.setOnCompletionListener {
                    it.release()
                    file.delete()
                    runOnUiThread { result.success(null) }
                }
                mediaPlayer.setOnErrorListener { mp, what, extra ->
                    mp.release()
                    runOnUiThread { result.error("PLAYBACK_ERROR", "MediaPlayer error: $what/$extra", null) }
                    true
                }
                mediaPlayer.prepareAsync()
            } catch (e: Exception) {
                runOnUiThread { result.error("PLAYBACK_ERROR", e.message, null) }
            }
        }.start()
    }
}
