package com.recipehub.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdf" -> {
                    val name = call.argument<String>("name")
                    val bytes = call.argument<ByteArray>("bytes")
                    val folder = call.argument<String>("folder") ?: "RecipeHub"
                    if (name == null || bytes == null) {
                        result.error("bad_args", "Thiếu dữ liệu", null)
                    } else {
                        savePdf(name, bytes, folder, result)
                    }
                }
                "openFile" -> {
                    val uri = call.argument<String>("uri")
                    val mime = call.argument<String>("mime") ?: "application/pdf"
                    result.success(uri != null && openFile(Uri.parse(uri), mime))
                }
                "shareFile" -> {
                    val uri = call.argument<String>("uri")
                    val mime = call.argument<String>("mime") ?: "application/pdf"
                    result.success(uri != null && shareFile(Uri.parse(uri), mime))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun savePdf(name: String, bytes: ByteArray, folder: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "Android dưới 10", null)
            return
        }
        val resolver = contentResolver
        var uri: Uri? = null
        try {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/" + folder)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("insert failed")
            val stream = resolver.openOutputStream(uri) ?: throw IOException("no stream")
            stream.use { it.write(bytes) }
            val done = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
            if (resolver.update(uri, done, null, null) != 1) {
                throw IOException("publish failed")
            }
            result.success(uri.toString())
        } catch (e: Exception) {
            uri?.let { runCatching { resolver.delete(it, null, null) } }
            val msg = e.message ?: ""
            val noSpace = msg.contains("ENOSPC", ignoreCase = true) || msg.contains("space", ignoreCase = true)
            result.error(if (noSpace) "no_space" else "write_failed", msg, null)
        }
    }

    private fun openFile(uri: Uri, mime: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Chia sẻ file đã lưu qua content Uri (MediaStore) bằng hộp chọn ứng dụng của Android. */
    private fun shareFile(uri: Uri, mime: String): Boolean {
        return try {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = mime
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(send, "Chia sẻ báo cáo").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL_ID = "recipehub_updates"
        const val FILES_CHANNEL = "com.recipehub.mobile/files"
    }
}
