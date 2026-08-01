package com.clashking.clashkingapp

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONArray

class UpgradeWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val tagsByRadioId = mutableMapOf<Int, String?>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        setContentView(buildContent())
    }

    private fun buildContent(): ScrollView {
        val padding = dp(24)
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, dp(32), padding, padding)
        }
        container.addView(TextView(this).apply {
            setText(R.string.upgrade_widget_configure_title)
            textSize = 24f
            setTypeface(typeface, Typeface.BOLD)
        })
        container.addView(TextView(this).apply {
            setText(R.string.upgrade_widget_configure_description)
            textSize = 15f
            setPadding(0, dp(8), 0, dp(20))
        })

        val accounts = readAccounts()
        val radioGroup = RadioGroup(this).apply {
            orientation = RadioGroup.VERTICAL
        }
        val savedTag = UpgradeWidgetSelectionStore.selectedTag(this, appWidgetId)
        val globalTag = homeWidgetPreferences()
            .getString("upgradeWidgetSelectedTag", null)
            ?.let(UpgradeWidgetSelectionStore::normalizeTag)
        var defaultRadioId: Int? = null

        accounts.forEach { account ->
            val radio = RadioButton(this).apply {
                id = View.generateViewId()
                text = listOf(account.name, account.tag, account.hall)
                    .filter { it.isNotBlank() }
                    .joinToString("  ·  ")
                textSize = 16f
                setPadding(0, dp(8), 0, dp(8))
            }
            tagsByRadioId[radio.id] = account.tag
            radioGroup.addView(radio)
            if (account.tag == savedTag ||
                (savedTag == null && account.tag == globalTag) ||
                defaultRadioId == null
            ) {
                defaultRadioId = radio.id
            }
        }

        val automatic = RadioButton(this).apply {
            id = View.generateViewId()
            setText(R.string.upgrade_widget_configure_automatic)
            textSize = 16f
            setPadding(0, dp(8), 0, dp(8))
        }
        tagsByRadioId[automatic.id] = null
        radioGroup.addView(automatic, 0)
        if (accounts.isEmpty()) {
            defaultRadioId = automatic.id
            container.addView(TextView(this).apply {
                setText(R.string.upgrade_widget_configure_empty)
                textSize = 14f
                setPadding(0, 0, 0, dp(12))
            })
        }
        radioGroup.check(defaultRadioId ?: automatic.id)
        container.addView(radioGroup)

        container.addView(Button(this).apply {
            setText(R.string.upgrade_widget_configure_add)
            isAllCaps = false
            setOnClickListener {
                saveSelection(tagsByRadioId[radioGroup.checkedRadioButtonId])
            }
            val params = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            params.topMargin = dp(24)
            layoutParams = params
        })
        return ScrollView(this).apply { addView(container) }
    }

    private fun saveSelection(tag: String?) {
        UpgradeWidgetSelectionStore.saveSelectedTag(this, appWidgetId, tag)
        sendBroadcast(Intent(this, UpgradeAppWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        })
        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        )
        finish()
    }

    private data class Account(val tag: String, val name: String, val hall: String)

    private fun readAccounts(): List<Account> {
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
                    Account(
                        tag = tag,
                        name = item.optString("name", "Chief"),
                        hall = if (townHall > 0) "TH$townHall" else "BH$builderHall"
                    )
                )
            }
        }
    }

    private fun homeWidgetPreferences() =
        getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
