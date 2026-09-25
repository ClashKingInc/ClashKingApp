package com.clashking.clashkingapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.text.format.DateUtils
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.time.Duration
import java.time.Instant
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class LegendsAppWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
        private const val PLAYER_OPTIONS_KEY = "legendsWidgetPlayers"
        private const val PAYLOAD_PREFIX = "legendsWidget_"
        private const val WIDE_MIN_WIDTH_DP = 300
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val preferences = context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        val imageUpdates = mutableListOf<LegendsWidgetImageUpdate>()
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, preferences)
                ?.let(imageUpdates::add)
        }
        if (imageUpdates.isEmpty()) return

        val pendingResult = goAsync()
        Thread {
            try {
                imageUpdates.forEach { it.apply(context) }
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        LegendsWidgetSelectionStore.delete(context, appWidgetIds)
        super.onDeleted(context, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        preferences: SharedPreferences
    ): LegendsWidgetImageUpdate? {
        val selectedTag = LegendsWidgetSelectionStore.selectedTag(context, appWidgetId)
            ?: firstPlayerTag(preferences)?.also {
                LegendsWidgetSelectionStore.saveSelectedTag(context, appWidgetId, it)
            }
        val normalizedTag = selectedTag?.let(LegendsWidgetSelectionStore::normalizeTag)
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val wide = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) >= WIDE_MIN_WIDTH_DP
        val layoutId = if (wide) R.layout.legends_widget_layout_wide else R.layout.legends_widget_layout
        val views = RemoteViews(context.packageName, layoutId)
        views.setInt(
            R.id.legends_root_layout,
            "setBackgroundResource",
            if (LegendsWidgetSelectionStore.transparentBackground(context, appWidgetId)) {
                android.R.color.transparent
            } else {
                R.drawable.legends_widget_background
            }
        )
        views.setOnClickPendingIntent(
            R.id.legends_root_layout,
            playerPendingIntent(context, appWidgetId, normalizedTag)
        )

        val payloadKey = normalizedTag?.let { "$PAYLOAD_PREFIX$it" }
        val rawPayload = payloadKey?.let { preferences.getString(it, null) }
        val payload = rawPayload?.let { runCatching { JSONObject(it) }.getOrNull() }
        if (payload == null || !validPayload(payload, normalizedTag)) {
            renderEmpty(context, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return null
        }

        val labels = payload.optJSONObject("labels") ?: JSONObject()
        if (!hasLegendData(payload)) {
            renderEmpty(
                views,
                label(labels, "noData", context.getString(R.string.legends_widget_no_data))
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return null
        }
        val stale = isStale(payload)
        renderCore(context, views, payload, labels, stale, wide)
        if (wide) {
            renderWide(context, views, payload)
        } else {
            renderCompact(context, views, payload)
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)

        val targets = buildMap {
            payload.optString("townHallImageUrl").takeIf(String::isNotBlank)?.let {
                put(R.id.legends_town_hall, it)
            }
            val artwork = payload.optJSONObject("artwork")
            artwork?.optString("attackIconUrl")?.takeIf(String::isNotBlank)?.let {
                put(R.id.legends_attack_icon, it)
            }
            artwork?.optString("defenseIconUrl")?.takeIf(String::isNotBlank)?.let {
                put(R.id.legends_defense_icon, it)
            }
            if (wide) {
                payload.optJSONObject("clan")
                    ?.optString("badgeUrl")
                    ?.takeIf(String::isNotBlank)
                    ?.let { put(R.id.legends_clan_badge, it) }
            }
            val recent = latestBattle(payload)
            recent?.let {
                artwork?.optString(
                    if (it.kind == BattleKind.ATTACK) "attackIconUrl" else "defenseIconUrl"
                )?.takeIf(String::isNotBlank)?.let { imageUrl ->
                    put(R.id.legends_recent_kind_icon, imageUrl)
                }
            }
            addStarTargets(
                this,
                recent?.battle,
                artwork,
                intArrayOf(
                    R.id.legends_recent_star_one,
                    R.id.legends_recent_star_two,
                    R.id.legends_recent_star_three
                )
            )
        }
        return targets.takeIf { it.isNotEmpty() }?.let {
            LegendsWidgetImageUpdate(
                appWidgetManager = appWidgetManager,
                appWidgetId = appWidgetId,
                views = views,
                expectedLayoutId = layoutId,
                expectedTag = normalizedTag.orEmpty(),
                expectedPayload = requireNotNull(rawPayload),
                targets = it
            )
        }
    }

    private fun validPayload(payload: JSONObject, expectedTag: String?): Boolean {
        if (expectedTag.isNullOrBlank() || payload.optInt("schemaVersion", 0) != 1) return false
        if (LegendsWidgetSelectionStore.normalizeTag(payload.optString("tag")) != expectedTag) return false
        return payload.optString("legendDay").matches(Regex("^\\d{4}-\\d{2}-\\d{2}$")) &&
            runCatching { Instant.parse(payload.getString("dayStartsAt")) }.isSuccess &&
            runCatching { Instant.parse(payload.getString("dayEndsAt")) }.isSuccess
    }

    private fun renderCore(
        context: Context,
        views: RemoteViews,
        payload: JSONObject,
        labels: JSONObject,
        stale: Boolean,
        showClan: Boolean
    ) {
        views.setViewVisibility(R.id.legends_content, View.VISIBLE)
        views.setViewVisibility(R.id.legends_empty_state, View.GONE)
        views.setTextViewText(
            R.id.legends_player_name,
            payload.optString("name").ifBlank { context.getString(R.string.legends_widget_player_label) }
        )
        views.setImageViewResource(R.id.legends_town_hall, R.drawable.ic_upgrade_hall_placeholder)
        val clan = payload.optJSONObject("clan")
        val hasClan = clan != null && clan.optString("name").isNotBlank()
        views.setViewVisibility(
            R.id.legends_clan_group,
            if (showClan && hasClan) View.VISIBLE else View.GONE
        )
        views.setTextViewText(R.id.legends_clan_name, clan?.optString("name").orEmpty())
        views.setTextViewText(
            R.id.legends_day,
            label(labels, "dayFormatted", payload.optString("legendDay"))
        )
        views.setTextViewText(R.id.legends_net_value, payload.optSigned("netTrophies"))
        views.setTextViewText(
            R.id.legends_attack_value,
            payload.optCount("attacksUsed")
        )
        views.setTextViewText(
            R.id.legends_defense_value,
            payload.optCount("defensesTaken")
        )
        views.setTextViewText(R.id.legends_rank_value, payload.optRank("globalRank"))
        views.setTextViewText(
            R.id.legends_rank_label,
            context.getString(R.string.legends_widget_rank)
        )
        views.setTextColor(R.id.legends_net_value, context.getColor(payload.semanticTrophyColor("netTrophies")))
        views.setViewVisibility(R.id.legends_stale_chip, if (stale) View.VISIBLE else View.GONE)
        views.setTextViewText(
            R.id.legends_stale_chip,
            label(labels, "staleData", context.getString(R.string.legends_widget_stale))
        )
    }

    private fun renderWide(
        context: Context,
        views: RemoteViews,
        payload: JSONObject
    ) {
        views.setTextViewText(
            R.id.legends_attack_trophies,
            payload.optSigned("attackTrophies")
        )
        views.setTextColor(
            R.id.legends_attack_trophies,
            context.getColor(payload.semanticTrophyColor("attackTrophies"))
        )
        views.setTextViewText(
            R.id.legends_defense_trophies,
            payload.optSigned("defenseTrophies")
        )
        views.setTextColor(
            R.id.legends_defense_trophies,
            context.getColor(payload.semanticTrophyColor("defenseTrophies"))
        )
        renderRecentBattle(context, views, payload)
    }

    private fun renderCompact(
        context: Context,
        views: RemoteViews,
        payload: JSONObject
    ) {
        renderRecentBattle(context, views, payload)
    }

    private fun renderRecentBattle(
        context: Context,
        views: RemoteViews,
        payload: JSONObject
    ) {
        val recent = latestBattle(payload)
        views.setViewVisibility(R.id.legends_recent_row, View.VISIBLE)
        views.setTextViewText(
            R.id.legends_recent_heading,
            "${context.getString(R.string.legends_widget_recent)}:"
        )
        if (recent == null) {
            views.setViewVisibility(R.id.legends_recent_kind_icon, View.INVISIBLE)
            setStarVisibility(
                views,
                intArrayOf(
                    R.id.legends_recent_star_one,
                    R.id.legends_recent_star_two,
                    R.id.legends_recent_star_three
                ),
                false
            )
            views.setTextViewText(R.id.legends_recent_opponent, "")
            views.setTextViewText(R.id.legends_recent_value, "")
            views.setTextViewText(R.id.legends_recent_percentage, "")
            views.setTextViewText(R.id.legends_recent_time, "")
            return
        }

        val artwork = payload.optJSONObject("artwork")
        val hasStarArtwork = artwork?.optString("starFilledIconUrl")?.isNotBlank() == true &&
            artwork.optString("starEmptyIconUrl").isNotBlank()
        setStarVisibility(
            views,
            intArrayOf(
                R.id.legends_recent_star_one,
                R.id.legends_recent_star_two,
                R.id.legends_recent_star_three
            ),
            hasStarArtwork
        )
        views.setViewVisibility(R.id.legends_recent_kind_icon, View.VISIBLE)
        views.setTextViewText(R.id.legends_recent_time, recent.battle.relativeBattleTime())
        views.setTextViewText(
            R.id.legends_recent_opponent,
            recent.battle.optString("opponentName").ifBlank { "—" }
        )
        views.setTextViewText(R.id.legends_recent_value, recent.battle.optSigned("trophies"))
        views.setTextViewText(
            R.id.legends_recent_percentage,
            recent.battle.optDoubleOrNull("destructionPercentage")?.let {
                "${Math.round(it)}%"
            } ?: "—"
        )
        views.setTextColor(
            R.id.legends_recent_value,
            context.getColor(recent.battle.semanticTrophyColor("trophies"))
        )
    }

    private fun setStarVisibility(views: RemoteViews, viewIds: IntArray, visible: Boolean) {
        viewIds.forEach { viewId ->
            views.setViewVisibility(viewId, if (visible) View.VISIBLE else View.INVISIBLE)
        }
    }

    private fun renderEmpty(context: Context, views: RemoteViews) {
        renderEmpty(views, context.getString(R.string.legends_widget_no_data))
    }

    private fun renderEmpty(views: RemoteViews, message: String) {
        views.setViewVisibility(R.id.legends_content, View.GONE)
        views.setViewVisibility(R.id.legends_empty_state, View.VISIBLE)
        views.setTextViewText(R.id.legends_empty_state, message)
    }

    private fun hasLegendData(payload: JSONObject): Boolean = listOf(
        "trophies",
        "globalRank",
        "attackTrophies",
        "defenseTrophies",
        "netTrophies",
        "attacksUsed",
        "defensesTaken",
        "latestAttack",
        "latestDefense"
    ).any { payload.has(it) && !payload.isNull(it) }

    private fun isStale(payload: JSONObject): Boolean {
        val now = Instant.now()
        val dayEndsAt = runCatching { Instant.parse(payload.getString("dayEndsAt")) }.getOrNull()
            ?: return true
        val updatedAt = runCatching { Instant.parse(payload.getString("updatedAt")) }.getOrNull()
            ?: return true
        return !now.isBefore(dayEndsAt) ||
            (!now.isBefore(updatedAt) && Duration.between(updatedAt, now).toMinutes() >= 60)
    }

    private fun firstPlayerTag(preferences: SharedPreferences): String? {
        val players = preferences.getString(PLAYER_OPTIONS_KEY, null)
            ?.let { runCatching { org.json.JSONArray(it) }.getOrNull() }
            ?: return null
        for (index in 0 until players.length()) {
            val tag = LegendsWidgetSelectionStore.normalizeTag(
                players.optJSONObject(index)?.optString("tag").orEmpty()
            )
            if (tag.isNotBlank()) return tag
        }
        return null
    }

    private fun playerPendingIntent(context: Context, appWidgetId: Int, tag: String?): PendingIntent {
        val destination = if (tag.isNullOrBlank()) {
            Uri.parse("clashking://players")
        } else {
            Uri.parse("clashking://player/$tag?tab=legends")
        }
        val intent = Intent(Intent.ACTION_VIEW, destination, context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            30_000 + appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private data class LegendsWidgetImageUpdate(
        val appWidgetManager: AppWidgetManager,
        val appWidgetId: Int,
        val views: RemoteViews,
        val expectedLayoutId: Int,
        val expectedTag: String,
        val expectedPayload: String,
        val targets: Map<Int, String>
    ) {
        fun apply(context: Context) {
            val executor = Executors.newFixedThreadPool(targets.size.coerceIn(1, 2))
            try {
                val downloads = targets.values.distinct().associateWith { imageUrl ->
                    executor.submit<Bitmap?> { loadWidgetBitmap(imageUrl) }
                }
                var changed = false
                targets.forEach { (viewId, imageUrl) ->
                    val bitmap = runCatching {
                        downloads.getValue(imageUrl).get(8, TimeUnit.SECONDS)
                    }.getOrNull() ?: return@forEach
                    views.setImageViewBitmap(viewId, bitmap)
                    changed = true
                }
                if (changed && isStillCurrent(context)) appWidgetManager.updateAppWidget(appWidgetId, views)
            } finally {
                executor.shutdownNow()
            }
        }

        private fun isStillCurrent(context: Context): Boolean {
            val currentLayout = if (
                appWidgetManager.getAppWidgetOptions(appWidgetId)
                    .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) >= WIDE_MIN_WIDTH_DP
            ) R.layout.legends_widget_layout_wide else R.layout.legends_widget_layout
            if (currentLayout != expectedLayoutId) return false
            val selected = LegendsWidgetSelectionStore.selectedTag(context, appWidgetId)
                ?.let(LegendsWidgetSelectionStore::normalizeTag)
                ?: return false
            if (selected != expectedTag) return false
            return context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .getString("$PAYLOAD_PREFIX$expectedTag", null) == expectedPayload
        }
    }
}

private enum class BattleKind { ATTACK, DEFENSE }

private data class RecentBattle(val kind: BattleKind, val battle: JSONObject)

private fun latestBattle(payload: JSONObject): RecentBattle? = listOfNotNull(
    payload.optJSONObject("latestAttack")?.let { RecentBattle(BattleKind.ATTACK, it) },
    payload.optJSONObject("latestDefense")?.let { RecentBattle(BattleKind.DEFENSE, it) }
).maxByOrNull { recent ->
    recent.battle.optString("battleTime").let { raw ->
        runCatching { Instant.parse(raw).toEpochMilli() }.getOrDefault(Long.MIN_VALUE)
    }
}

private fun label(labels: JSONObject, key: String, fallback: String): String =
    labels.optString(key).ifBlank { fallback }

private fun JSONObject.optIntOrNull(key: String): Int? =
    if (has(key) && !isNull(key) && opt(key) is Number) optInt(key) else null

private fun JSONObject.optDoubleOrNull(key: String): Double? =
    if (has(key) && !isNull(key) && opt(key) is Number) optDouble(key) else null

private fun JSONObject.optSigned(key: String): String = optIntOrNull(key)?.let {
    if (it > 0) "+$it" else it.toString()
} ?: "—"

private fun JSONObject.semanticTrophyColor(key: String): Int = when {
    (optIntOrNull(key) ?: 0) > 0 -> R.color.widget_stat_positive
    (optIntOrNull(key) ?: 0) < 0 -> R.color.widget_stat_negative
    else -> R.color.widget_text
}

private fun JSONObject.relativeBattleTime(): String {
    val time = optString("battleTime")
        .takeIf(String::isNotBlank)
        ?.let { runCatching { Instant.parse(it) }.getOrNull() }
        ?: return ""
    return DateUtils.getRelativeTimeSpanString(
        time.toEpochMilli(),
        System.currentTimeMillis(),
        DateUtils.MINUTE_IN_MILLIS,
        DateUtils.FORMAT_ABBREV_RELATIVE or DateUtils.FORMAT_ABBREV_ALL
    ).toString()
}

private fun JSONObject.optCount(key: String): String = optIntOrNull(key)?.let { "$it/8" } ?: "—"

private fun JSONObject.optRank(key: String): String = optIntOrNull(key)?.takeIf { it > 0 }?.let { "#$it" } ?: "—"

private fun addStarTargets(
    targets: MutableMap<Int, String>,
    battle: JSONObject?,
    artwork: JSONObject?,
    viewIds: IntArray
) {
    val filled = artwork?.optString("starFilledIconUrl")?.takeIf(String::isNotBlank)
    val empty = artwork?.optString("starEmptyIconUrl")?.takeIf(String::isNotBlank)
    if (filled == null || empty == null) return
    val stars = battle?.optIntOrNull("stars")?.coerceIn(0, 3) ?: 0
    viewIds.forEachIndexed { index, viewId ->
        targets[viewId] = if (index < stars) filled else empty
    }
}

private fun loadWidgetBitmap(rawUrl: String): Bitmap? {
    var connection: HttpURLConnection? = null
    return try {
        val source = URL(rawUrl)
        if (source.protocol != "https") return null
        val resolved = if (source.host == "badges.clashk.ing") {
            URL("https", source.host, source.path.replace(Regex("\\.[^/]+$"), "") + ".png?size=256")
        } else source
        connection = resolved.openConnection() as HttpURLConnection
        connection.connectTimeout = 5_000
        connection.readTimeout = 5_000
        connection.doInput = true
        connection.connect()
        if (connection.responseCode !in 200..299) null
        else connection.inputStream.use(BitmapFactory::decodeStream)
    } catch (_: Exception) {
        null
    } finally {
        connection?.disconnect()
    }
}
