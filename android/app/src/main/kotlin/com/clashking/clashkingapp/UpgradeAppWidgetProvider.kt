package com.clashking.clashkingapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.time.Duration
import java.time.Instant
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class UpgradeAppWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
        val imageUpdates = mutableListOf<UpgradeWidgetImageUpdate>()
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
                ?.let(imageUpdates::add)
        }
        if (imageUpdates.isEmpty()) return

        val pendingResult = goAsync()
        Thread {
            try {
                imageUpdates.forEach { it.apply(context) }
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        UpgradeWidgetSelectionStore.delete(context, appWidgetIds)
        super.onDeleted(context, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    private data class UpgradeWidgetImageUpdate(
        val appWidgetManager: AppWidgetManager,
        val appWidgetId: Int,
        val views: RemoteViews,
        val targets: Map<Int, String>
    ) {
        fun apply(context: Context) {
            val urls = targets.values.distinct()
            val executor = Executors.newFixedThreadPool(urls.size.coerceIn(1, 4))
            try {
                val downloads = urls.associateWith { imageUrl ->
                    executor.submit<Bitmap?> {
                        loadUpgradeBitmap(context, imageUrl)
                    }
                }
                var changed = false
                for ((viewId, imageUrl) in targets) {
                    val bitmap = runCatching {
                        downloads.getValue(imageUrl).get(8, TimeUnit.SECONDS)
                    }.getOrNull() ?: continue
                    views.setImageViewBitmap(viewId, bitmap)
                    changed = true
                }
                if (changed) {
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            } finally {
                executor.shutdownNow()
            }
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ): UpgradeWidgetImageUpdate? {
        val isLarge = isLargeWidget(appWidgetManager, appWidgetId)
        val layoutId = if (isLarge) {
            R.layout.upgrade_widget_layout_large
        } else {
            R.layout.upgrade_widget_layout
        }
        val views = RemoteViews(context.packageName, layoutId)
        views.setOnClickPendingIntent(R.id.upgrade_root_layout, getUpgradePendingIntent(context))

        val data = readCurrentUpgradeData(context, appWidgetId, widgetData)
        if (data == null) {
            renderEmptyState(views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return null
        }

        val imageTargets = if (isLarge) {
            renderLargeUpgradeData(context, views, data)
        } else {
            renderUpgradeData(
                context,
                views,
                data,
                taskCapacity(appWidgetManager, appWidgetId)
            )
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
        return imageTargets.takeIf { it.isNotEmpty() }?.let {
            UpgradeWidgetImageUpdate(appWidgetManager, appWidgetId, views, it)
        }
    }

    private fun readCurrentUpgradeData(
        context: Context,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ): JSONObject? {
        val accounts = widgetData.getString("upgradeWidgetAccounts", null)
            ?.let { runCatching { JSONArray(it) }.getOrNull() }
            ?: JSONArray()
        val linkedTags = buildList {
            for (index in 0 until accounts.length()) {
                val tag = normalizedTag(accounts.optJSONObject(index)?.optString("tag", "") ?: "")
                if (tag.isNotEmpty() && tag !in this) add(tag)
            }
        }

        val instanceTag = UpgradeWidgetSelectionStore.selectedTag(context, appWidgetId)
        val globalTag = widgetData.getString("upgradeWidgetSelectedTag", null)
            ?.let(::normalizedTag)
        val candidateTags = listOfNotNull(instanceTag, globalTag, linkedTags.firstOrNull())
            .distinct()
        for (tag in candidateTags) {
            if (tag !in linkedTags) continue
            val raw = widgetData.getString("upgradeWidget_$tag", null) ?: continue
            val decoded = runCatching { JSONObject(raw) }.getOrNull() ?: continue
            if (normalizedTag(decoded.optString("tag", "")) == tag) {
                return decoded
            }
        }

        // Compatibility with payloads written before per-account storage existed.
        return widgetData.getString("upgradeWidgetData", null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
    }

    private fun renderEmptyState(views: RemoteViews) {
        views.setTextViewText(R.id.upgrade_account_name, "Upgrade Progress")
        views.setTextViewText(R.id.upgrade_account_tag, "")
        views.setViewVisibility(R.id.upgrade_empty_state, View.VISIBLE)
        views.setViewVisibility(R.id.upgrade_content, View.GONE)
        views.setImageViewResource(
            R.id.upgrade_hall_image,
            R.drawable.ic_upgrade_hall_placeholder
        )
    }

    private fun renderUpgradeData(
        context: Context,
        views: RemoteViews,
        data: JSONObject,
        taskCapacity: Int
    ): Map<Int, String> {
        val imageTargets = mutableMapOf<Int, String>()
        views.setViewVisibility(R.id.upgrade_empty_state, View.GONE)
        views.setViewVisibility(R.id.upgrade_content, View.VISIBLE)
        views.setImageViewResource(
            R.id.upgrade_hall_image,
            R.drawable.ic_upgrade_hall_placeholder
        )

        views.setTextViewText(R.id.upgrade_account_name, data.optString("name", "Upgrade Progress"))
        views.setTextViewText(R.id.upgrade_account_tag, data.optString("tag", ""))
        addImageTarget(
            imageTargets,
            R.id.upgrade_hall_image,
            data.optString("hallImageUrl", "")
        )

        val activeTasks = activeTasks(data)
        val featured = activeTasks.firstOrNull()
        if (featured != null) {
            views.setViewVisibility(R.id.upgrade_featured_card, View.VISIBLE)
            views.setViewVisibility(R.id.upgrade_compact_sections, View.GONE)
            views.setTextViewText(R.id.upgrade_featured_category, featured.category)
            views.setTextViewText(R.id.upgrade_active_count, "${activeTasks.size} ACTIVE")
            views.setTextViewText(
                R.id.upgrade_featured_name,
                featured.task.optString("name", "Upgrade")
            )
            views.setTextViewText(R.id.upgrade_featured_meta, taskMeta(featured.task))
            views.setImageViewResource(
                R.id.upgrade_featured_image,
                R.drawable.ic_upgrade_task_placeholder
            )
            addImageTarget(
                imageTargets,
                R.id.upgrade_featured_image,
                featured.task.optString("imageUrl", "")
            )
            renderAdditionalTasks(
                views,
                activeTasks,
                taskCapacity,
                imageTargets
            )
        } else {
            views.setViewVisibility(R.id.upgrade_featured_card, View.GONE)
            views.setViewVisibility(R.id.upgrade_compact_sections, View.VISIBLE)
            renderCompactSection(
                context,
                views,
                data.optJSONObject("homeBuilders"),
                R.id.upgrade_village_state,
                R.id.upgrade_village_status
            )
            renderCompactResearch(context, views, data)
        }

        val boosts = data.optJSONArray("boosts")
        val helpers = data.optJSONArray("helpers")
        val hasStatus = (boosts?.length() ?: 0) > 0 || (helpers?.length() ?: 0) > 0
        views.setViewVisibility(R.id.upgrade_status_row, if (hasStatus) View.VISIBLE else View.GONE)
        renderBoost(
            views,
            boosts?.optJSONObject(0),
            R.id.upgrade_boost_one_slot,
            R.id.upgrade_boost_one,
            R.id.upgrade_boost_one_image,
            imageTargets
        )
        renderBoost(
            views,
            boosts?.optJSONObject(1),
            R.id.upgrade_boost_two_slot,
            R.id.upgrade_boost_two,
            R.id.upgrade_boost_two_image,
            imageTargets
        )
        renderHelper(
            views,
            helpers?.optJSONObject(0),
            imageTargets
        )
        return imageTargets
    }

    private fun renderLargeUpgradeData(
        context: Context,
        views: RemoteViews,
        data: JSONObject
    ): Map<Int, String> {
        val imageTargets = mutableMapOf<Int, String>()
        views.setViewVisibility(R.id.upgrade_empty_state, View.GONE)
        views.setViewVisibility(R.id.upgrade_content, View.VISIBLE)
        views.setImageViewResource(
            R.id.upgrade_hall_image,
            R.drawable.ic_upgrade_hall_placeholder
        )
        views.setTextViewText(R.id.upgrade_account_name, data.optString("name", "Upgrade Progress"))
        views.setTextViewText(R.id.upgrade_account_tag, data.optString("tag", ""))
        addImageTarget(
            imageTargets,
            R.id.upgrade_hall_image,
            data.optString("hallImageUrl", "")
        )

        val boosts = data.optJSONArray("boosts")
        val hasBoosts = (boosts?.length() ?: 0) > 0
        views.setViewVisibility(
            R.id.upgrade_large_boosts,
            if (hasBoosts) View.VISIBLE else View.GONE
        )
        val boostSlots = listOf(
            StatusSlot(
                R.id.upgrade_large_boost_one_slot,
                R.id.upgrade_large_boost_one,
                R.id.upgrade_large_boost_one_image
            ),
            StatusSlot(
                R.id.upgrade_large_boost_two_slot,
                R.id.upgrade_large_boost_two,
                R.id.upgrade_large_boost_two_image
            ),
            StatusSlot(
                R.id.upgrade_large_boost_three_slot,
                R.id.upgrade_large_boost_three,
                R.id.upgrade_large_boost_three_image
            )
        )
        boostSlots.forEachIndexed { index, slot ->
            renderBoost(
                views,
                boosts?.optJSONObject(index),
                slot.containerId,
                slot.textId,
                slot.imageId,
                imageTargets
            )
        }

        val helpers = data.optJSONArray("helpers")
        val hasHelpers = (helpers?.length() ?: 0) > 0
        views.setViewVisibility(
            R.id.upgrade_large_helpers,
            if (hasHelpers) View.VISIBLE else View.GONE
        )
        val helperSlots = listOf(
            StatusSlot(
                R.id.upgrade_large_helper_one_slot,
                R.id.upgrade_large_helper_one,
                R.id.upgrade_large_helper_one_image
            ),
            StatusSlot(
                R.id.upgrade_large_helper_two_slot,
                R.id.upgrade_large_helper_two,
                R.id.upgrade_large_helper_two_image
            ),
            StatusSlot(
                R.id.upgrade_large_helper_three_slot,
                R.id.upgrade_large_helper_three,
                R.id.upgrade_large_helper_three_image
            )
        )
        helperSlots.forEachIndexed { index, slot ->
            renderLargeHelper(
                views,
                helpers?.optJSONObject(index),
                slot,
                imageTargets
            )
        }

        renderLargeSection(
            context,
            views,
            data.optJSONObject("homeBuilders"),
            R.id.upgrade_large_home_status,
            R.id.upgrade_large_home_empty,
            listOf(
                LargeTaskSlot(
                    R.id.upgrade_large_home_task_one,
                    R.id.upgrade_large_home_task_one_image,
                    R.id.upgrade_large_home_task_one_text
                ),
                LargeTaskSlot(
                    R.id.upgrade_large_home_task_two,
                    R.id.upgrade_large_home_task_two_image,
                    R.id.upgrade_large_home_task_two_text
                ),
                LargeTaskSlot(
                    R.id.upgrade_large_home_task_three,
                    R.id.upgrade_large_home_task_three_image,
                    R.id.upgrade_large_home_task_three_text
                )
            ),
            imageTargets
        )
        renderLargeSection(
            context,
            views,
            data.optJSONObject("laboratory"),
            R.id.upgrade_large_lab_status,
            R.id.upgrade_large_lab_empty,
            listOf(
                LargeTaskSlot(
                    R.id.upgrade_large_lab_task_one,
                    R.id.upgrade_large_lab_task_one_image,
                    R.id.upgrade_large_lab_task_one_text
                ),
                LargeTaskSlot(
                    R.id.upgrade_large_lab_task_two,
                    R.id.upgrade_large_lab_task_two_image,
                    R.id.upgrade_large_lab_task_two_text
                )
            ),
            imageTargets
        )
        renderLargeSection(
            context,
            views,
            data.optJSONObject("pets"),
            R.id.upgrade_large_pets_status,
            R.id.upgrade_large_pets_empty,
            listOf(
                LargeTaskSlot(
                    R.id.upgrade_large_pets_task_one,
                    R.id.upgrade_large_pets_task_one_image,
                    R.id.upgrade_large_pets_task_one_text
                )
            ),
            imageTargets
        )
        renderLargeSection(
            context,
            views,
            data.optJSONObject("builderBase"),
            R.id.upgrade_large_builder_status,
            R.id.upgrade_large_builder_empty,
            listOf(
                LargeTaskSlot(
                    R.id.upgrade_large_builder_task_one,
                    R.id.upgrade_large_builder_task_one_image,
                    R.id.upgrade_large_builder_task_one_text
                ),
                LargeTaskSlot(
                    R.id.upgrade_large_builder_task_two,
                    R.id.upgrade_large_builder_task_two_image,
                    R.id.upgrade_large_builder_task_two_text
                )
            ),
            imageTargets
        )
        return imageTargets
    }

    private data class StatusSlot(
        val containerId: Int,
        val textId: Int,
        val imageId: Int
    )

    private data class LargeTaskSlot(
        val containerId: Int,
        val imageId: Int,
        val textId: Int
    )

    private fun renderLargeHelper(
        views: RemoteViews,
        helper: JSONObject?,
        slot: StatusSlot,
        imageTargets: MutableMap<Int, String>
    ) {
        if (helper == null) {
            views.setViewVisibility(slot.containerId, View.GONE)
            return
        }
        val until = durationUntil(helper.optString("statusUntil", ""))
        val status = listOf(helper.optString("status", ""), until)
            .filter { it.isNotBlank() }
            .joinToString(" ")
        val text = listOf(shortHelperName(helper.optString("name", "Helper")), status)
            .filter { it.isNotBlank() }
            .joinToString("\n")
        views.setViewVisibility(slot.containerId, View.VISIBLE)
        views.setImageViewResource(slot.imageId, R.drawable.ic_upgrade_status)
        views.setTextViewText(slot.textId, text)
        addImageTarget(
            imageTargets,
            slot.imageId,
            helper.optString("imageUrl", "")
        )
    }

    private fun renderLargeSection(
        context: Context,
        views: RemoteViews,
        section: JSONObject?,
        statusViewId: Int,
        emptyViewId: Int,
        slots: List<LargeTaskSlot>,
        imageTargets: MutableMap<Int, String>
    ) {
        val status = sectionStatus(section)
        views.setTextViewText(statusViewId, status)
        views.setTextColor(statusViewId, context.getColor(statusColor(status)))
        val tasks = section?.optJSONArray("tasks")
        val taskCount = tasks?.length() ?: 0
        views.setViewVisibility(
            emptyViewId,
            if (taskCount == 0) View.VISIBLE else View.GONE
        )
        views.setTextViewText(emptyViewId, emptySectionLabel(section))
        slots.forEachIndexed { index, slot ->
            val task = tasks?.optJSONObject(index)
            views.setViewVisibility(
                slot.containerId,
                if (task == null) View.GONE else View.VISIBLE
            )
            if (task == null) return@forEachIndexed
            views.setImageViewResource(slot.imageId, R.drawable.ic_upgrade_task_placeholder)
            views.setTextViewText(
                slot.textId,
                "${task.optString("name", "Upgrade")}\n${taskMeta(task)}"
            )
            addImageTarget(
                imageTargets,
                slot.imageId,
                task.optString("imageUrl", "")
            )
        }
    }

    private data class CategorizedTask(val category: String, val task: JSONObject)

    private fun activeTasks(data: JSONObject): List<CategorizedTask> {
        val sections = listOf(
            "HOME VILLAGE" to data.optJSONObject("homeBuilders"),
            "LAB" to data.optJSONObject("laboratory"),
            "PETS" to data.optJSONObject("pets"),
            "BUILDER BASE" to data.optJSONObject("builderBase")
        )
        return buildList {
            for ((title, section) in sections) {
                val tasks = section?.optJSONArray("tasks") ?: continue
                for (index in 0 until tasks.length()) {
                    tasks.optJSONObject(index)?.let { add(CategorizedTask(title, it)) }
                }
            }
        }
    }

    private data class TaskSlot(
        val containerId: Int,
        val imageId: Int,
        val nameId: Int,
        val metaId: Int
    )

    private fun renderAdditionalTasks(
        views: RemoteViews,
        activeTasks: List<CategorizedTask>,
        taskCapacity: Int,
        imageTargets: MutableMap<Int, String>
    ) {
        val slots = listOf(
            TaskSlot(
                R.id.upgrade_task_two,
                R.id.upgrade_task_two_image,
                R.id.upgrade_task_two_name,
                R.id.upgrade_task_two_meta
            ),
            TaskSlot(
                R.id.upgrade_task_three,
                R.id.upgrade_task_three_image,
                R.id.upgrade_task_three_name,
                R.id.upgrade_task_three_meta
            ),
            TaskSlot(
                R.id.upgrade_task_four,
                R.id.upgrade_task_four_image,
                R.id.upgrade_task_four_name,
                R.id.upgrade_task_four_meta
            )
        )
        slots.forEachIndexed { index, slot ->
            val task = activeTasks.getOrNull(index + 1)
                ?.takeIf { index + 1 < taskCapacity }
            views.setViewVisibility(
                slot.containerId,
                if (task == null) View.GONE else View.VISIBLE
            )
            if (task == null) return@forEachIndexed
            views.setImageViewResource(slot.imageId, R.drawable.ic_upgrade_task_placeholder)
            views.setTextViewText(slot.nameId, task.task.optString("name", "Upgrade"))
            views.setTextViewText(
                slot.metaId,
                "${task.category} · ${taskMeta(task.task)}"
            )
            addImageTarget(
                imageTargets,
                slot.imageId,
                task.task.optString("imageUrl", "")
            )
        }

        val hiddenCount = (activeTasks.size - taskCapacity).coerceAtLeast(0)
        views.setViewVisibility(
            R.id.upgrade_more_count,
            if (hiddenCount > 0) View.VISIBLE else View.GONE
        )
        views.setTextViewText(
            R.id.upgrade_more_count,
            if (hiddenCount == 1) "+1 more upgrade" else "+$hiddenCount more upgrades"
        )
    }

    private fun taskCapacity(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Int {
        val minHeight = appWidgetManager.getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            minHeight >= 250 -> 4
            minHeight >= 180 -> 3
            minHeight >= 145 -> 2
            else -> 1
        }
    }

    private fun isLargeWidget(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Boolean {
        val minHeight = appWidgetManager.getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return minHeight >= 250
    }

    private fun renderCompactSection(
        context: Context,
        views: RemoteViews,
        section: JSONObject?,
        stateViewId: Int,
        statusViewId: Int
    ) {
        val status = sectionStatus(section)
        views.setTextViewText(stateViewId, emptySectionLabel(section))
        views.setTextViewText(statusViewId, status)
        views.setTextColor(statusViewId, context.getColor(statusColor(status)))
    }

    private fun renderCompactResearch(context: Context, views: RemoteViews, data: JSONObject) {
        val sections = listOf(
            data.optJSONObject("laboratory"),
            data.optJSONObject("pets"),
            data.optJSONObject("builderBase")
        )
        val available = sections.filterNotNull().filter { it.optBoolean("available", true) }
        val remaining = available.sumOf { it.optInt("remainingCount", 0) }
        val state = when {
            available.isEmpty() -> "Not unlocked"
            remaining == 0 -> "Fully upgraded"
            else -> "No active research"
        }
        val status = when {
            available.isEmpty() -> "LOCKED"
            remaining == 0 -> "MAXED"
            else -> "IDLE"
        }
        views.setTextViewText(R.id.upgrade_research_state, state)
        views.setTextViewText(R.id.upgrade_research_status, status)
        views.setTextColor(
            R.id.upgrade_research_status,
            context.getColor(statusColor(status))
        )
    }

    private fun renderBoost(
        views: RemoteViews,
        boost: JSONObject?,
        slotViewId: Int,
        textViewId: Int,
        imageViewId: Int,
        imageTargets: MutableMap<Int, String>
    ) {
        if (boost == null) {
            views.setViewVisibility(slotViewId, View.GONE)
            return
        }
        views.setViewVisibility(slotViewId, View.VISIBLE)
        views.setImageViewResource(imageViewId, R.drawable.ic_upgrade_status)
        views.setTextViewText(textViewId, boostText(boost))
        addImageTarget(imageTargets, imageViewId, boost.optString("imageUrl", ""))
    }

    private fun boostText(boost: JSONObject?): String {
        if (boost == null) return ""
        val duration = durationUntil(boost.optString("expiresAt", ""))
        return listOf(shortBoostName(boost.optString("label", "Boost")), duration)
            .filter { it.isNotBlank() }
            .joinToString("\n")
    }

    private fun renderHelper(
        views: RemoteViews,
        helper: JSONObject?,
        imageTargets: MutableMap<Int, String>
    ) {
        if (helper == null) {
            views.setViewVisibility(R.id.upgrade_helper_slot, View.GONE)
            return
        }
        val until = durationUntil(helper.optString("statusUntil", ""))
        val status = listOf(helper.optString("status", ""), until)
            .filter { it.isNotBlank() }
            .joinToString(" ")
        val text = listOf(shortHelperName(helper.optString("name", "Helper")), status)
            .filter { it.isNotBlank() }
            .joinToString("\n")
        views.setViewVisibility(R.id.upgrade_helper_slot, View.VISIBLE)
        views.setImageViewResource(R.id.upgrade_helper_image, R.drawable.ic_upgrade_status)
        views.setTextViewText(R.id.upgrade_helper_one, text)
        addImageTarget(
            imageTargets,
            R.id.upgrade_helper_image,
            helper.optString("imageUrl", "")
        )
    }

    private fun taskMeta(task: JSONObject): String {
        val fromLevel = task.optInt("fromLevel", 0)
        val toLevel = task.optInt("toLevel", 0)
        val duration = durationUntil(task.optString("finishesAt", ""))
        return "Lv $fromLevel → $toLevel  ·  $duration"
    }

    private fun sectionStatus(section: JSONObject?): String {
        if (section == null || !section.optBoolean("available", true)) return "LOCKED"
        val tasks = section.optJSONArray("tasks")?.length() ?: 0
        if (tasks == 0 && section.optInt("remainingCount", 0) == 0) return "MAXED"
        val idle = (section.optInt("capacity", 0) - tasks).coerceAtLeast(0)
        return when {
            idle > 0 -> "$idle IDLE"
            tasks > 0 -> "$tasks ACTIVE"
            else -> ""
        }
    }

    private fun statusColor(status: String): Int {
        return when {
            status == "MAXED" -> R.color.widget_status_maxed
            "IDLE" in status || "ACTIVE" in status -> R.color.widget_status_idle
            else -> R.color.widget_text_secondary
        }
    }

    private fun emptySectionLabel(section: JSONObject?): String {
        if (section == null) return "No active upgrades"
        if (!section.optBoolean("available", true)) return "Not unlocked"
        return if (section.optInt("remainingCount", 0) == 0) {
            "Fully upgraded"
        } else {
            "No active upgrades"
        }
    }

    private fun shortBoostName(name: String): String {
        val lower = name.lowercase()
        return when {
            "builder" in lower -> "Builder"
            "research" in lower || "lab" in lower -> "Research"
            "pet" in lower -> "Pet"
            "clock" in lower -> "Clock"
            else -> name
        }
    }

    private fun shortHelperName(name: String): String {
        val lower = name.lowercase()
        return when {
            "apprentice" in lower -> "Apprentice"
            "assistant" in lower -> "Assistant"
            "alchemist" in lower -> "Alchemist"
            else -> name
        }
    }

    private fun addImageTarget(
        targets: MutableMap<Int, String>,
        viewId: Int,
        imageUrl: String
    ) {
        if (imageUrl.startsWith("https://")) {
            targets[viewId] = imageUrl
        }
    }

    private fun durationUntil(value: String): String {
        if (value.isBlank()) return ""
        val end = runCatching { Instant.parse(value) }.getOrNull() ?: return ""
        val seconds = Duration.between(Instant.now(), end).seconds.coerceAtLeast(0)
        val days = seconds / 86_400
        val hours = (seconds % 86_400) / 3_600
        val minutes = (seconds % 3_600) / 60
        return when {
            days > 0 -> "${days}d ${hours}h"
            hours > 0 -> "${hours}h ${minutes}m"
            else -> "${minutes}m"
        }
    }

    private fun normalizedTag(tag: String): String {
        return tag.replace("#", "").trim().uppercase()
    }
}

private fun getUpgradePendingIntent(context: Context): PendingIntent {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
}

private fun loadUpgradeBitmap(context: Context, url: String): Bitmap? {
    val cacheDirectory = File(context.cacheDir, "upgrade_widget_images")
    val cachedFile = File(cacheDirectory, "${url.hashCode()}.image")
    if (cachedFile.isFile) {
        BitmapFactory.decodeFile(cachedFile.path)?.let {
            return fitUpgradeWidgetBitmap(it)
        }
        cachedFile.delete()
    }

    var connection: HttpURLConnection? = null
    return try {
        connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 4_000
        connection.readTimeout = 4_000
        connection.instanceFollowRedirects = true
        connection.doInput = true
        connection.connect()
        if (connection.responseCode !in 200..299) return null
        val bytes = connection.inputStream.use { it.readBytes() }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        runCatching {
            cacheDirectory.mkdirs()
            cachedFile.writeBytes(bytes)
        }
        fitUpgradeWidgetBitmap(bitmap)
    } catch (_: Exception) {
        null
    } finally {
        connection?.disconnect()
    }
}

private fun fitUpgradeWidgetBitmap(bitmap: Bitmap): Bitmap {
    val maxDimension = 128
    val largestSide = maxOf(bitmap.width, bitmap.height)
    if (largestSide <= maxDimension) return bitmap
    val scale = maxDimension.toFloat() / largestSide
    val width = (bitmap.width * scale).toInt().coerceAtLeast(1)
    val height = (bitmap.height * scale).toInt().coerceAtLeast(1)
    return Bitmap.createScaledBitmap(bitmap, width, height, true).also {
        if (it !== bitmap) bitmap.recycle()
    }
}
