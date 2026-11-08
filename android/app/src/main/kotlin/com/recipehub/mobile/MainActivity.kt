package com.recipehub.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Kênh mặc định cho tin FCM (khai báo trong AndroidManifest) — thay kênh fallback
        // "Miscellaneous" để tin công thức/SOP hiện nổi bật và người dùng tắt/bật riêng được.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Cập nhật công thức & SOP",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Thông báo từ Admin RecipeHub" }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    companion object {
        const val CHANNEL_ID = "recipehub_updates"
    }
}
