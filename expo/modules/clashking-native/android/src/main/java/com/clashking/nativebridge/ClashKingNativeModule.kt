package com.clashking.nativebridge

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.it_nomads.fluttersecurestorage.FlutterSecureStorage
import com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig
import com.it_nomads.fluttersecurestorage.SecurePreferencesCallback
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.activityresult.AppContextActivityResultContract
import expo.modules.kotlin.activityresult.AppContextActivityResultLauncher
import expo.modules.kotlin.functions.Coroutine
import java.io.File
import java.io.RandomAccessFile
import java.io.Serializable
import java.net.HttpURLConnection
import java.net.URL
import java.nio.channels.FileChannel
import java.nio.channels.FileLock
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private const val SESSION_KEY = "shared_auth_session_v1"
private const val WIDGET_PREFERENCES = "HomeWidgetPreferences"
private const val WIDGET_ACTION_PREFERENCES = "ClashKingWidgetActions"
private const val PENDING_WIDGET_ACTION = "pending_widget_action"
private const val SECURE_STORAGE_TIMEOUT_SECONDS = 30L
private val LEGACY_WIDGET_KEYS = setOf(
    "warWidgetClans",
    "warWidgetSelectedClan",
    "warInfo",
    "warWidgetProxyUrl",
    "warWidgetApiV2Url",
    "upgradeWidgetAccounts",
    "upgradeWidgetData",
    "upgradeWidgetSelectedTag"
)

class ClashKingNativeModule : Module() {
    private val refreshLock = AndroidSharedAuthRefreshLock()
    private val secureStorageLock = Any()
    private var secureStorage: FlutterSecureStorage? = null
    private val sceneryAudio by lazy {
        AndroidSceneryAudioBridge { status -> sendEvent("onSceneryAudioStatus", status) }
    }

