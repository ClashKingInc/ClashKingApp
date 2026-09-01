package com.clashking.clashkingapp

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
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
import android.widget.Switch
import android.widget.TextView
import androidx.annotation.StringRes

data class WidgetSelectionOption(
    val tag: String,
    val title: String,
    val detail: String
)

abstract class WidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val tagsByRadioId = mutableMapOf<Int, String?>()

    @get:StringRes protected abstract val eyebrowText: Int
    @get:StringRes protected abstract val titleText: Int
    @get:StringRes protected abstract val descriptionText: Int
    @get:StringRes protected abstract val emptyText: Int
    @get:StringRes protected abstract val automaticText: Int
    @get:StringRes protected abstract val actionText: Int
    @get:StringRes protected open val builderBaseOptionText: Int? = null

    protected abstract fun selectedTag(appWidgetId: Int): String?
    protected abstract fun readOptions(): List<WidgetSelectionOption>
    protected abstract fun saveSelectedTag(appWidgetId: Int, tag: String?)
    protected abstract fun widgetProviderClass(): Class<out AppWidgetProvider>
    protected open fun builderBaseEnabled(appWidgetId: Int): Boolean = true
    protected open fun saveBuilderBaseEnabled(appWidgetId: Int, enabled: Boolean) = Unit

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
            setPadding(padding, dp(22), padding, dp(28))
            setBackgroundColor(getColor(R.color.widget_background))
        }
        container.addView(TextView(this).apply {
            setText(eyebrowText)
            textSize = 10f
            setTextColor(getColor(R.color.widget_accent))
            setTypeface(typeface, Typeface.BOLD)
            letterSpacing = 0.08f
        })
        container.addView(TextView(this).apply {
            setText(titleText)
            textSize = 24f
            setTextColor(getColor(R.color.widget_text))
            setTypeface(typeface, Typeface.BOLD)
            includeFontPadding = false
            setPadding(0, dp(8), 0, 0)
        })
        container.addView(TextView(this).apply {
            setText(descriptionText)
            textSize = 14f
            setTextColor(getColor(R.color.widget_text_secondary))
            setLineSpacing(dp(2).toFloat(), 1f)
            setPadding(0, dp(10), 0, dp(24))
        })

        val options = readOptions()
        val radioGroup = RadioGroup(this).apply {
            orientation = RadioGroup.VERTICAL
        }
        val savedTag = selectedTag(appWidgetId)
        var defaultRadioId: Int? = null

        options.forEach { option ->
            val radio = selectionOption(option.title + "\n" + option.detail)
            tagsByRadioId[radio.id] = option.tag
            radioGroup.addView(radio)
            if (savedTag != null && option.tag == savedTag) {
                defaultRadioId = radio.id
            }
        }

        val automatic = selectionOption(getString(automaticText))
        tagsByRadioId[automatic.id] = null
        radioGroup.addView(automatic, 0)
        if (savedTag == null) {
            defaultRadioId = automatic.id
        }
        if (options.isEmpty()) {
            defaultRadioId = automatic.id
            container.addView(TextView(this).apply {
                setText(emptyText)
                textSize = 14f
                setTextColor(getColor(R.color.widget_text_secondary))
                setPadding(0, 0, 0, dp(12))
            })
        }
        radioGroup.check(defaultRadioId ?: automatic.id)
        container.addView(radioGroup)

        val builderBaseSwitch = builderBaseOptionText?.let { textResource ->
            Switch(this).apply {
                setText(textResource)
                textSize = 15f
                setTextColor(getColor(R.color.widget_text))
                isChecked = builderBaseEnabled(appWidgetId)
                buttonTintList = null
                thumbTintList = ColorStateList.valueOf(getColor(R.color.widget_text))
                trackTintList = ColorStateList(
                    arrayOf(
                        intArrayOf(android.R.attr.state_checked),
                        intArrayOf()
                    ),
                    intArrayOf(
                        getColor(R.color.widget_accent),
                        getColor(R.color.widget_text_secondary)
                    )
                )
                setPadding(dp(14), dp(10), dp(14), dp(10))
                setBackgroundResource(R.drawable.upgrade_widget_config_option)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(10) }
            }.also(container::addView)
        }

        container.addView(Button(this).apply {
            setText(actionText)
            isAllCaps = false
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(getColor(android.R.color.white))
            setBackgroundResource(R.drawable.upgrade_widget_config_button)
            stateListAnimator = null
            minHeight = 0
            minWidth = 0
            setPadding(dp(16), 0, dp(16), 0)
            setOnClickListener {
                saveSelection(
                    tagsByRadioId[radioGroup.checkedRadioButtonId],
                    builderBaseSwitch?.isChecked ?: true
                )
            }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(50)
            ).apply {
                topMargin = dp(18)
            }
        })
        return ScrollView(this).apply {
            setBackgroundColor(getColor(R.color.widget_background))
            isFillViewport = true
            addView(
                container,
                ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
            )
        }
    }

    private fun selectionOption(label: String): RadioButton {
        val accent = getColor(R.color.widget_accent)
        val secondary = getColor(R.color.widget_text_secondary)
        return RadioButton(this).apply {
            id = View.generateViewId()
            text = label
            textSize = 15f
            setTextColor(getColor(R.color.widget_text))
            setLineSpacing(dp(1).toFloat(), 1f)
            setPadding(dp(14), dp(10), dp(14), dp(10))
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
                bottomMargin = dp(8)
            }
        }
    }

    private fun saveSelection(tag: String?, showBuilderBase: Boolean) {
        saveSelectedTag(appWidgetId, tag)
        saveBuilderBaseEnabled(appWidgetId, showBuilderBase)
        sendBroadcast(Intent(this, widgetProviderClass()).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        })
        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        )
        finish()
    }

    protected fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
