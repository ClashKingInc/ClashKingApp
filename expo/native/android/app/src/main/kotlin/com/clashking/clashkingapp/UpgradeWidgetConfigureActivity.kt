package com.clashking.clashkingapp

import android.appwidget.AppWidgetProvider
import android.content.Context
import org.json.JSONArray

class UpgradeWidgetConfigureActivity : WidgetConfigureActivity() {
    override val eyebrowText = R.string.upgrade_widget_configure_eyebrow
    override val titleText = R.string.upgrade_widget_configure_title
    override val descriptionText = R.string.upgrade_widget_configure_description
    override val emptyText = R.string.upgrade_widget_configure_empty
    override val automaticText = R.string.upgrade_widget_configure_automatic
    override val actionText = R.string.upgrade_widget_configure_add

    override fun selectedTag(appWidgetId: Int): String? =
        UpgradeWidgetSelectionStore.selectedTag(this, appWidgetId)

    override fun readOptions(): List<WidgetSelectionOption> {
        val raw = homeWidgetPreferences().getString("upgradeWidgetAccounts", null)
            ?: return emptyList()
        val array = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
        val seen = mutableSetOf<String>()
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val tag = UpgradeWidgetSelectionStore.normalizeTag(item.optString("tag"))
                if (tag.isBlank() || !seen.add(tag)) continue
                val townHall = item.optInt("townHallLevel", 0)
                val builderHall = item.optInt("builderHallLevel", 0)
                add(
                    WidgetSelectionOption(
                        tag = tag,
                        title = item.optString("name", "Chief"),
                        detail = "#" + tag + "  ·  " +
                            if (townHall > 0) "TH$townHall" else "BH$builderHall"
                    )
                )
            }
        }
    }

    override fun saveSelectedTag(appWidgetId: Int, tag: String?) {
        UpgradeWidgetSelectionStore.saveSelectedTag(this, appWidgetId, tag)
    }

    override fun widgetProviderClass(): Class<out AppWidgetProvider> =
        UpgradeAppWidgetProvider::class.java

    private fun homeWidgetPreferences() =
        getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
}