    override fun definition() = ModuleDefinition {
        Name("ClashKingNative")
        Events("onSceneryAudioStatus")

        AsyncFunction("prepareSceneryAudio") Coroutine { source: String ->
            sceneryAudio.prepare(requireContext(), source)
        }
        AsyncFunction("playSceneryAudio") { sceneryAudio.play() }
        AsyncFunction("pauseSceneryAudio") { sceneryAudio.pause() }
        AsyncFunction("seekSceneryAudio") { positionMilliseconds: Double ->
            sceneryAudio.seek(positionMilliseconds)
        }
        AsyncFunction("releaseSceneryAudio") { sceneryAudio.release() }

        AsyncFunction("acquireSharedAuthRefreshLock") { timeoutSeconds: Double? ->
            refreshLock.acquire(requireContext(), timeoutSeconds ?: 12.0)
        }
        AsyncFunction("releaseSharedAuthRefreshLock") { refreshLock.release() }

        AsyncFunction("supportsAlternateIcons") { false }
        AsyncFunction("getAlternateIconName") { null as String? }
        AsyncFunction("setAlternateIconName") { iconName: String? ->
            require(iconName == null) {
                "Alternate app icons are only supported by the ClashKing iOS build."
            }
        }

        AsyncFunction("showDebugNotification") { _: Map<String, Any?> ->
            unsupportedDebugNotification()
        }

        lateinit var fileSaveLauncher: AppContextActivityResultLauncher<FileSaveOptions, FileSaveResult>

        RegisterActivityContracts {
            fileSaveLauncher = registerForActivityResult(FileSaveContract())
        }

        AsyncFunction("saveFile") Coroutine { options: Map<String, String> ->
            val fileUri = requireNotNull(options["fileUri"]) { "fileUri is required." }
            val fileName = requireNotNull(options["fileName"]) { "fileName is required." }
            val mimeType = requireNotNull(options["mimeType"]) { "mimeType is required." }
            val result = fileSaveLauncher.launch(
                FileSaveOptions(fileUri, fileName, mimeType)
            )
            check(result is FileSaveResult.Saved) { "CANCELLED" }
            val destination = result.uri
            val source = File(requireNotNull(Uri.parse(fileUri).path))
            requireContext().contentResolver.openOutputStream(Uri.parse(destination), "w").use { output ->
                requireNotNull(output) { "Could not open the selected save destination." }
                source.inputStream().use { inputStream -> inputStream.copyTo(output) }
            }
            Uri.parse(destination).path ?: destination
        }

        AsyncFunction("setWidgetValue") { key: String, value: String? ->
            val editor = requireContext()
                .getSharedPreferences(WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .edit()
            if (value == null) editor.remove(key) else editor.putString(key, value)
            check(editor.commit()) { "Could not persist shared widget value '$key'." }
        }

        AsyncFunction("reloadWidgets") { reloadWidgets(requireContext()) }

        AsyncFunction("consumePendingWidgetAction") {
            val preferences = requireContext().getSharedPreferences(
                WIDGET_ACTION_PREFERENCES,
                Context.MODE_PRIVATE
            )
            val action = preferences.getString(PENDING_WIDGET_ACTION, null)
            if (action != null) preferences.edit().remove(PENDING_WIDGET_ACTION).commit()
            action
        }

        AsyncFunction("readLegacyWidgetValues") {
            requireContext()
                .getSharedPreferences(WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .all
                .mapNotNull { (key, value) ->
                    if (legacyWidgetKeyIsAllowed(key) && value is String) key to value else null
                }
                .toMap()
        }

        AsyncFunction("requestPinWarWidget") {
            requestPinWarWidget(requireContext())
        }

        AsyncFunction("readSharedAuthSession") {
            withSecureStorage(requireContext()) { storage ->
                val key = storage.addPrefixToKey(SESSION_KEY)
                if (storage.containsKey(key)) storage.read(key) else null
            }
        }

        AsyncFunction("writeSharedAuthSession") { encodedSession: String ->
            withSecureStorage(requireContext()) { storage ->
                storage.write(storage.addPrefixToKey(SESSION_KEY), encodedSession)
            }
        }

        AsyncFunction("clearSharedAuthSession") {
            withSecureStorage(requireContext()) { storage ->
                storage.delete(storage.addPrefixToKey(SESSION_KEY))
            }
        }

        Function("getLegacyMigrationCapabilities") {
            mapOf(
                "platform" to "android",
                "secureStorageReadable" to true,
                "sharedPreferencesReadable" to true,
                "destructiveReads" to false,
                "note" to "Uses the vendored flutter_secure_storage 10.3.1 default preferences, key prefix, cipher migration, and Android Keystore implementation."
            )
        }

        AsyncFunction("readLegacyFlutterSecureValue") { key: String, _: Boolean? ->
            withSecureStorage(requireContext()) { storage ->
                val prefixedKey = storage.addPrefixToKey(key)
                if (storage.containsKey(prefixedKey)) storage.read(prefixedKey) else null
            }
        }

        AsyncFunction("readAllLegacyFlutterSecureValues") { _: Boolean? ->
            withSecureStorage(requireContext()) { storage -> storage.readAll() }
        }

        AsyncFunction("readLegacyFlutterPreferences") { keys: List<String> ->
            readLegacyFlutterPreferences(requireContext(), keys)
        }

        AsyncFunction("readAllLegacyFlutterPreferences") {
            readAllLegacyFlutterPreferences(requireContext())
        }
    }

    private fun requireContext(): Context = appContext.reactContext
        ?: throw IllegalStateException("React context is unavailable.")

    private fun reloadWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        listOf("WarAppWidgetProvider", "UpgradeAppWidgetProvider").forEach { className ->
            val component = ComponentName(context.packageName, "${context.packageName}.$className")
            val widgetIds = manager.getAppWidgetIds(component)
            if (widgetIds.isNotEmpty()) {
                context.sendBroadcast(Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    setComponent(component)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                })
            }
        }
    }

    private fun requestPinWarWidget(context: Context): Map<String, Boolean> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return mapOf("supported" to false, "requested" to false)
        }
        val manager = AppWidgetManager.getInstance(context)
        val provider = ComponentName(context.packageName, "${context.packageName}.WarAppWidgetProvider")
        val providerAvailable = try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getReceiverInfo(
                    provider,
                    PackageManager.ComponentInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getReceiverInfo(provider, 0)
            }
            info.enabled
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
        val supported = providerAvailable && manager.isRequestPinAppWidgetSupported
        val requested = supported && manager.requestPinAppWidget(provider, null, null)
        return mapOf("supported" to supported, "requested" to requested)
    }

    private fun <T> withSecureStorage(context: Context, operation: (FlutterSecureStorage) -> T): T {
        return synchronized(secureStorageLock) {
            val storage = secureStorage ?: FlutterSecureStorage(context).also { candidate ->
                val latch = CountDownLatch(1)
                val initializationError = AtomicReference<Exception?>()
                candidate.initialize(
                    FlutterSecureStorageConfig(emptyMap()),
                    object : SecurePreferencesCallback<Void> {
                        override fun onSuccess(result: Void?) = latch.countDown()
                        override fun onError(error: Exception) {
                            initializationError.set(error)
                            latch.countDown()
                        }
                    }
                )
                check(latch.await(SECURE_STORAGE_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                    "Timed out initializing the legacy Flutter secure storage reader."
                }
                initializationError.get()?.let { throw it }
                secureStorage = candidate
            }
            operation(storage)
        }
    }

    private fun readLegacyFlutterPreferences(
        context: Context,
        keys: List<String>
    ): Map<String, Any> {
        val preferences = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        return keys.distinct().mapNotNull { key ->
            val flutterKey = "flutter.$key"
            val value = when {
                preferences.contains(flutterKey) -> preferences.all[flutterKey]
                preferences.contains(key) -> preferences.all[key]
                else -> null
            }
            when (value) {
                is String, is Boolean, is Int, is Long, is Float -> key to value
                else -> null
            }
        }.toMap()
    }

    private fun readAllLegacyFlutterPreferences(context: Context): Map<String, Any> {
        val preferences = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        return preferences.all.mapNotNull { (storedKey, value) ->
            val key = storedKey.removePrefix("flutter.")
            when (value) {
                is String, is Boolean, is Int, is Long, is Float -> key to value
                else -> null
            }
        }.toMap()
    }
}

