package com.clashking.clashkingapp

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
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
        val padding = dp(20)
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, dp(24), padding, padding)
            setBackgroundColor(getColor(R.color.widget_background))
        }
        container.addView(TextView(this).apply {
            setText(R.string.upgrade_widget_configure_eyebrow)
            textSize = 11f
            setTextColor(getColor(R.color.widget_accent))
            setTypeface(typeface, Typeface.BOLD)
        }
        )
        container.addView(TextView(this).apply {
            setText(R.string.upgrade_widget_configure_title)
            textSize = 22f
            setTextColor(getColor(R.color.widget_text))
            setTypeface(typeface, Typeface.BOLD)
            setPadding(0, dp(4), 0, 0)
        })
        container.addView(TextView(this).apply {
            setText(R.string.upgrade_widget_configure_description)
            textSize = 14f
            setTextColor(getColor(R.color.widget_text_secondary))
            setPadding(0, dp(6), 0, dp(22))
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
            val radio = accountOption(
                "${account.name}\n#${account.tag}  ·  ${account.hall}"
            )
            tagsByRadioId[radio.id] = account.tag
            radioGroup.addView(radio)
            if (account.tag == savedTag ||
                (savedTag == null && account.tag == globalTag) ||
                defaultRadioId == null
            ) {
                defaultRadioId = radio.id
            }
        }

        val automatic = accountOption(
            getString(R.string.upgrade_widget_configure_automatic)
        )
        tagsByRadioId[automatic.id] = null
        radioGroup.addView(automatic, 0)
        if (accounts.isEmpty()) {
            defaultRadioId = automatic.id
            container.addView(TextView(this).apply {
                setText(R.string.upgrade_widget_configure_empty)
                textSize = 14f
                setTextColor(getColor(R.color.widget_text_secondary))
                setPadding(0, 0, 0, dp(12))
            })
        }
        radioGroup.check(defaultRadioId ?: automatic.id)
        container.addView(radioGroup)

        container.addView(Button(this).apply {
            setText(R.string.upgrade_widget_configure_add)
            isAllCaps = false
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(getColor(android.R.color.white))
            setBackgroundResource(R.drawable.upgrade_widget_config_button)
            stateListAnimator = null
            minHeight = dp(52)
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

    private fun accountOption(label: String): RadioButton {
        val accent = getColor(R.color.widget_accent)
        val secondary = getColor(R.color.widget_text_secondary)
        return RadioButton(this).apply {
            id = View.generateViewId()
            text = label
            textSize = 15f
            setTextColor(getColor(R.color.widget_text))
            setLineSpacing(dp(2).toFloat(), 1f)
            setPadding(dp(14), dp(11), dp(14), dp(11))
            setBackgroundResource(R.drawable.upgrade_widget_config_option)
            buttonTintList = ColorStateList(
                arrayOf(
                    intArrayOf(android.R.attr.state_checked),
                    intArrayOf()
                ),
                intArrayOf(accent, secondary)
            )
            layoutParams = RadioGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(10)
            }
        }
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
