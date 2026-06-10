package com.example.real_estate_crm

import android.app.DownloadManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private var pendingUpdateNotificationTap: Boolean = false
    private var updateNotificationChannel: MethodChannel? = null
    private var pendingExportSaveResult: MethodChannel.Result? = null
    private var pendingExportSourcePath: String = ""
    private var pendingExportFileName: String = ""
    private var pendingExportMimeType: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_DOWNLOADER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val fileName = call.argument<String>("fileName")?.trim().orEmpty()
                    val mimeType = call.argument<String>("mimeType")?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "application/octet-stream"
                    val bytes = call.argument<ByteArray>("bytes")

                    if (fileName.isEmpty() || bytes == null || bytes.isEmpty()) {
                        result.error(
                            "invalid_arguments",
                            "A file name and non-empty file bytes are required.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(saveToDownloads(fileName, mimeType, bytes))
                    } catch (error: Exception) {
                        result.error(
                            "download_failed",
                            error.message ?: "The file could not be saved.",
                            null
                        )
                    }
                }

                "saveFileToDownloads" -> {
                    val fileName = call.argument<String>("fileName")?.trim().orEmpty()
                    val mimeType = call.argument<String>("mimeType")?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "application/octet-stream"
                    val sourcePath = call.argument<String>("sourcePath")?.trim().orEmpty()

                    if (fileName.isEmpty() || sourcePath.isEmpty()) {
                        result.error(
                            "invalid_arguments",
                            "A file name and source file path are required.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(saveFileToDownloads(fileName, mimeType, sourcePath))
                    } catch (error: Exception) {
                        try {
                            requestUserChosenExportSave(fileName, mimeType, sourcePath, result)
                        } catch (fallbackError: Exception) {
                            result.error(
                                "download_failed",
                                fallbackError.message ?: error.message ?: "The file could not be saved.",
                                null
                            )
                        }
                    }
                }
                "openDownloadedFile" -> {
                    val uri = call.argument<String>("uri")?.trim().orEmpty()
                    val mimeType = call.argument<String>("mimeType")?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "application/octet-stream"
                    if (uri.isEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        openDownloadedFile(uri, mimeType)
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
                "openDownloadsLocation" -> {
                    val uri = call.argument<String>("uri")?.trim().orEmpty()
                    val mimeType = call.argument<String>("mimeType")?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "application/octet-stream"
                    try {
                        openDownloadsLocation(uri, mimeType)
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        updateNotificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATE_NOTIFICATIONS_CHANNEL
        )
        updateNotificationChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showUpdateAvailableNotification" -> {
                    val title = call.argument<String>("title")?.trim().orEmpty()
                    val body = call.argument<String>("body")?.trim().orEmpty()
                    val actionLabel = call.argument<String>("actionLabel")?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "Update"
                    val required = call.argument<Boolean>("updateRequired") ?: false
                    if (title.isEmpty() || body.isEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(showUpdateAvailableNotification(title, body, actionLabel, required))
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "consumePendingUpdateNotificationTap" -> {
                    val hadPendingTap = pendingUpdateNotificationTap || hasUpdateNotificationAction(intent)
                    pendingUpdateNotificationTap = false
                    clearUpdateNotificationAction(intent)
                    result.success(hadPendingTap)
                }
                else -> result.notImplemented()
            }
        }
        if (hasUpdateNotificationAction(intent)) {
            pendingUpdateNotificationTap = true
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APK_UPDATER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startApkDownload" -> {
                    val url = call.argument<String>("url")?.trim().orEmpty()
                    val fileName = call.argument<String>("fileName")?.trim().orEmpty()
                    if (url.isEmpty() || fileName.isEmpty()) {
                        result.error(
                            "invalid_arguments",
                            "A valid update URL and file name are required.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(startApkDownload(url, fileName))
                    } catch (error: Exception) {
                        result.error(
                            "download_not_started",
                            error.message ?: "The update download could not be started.",
                            null
                        )
                    }
                }
                "getApkDownloadStatus" -> {
                    val downloadId = longArgument(call.argument<Any>("downloadId"))
                    if (downloadId <= 0L) {
                        result.error("invalid_arguments", "A valid download id is required.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(getApkDownloadStatus(downloadId))
                    } catch (error: Exception) {
                        result.error(
                            "download_status_failed",
                            error.message ?: "The update download status could not be read.",
                            null
                        )
                    }
                }
                "installDownloadedApk" -> {
                    val downloadId = longArgument(call.argument<Any>("downloadId"))
                    if (downloadId <= 0L) {
                        result.error("invalid_arguments", "A valid download id is required.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        installDownloadedApk(downloadId)
                        result.success(true)
                    } catch (error: InstallPermissionRequiredException) {
                        openInstallPermissionSettings()
                        result.error(
                            "install_permission_required",
                            "Allow Masar CRM to install updates, then try again.",
                            null
                        )
                    } catch (error: Exception) {
                        result.error(
                            "install_failed",
                            error.message ?: "The Android installer could not be opened.",
                            null
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (hasUpdateNotificationAction(intent)) {
            pendingUpdateNotificationTap = true
            updateNotificationChannel?.invokeMethod("showUpdateReminderFromNotification", null)
        }
    }

    private fun showUpdateAvailableNotification(
        title: String,
        body: String,
        actionLabel: String,
        required: Boolean
    ): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                UPDATE_NOTIFICATION_CHANNEL_ID,
                "App updates",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Masar CRM update reminders"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val tapIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_SHOW_UPDATE
            putExtra(EXTRA_UPDATE_NOTIFICATION_TAP, true)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val tapPendingIntent = PendingIntent.getActivity(
            this,
            UPDATE_NOTIFICATION_REQUEST_CODE,
            tapIntent,
            flags
        )
        val smallIcon = if (applicationInfo.icon != 0) applicationInfo.icon else R.mipmap.ic_launcher
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, UPDATE_NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(smallIcon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(tapPendingIntent)
            .setAutoCancel(true)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .setPriority(if (required) Notification.PRIORITY_HIGH else Notification.PRIORITY_DEFAULT)
            .setCategory(Notification.CATEGORY_STATUS)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            builder.addAction(
                Notification.Action.Builder(smallIcon, actionLabel, tapPendingIntent).build()
            )
        } else {
            @Suppress("DEPRECATION")
            builder.addAction(smallIcon, actionLabel, tapPendingIntent)
        }

        notificationManager.notify(UPDATE_NOTIFICATION_ID, builder.build())
        return true
    }

    private fun hasUpdateNotificationAction(intent: Intent?): Boolean {
        return intent?.getBooleanExtra(EXTRA_UPDATE_NOTIFICATION_TAP, false) == true ||
            intent?.action == ACTION_SHOW_UPDATE
    }

    private fun clearUpdateNotificationAction(intent: Intent?) {
        intent?.removeExtra(EXTRA_UPDATE_NOTIFICATION_TAP)
        if (intent?.action == ACTION_SHOW_UPDATE) {
            intent.action = null
        }
    }

    private fun startApkDownload(url: String, fileName: String): Long {
        val uri = Uri.parse(url)
        val scheme = uri.scheme?.lowercase().orEmpty()
        if (scheme != "https" && scheme != "http") {
            throw IOException("The update URL must be an HTTP or HTTPS link.")
        }

        val safeFileName = sanitizeFileName(fileName).ifEmpty { "masar-crm-update.apk" }
        val request = DownloadManager.Request(uri)
            .setTitle("Masar CRM update")
            .setDescription(safeFileName)
            .setMimeType(APK_MIME_TYPE)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setDestinationInExternalFilesDir(
                this,
                Environment.DIRECTORY_DOWNLOADS,
                safeFileName
            )

        return downloadManager().enqueue(request)
    }

    private fun getApkDownloadStatus(downloadId: Long): Map<String, Any?> {
        val query = DownloadManager.Query().setFilterById(downloadId)
        downloadManager().query(query).use { cursor ->
            if (cursor == null || !cursor.moveToFirst()) {
                return mapOf(
                    "status" to "unknown",
                    "bytesDownloaded" to 0,
                    "totalBytes" to 0,
                    "reason" to "not_found"
                )
            }

            val statusValue = cursor.getInt(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS)
            )
            val reason = cursor.getInt(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)
            )
            val downloaded = cursor.getLong(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
            )
            val total = cursor.getLong(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
            )

            var statusName = downloadStatusName(statusValue)
            var reasonText = reason.toString()

            if (statusValue == DownloadManager.STATUS_SUCCESSFUL) {
                val validationError = validateDownloadedApk(downloadId, downloaded)
                if (validationError != null) {
                    statusName = "failed"
                    reasonText = validationError
                }
            }

            return mapOf(
                "status" to statusName,
                "bytesDownloaded" to downloaded,
                "totalBytes" to total,
                "reason" to reasonText
            )
        }
    }

    private fun installDownloadedApk(downloadId: Long) {
        val validationError = validateDownloadedApk(downloadId)
        if (validationError != null) {
            throw IOException("The downloaded update file is not a valid APK: $validationError")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            throw InstallPermissionRequiredException()
        }

        val apkUri = downloadManager().getUriForDownloadedFile(downloadId)
            ?: throw IOException("The downloaded APK could not be found.")

        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(installIntent)
    }

    private fun validateDownloadedApk(downloadId: Long, reportedBytes: Long? = null): String? {
        val apkUri = downloadManager().getUriForDownloadedFile(downloadId)
            ?: return "missing_apk_file"

        val size = reportedBytes?.takeIf { it > 0 } ?: queryDownloadedFileSize(apkUri)
        if (size in 1 until MIN_APK_BYTES) {
            return "invalid_apk_too_small"
        }

        return try {
            contentResolver.openInputStream(apkUri)?.use { input ->
                val header = ByteArray(4)
                val read = input.read(header)
                if (read < 4 || header[0] != 0x50.toByte() || header[1] != 0x4B.toByte()) {
                    return "invalid_apk_content"
                }
            } ?: return "missing_apk_file"
            null
        } catch (_: Exception) {
            "invalid_apk_content"
        }
    }

    private fun queryDownloadedFileSize(uri: Uri): Long {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return 0L
                }
                val sizeIndex = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE)
                if (sizeIndex >= 0) cursor.getLong(sizeIndex) else 0L
            } ?: 0L
        } catch (_: Exception) {
            0L
        }
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val settingsIntent = Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:$packageName")
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(settingsIntent)
    }

    private fun downloadStatusName(status: Int): String {
        return when (status) {
            DownloadManager.STATUS_PENDING -> "pending"
            DownloadManager.STATUS_RUNNING -> "running"
            DownloadManager.STATUS_PAUSED -> "paused"
            DownloadManager.STATUS_SUCCESSFUL -> "successful"
            DownloadManager.STATUS_FAILED -> "failed"
            else -> "unknown"
        }
    }

    private fun downloadManager(): DownloadManager {
        return getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    }

    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): Map<String, Any?> {
        val tempFile = File.createTempFile("masar-export-", ".tmp", cacheDir)
        try {
            FileOutputStream(tempFile).use { output ->
                output.write(bytes)
                output.flush()
            }
            return saveFileToDownloads(fileName, mimeType, tempFile.absolutePath)
        } finally {
            try {
                tempFile.delete()
            } catch (_: Exception) {
                // Best-effort cleanup only.
            }
        }
    }

    private fun saveFileToDownloads(
        fileName: String,
        mimeType: String,
        sourcePath: String
    ): Map<String, Any?> {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists() || sourceFile.length() <= 0L) {
            throw IOException("The generated export file is empty or missing.")
        }

        val safeFileName = sanitizeFileName(fileName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val uri = saveFileToDownloadsWithMediaStore(safeFileName, mimeType, sourceFile)
            return mapOf(
                "success" to true,
                "fileName" to safeFileName,
                "displayPath" to "Phone storage / Download / Masar CRM / $safeFileName",
                "uri" to uri.toString(),
                "mimeType" to mimeType
            )
        }

        throw IOException("Choose where to save the export file.")
    }

    private fun requestUserChosenExportSave(
        fileName: String,
        mimeType: String,
        sourcePath: String,
        result: MethodChannel.Result
    ) {
        if (pendingExportSaveResult != null) {
            throw IOException("Another export save is already waiting for a folder selection.")
        }
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists() || sourceFile.length() <= 0L) {
            throw IOException("The generated export file is empty or missing.")
        }
        val safeFileName = sanitizeFileName(fileName)
        pendingExportSaveResult = result
        pendingExportSourcePath = sourcePath
        pendingExportFileName = safeFileName
        pendingExportMimeType = mimeType

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType.ifBlank { EXCEL_XLSX_MIME_TYPE }
            putExtra(Intent.EXTRA_TITLE, safeFileName)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        startActivityForResult(intent, EXPORT_SAVE_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == EXPORT_SAVE_REQUEST_CODE) {
            val pendingResult = pendingExportSaveResult
            val sourcePath = pendingExportSourcePath
            val fileName = pendingExportFileName
            val mimeType = pendingExportMimeType
            clearPendingExportSave()

            if (pendingResult == null) {
                super.onActivityResult(requestCode, resultCode, data)
                return
            }

            val uri = data?.data
            if (resultCode != RESULT_OK || uri == null) {
                pendingResult.error("save_cancelled", "The file save was cancelled.", null)
                return
            }

            try {
                FileInputStream(File(sourcePath)).use { input ->
                    contentResolver.openOutputStream(uri)?.use { output ->
                        input.copyTo(output)
                        output.flush()
                    } ?: throw IOException("Could not open the selected save location.")
                }
                pendingResult.success(mapOf(
                    "success" to true,
                    "fileName" to fileName,
                    "displayPath" to "Selected phone folder / $fileName",
                    "uri" to uri.toString(),
                    "mimeType" to mimeType
                ))
            } catch (error: Exception) {
                pendingResult.error(
                    "download_failed",
                    error.message ?: "The file could not be saved.",
                    null
                )
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun clearPendingExportSave() {
        pendingExportSaveResult = null
        pendingExportSourcePath = ""
        pendingExportFileName = ""
        pendingExportMimeType = ""
    }

    private fun saveFileToDownloadsWithMediaStore(
        fileName: String,
        mimeType: String,
        sourceFile: File
    ): Uri {
        val resolver = applicationContext.contentResolver
        val collection = MediaStore.Downloads.getContentUri(
            MediaStore.VOLUME_EXTERNAL_PRIMARY
        )
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Masar CRM")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(collection, values)
            ?: throw IOException("Could not create a Downloads file.")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(sourceFile).use { input ->
                    input.copyTo(output)
                }
                output.flush()
            } ?: throw IOException("Could not open the Downloads file.")

            val publishedValues = ContentValues().apply {
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
            resolver.update(uri, publishedValues, null, null)
            return uri
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun saveFileToAppExternalDownloads(fileName: String, sourceFile: File): File {
        val baseDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        val masarDir = File(baseDir, "Masar CRM")
        if (!masarDir.exists() && !masarDir.mkdirs()) {
            throw IOException("Could not create the Masar CRM downloads folder.")
        }
        val outputFile = File(masarDir, fileName)
        FileInputStream(sourceFile).use { input ->
            FileOutputStream(outputFile).use { output ->
                input.copyTo(output)
                output.flush()
            }
        }
        return outputFile
    }

    private fun fileProviderUri(file: File): Uri {
        return FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )
    }

    private fun openDownloadedFile(uriString: String, mimeType: String) {
        val uri = Uri.parse(uriString)
        val mimeTypes = listOf(
            mimeType.takeIf { it.isNotBlank() } ?: EXCEL_XLSX_MIME_TYPE,
            EXCEL_XLSX_MIME_TYPE,
            EXCEL_LEGACY_MIME_TYPE,
            "application/octet-stream",
            "*/*"
        ).distinct()

        var lastError: Exception? = null
        for (candidateMimeType in mimeTypes) {
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, candidateMimeType)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(Intent.createChooser(intent, "Open Masar CRM export"))
                return
            } catch (error: Exception) {
                lastError = error
            }
        }
        throw lastError ?: IOException("No app can open this exported file.")
    }

    private fun openDownloadsLocation(uriString: String, mimeType: String) {
        val downloadsFolderIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(
                Uri.parse("content://com.android.externalstorage.documents/document/primary%3ADownload%2FMasar%20CRM"),
                "vnd.android.document/directory"
            )
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivity(downloadsFolderIntent)
            return
        } catch (_: Exception) {
            // Some Android file managers do not allow opening a direct folder URI.
        }

        val downloadsRootIntent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(downloadsRootIntent)
    }

    private fun sanitizeFileName(fileName: String): String {
        val cleaned = fileName
            .replace(Regex("[\\\\/:*?\"<>|]"), "-")
            .replace(Regex("\\s+"), " ")
            .trim()
        return cleaned.ifEmpty { "masar-export.xlsx" }
    }

    private fun longArgument(value: Any?): Long {
        return when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Number -> value.toLong()
            is String -> value.toLongOrNull() ?: 0L
            else -> 0L
        }
    }

    private class InstallPermissionRequiredException : Exception()

    private companion object {
        const val FILE_DOWNLOADER_CHANNEL = "masarcrm/file_downloader"
        const val APK_UPDATER_CHANNEL = "masarcrm/android_apk_updater"
        const val UPDATE_NOTIFICATIONS_CHANNEL = "masarcrm/update_notifications"
        const val APK_MIME_TYPE = "application/vnd.android.package-archive"
        const val EXCEL_XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        const val EXCEL_LEGACY_MIME_TYPE = "application/vnd.ms-excel"
        const val MIN_APK_BYTES = 1024 * 1024
        const val EXPORT_SAVE_REQUEST_CODE = 42420
        const val UPDATE_NOTIFICATION_CHANNEL_ID = "masar_app_updates"
        const val UPDATE_NOTIFICATION_ID = 93021
        const val UPDATE_NOTIFICATION_REQUEST_CODE = 93022
        const val ACTION_SHOW_UPDATE = "com.example.real_estate_crm.SHOW_UPDATE"
        const val EXTRA_UPDATE_NOTIFICATION_TAP = "masar_update_notification_tap"
    }
}