private class AndroidSceneryAudioBridge(
    private val emit: (Map<String, Any>) -> Unit
) : AudioManager.OnAudioFocusChangeListener {
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var resumeOnFocus = false
    private var didJustFinish = false
    private val statusTick = object : Runnable {
        override fun run() {
            sendStatus()
            if (player != null) handler.postDelayed(this, 250L)
        }
    }

    suspend fun prepare(context: Context, source: String) {
        require(source.startsWith("https://") || source.startsWith("http://")) {
            "Scenery audio requires an HTTP or HTTPS source."
        }
        val file = cachedAudioFile(context, source)
        withContext(Dispatchers.Main) {
            releaseOnMain()
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager = manager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(attributes)
                    .setWillPauseWhenDucked(true)
                    .setOnAudioFocusChangeListener(this@AndroidSceneryAudioBridge, handler)
                    .build()
            }
            player = MediaPlayer().apply {
                setAudioAttributes(attributes)
                setDataSource(file.absolutePath)
                isLooping = false
                setVolume(1f, 1f)
                setOnCompletionListener {
                    didJustFinish = true
                    seekTo(0)
                    sendStatus()
                }
                prepare()
            }
            handler.removeCallbacks(statusTick)
            handler.post(statusTick)
            sendStatus()
        }
    }

    fun play() = handler.post {
        val mediaPlayer = player ?: return@post
        val manager = audioManager ?: return@post
        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.requestAudioFocus(requireNotNull(focusRequest))
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                this@AndroidSceneryAudioBridge,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            )
        }
        if (granted == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            didJustFinish = false
            mediaPlayer.start()
            sendStatus()
        }
    }

    fun pause() = handler.post { pauseOnMain(abandonFocus = true) }

    fun seek(positionMilliseconds: Double) = handler.post {
        didJustFinish = false
        player?.seekTo(positionMilliseconds.coerceAtLeast(0.0).toInt())
        sendStatus()
    }

    fun release() = handler.post { releaseOnMain() }

    override fun onAudioFocusChange(change: Int) {
        handler.post {
            when (change) {
                AudioManager.AUDIOFOCUS_GAIN -> {
                    if (resumeOnFocus) {
                        resumeOnFocus = false
                        player?.start()
                    }
                }
                AudioManager.AUDIOFOCUS_LOSS,
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                    val wasPlaying = player?.isPlaying == true
                    resumeOnFocus = wasPlaying && change != AudioManager.AUDIOFOCUS_LOSS
                    if (wasPlaying) player?.pause()
                }
            }
            sendStatus()
        }
    }

    private suspend fun cachedAudioFile(context: Context, source: String): File =
        withContext(Dispatchers.IO) {
            val digest = MessageDigest.getInstance("SHA-256")
                .digest(source.toByteArray())
                .joinToString("") { "%02x".format(it) }
            val extension = Uri.parse(source).lastPathSegment
                ?.substringAfterLast('.', "audio")
                ?.takeIf { it.matches(Regex("[A-Za-z0-9]{1,8}")) }
                ?: "audio"
            val directory = File(context.cacheDir, "scenery-audio").apply { mkdirs() }
            val destination = File(directory, "$digest.$extension")
            if (destination.isFile && destination.length() > 0) return@withContext destination
            val temporary = File(directory, "$digest.download")
            val connection = URL(source).openConnection() as HttpURLConnection
            try {
                connection.connectTimeout = 15_000
                connection.readTimeout = 30_000
                connection.instanceFollowRedirects = true
                connection.connect()
                require(connection.responseCode in 200..299) {
                    "Scenery audio download failed with HTTP ${connection.responseCode}."
                }
                connection.inputStream.use { input ->
                    temporary.outputStream().use { output -> input.copyTo(output) }
                }
                check(temporary.renameTo(destination) || destination.isFile) {
                    "Could not persist the scenery audio disk cache."
                }
            } finally {
                connection.disconnect()
                if (temporary.exists()) temporary.delete()
            }
            destination
        }

    private fun pauseOnMain(abandonFocus: Boolean) {
        if (player?.isPlaying == true) player?.pause()
        resumeOnFocus = false
        if (abandonFocus) abandonAudioFocus()
        sendStatus()
    }

    private fun releaseOnMain() {
        handler.removeCallbacks(statusTick)
        abandonAudioFocus()
        player?.run {
            setOnCompletionListener(null)
            stopSafely()
            release()
        }
        player = null
        audioManager = null
        focusRequest = null
        resumeOnFocus = false
        didJustFinish = false
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let(manager::abandonAudioFocusRequest)
        } else {
            @Suppress("DEPRECATION")
            manager.abandonAudioFocus(this)
        }
    }

    private fun sendStatus() {
        val mediaPlayer = player
        val loaded = mediaPlayer != null
        val position = if (loaded) runCatching { mediaPlayer!!.currentPosition }.getOrDefault(0) else 0
        val duration = if (loaded) runCatching { mediaPlayer!!.duration }.getOrDefault(0) else 0
        val playing = loaded && runCatching { mediaPlayer!!.isPlaying }.getOrDefault(false)
        emit(
            mapOf(
                "positionMilliseconds" to position.coerceAtLeast(0),
                "durationMilliseconds" to duration.coerceAtLeast(0),
                "playing" to playing,
                "loaded" to loaded,
                "buffering" to false,
                "didJustFinish" to didJustFinish
            )
        )
        didJustFinish = false
    }
}

