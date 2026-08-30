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
        val expectedLayoutId: Int,
        val expectedTaskCapacity: Int,
        val expectedTag: String,
        val expectedUpdatedAt: String,
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
                if (changed && isStillCurrent(context)) {
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            } finally {
                executor.shutdownNow()
            }
        }

        private fun isStillCurrent(context: Context): Boolean {
            val widgetData = context.getSharedPreferences(HOME_WIDGET_PREFERENCES, Context.MODE_PRIVATE)
            if (currentLayoutId() != expectedLayoutId) return false
            if (expectedLayoutId == R.layout.upgrade_widget_layout &&
                currentTaskCapacity() != expectedTaskCapacity
            ) {
                return false
            }

            val expectedNormalizedTag = normalizedTagValue(expectedTag)
            val currentTag = UpgradeWidgetSelectionStore.selectedTag(context, appWidgetId)
                ?: widgetData.getString("upgradeWidgetSelectedTag", null)?.let(::normalizedTagValue)
                ?: firstLinkedTag(widgetData)
            if (currentTag != expectedNormalizedTag) return false

            val raw = widgetData.getString("upgradeWidget_$expectedNormalizedTag", null)
                ?: widgetData.getString("upgradeWidgetData", null)
                ?: return false
            val decoded = runCatching { JSONObject(raw) }.getOrNull() ?: return false
            return normalizedTagValue(decoded.optString("tag", "")) == expectedNormalizedTag &&
                decoded.optString("updatedAt", "") == expectedUpdatedAt
        }

        private fun currentLayoutId(): Int {
            return if (currentMinHeight() >= 190) {
                R.layout.upgrade_widget_layout_large
            } else {
                R.layout.upgrade_widget_layout
            }
        }

        private fun currentTaskCapacity(): Int {
            val minHeight = currentMinHeight()
            return when {
                minHeight >= 250 -> 4
                minHeight >= 180 -> 2
                else -> 1
            }
        }

        private fun currentMinHeight(): Int {
            return appWidgetManager.getAppWidgetOptions(appWidgetId)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        }

        private fun firstLinkedTag(widgetData: SharedPreferences): String? {
            val accounts = widgetData.getString("upgradeWidgetAccounts", null)
                ?.let { runCatching { JSONArray(it) }.getOrNull() }
                ?: return null
            for (index in 0 until accounts.length()) {
                val tag = normalizedTagValue(accounts.optJSONObject(index)?.optString("tag", "") ?: "")
                if (tag.isNotEmpty()) return tag
            }
            return null
        }

        private fun normalizedTagValue(tag: String): String =
            tag.replace("#", "").trim().uppercase()
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
        val compactTaskCapacity = if (isLarge) 0 else taskCapacity(appWidgetManager, appWidgetId)
        val views = RemoteViews(context.packageName, layoutId)
        views.setOnClickPendingIntent(R.id.upgrade_root_layout, getUpgradePendingIntent(context))

        val data = readCurrentUpgradeData(context, appWidgetId, widgetData)
        if (data == null) {
            renderEmptyState(context, views)
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
                compactTaskCapacity
            )
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
        return imageTargets.takeIf { it.isNotEmpty() }?.let {
            UpgradeWidgetImageUpdate(
                appWidgetManager,
                appWidgetId,
                views,
                layoutId,
                compactTaskCapacity,
                data.optString("tag", ""),
                data.optString("updatedAt", ""),
                it
            )
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
        val candidateTags = if (instanceTag != null) {
            listOf(instanceTag)
        } else if (!globalTag.isNullOrEmpty()) {
            listOf(globalTag)
        } else {
            listOfNotNull(linkedTags.firstOrNull())
        }
        for (tag in candidateTags) {
            if (tag !in linkedTags) continue
            val raw = widgetData.getString("upgradeWidget_$tag", null) ?: continue
            val decoded = runCatching { JSONObject(raw) }.getOrNull() ?: continue
            if (normalizedTag(decoded.optString("tag", "")) == tag) {
                return decoded
            }
        }

        // Compatibility with payloads written before per-account storage existed.
        if (linkedTags.isNotEmpty()) return null
        return legacyUpgradeData(widgetData, instanceTag ?: globalTag)
    }

    private fun legacyUpgradeData(
        widgetData: SharedPreferences,
        requestedTag: String?
    ): JSONObject? {
        val decoded = widgetData.getString("upgradeWidgetData", null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?: return null
        val decodedTag = normalizedTag(decoded.optString("tag", ""))
        return if (requestedTag == null || decodedTag == requestedTag) decoded else null
    }

    private fun renderEmptyState(context: Context, views: RemoteViews) {
        views.setTextViewText(R.id.upgrade_account_name, context.getString(R.string.upgrade_widget_label))
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
        val labels = labels(data)
        views.setViewVisibility(R.id.upgrade_empty_state, View.GONE)
        views.setViewVisibility(R.id.upgrade_content, View.VISIBLE)
        renderStaleChip(views, data, labels)
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
            views.setTextViewText(
                R.id.upgrade_active_count,
                activeStatus(labels, totalActiveCount(data))
            )
            views.setTextViewText(
                R.id.upgrade_featured_name,
                taskName(featured.task)
            )
            views.setTextViewText(R.id.upgrade_featured_meta, taskMeta(featured.task, labels))
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
                labels,
                imageTargets
            )
        } else {
            views.setViewVisibility(R.id.upgrade_featured_card, View.GONE)
            views.setViewVisibility(R.id.upgrade_compact_sections, View.VISIBLE)
            views.setTextViewText(R.id.upgrade_village_title, label(labels, "village", "VILLAGE"))
            views.setTextViewText(R.id.upgrade_research_title, label(labels, "research", "RESEARCH"))
            renderCompactSection(
                context,
                views,
                data.optJSONObject("homeBuilders"),
                labels,
                R.id.upgrade_village_state,
                R.id.upgrade_village_status
            )
            renderCompactResearch(context, views, data, labels)
        }

        val boosts = activeBoosts(data.optJSONArray("boosts"))
        val helpers = data.optJSONArray("helpers")
        val hasStatus = boosts.isNotEmpty() || (helpers?.length() ?: 0) > 0
        views.setViewVisibility(R.id.upgrade_status_row, if (hasStatus) View.VISIBLE else View.GONE)
        renderBoost(
            views,
            boosts.getOrNull(0),
            R.id.upgrade_boost_one_slot,
            R.id.upgrade_boost_one,
            R.id.upgrade_boost_one_image,
            imageTargets
        )
        renderBoost(
            views,
            boosts.getOrNull(1),
            R.id.upgrade_boost_two_slot,
            R.id.upgrade_boost_two,
            R.id.upgrade_boost_two_image,
            imageTargets
        )
        renderHelper(
            views,
            helpers?.optJSONObject(0),
            labels,
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
        val labels = labels(data)
        views.setViewVisibility(R.id.upgrade_empty_state, View.GONE)
        views.setViewVisibility(R.id.upgrade_content, View.VISIBLE)
        renderStaleChip(views, data, labels)
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

        val boosts = activeBoosts(data.optJSONArray("boosts"))
        val hasBoosts = boosts.isNotEmpty()
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
                boosts.getOrNull(index),
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
                labels,
                slot,
                imageTargets
            )
        }

        views.setTextViewText(R.id.upgrade_large_home_title, label(labels, "homeVillage", "HOME VILLAGE"))
        views.setTextViewText(R.id.upgrade_large_lab_title, label(labels, "laboratory", "LAB"))
        views.setTextViewText(R.id.upgrade_large_pets_title, label(labels, "pets", "PETS"))
        views.setTextViewText(R.id.upgrade_large_builder_title, label(labels, "builderBase", "BUILDER BASE"))

        renderLargeSection(
            context,
            views,
            data.optJSONObject("homeBuilders"),
            labels,
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
            labels,
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
            labels,
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
            labels,
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
        labels: JSONObject?,
        slot: StatusSlot,
        imageTargets: MutableMap<Int, String>
    ) {
        if (helper == null) {
            views.setViewVisibility(slot.containerId, View.GONE)
            return
        }
        val status = helperStatus(helper, labels)
        val text = listOf(shortHelperName(helper.optString("name", "Helper")), status)
            .filter { it.isNotBlank() }
            .joinToString("\n")
        val imageUrl = helper.optString("imageUrl", "")
        views.setViewVisibility(slot.containerId, View.VISIBLE)
        views.setTextViewText(slot.textId, text)
        if (imageUrl.startsWith("https://")) {
            views.setViewVisibility(slot.imageId, View.VISIBLE)
            views.setImageViewResource(slot.imageId, R.drawable.ic_upgrade_status)
            addImageTarget(imageTargets, slot.imageId, imageUrl)
        } else {
            views.setViewVisibility(slot.imageId, View.GONE)
        }
    }

    private fun renderStaleChip(
        views: RemoteViews,
        data: JSONObject,
        labels: JSONObject?
    ) {
        val isStale = data.optBoolean("hasStaleData", false) || hasFinishedTask(data)
        views.setViewVisibility(R.id.upgrade_stale_chip, if (isStale) View.VISIBLE else View.GONE)
        views.setTextViewText(
            R.id.upgrade_stale_chip,
            label(labels, "staleData", "Update needed")
        )
    }

    private fun renderLargeSection(
        context: Context,
        views: RemoteViews,
        section: JSONObject?,
        labels: JSONObject?,
        statusViewId: Int,
        emptyViewId: Int,
        slots: List<LargeTaskSlot>,
        imageTargets: MutableMap<Int, String>
    ) {
        val status = sectionStatus(section, labels)
        views.setTextViewText(statusViewId, status)
        views.setTextColor(statusViewId, context.getColor(statusColor(status)))
        val tasks = section?.optJSONArray("tasks")
        val taskCount = taskArrayDisplayCount(tasks)
        views.setViewVisibility(
            emptyViewId,
            if (taskCount == 0) View.VISIBLE else View.GONE
        )
        views.setTextViewText(emptyViewId, emptySectionLabel(section, labels))
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
                "${taskName(task)}\n${taskMeta(task, labels)}"
            )
            addImageTarget(
                imageTargets,
                slot.imageId,
                task.optString("imageUrl", "")
            )
        }
    }

    private data class CategorizedTask(val category: String, val task: JSONObject)

    private fun upgradeSections(data: JSONObject): List<Pair<String, JSONObject?>> =
        listOf(
            label(labels(data), "homeVillage", "HOME VILLAGE") to data.optJSONObject("homeBuilders"),
            label(labels(data), "laboratory", "LAB") to data.optJSONObject("laboratory"),
            label(labels(data), "pets", "PETS") to data.optJSONObject("pets"),
            label(labels(data), "builderBase", "BUILDER BASE") to data.optJSONObject("builderBase")
        )

    private fun activeTasks(data: JSONObject): List<CategorizedTask> {
        return buildList {
            for ((title, section) in upgradeSections(data)) {
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
        labels: JSONObject?,
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
            views.setTextViewText(slot.nameId, taskName(task.task))
            views.setTextViewText(
                slot.metaId,
                "${task.category} · ${taskMeta(task.task, labels)}"
            )
            addImageTarget(
                imageTargets,
                slot.imageId,
                task.task.optString("imageUrl", "")
            )
        }

        val hiddenCount = activeTasks.drop(taskCapacity).sumOf { taskDisplayCount(it.task) }
        views.setViewVisibility(
            R.id.upgrade_more_count,
            if (hiddenCount > 0) View.VISIBLE else View.GONE
        )
        views.setTextViewText(
            R.id.upgrade_more_count,
            if (hiddenCount == 1) {
                "+1 ${label(labels, "moreUpgrade", "more upgrade")}"
            } else {
                "+$hiddenCount ${label(labels, "moreUpgrades", "more upgrades")}"
            }
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
            minHeight >= 180 -> 2
            else -> 1
        }
    }

    private fun isLargeWidget(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Boolean {
        val minHeight = appWidgetManager.getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return minHeight >= 190
    }

    private fun renderCompactSection(
        context: Context,
        views: RemoteViews,
        section: JSONObject?,
        labels: JSONObject?,
        stateViewId: Int,
        statusViewId: Int
    ) {
        val status = sectionStatus(section, labels)
        views.setTextViewText(stateViewId, emptySectionLabel(section, labels))
        views.setTextViewText(statusViewId, status)
        views.setTextColor(statusViewId, context.getColor(statusColor(status)))
    }

    private fun renderCompactResearch(context: Context, views: RemoteViews, data: JSONObject, labels: JSONObject?) {
        val sections = listOf(
            data.optJSONObject("laboratory"),
            data.optJSONObject("pets"),
            data.optJSONObject("builderBase")
        )
        val available = sections.filterNotNull().filter { it.optBoolean("available", true) }
        val remaining = available.sumOf { it.optInt("remainingCount", 0) }
        val state = when {
            available.isEmpty() -> label(labels, "notUnlocked", "Not unlocked")
            remaining == 0 -> label(labels, "fullyUpgraded", "Fully upgraded")
            else -> label(labels, "noActiveResearch", "No active research")
        }
        val status = when {
            available.isEmpty() -> label(labels, "locked", "LOCKED")
            remaining == 0 -> label(labels, "maxed", "MAXED")
            else -> label(labels, "idle", "IDLE")
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
        return listOf(boost.optString("shortLabel", boost.optString("label", "Boost")), duration)
            .filter { it.isNotBlank() }
            .joinToString("\n")
    }

    private fun isExpiredTimedBoost(boost: JSONObject): Boolean {
        val expiresAt = boost.optString("expiresAt", "")
        if (expiresAt.isBlank()) return false
        val end = runCatching { Instant.parse(expiresAt) }.getOrNull() ?: return false
        return !end.isAfter(Instant.now())
    }

    private fun activeBoosts(boosts: JSONArray?): List<JSONObject> {
        if (boosts == null) return emptyList()
        val active = mutableListOf<JSONObject>()
        for (index in 0 until boosts.length()) {
            val boost = boosts.optJSONObject(index) ?: continue
            if (!isExpiredTimedBoost(boost)) active.add(boost)
        }
        return active
    }

    private fun renderHelper(
        views: RemoteViews,
        helper: JSONObject?,
        labels: JSONObject?,
        imageTargets: MutableMap<Int, String>
    ) {
        if (helper == null) {
            views.setViewVisibility(R.id.upgrade_helper_slot, View.GONE)
            return
        }
        val status = helperStatus(helper, labels)
        val text = listOf(helper.optString("shortName", shortHelperName(helper.optString("name", "Helper"))), status)
            .filter { it.isNotBlank() }
            .joinToString("\n")
        val imageUrl = helper.optString("imageUrl", "")
        views.setViewVisibility(R.id.upgrade_helper_slot, View.VISIBLE)
        views.setTextViewText(R.id.upgrade_helper_one, text)
        if (imageUrl.startsWith("https://")) {
            views.setViewVisibility(R.id.upgrade_helper_image, View.VISIBLE)
            views.setImageViewResource(R.id.upgrade_helper_image, R.drawable.ic_upgrade_status)
            addImageTarget(imageTargets, R.id.upgrade_helper_image, imageUrl)
        } else {
            views.setViewVisibility(R.id.upgrade_helper_image, View.GONE)
        }
    }

    private fun helperStatus(helper: JSONObject, labels: JSONObject?): String {
        val statusUntil = helper.optString("statusUntil", "")
        val statusEnd = statusUntil
            .takeIf { it.isNotBlank() }
            ?.let { runCatching { Instant.parse(it) }.getOrNull() }
        if (statusEnd != null && !statusEnd.isAfter(Instant.now())) {
            return label(labels, "ready", "Ready")
        }
        val until = durationUntil(statusUntil)
        return listOf(helper.optString("status", ""), until)
            .filter { it.isNotBlank() }
            .joinToString(" ")
    }

    private fun taskMeta(task: JSONObject, labels: JSONObject?): String {
        val fromLevel = task.optInt("fromLevel", 0)
        val toLevel = task.optInt("toLevel", 0)
        val duration = durationUntil(task.optString("finishesAt", ""))
        return "${label(labels, "level", "Lv")} $fromLevel → $toLevel  ·  $duration"
    }

    private fun taskName(task: JSONObject): String {
        val name = task.optString("name", "Upgrade")
        val count = taskDisplayCount(task)
        return if (count > 1) "${count}x $name" else name
    }

    private fun taskDisplayCount(task: JSONObject?): Int =
        (task?.optInt("count", 1) ?: 1).coerceAtLeast(1)

    private fun taskArrayDisplayCount(tasks: JSONArray?): Int {
        if (tasks == null) return 0
        var count = 0
        for (index in 0 until tasks.length()) {
            count += taskDisplayCount(tasks.optJSONObject(index))
        }
        return count
    }

    private fun totalActiveCount(data: JSONObject): Int =
        upgradeSections(data).sumOf { (_, section) ->
            val displayedTasks = taskArrayDisplayCount(section?.optJSONArray("tasks"))
            section?.optInt("activeCount", displayedTasks) ?: 0
        }

    private fun hasFinishedTask(data: JSONObject): Boolean {
        val sections = listOf(
            data.optJSONObject("homeBuilders"),
            data.optJSONObject("laboratory"),
            data.optJSONObject("pets"),
            data.optJSONObject("builderBase")
        )
        val now = Instant.now()
        for (section in sections) {
            val hiddenFinishesAt = section
                ?.optString("hiddenFinishesAt", "")
                ?.takeIf { it.isNotBlank() }
            if (hiddenFinishesAt != null) {
                val hiddenFinish = runCatching {
                    Instant.parse(hiddenFinishesAt)
                }.getOrNull()
                if (hiddenFinish != null && !hiddenFinish.isAfter(now)) return true
            }
            val tasks = section?.optJSONArray("tasks") ?: continue
            for (index in 0 until tasks.length()) {
                val finishesAt = tasks.optJSONObject(index)
                    ?.optString("finishesAt", "")
                    ?.takeIf { it.isNotBlank() }
                    ?: continue
                val finish = runCatching { Instant.parse(finishesAt) }.getOrNull() ?: continue
                if (!finish.isAfter(now)) return true
            }
        }
        return false
    }

    private fun sectionStatus(section: JSONObject?, labels: JSONObject?): String {
        if (section == null || !section.optBoolean("available", true)) {
            return label(labels, "locked", "LOCKED")
        }
        val displayedTasks = taskArrayDisplayCount(section.optJSONArray("tasks"))
        val tasks = section.optInt("activeCount", displayedTasks)
        if (tasks == 0 && section.optInt("remainingCount", 0) == 0) {
            return label(labels, "maxed", "MAXED")
        }
        val idle = (section.optInt("capacity", 0) - tasks).coerceAtLeast(0)
        return when {
            idle > 0 -> idleStatus(labels, idle)
            tasks > 0 -> activeStatus(labels, tasks)
            else -> ""
        }
    }

    private fun emptySectionLabel(section: JSONObject?, labels: JSONObject?): String {
        if (section == null) return label(labels, "noActiveUpgrades", "No active upgrades")
        if (!section.optBoolean("available", true)) return label(labels, "notUnlocked", "Not unlocked")
        return if (section.optInt("remainingCount", 0) == 0) {
            label(labels, "fullyUpgraded", "Fully upgraded")
        } else {
            label(labels, "noActiveUpgrades", "No active upgrades")
        }
    }

    private fun labels(data: JSONObject?): JSONObject? = data?.optJSONObject("labels")

    private fun label(labels: JSONObject?, key: String, fallback: String): String =
        labels?.optString(key, fallback)?.takeIf { it.isNotBlank() } ?: fallback

    private fun activeStatus(labels: JSONObject?, count: Int): String =
        "$count ${label(labels, "active", "ACTIVE")}"

    private fun idleStatus(labels: JSONObject?, count: Int): String =
        "$count ${label(labels, "idle", "IDLE")}"

    private fun isMaxedStatus(status: String): Boolean {
        val normalized = status.uppercase()
        return normalized == "MAXED" || normalized == "MAXÉ" || normalized == "MAXE"
    }

    private fun statusColor(status: String): Int {
        return when {
            isMaxedStatus(status) -> R.color.widget_status_maxed
            status.isNotBlank() -> R.color.widget_status_idle
            else -> R.color.widget_text_secondary
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
