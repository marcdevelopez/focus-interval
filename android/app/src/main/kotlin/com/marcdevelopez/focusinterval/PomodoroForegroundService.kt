package com.marcdevelopez.focusinterval

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class PomodoroForegroundService : Service() {
  companion object {
    private const val CHANNEL_ID = "pomodoro_foreground"
    private const val CHANNEL_NAME = "Pomodoro running"
    private const val CHANNEL_DESCRIPTION = "Keeps the pomodoro running in background"
    private const val NOTIFICATION_ID = 1001

    const val ACTION_START = "com.marcdevelopez.focusinterval.START_FOREGROUND"
    const val ACTION_UPDATE = "com.marcdevelopez.focusinterval.UPDATE_FOREGROUND"
    const val ACTION_STOP = "com.marcdevelopez.focusinterval.STOP_FOREGROUND"
    const val EXTRA_TITLE = "extra_title"
    const val EXTRA_TEXT = "extra_text"

    fun start(context: Context, title: String, text: String) {
      val intent = Intent(context, PomodoroForegroundService::class.java).apply {
        action = ACTION_START
        putExtra(EXTRA_TITLE, title)
        putExtra(EXTRA_TEXT, text)
      }
      ContextCompat.startForegroundService(context, intent)
    }

    fun update(context: Context, title: String, text: String) {
      val intent = Intent(context, PomodoroForegroundService::class.java).apply {
        action = ACTION_UPDATE
        putExtra(EXTRA_TITLE, title)
        putExtra(EXTRA_TEXT, text)
      }
      ContextCompat.startForegroundService(context, intent)
    }

    fun stop(context: Context) {
      val intent = Intent(context, PomodoroForegroundService::class.java).apply {
        action = ACTION_STOP
      }
      context.startService(intent)
    }
  }

  private var isForeground = false
  private var wakeLock: PowerManager.WakeLock? = null
  private var title: String = "Pomodoro running"
  private var text: String = "Focus Interval is active"

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_STOP -> stopService()
      ACTION_UPDATE -> {
        updateFromIntent(intent)
        startOrUpdate()
      }
      ACTION_START, null -> {
        updateFromIntent(intent)
        startOrUpdate()
      }
    }
    return START_STICKY
  }

  override fun onDestroy() {
    releaseWakeLock()
    super.onDestroy()
  }

  private fun updateFromIntent(intent: Intent?) {
    intent?.getStringExtra(EXTRA_TITLE)?.let { title = it }
    intent?.getStringExtra(EXTRA_TEXT)?.let { text = it }
  }

  private fun startOrUpdate() {
    createNotificationChannel()
    val notification = buildNotification()
    if (!isForeground) {
      startForeground(NOTIFICATION_ID, notification)
      isForeground = true
      acquireWakeLock()
    } else {
      val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      manager.notify(NOTIFICATION_ID, notification)
    }
  }

  private fun stopService() {
    if (isForeground) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        stopForeground(STOP_FOREGROUND_REMOVE)
      } else {
        @Suppress("DEPRECATION")
        stopForeground(true)
      }
      isForeground = false
    }
    releaseWakeLock()
    stopSelf()
  }

  private fun buildNotification(): Notification {
    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
    val pendingIntent = if (launchIntent != null) {
      PendingIntent.getActivity(
        this,
        0,
        launchIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      )
    } else {
      null
    }

    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle(title)
      .setContentText(text)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setPriority(NotificationCompat.PRIORITY_LOW)
      .setContentIntent(pendingIntent)
      .build()
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val manager = getSystemService(NotificationManager::class.java)
      val channel = NotificationChannel(
        CHANNEL_ID,
        CHANNEL_NAME,
        NotificationManager.IMPORTANCE_LOW
      )
      channel.description = CHANNEL_DESCRIPTION
      manager.createNotificationChannel(channel)
    }
  }

  private fun acquireWakeLock() {
    if (wakeLock?.isHeld == true) return
    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
    wakeLock =
      powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "FocusInterval:Pomodoro")
    wakeLock?.setReferenceCounted(false)
    wakeLock?.acquire()
  }

  private fun releaseWakeLock() {
    wakeLock?.let {
      if (it.isHeld) {
        it.release()
      }
    }
    wakeLock = null
  }
}
