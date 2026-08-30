package com.clashking.nativebridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import expo.modules.backgroundtask.BackgroundTaskWork

private const val WIDGET_REFRESH_WORK = "CLASHKING_WIDGET_REFRESH"

class ClashKingWidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val actionUri = intent.dataString ?: return
        context.getSharedPreferences("ClashKingWidgetActions", Context.MODE_PRIVATE)
            .edit()
            .putString("pending_widget_action", actionUri)
            .commit()

        val worker = OneTimeWorkRequestBuilder<BackgroundTaskWork>()
            .setInputData(Data.Builder().putString("appScopeKey", context.packageName).build())
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            WIDGET_REFRESH_WORK,
            ExistingWorkPolicy.REPLACE,
            worker
        )
    }
}
