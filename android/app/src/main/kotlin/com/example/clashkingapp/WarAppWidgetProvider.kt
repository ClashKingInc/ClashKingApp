package com.example.clashkingapp

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
        const val ACTION_UPDATE_WIDGET = "com.example.clashkingapp.ACTION_UPDATE_WIDGET"
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

        println("Widget Data: ")
        for ((key, value) in widgetData.all) {
            println("$key: $value")
        }
        // Get the war info from SharedPreferences
        val warInfoJson = widgetData.getString("warInfo", null)
        if (warInfoJson != "notInWar" && warInfoJson != null) {
            print("War Info: $warInfoJson");
            // Parse the JSON string into a JSONObject
            val warInfo = JSONObject(warInfoJson)

            // Get score
            val score = warInfo.optString("score", "")

            // Get war status
            val warStatus = warInfo.optString("timeState", "notInWar")

            // Get updated time
            val updatedTime = warInfo.optString("updatedAt", "")

            // Get the clan and opponent info
            val clanInfo = warInfo.getJSONObject("clan")
            val opponentInfo = warInfo.getJSONObject("opponent")

            // Get the clan details
            val clanName = clanInfo.optString("name", "Unknown Clan")
            val clanBadgeUrlMedium = clanInfo.optString(
                "badgeUrlMedium",
                "https://clashkingfiles.b-cdn.net/clashkinglogo.png"
            )
            val clanPercent = clanInfo.optString("percent", "0%")
            val clanAttacks = clanInfo.optString("attacks", "0/0")

            // Get the opponent details
            val opponentName = opponentInfo.optString("name", "Unknown Opponent")
            val opponentBadgeUrlMedium = opponentInfo.optString(
                "badgeUrlMedium",
                "https://clashkingfiles.b-cdn.net/clashkinglogo.png"
            )
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

            // Load the images from the URLs into the ImageViews
            Thread {
                val clanBitmap = downloadBitmap(clanBadgeUrlMedium)
                val opponentBitmap = downloadBitmap(opponentBadgeUrlMedium)
                views.setImageViewBitmap(R.id.clan_flag, clanBitmap)
                views.setImageViewBitmap(R.id.opponent_flag, opponentBitmap)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }.start()
        } else {
            views.setTextViewText(R.id.text_state, "You're currently not in War.")
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
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
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