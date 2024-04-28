package com.example.clashkingapp

import android.appwidget.AppWidgetManager
import android.content.Context
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

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            Log.d("TAG", "onUpdate: $widgetData")
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, widgetData: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        println("Widget Data: $widgetData")
        // Get the war info from SharedPreferences
        val warInfoJson = widgetData.getString("warInfo", null)
        if (warInfoJson != null && warInfoJson != "notInWar") {
        // Parse the JSON string into a JSONObject
        val warInfo = JSONObject(warInfoJson)

        // Get score
        val score = warInfo.optString("score", "")

        // Get war status
        val warStatus = warInfo.optString("state", "notInWar")

        // Get updated time
        val updatedTime = warInfo.optString("updatedAt", "")

        // Get the clan and opponent info
        val clanInfo = warInfo.getJSONObject("clan")
        val opponentInfo = warInfo.getJSONObject("opponent")

        // Get the clan details
        val clanName = clanInfo.optString("name", "Unknown Clan")
        val clanBadgeUrlMedium = clanInfo.optString("badgeUrlMedium", "https://clashkingfiles.b-cdn.net/clashkinglogo.png")
        val clanPercent = clanInfo.optString("percent", "0%")
        val clanAttacks = clanInfo.optString("attacks", "0/0")

        // Get the opponent details
        val opponentName = opponentInfo.optString("name", "Unknown Opponent")
        val opponentBadgeUrlMedium = opponentInfo.optString("badgeUrlMedium", "https://clashkingfiles.b-cdn.net/clashkinglogo.png")
        val opponentPercent = opponentInfo.optString("percent", "0%")
        val opponentAttacks = opponentInfo.optString("attacks", "0/0")

        // Set the clan and opponent details to the views
        views.setTextViewText(R.id.clan_name, clanName)
        views.setTextViewText(R.id.opponent_name, opponentName)
        views.setTextViewText(R.id.text_score, score)
        views.setTextViewText(R.id.text_state, warStatus)
        views.setTextViewText(R.id.clan_percent, clanPercent.toString())
        views.setTextViewText(R.id.clan_attacks, clanAttacks.toString())
        views.setTextViewText(R.id.opponent_percent, opponentPercent.toString())
        views.setTextViewText(R.id.opponent_attacks, opponentAttacks.toString())
        views.setTextViewText(R.id.text_update_time, updatedTime)

        // Background callback
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("warWidget://refreshClicked")
        )
        views.setOnClickPendingIntent(R.id.refresh_icon, backgroundIntent)


        // Load the images from the URLs into the ImageViews
        Thread {
            val clanBitmap = downloadBitmap(clanBadgeUrlMedium)
            val opponentBitmap = downloadBitmap(opponentBadgeUrlMedium)
            views.setImageViewBitmap(R.id.clan_flag, clanBitmap)
            views.setImageViewBitmap(R.id.opponent_flag, opponentBitmap)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }.start()
        }

        else{
        views.setTextViewText(R.id.text_score, "You're currently not in War.")
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
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