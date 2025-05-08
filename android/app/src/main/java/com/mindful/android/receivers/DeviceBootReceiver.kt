/*
 *
 *  *
 *  *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *  *
 *  *  * This source code is licensed under the GPL-2.0 license license found in the
 *  *  * LICENSE file in the root directory of this source tree.
 *  *
 *
 */
package com.mindful.android.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import com.mindful.android.helpers.AlarmTasksSchedulingHelper
import com.mindful.android.helpers.device.NotificationHelper
import com.mindful.android.helpers.storage.SharedPrefsHelper
import com.mindful.android.workers.FlutterBgExecutionWorker
import com.mindful.android.workers.FlutterBgExecutionWorker.Companion.FLUTTER_TASK_ID

/**
 * BroadcastReceiver that listens for device boot and package replacement events
 * to restart required services and reschedule any pending alarms.
 */
class DeviceBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "Mindful.DeviceBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> {
                Log.d(
                    TAG,
                    "onReceive: Device reboot broadcast received, initializing necessary services and tasks."
                )

                try {
                    // Register channels before starting foreground services
                    NotificationHelper.registerNotificationChannels(context.applicationContext)

                    // Reschedule midnight reset task
                    AlarmTasksSchedulingHelper.scheduleMidnightResetTask(context, false)

                    // Queue a one-time work request to execute BootWorker tasks
                    WorkManager.getInstance(context).enqueueUniqueWork(
                        TAG, ExistingWorkPolicy.KEEP,
                        OneTimeWorkRequest
                            .Builder(FlutterBgExecutionWorker::class.java)
                            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                            .setInputData(
                                Data.Builder().putString(FLUTTER_TASK_ID, "onBootOrAppUpdate")
                                    .build()
                            ).build()
                    )
                } catch (e: Exception) {
                    SharedPrefsHelper.insertCrashLogToPrefs(context, e)
                    Log.e(TAG, "onReceive: Something went wrong!", e)
                }
            }
        }
    }
}
