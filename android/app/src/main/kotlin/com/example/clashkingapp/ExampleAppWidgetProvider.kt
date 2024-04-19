package com.example.clashkingapp

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.clashkingapp.R
import android.util.Log
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.net.HttpURLConnection
import java.net.URL

class ExampleAppWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            Log.d("TAG", "onUpdate: $widgetData")
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, widgetData: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
    
        // Get the war info from SharedPreferences
        val warInfoJson = widgetData.getString("warInfo", null)
        if (warInfoJson != null && warInfoJson != "notInWar") {
        // Parse the JSON string into a JSONObject
        val warInfo = JSONObject(warInfoJson)
        // Get the clan and opponent info
        val clanInfo = warInfo.getJSONObject("clan")
        val opponentInfo = warInfo.getJSONObject("opponent")
    
        // Get the clan and opponent details
        
        val clanName = clanInfo.optString("name", "Unknown Clan")
        val clanBadgeUrlMedium = clanInfo.optString("badgeUrlMedium", "https://clashkingfiles.b-cdn.net/clashkinglogo.png") 
        val clanStars = clanInfo.optInt("stars", 0)
    
        val opponentName = opponentInfo.optString("name", "Unknown Opponent")
        val opponentBadgeUrlMedium = opponentInfo.optString("badgeUrlMedium", "https://clashkingfiles.b-cdn.net/clashkinglogo.png")
        val opponentStars = opponentInfo.optInt("stars", 0)
    
        // Set the clan and opponent details to the views
        views.setTextViewText(R.id.clan_name, clanName)
        views.setTextViewText(R.id.opponent_name, opponentName)
        views.setTextViewText(R.id.text_score, "${clanStars.toString()} - ${opponentStars.toString()}")
    
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