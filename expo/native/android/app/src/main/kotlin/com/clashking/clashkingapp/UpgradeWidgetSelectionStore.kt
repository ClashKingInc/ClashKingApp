package com.clashking.clashkingapp

import android.content.Context

internal object UpgradeWidgetSelectionStore {
    private const val PREFERENCES = "UpgradeWidgetPreferences"
    private const val SELECTED_TAG_PREFIX = "selectedTag_"

    fun selectedTag(context: Context, appWidgetId: Int): String? {
        return context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString("$SELECTED_TAG_PREFIX$appWidgetId", null)
            ?.takeIf { it.isNotBlank() }
    }

    fun saveSelectedTag(context: Context, appWidgetId: Int, tag: String?) {
        val editor = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
        val key = "$SELECTED_TAG_PREFIX$appWidgetId"
        if (tag.isNullOrBlank()) {
            editor.remove(key)
        } else {
            editor.putString(key, normalizeTag(tag))
        }
        editor.apply()
    }

    fun delete(context: Context, appWidgetIds: IntArray) {
        val editor = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
        appWidgetIds.forEach { editor.remove("$SELECTED_TAG_PREFIX$it") }
        editor.apply()
    }

    fun normalizeTag(tag: String): String {
        return tag.replace("#", "").trim().uppercase()
    }
}