private fun MediaPlayer.stopSafely() {
    runCatching { stop() }
}

private data class FileSaveOptions(
    val fileUri: String,
    val fileName: String,
    val mimeType: String
) : Serializable

private sealed class FileSaveResult {
    data class Saved(val uri: String) : FileSaveResult()
    data object Cancelled : FileSaveResult()
}

private class FileSaveContract : AppContextActivityResultContract<FileSaveOptions, FileSaveResult> {
    override fun createIntent(context: Context, input: FileSaveOptions): Intent {
        val source = File(requireNotNull(Uri.parse(input.fileUri).path) {
            "The source file URI has no path."
        })
        require(source.isFile) { "The source file does not exist: ${source.path}" }
        return Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = input.mimeType
            putExtra(Intent.EXTRA_TITLE, input.fileName)
        }
    }

    override fun parseResult(
        input: FileSaveOptions,
        resultCode: Int,
        intent: Intent?
    ): FileSaveResult {
        if (resultCode != Activity.RESULT_OK) return FileSaveResult.Cancelled
        return intent?.data?.toString()?.let(FileSaveResult::Saved) ?: FileSaveResult.Cancelled
    }
}

private fun unsupportedDebugNotification(): Map<String, Any?> {
    throw IllegalStateException(
        "Notification debug samples are only supported by the ClashKing iOS build."
    )
}

private fun legacyWidgetKeyIsAllowed(key: String): Boolean {
    return key in LEGACY_WIDGET_KEYS || key.startsWith("warInfo_") || key.startsWith("upgradeWidget_")
}

private class AndroidSharedAuthRefreshLock {
    private var channel: FileChannel? = null
    private var lock: FileLock? = null

    @Synchronized
    fun acquire(context: Context, requestedTimeoutSeconds: Double): Boolean {
        check(lock == null) { "The shared authentication lock is already held." }
        val timeoutSeconds = requestedTimeoutSeconds.coerceIn(0.1, 60.0)
        val deadlineNanos = System.nanoTime() + (timeoutSeconds * 1_000_000_000L).toLong()
        val candidateChannel = RandomAccessFile(
            context.filesDir.resolve("auth-refresh.lock"),
            "rw"
        ).channel
        try {
            do {
                try {
                    val candidateLock = candidateChannel.tryLock()
                    if (candidateLock != null) {
                        channel = candidateChannel
                        lock = candidateLock
                        return true
                    }
                } catch (_: java.nio.channels.OverlappingFileLockException) {
                    // Another lock in this process owns the same file.
                }
                Thread.sleep(50)
            } while (System.nanoTime() < deadlineNanos)
        } catch (error: Throwable) {
            candidateChannel.close()
            throw error
        }
        candidateChannel.close()
        return false
    }

    @Synchronized
    fun release() {
        lock?.release()
        channel?.close()
        lock = null
        channel = null
    }
}
