package com.marcdevelopez.focusinterval

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "focus_interval/foreground_service"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "start" -> {
            val title = call.argument<String>("title") ?: "Pomodoro running"
            val text = call.argument<String>("text") ?: "Focus Interval is active"
            PomodoroForegroundService.start(applicationContext, title, text)
            result.success(null)
          }
          "update" -> {
            val title = call.argument<String>("title") ?: "Pomodoro running"
            val text = call.argument<String>("text") ?: "Focus Interval is active"
            PomodoroForegroundService.update(applicationContext, title, text)
            result.success(null)
          }
          "stop" -> {
            PomodoroForegroundService.stop(applicationContext)
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }
}
