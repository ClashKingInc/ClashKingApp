package com.clashking.clashkingapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class WarAppWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.clashking.clashkingapp.ACTION_UPDATE_WIDGET"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            Log.d("TAG", "onUpdate: $widgetData")
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        // Set the PendingIntent to the root layout of the widget
        views.setOnClickPendingIntent(R.id.root_layout, getPendingIntent(context))

        // Get the war info from SharedPreferences
        val warInfoJson = widgetData.getString("warInfo", null)

        if (warInfoJson != null) {
            val warInfo = JSONObject(warInfoJson)
            val state = warInfo.getString("state")
            val updatedTime = warInfo.optString("updatedAt", "")
            views.setTextViewText(R.id.text_update_time, updatedTime)
            when (state) {
                "notInWar" -> {
                    setWidgetText(views, "You're currently not in War.")
                }

                "notInClan" -> {
                    setWidgetText(views, "You're currently not in a Clan.")
                }

                "error" -> {
                    setWidgetText(views, "An error occurred while fetching data.")
                }

                else -> {
                    val score = warInfo.optString("score", "")
                    val warStatus = warInfo.optString("timeState", "notInWar")

                    val clanInfo = warInfo.getJSONObject("clan")
                    val opponentInfo = warInfo.getJSONObject("opponent")

                    val clanDetails = getClanOrOpponentDetails(clanInfo)
                    val opponentDetails = getClanOrOpponentDetails(opponentInfo)

                    views.setTextViewText(R.id.text_score, score)
                    views.setTextViewText(R.id.text_state, warStatus)
                    setDetailsToViews(views, clanDetails, opponentDetails)

                    Thread {
                        val clanBitmap = downloadBitmap(clanDetails.badgeUrl)
                        val opponentBitmap = downloadBitmap(opponentDetails.badgeUrl)
                        views.setImageViewBitmap(R.id.clan_flag, clanBitmap)
                        views.setImageViewBitmap(R.id.opponent_flag, opponentBitmap)
                        appWidgetManager.updateAppWidget(appWidgetId, views)
                    }.start()
                }
            }
        }

        // Update the widget when the refresh icon is clicked
        val updateIntent = Intent(context, WarAppWidgetProvider::class.java).apply {
            action = ACTION_UPDATE_WIDGET
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }

        // Create a PendingIntent to handle the click event
        val updatePendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            updateIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        views.setOnClickPendingIntent(R.id.refresh_icon, updatePendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    // Handle the new action in onReceive method of WarAppWidgetProvider
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE_WIDGET) {
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.text_update_time, "Updating...")
            AppWidgetManager.getInstance(context).updateAppWidget(appWidgetId, views)

            // Creating the PendingIntent to initiate the refresh
            val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("warWidget://refreshClicked")
            )
            // Send the PendingIntent
            refreshIntent.send()// Send the PendingIntent directly
        }
    }


}

private fun downloadBitmap(url: String): Bitmap? {
    return try {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.doInput = true
        connection.connect()
        val input = connection.inputStream
        BitmapFactory.decodeStream(input)
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}

private fun getPendingIntent(context: Context): PendingIntent {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
}


fun setWidgetText(views: RemoteViews, stateText: String) {
    views.setTextViewText(R.id.text_state, stateText)
    listOf(
        R.id.clan_name,
        R.id.opponent_name,
        R.id.text_score,
        R.id.clan_percent,
        R.id.clan_attacks,
        R.id.opponent_percent,
        R.id.opponent_attacks,
        R.id.text_update_time
    ).forEach {
        views.setTextViewText(it, "")
    }
    views.setImageViewBitmap(R.id.clan_flag, null)
    views.setImageViewBitmap(R.id.opponent_flag, null)
}

data class ClanOrOpponentDetails(
    val name: String,
    val badgeUrl: String,
    val percent: String,
    val attacks: String
)

fun getClanOrOpponentDetails(info: JSONObject): ClanOrOpponentDetails {
    return ClanOrOpponentDetails(
        name = info.optString("name", "Unknown"),
        badgeUrl = info.optString(
            "badgeUrlMedium",
            "https://assets.clashk.ing/clashkinglogo.png"
        ),
        percent = info.optString("percent", "0%"),
        attacks = info.optString("attacks", "0/0")
    )
}

fun setDetailsToViews(
    views: RemoteViews,
    clanDetails: ClanOrOpponentDetails,
    opponentDetails: ClanOrOpponentDetails
) {
    views.setTextViewText(R.id.clan_name, clanDetails.name)
    views.setTextViewText(R.id.clan_percent, clanDetails.percent)
    views.setTextViewText(R.id.clan_attacks, clanDetails.attacks)
    views.setTextViewText(R.id.opponent_name, opponentDetails.name)
    views.setTextViewText(R.id.opponent_percent, opponentDetails.percent)
    views.setTextViewText(R.id.opponent_attacks, opponentDetails.attacks)
}