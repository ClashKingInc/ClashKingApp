package com.clashking.clashkingapp

import android.appwidget.AppWidgetProvider
import android.content.Context
import org.json.JSONArray

class WarWidgetConfigureActivity : WidgetConfigureActivity() {
    override val eyebrowText = R.string.war_widget_configure_eyebrow
    override val titleText = R.string.war_widget_configure_title
    override val descriptionText = R.string.war_widget_configure_description
    override val emptyText = R.string.war_widget_configure_empty
    override val automaticText = R.string.war_widget_configure_automatic
    override val actionText = R.string.war_widget_configure_add

    override fun selectedTag(appWidgetId: Int): String? =
        WarWidgetSelectionStore.selectedTag(this, appWidgetId)

    override fun readOptions(): List<WidgetSelectionOption> {
        val raw = homeWidgetPreferences().getString("warWidgetClans", null)
            ?: return emptyList()
        val array = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
        val seen = mutableSetOf<String>()
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val tag = WarWidgetSelectionStore.normalizeTag(item.optString("tag"))
                if (tag.isBlank() || !seen.add(tag)) continue
                add(
                    WidgetSelectionOption(
                        tag = tag,
                        title = item.optString("name", "Clan"),
                        detail = "#" + tag
                    )
                )
            }
        }
    }

    override fun saveSelectedTag(appWidgetId: Int, tag: String?) {
        WarWidgetSelectionStore.saveSelectedTag(this, appWidgetId, tag)
    }

    override fun widgetProviderClass(): Class<out AppWidgetProvider> =
        WarAppWidgetProvider::class.java

    private fun homeWidgetPreferences() =
        getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
}
