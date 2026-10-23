package com.clashking.clashkingapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.util.TypedValue
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
        val layoutId = legendsLayout(context, options)
        val wide = layoutId == R.layout.legends_widget_layout_wide
        if (BuildConfig.DEBUG) android.util.Log.d("CKWidgetSizing",
            "widget=$appWidgetId bounds=${widgetBounds(options)} actual=${widgetDimensions(context, options)} medium=$wide")
        val views = RemoteViews(context.packageName, layoutId)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Match WidgetKit's two shapes, not the launcher's leftover empty
            // area. Both card sizes have bounded content and transparent margins.
            val (width, height) = widgetDimensions(context, options)
            val cardWidth = if (wide) width.coerceAtMost(440) else minOf(width, height, 220)
            val cardHeight = if (wide) minOf(height, maxOf(152, (cardWidth * 0.47).toInt())) else cardWidth
            views.setViewLayoutWidth(R.id.legends_card, cardWidth.coerceAtLeast(110).toFloat(), TypedValue.COMPLEX_UNIT_DIP)
            views.setViewLayoutHeight(R.id.legends_card, cardHeight.coerceAtLeast(110).toFloat(), TypedValue.COMPLEX_UNIT_DIP)
        }
        views.setInt(
            R.id.legends_card,
            "setBackgroundResource",
            if (LegendsWidgetSelectionStore.transparentBackground(context, appWidgetId)) {
                android.R.color.transparent
            } else {
                R.drawable.legends_widget_background
            }
        )
        val payloadKey = normalizedTag?.let { "$PAYLOAD_PREFIX$it" }
        val rawPayload = payloadKey?.let { preferences.getString(it, null) }
        val payload = rawPayload?.let { runCatching { JSONObject(it) }.getOrNull() }
        views.setOnClickPendingIntent(
            R.id.legends_root_layout,
            playerPendingIntent(context, appWidgetId, normalizedTag, payload?.optString("mode"))
        )
        if (payload == null || !validPayload(payload, normalizedTag)) {
            val identity = configuredIdentity(preferences, normalizedTag)
            if (identity == null) {
                renderEmpty(context, views)
            } else {
                // Selection metadata is not a Legend-day snapshot. Show the real
                // account, but leave counters unknown until an eligible feed arrives.
                identity.put("legendDay", "")
                renderCore(context, views, identity, JSONObject(), true, wide)
                if (wide) renderWide(context, views, identity)
                else renderCompact(context, views, identity)
                views.setViewVisibility(R.id.legends_recent_row, View.GONE)
            }
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
            artwork?.optString("trophyIconUrl")?.takeIf(String::isNotBlank)?.let {
                put(R.id.legends_trophy_icon, it)
            }
            artwork?.optString("attackIconUrl")?.takeIf(String::isNotBlank)?.let {
                put(R.id.legends_attack_icon, it)
            }
            artwork?.optString("defenseIconUrl")?.takeIf(String::isNotBlank)?.let {
                put(R.id.legends_defense_icon, it)
            }
            if (wide) {
                val ranked = payload.optString("mode") == "ranked"
                payload.optJSONObject(if (ranked) "league" else "clan")
                    ?.optString(if (ranked) "iconUrl" else "badgeUrl")
                    ?.takeIf(String::isNotBlank)
                    ?.let { put(R.id.legends_clan_badge, it) }
            }
            val recent = payload.optJSONObject("latestAttack")?.let { RecentBattle(BattleKind.ATTACK, it) }
                ?: latestBattle(payload)
            if (wide && payload.optJSONObject("latestAttack") != null && payload.optJSONObject("latestDefense") != null) {
                artwork?.optString("defenseIconUrl")?.takeIf(String::isNotBlank)?.let {
                    put(R.id.legends_second_icon, it)
                }
                addStarTargets(this, payload.optJSONObject("latestDefense"), artwork,
                    intArrayOf(R.id.legends_second_star_one, R.id.legends_second_star_two, R.id.legends_second_star_three))
            }
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
                expectedBounds = widgetBounds(options),
                expectedOrientation = context.resources.configuration.orientation,
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
        val ranked = payload.optString("mode") == "ranked"
        // Do not substitute the clan when an older Ranked cache lacks its tier.
        val identity = payload.optJSONObject(if (ranked) "league" else "clan")
        val hasIdentity = identity != null && identity.optString("name").isNotBlank()
        views.setViewVisibility(
            R.id.legends_clan_group,
            if (showClan && hasIdentity) View.VISIBLE else View.GONE
        )
        views.setTextViewText(R.id.legends_clan_name, identity?.optString("name").orEmpty())
        views.setContentDescription(R.id.legends_clan_badge, identity?.optString("name").orEmpty())
        // Hosts reuse views during account changes. Clear the previous badge
        // while the current league/clan image is being loaded.
        views.setImageViewResource(R.id.legends_clan_badge, android.R.color.transparent)
        // Legend days are meaningful daily context; Ranked is a weekly snapshot
        // and must not inherit a generic Period or fabricated Legend day.
        val legendDay = label(labels, "dayFormatted", payload.optString("legendDay"))
        val dayLabel = if (showClan && payload.optString("mode") == "ranked")
            payload.optString("periodLabel") else legendDay
        views.setTextViewText(R.id.legends_day, dayLabel)
        views.setViewVisibility(R.id.legends_day,
            if ((showClan || payload.optString("mode") != "ranked") && dayLabel.isNotBlank()) View.VISIBLE else View.GONE)
        // Header is the total, not the period delta. Gains/losses are paired
        // with their own counters, matching the small and medium iOS widgets.
        views.setTextViewText(R.id.legends_net_value,
            payload.optIntOrNull("trophies")?.let { java.text.NumberFormat.getIntegerInstance().format(it) } ?: "—")
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
        views.setViewVisibility(R.id.legends_rank_label, if (showClan) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.legends_rank_value, if (showClan) View.VISIBLE else View.GONE)
        views.setContentDescription(R.id.legends_rank_value,
            context.getString(R.string.legends_widget_rank) + " " + payload.optRank("globalRank"))
        setTextColorResource(context, views, R.id.legends_net_value, R.color.widget_text_secondary)
        views.setTextViewText(R.id.legends_attack_trophies, payload.counterChange("attackTrophies", false))
        views.setTextViewText(R.id.legends_defense_trophies, payload.counterChange("defenseTrophies", true))
        applyTrophyColor(context, views, R.id.legends_attack_trophies, payload, "attackTrophies")
        applyTrophyColor(context, views, R.id.legends_defense_trophies, payload, "defenseTrophies")
        views.setViewVisibility(R.id.legends_stale_chip, View.GONE)
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
            payload.counterChange("attackTrophies", false)
        )
        views.setTextViewText(
            R.id.legends_defense_trophies,
            payload.counterChange("defenseTrophies", true)
        )
        renderRecentBattle(context, views, payload)

    }

    private fun renderCompact(
        context: Context,
        views: RemoteViews,
        payload: JSONObject
    ) {
        // Small widgets reserve their space for identity and counters. Recent
        // battle context (including empty-history messaging) is medium-only.
        views.setViewVisibility(R.id.legends_recent_row, View.GONE)
        views.setViewVisibility(R.id.legends_no_activity, View.GONE)
    }

    private fun renderRecentBattle(context: Context, views: RemoteViews, payload: JSONObject) {
        val attack = payload.optJSONObject("latestAttack")
        val defense = payload.optJSONObject("latestDefense")
        val first = attack?.let { RecentBattle(BattleKind.ATTACK, it) }
            ?: defense?.let { RecentBattle(BattleKind.DEFENSE, it) }
        val stale = isStale(payload)
        val hasBoth = attack != null && defense != null
        // Match the iOS medium card: attack first, defense second, or one
        // honest empty/stale message. Small widgets never render this panel.
        views.setViewVisibility(R.id.legends_recent_row, View.VISIBLE)
        views.setViewVisibility(R.id.legends_recent_heading, if (stale) View.GONE else View.VISIBLE)
        views.setTextViewText(R.id.legends_recent_heading, context.getString(R.string.legends_widget_recent) + ":")
        views.setViewVisibility(R.id.legends_first_recent, if (!stale && first != null) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.legends_second_recent, if (!stale && hasBoth) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.legends_no_activity, if (stale || first == null) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.legends_no_activity, if (stale) {
            label(payload.optJSONObject("labels") ?: JSONObject(), "staleData", context.getString(R.string.legends_widget_stale))
        } else context.getString(
            if (payload.optIntOrNull("attacksUsed") == 0 && payload.optIntOrNull("defensesTaken") == 0)
                R.string.legends_widget_no_activity else R.string.legends_widget_history_unavailable
        ))
        first?.let { renderBattleRow(context, views, payload, it.battle, false) }
        if (hasBoth) renderBattleRow(context, views, payload, requireNotNull(defense), true)
    }

    private fun renderBattleRow(context: Context, views: RemoteViews, payload: JSONObject, battle: JSONObject, second: Boolean) {
        val opponent = if (second) R.id.legends_second_opponent else R.id.legends_recent_opponent
        val value = if (second) R.id.legends_second_value else R.id.legends_recent_value
        val percentage = if (second) R.id.legends_second_percentage else R.id.legends_recent_percentage
        val time = if (second) R.id.legends_second_time else R.id.legends_recent_time
        val stars = if (second) intArrayOf(R.id.legends_second_star_one, R.id.legends_second_star_two, R.id.legends_second_star_three)
            else intArrayOf(R.id.legends_recent_star_one, R.id.legends_recent_star_two, R.id.legends_recent_star_three)
        val artwork = payload.optJSONObject("artwork")
        setStarVisibility(views, stars, artwork?.optString("starFilledIconUrl")?.isNotBlank() == true &&
            artwork.optString("starEmptyIconUrl").isNotBlank())
        views.setTextViewText(opponent, battle.optString("opponentName").ifBlank { "—" })
        views.setTextViewText(value, battle.optSigned("trophies"))
        views.setTextViewText(percentage, battle.optDoubleOrNull("destructionPercentage")?.let { "${Math.round(it)}%" } ?: "—")
        views.setTextViewText(time, battle.relativeBattleTime())
        // Battle gains remain primary text, matching the iOS Recent rows.
    }

    private fun applyTrophyColor(context: Context, views: RemoteViews, id: Int, data: JSONObject, key: String) {
        // Hosts can reapply this layout over the previous account's views.
        // Always reset neutral colors too, or Ranked green leaks into Legend.
        setTextColorResource(context, views, id, data.semanticTrophyColor(key))
    }

    private fun setTextColorResource(context: Context, views: RemoteViews, id: Int, color: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Resolve on the host, preserving light/dark resources after reapply.
            views.setColor(id, "setTextColor", color)
        } else {
            views.setTextColor(id, context.getColor(color))
        }
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

    // A valid selected player remains useful before today's battle feed arrives.
    // Keep identity visible and render absent counters as dashes, not invented zeroes.
    private fun hasLegendData(payload: JSONObject): Boolean = payload.optString("name").isNotBlank() || listOf(
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

    private fun configuredIdentity(preferences: SharedPreferences, tag: String?): JSONObject? {
        if (tag.isNullOrBlank()) return null
        val players = preferences.getString(PLAYER_OPTIONS_KEY, null)
            ?.let { runCatching { org.json.JSONArray(it) }.getOrNull() } ?: return null
        for (index in 0 until players.length()) {
            val player = players.optJSONObject(index) ?: continue
            if (LegendsWidgetSelectionStore.normalizeTag(player.optString("tag")) == tag) {
                return player.takeIf { it.optString("name").isNotBlank() }
            }
        }
        return null
    }

    private fun playerPendingIntent(context: Context, appWidgetId: Int, tag: String?, mode: String?): PendingIntent {
        val destination = if (tag.isNullOrBlank()) {
            Uri.parse("clashking://players")
        } else if (mode == "ranked") {
            Uri.parse("clashking://ranked?player=$tag")
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
        val expectedBounds: List<Int>,
        val expectedOrientation: Int,
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
            val currentOptions = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val currentLayout = legendsLayout(context, currentOptions)
            if (currentLayout != expectedLayoutId) return false
            // An image fetch started before a resize must not restore old bounds.
            if (widgetBounds(currentOptions) != expectedBounds ||
                context.resources.configuration.orientation != expectedOrientation) return false
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

private fun JSONObject.counterChange(key: String, defense: Boolean): String {
    // Zero still identifies gain versus loss; never reverse real Ranked gains.
    val value = optIntOrNull(key) ?: return "—"
    if (value == 0) return if (defense && optString("mode") != "ranked") "−0" else "+0"
    return optSigned(key)
}

private fun JSONObject.optSigned(key: String): String = optIntOrNull(key)?.let {
    if (it > 0) "+" + java.text.NumberFormat.getIntegerInstance().format(it)
        else java.text.NumberFormat.getIntegerInstance().format(it)
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

private fun widgetDimensions(context: Context, options: Bundle): Pair<Int, Int> {
    // Android supplies portrait/landscape ranges rather than one live rectangle.
    val landscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    val width = options.getInt(if (landscape) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
        else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
    val height = options.getInt(if (landscape) AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
        else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, width)
    return width to height
}

private fun legendsLayout(context: Context, options: Bundle): Int {
    val (width, height) = widgetDimensions(context, options)
    return if (width >= 300 && height >= 150) R.layout.legends_widget_layout_wide
        else R.layout.legends_widget_layout
}

private fun widgetBounds(options: Bundle): List<Int> = listOf(
    AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
    AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,
    AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
    AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
).map { options.getInt(it, 0) }

private fun JSONObject.optCount(key: String): String = optIntOrNull(key)?.let { count ->
    val limit = optIntOrNull(if (key == "attacksUsed") "attacksLimit" else "defensesLimit")
        ?: if (optString("mode") == "ranked") null else 8
    if (limit != null && limit > 0) "$count/$limit" else "$count/—"
} ?: "—"

private fun JSONObject.optRank(key: String): String = optIntOrNull(key)?.takeIf { it > 0 }?.let { "#" + java.text.NumberFormat.getIntegerInstance().format(it) } ?: "—"

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
