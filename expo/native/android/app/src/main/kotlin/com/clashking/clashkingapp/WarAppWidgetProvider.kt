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
        views.setOnClickPendingIntent(R.id.root_layout, launchAppIntent(context, appWidgetId))

        val selectedTag = WarWidgetSelectionStore.selectedTag(context, appWidgetId)
        var payloadKey = selectedTag?.let {
            "warInfo_${WarWidgetSelectionStore.normalizeTag(it)}"
        } ?: "warInfo"
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
        if (rawWarInfo == null) {
            showEmptyState(
                views,
                context.getString(R.string.war_widget_empty_title),
                context.getString(R.string.war_widget_empty_subtitle)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        val warInfo = runCatching { JSONObject(rawWarInfo) }.getOrNull()
        if (warInfo == null) {
            showEmptyState(
                views,
                context.getString(R.string.war_widget_empty_title),
                context.getString(R.string.war_widget_empty_subtitle)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        when (warInfo.optString("state", "error")) {
            "notInClan" -> showEmptyState(
                views,
                context.getString(R.string.war_widget_not_in_clan),
                context.getString(R.string.war_widget_choose_account)
            )
            "notInWar" -> showEmptyState(
                views,
                displayText(warInfo, context.getString(R.string.war_widget_not_in_war)),
                warInfo.optString("secondaryText", "")
            )
            "accessDenied" -> showEmptyState(
                views,
                displayText(warInfo, context.getString(R.string.war_widget_private)),
                warInfo.optString("secondaryText", "")
            )
            "error" -> showEmptyState(
                views,
                displayText(warInfo, context.getString(R.string.war_widget_error)),
                warInfo.optString("secondaryText", context.getString(R.string.war_widget_empty_subtitle))
            )
            else -> showMatchup(
                context,
                views,
                appWidgetManager,
                appWidgetId,
                warInfo,
                payloadKey,
                rawWarInfo
            )
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
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
            showEmptyState(
                views,
                displayText(warInfo, context.getString(R.string.war_widget_empty_title)),
                warInfo.optString("secondaryText", "")
            )
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
        views.setTextViewText(R.id.clan_percent, clan.percent)
        views.setTextViewText(R.id.opponent_name, opponent.name)
        views.setTextViewText(R.id.opponent_percent, opponent.percent)
        views.setImageViewBitmap(R.id.clan_flag, null)
        views.setImageViewBitmap(R.id.opponent_flag, null)

        Thread {
            val clanBadge = downloadBitmap(clan.badgeUrl)
            val opponentBadge = downloadBitmap(opponent.badgeUrl)
            val currentPayload = context
                .getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
                .getString(payloadKey, null)
            if (currentPayload == sourcePayload) {
                if (clanBadge != null) views.setImageViewBitmap(R.id.clan_flag, clanBadge)
                if (opponentBadge != null) views.setImageViewBitmap(R.id.opponent_flag, opponentBadge)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }.start()
    }
}

private data class WarSideDetails(
    val name: String,
    val badgeUrl: String,
    val percent: String
)

private fun JSONObject.toSideDetails(): WarSideDetails {
    return WarSideDetails(
        name = optString("name", "Unknown"),
        badgeUrl = optString("badgeUrlMedium", ""),
        percent = optString("percent", "")
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

private fun showEmptyState(views: RemoteViews, title: String, subtitle: String) {
    views.setViewVisibility(R.id.matchup_content, View.GONE)
    views.setViewVisibility(R.id.empty_content, View.VISIBLE)
    views.setTextViewText(R.id.empty_title, title)
    views.setTextViewText(R.id.empty_subtitle, subtitle)
    views.setViewVisibility(R.id.empty_subtitle, if (subtitle.isBlank()) View.GONE else View.VISIBLE)
}

private fun downloadBitmap(url: String): Bitmap? {
    if (url.isBlank()) return null
    var connection: HttpURLConnection? = null
    return try {
        connection = URL(url).openConnection() as HttpURLConnection
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

private fun launchAppIntent(context: Context, appWidgetId: Int): PendingIntent {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        ?: Intent(Intent.ACTION_MAIN).setPackage(context.packageName)
    return PendingIntent.getActivity(
        context,
        appWidgetId,
        intent,
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )
}
