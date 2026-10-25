package com.clashking.clashkingapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class WarAppWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        WarWidgetSelectionStore.delete(context, appWidgetIds)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        views.setInt(
            R.id.root_layout,
            "setBackgroundResource",
            if (WarWidgetSelectionStore.transparentBackground(context, appWidgetId)) {
                android.R.color.transparent
            } else {
                R.drawable.war_widget_background
            }
        )

        // Migrate old automatic widgets once, then keep each instance pinned to that clan.
        val selectedTag = WarWidgetSelectionStore.selectedTag(context, appWidgetId)
            ?: widgetData.getString("warWidgetSelectedClan", null)?.takeIf { it.isNotBlank() }?.also {
                WarWidgetSelectionStore.saveSelectedTag(context, appWidgetId, it)
            }
        views.setOnClickPendingIntent(R.id.root_layout, launchAppIntent(context, appWidgetId, selectedTag))
        var payloadKey = selectedTag?.let {
            "warInfo_${WarWidgetSelectionStore.normalizeTag(it)}"
        } ?: "warInfo_unconfigured"
        var rawWarInfo = widgetData.getString(payloadKey, null)
        val selectedDefaultTag = widgetData.getString("warWidgetSelectedClan", null)
            ?.let(WarWidgetSelectionStore::normalizeTag)
        if (
            rawWarInfo == null &&
            selectedTag != null &&
            selectedDefaultTag == WarWidgetSelectionStore.normalizeTag(selectedTag)
        ) {
            payloadKey = "warInfo"
            rawWarInfo = widgetData.getString(payloadKey, null)
        }
        val warInfo = rawWarInfo?.let { runCatching { JSONObject(it) }.getOrNull() }
        val state = warInfo?.optString("state", "unavailable")
            ?: if (selectedTag == null) "unconfigured" else "unavailable"
        if (state in setOf("notInClan", "notInWar", "accessDenied", "error", "unavailable", "unconfigured") ||
            warInfo?.optJSONObject("clan") == null || warInfo.optJSONObject("opponent") == null) {
            showEmptyState(context, views, appWidgetManager, appWidgetId, widgetData, selectedTag, state, warInfo, payloadKey)
        } else {
            showMatchup(context, views, appWidgetManager, appWidgetId, warInfo, payloadKey, rawWarInfo!!)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun showEmptyState(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        widgetId: Int,
        preferences: SharedPreferences,
        selectedTag: String?,
        state: String,
        payload: JSONObject?,
        payloadKey: String
    ) {
        // Identity comes from the selected clan even when the war payload is absent.
        // Missing data must not be presented as a confirmed absence of war.
        val options = runCatching { JSONArray(preferences.getString("warWidgetClans", "[]")) }.getOrNull()
        val selected = (0 until (options?.length() ?: 0)).mapNotNull { options?.optJSONObject(it) }
            .firstOrNull { WarWidgetSelectionStore.normalizeTag(it.optString("tag")) ==
                selectedTag?.let(WarWidgetSelectionStore::normalizeTag) }
        val clan = payload?.optJSONObject("clan")
        val name = selected?.optString("name")?.takeIf { it.isNotBlank() }
            ?: clan?.optString("name")?.takeIf { it.isNotBlank() } ?: "ClashKing"
        val message = when (state) {
            "notInWar", "cwl" -> context.getString(R.string.war_state_idle_message, name)
            "accessDenied" -> context.getString(R.string.war_state_private_message, name)
            "notInClan", "unconfigured" -> context.getString(R.string.war_state_choose)
            else -> "$name\n${context.getString(R.string.war_state_unavailable)}"
        }
        views.setViewVisibility(R.id.matchup_content, View.GONE)
        views.setViewVisibility(R.id.empty_content, View.VISIBLE)
        views.setTextViewText(R.id.empty_title, message)
        views.setImageViewResource(R.id.empty_badge, R.mipmap.launcher_icon)
        val normalized = selectedTag?.let(WarWidgetSelectionStore::normalizeTag)
        if (!normalized.isNullOrBlank()) {
            val sourcePayload = preferences.getString(payloadKey, null)
            Thread {
                val badge = downloadBitmap("https://badges.clashk.ing/$normalized")
                if (badge != null && preferences.getString(payloadKey, null) == sourcePayload &&
                    WarWidgetSelectionStore.selectedTag(context, widgetId) == selectedTag) {
                    views.setImageViewBitmap(R.id.empty_badge, badge)
                    manager.updateAppWidget(widgetId, views)
                }
            }.start()
        }
    }

    private fun showMatchup(
        context: Context,
        views: RemoteViews,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        warInfo: JSONObject,
        payloadKey: String,
        sourcePayload: String
    ) {
        val clanInfo = warInfo.optJSONObject("clan")
        val opponentInfo = warInfo.optJSONObject("opponent")
        if (clanInfo == null || opponentInfo == null) {
            val preferences = context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
            showEmptyState(context, views, appWidgetManager, appWidgetId, preferences,
                WarWidgetSelectionStore.selectedTag(context, appWidgetId), warInfo.optString("state"), warInfo, payloadKey)
            return
        }

        val clan = clanInfo.toSideDetails()
        val opponent = opponentInfo.toSideDetails()
        val score = normalizedScore(warInfo)
        val status = displayText(warInfo, context.getString(R.string.war_widget_status))

        views.setViewVisibility(R.id.matchup_content, View.VISIBLE)
        views.setViewVisibility(R.id.empty_content, View.GONE)
        views.setTextViewText(R.id.text_score, score)
        views.setTextViewTextSize(
            R.id.text_score,
            TypedValue.COMPLEX_UNIT_SP,
            if (score.length >= 7) 24f else 28f
        )
        views.setTextViewText(R.id.text_state, status)
        views.setTextViewText(R.id.clan_name, clan.name)
        views.setTextViewText(R.id.clan_attacks, clan.attacks)
        views.setTextViewText(R.id.opponent_name, opponent.name)
        views.setTextViewText(R.id.opponent_attacks, opponent.attacks)
        views.setImageViewBitmap(R.id.clan_flag, null)
        views.setImageViewBitmap(R.id.opponent_flag, null)

        Thread {
            val clanBadge = downloadBitmap(clan.badgeUrl)
            val opponentBadge = downloadBitmap(opponent.badgeUrl)
            val attackIcon = downloadBitmap(warInfo.optString("attackIconUrl"))
            val currentPayload = context
                .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .getString(payloadKey, null)
            if (currentPayload == sourcePayload) {
                if (clanBadge != null) views.setImageViewBitmap(R.id.clan_flag, clanBadge)
                if (opponentBadge != null) views.setImageViewBitmap(R.id.opponent_flag, opponentBadge)
                if (attackIcon != null) {
                    views.setImageViewBitmap(R.id.clan_attack_icon, attackIcon)
                    views.setImageViewBitmap(R.id.opponent_attack_icon, attackIcon)
                }
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }.start()
    }
}

private data class WarSideDetails(
    val name: String,
    val badgeUrl: String,
    val attacks: String
)

private fun JSONObject.toSideDetails(): WarSideDetails {
    return WarSideDetails(
        name = optString("name", "Unknown"),
        badgeUrl = optString("badgeUrlMedium", ""),
        attacks = optString("attacks", "—")
    )
}

private fun normalizedScore(warInfo: JSONObject): String {
    val score = warInfo.optString("score", "").ifBlank {
        warInfo.optString("secondaryText", "")
    }
    return score
        .replace(" ", "")
        .replace("–", "-")
        .ifBlank { "-" }
}

private fun displayText(warInfo: JSONObject, fallback: String): String {
    return warInfo.optString("primaryText", "").ifBlank {
        warInfo.optString("timeState", "")
    }.ifBlank { fallback }
}

private fun downloadBitmap(url: String): Bitmap? {
    if (url.isBlank()) return null
    var connection: HttpURLConnection? = null
    return try {
        val source = URL(url)
        val badgeUrl = if (source.host == "badges.clashk.ing") {
            URL("https", source.host, source.path.replace(Regex("\\.[^/]+$"), "") + ".png?size=256")
        } else source
        connection = badgeUrl.openConnection() as HttpURLConnection
        connection.connectTimeout = 5_000
        connection.readTimeout = 5_000
        connection.doInput = true
        connection.connect()
        connection.inputStream.use { input -> BitmapFactory.decodeStream(input) }
    } catch (_: Exception) {
        null
    } finally {
        connection?.disconnect()
    }
}

private fun launchAppIntent(context: Context, appWidgetId: Int, selectedTag: String?): PendingIntent {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        ?: Intent(Intent.ACTION_MAIN).setPackage(context.packageName)
    intent.action = Intent.ACTION_VIEW
    val tag = selectedTag?.let { android.net.Uri.encode(WarWidgetSelectionStore.normalizeTag(it)) }
    intent.data = android.net.Uri.parse(if (tag.isNullOrBlank()) "clashking://war" else "clashking://clan/$tag/war")
    return PendingIntent.getActivity(
        context,
        appWidgetId,
        intent,
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )
}
