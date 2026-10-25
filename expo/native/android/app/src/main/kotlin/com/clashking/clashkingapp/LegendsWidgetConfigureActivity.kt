package com.clashking.clashkingapp

import android.appwidget.AppWidgetProvider
import android.content.Context
import org.json.JSONArray

class LegendsWidgetConfigureActivity : WidgetConfigureActivity() {
    override val eyebrowText = R.string.legends_widget_configure_eyebrow
    override val titleText = R.string.legends_widget_configure_title
    override val descriptionText = R.string.legends_widget_configure_description
    override val emptyText = R.string.legends_widget_configure_empty
    override val automaticText = R.string.legends_widget_configure_automatic
    override val actionText = R.string.legends_widget_configure_add

    override fun selectedTag(appWidgetId: Int): String? =
        LegendsWidgetSelectionStore.selectedTag(this, appWidgetId)

    override fun readOptions(): List<WidgetSelectionOption> {
        val raw = homeWidgetPreferences().getString("legendsWidgetPlayers", null)
            ?: return emptyList()
        val array = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
        val seen = mutableSetOf<String>()
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val tag = LegendsWidgetSelectionStore.normalizeTag(item.optString("tag"))
                if (tag.isBlank() || !seen.add(tag)) continue
                val name = item.optString("name").ifBlank { "#$tag" }
                val townHall = item.optInt("townHallLevel", 0)
                add(
                    WidgetSelectionOption(
                        tag = tag,
                        title = name,
                        detail = buildString {
                            append("#").append(tag)
                            if (townHall > 0) append(" · TH ").append(townHall)
                        }
                    )
                )
            }
        }
    }

    override fun saveSelectedTag(appWidgetId: Int, tag: String?) {
        LegendsWidgetSelectionStore.saveSelectedTag(this, appWidgetId, tag)
    }

    override fun transparentBackgroundEnabled(appWidgetId: Int): Boolean =
        LegendsWidgetSelectionStore.transparentBackground(this, appWidgetId)

    override fun saveTransparentBackgroundEnabled(appWidgetId: Int, enabled: Boolean) {
        LegendsWidgetSelectionStore.saveTransparentBackground(this, appWidgetId, enabled)
    }

    override fun widgetProviderClass(): Class<out AppWidgetProvider> =
        LegendsAppWidgetProvider::class.java

    private fun homeWidgetPreferences() =
        getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
}
