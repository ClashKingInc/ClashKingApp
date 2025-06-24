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
            val statusIcon = warInfo.optString("statusIcon", "")
            val primaryText = warInfo.optString("primaryText", "")
            val secondaryText = warInfo.optString("secondaryText", "")
            val colorTheme = warInfo.optString("colorTheme", "neutral")
            
            views.setTextViewText(R.id.text_update_time, updatedTime)
            
            // Apply color theme
            applyColorTheme(views, colorTheme)
            
            when (state) {
                "notInWar" -> {
                    setWidgetText(views, "$statusIcon $primaryText", secondaryText)
                }

                "notInClan" -> {
                    setWidgetText(views, "You're currently not in a Clan.")
                }
                
                "accessDenied" -> {
                    setWidgetText(views, "$statusIcon $primaryText", secondaryText)
                }

                "error" -> {
                    setWidgetText(views, "An error occurred while fetching data.")
                }
                
                "cwl" -> {
                    // Handle CWL state with enhanced UI
                    val score = warInfo.optString("score", "")
                    
                    // Use new enhanced text fields
                    views.setTextViewText(R.id.text_score, if (primaryText.isNotEmpty()) primaryText else score)
                    views.setTextViewText(R.id.text_state, if (secondaryText.isNotEmpty()) secondaryText else warInfo.optString("timeState", "CWL"))

                    val clanInfo = warInfo.getJSONObject("clan")
                    val opponentInfo = warInfo.getJSONObject("opponent")

                    val clanDetails = getClanOrOpponentDetails(clanInfo)
                    val opponentDetails = getClanOrOpponentDetails(opponentInfo)

                    setDetailsToViews(views, clanDetails, opponentDetails)

                    Thread {
                        val clanBitmap = downloadBitmap(clanDetails.badgeUrl)
                        val opponentBitmap = downloadBitmap(opponentDetails.badgeUrl)
                        views.setImageViewBitmap(R.id.clan_flag, clanBitmap)
                        views.setImageViewBitmap(R.id.opponent_flag, opponentBitmap)
                        appWidgetManager.updateAppWidget(appWidgetId, views)
                    }.start()
                }

                else -> {
                    // Handle regular war states with enhanced UI
                    val score = warInfo.optString("score", "")
                    
                    // Use new enhanced text fields
                    views.setTextViewText(R.id.text_score, if (primaryText.isNotEmpty()) primaryText else score)
                    views.setTextViewText(R.id.text_state, if (secondaryText.isNotEmpty()) secondaryText else warInfo.optString("timeState", "notInWar"))

                    val clanInfo = warInfo.getJSONObject("clan")
                    val opponentInfo = warInfo.getJSONObject("opponent")

                    val clanDetails = getClanOrOpponentDetails(clanInfo)
                    val opponentDetails = getClanOrOpponentDetails(opponentInfo)

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


fun setWidgetText(views: RemoteViews, primaryText: String, secondaryText: String = "") {
    views.setTextViewText(R.id.text_score, primaryText)
    views.setTextViewText(R.id.text_state, secondaryText.ifEmpty { primaryText })
    
    // Clear other details when showing simple text
    listOf(
        R.id.clan_name,
        R.id.opponent_name,
        R.id.clan_percent,
        R.id.clan_attacks,
        R.id.opponent_percent,
        R.id.opponent_attacks
    ).forEach {
        views.setTextViewText(it, "")
    }
    views.setImageViewBitmap(R.id.clan_flag, null)
    views.setImageViewBitmap(R.id.opponent_flag, null)
}

fun applyColorTheme(views: RemoteViews, colorTheme: String) {
    // Apply color themes to widget top section only
    val backgroundColor = when (colorTheme) {
        "winning" -> android.graphics.Color.parseColor("#1B5E20") // Dark green
        "losing" -> android.graphics.Color.parseColor("#B71C1C") // Dark red  
        "tied" -> android.graphics.Color.parseColor("#E65100") // Orange
        "victory" -> android.graphics.Color.parseColor("#2E7D32") // Green
        "defeat" -> android.graphics.Color.parseColor("#C62828") // Red
        "preparation" -> android.graphics.Color.parseColor("#1565C0") // Blue
        "cwl" -> android.graphics.Color.parseColor("#6A1B9A") // Purple
        "warning" -> android.graphics.Color.parseColor("#EF6C00") // Orange
        "neutral" -> android.graphics.Color.parseColor("#424242") // Gray
        else -> android.graphics.Color.parseColor("#424242") // Default gray
    }
    
    // Create a rounded top background with the theme color
    val topBackground = android.graphics.drawable.GradientDrawable().apply {
        setColor(backgroundColor)
        cornerRadii = floatArrayOf(
            16f, 16f, // top-left
            16f, 16f, // top-right  
            0f, 0f,   // bottom-right
            0f, 0f    // bottom-left
        )
    }
    
    // Apply the colored background to the top container only
    views.setInt(R.id.root_layout, "setBackgroundColor", backgroundColor)
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