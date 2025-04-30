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
package com.mindful.android.helpers.device

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service.NOTIFICATION_SERVICE
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.mindful.android.AppConstants
import com.mindful.android.R
import com.mindful.android.enums.DndWakeLock
import com.mindful.android.helpers.storage.SharedPrefsHelper
import com.mindful.android.utils.AppUtils
import com.mindful.android.utils.ThreadUtils.runOnMainThread

/**
 * NotificationHelper provides utility methods for managing notification channels and permissions
 * in an Android application.
 * It includes functionalities to register notification channels and request notification permissions.
 */
object NotificationHelper {
    private const val TAG = "Mindful.NotificationHelper"

    // Notification channel IDs
    const val NOTIFICATION_CRITICAL_CHANNEL_ID: String = "mindful.notification.channel.CRITICAL"
    const val NOTIFICATION_FOCUS_CHANNEL_ID: String = "mindful.notification.channel.FOCUS"
    const val NOTIFICATION_BEDTIME_CHANNEL_ID: String = "mindful.notification.channel.BEDTIME"
    private const val NOTIFICATION_SERVICE_CHANNEL_ID: String =
        "mindful.notification.channel.SERVICE"

    /**
     * Registers notification channels for the application. This method creates and registers
     * channels for important and other notifications, specifying their importance and descriptions.
     *
     * @param context The application context used to access system services.
     */
    fun registerNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create channels
            val criticalChannel = NotificationChannel(
                NOTIFICATION_CRITICAL_CHANNEL_ID,
                "Critical Alerts",
                NotificationManager.IMPORTANCE_HIGH
            )
            criticalChannel.description =
                "These notifications include crucial updates regarding the essential system operations to ensure Mindful runs smoothly."

            val focusChannel = NotificationChannel(
                NOTIFICATION_FOCUS_CHANNEL_ID,
                "Focus Sessions",
                NotificationManager.IMPORTANCE_HIGH
            )
            focusChannel.description =
                "These notifications include updates regarding focus sessions to help you stay on track."

            val bedtimeChannel = NotificationChannel(
                NOTIFICATION_BEDTIME_CHANNEL_ID,
                "Bedtime Routine",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            bedtimeChannel.description =
                "These notifications include updates regarding bedtime routine to help you get a peaceful sleep."

            val serviceChannel = NotificationChannel(
                NOTIFICATION_SERVICE_CHANNEL_ID,
                "Running Services",
                NotificationManager.IMPORTANCE_LOW
            )
            serviceChannel.description =
                "These are non-critical notifications. They can be disabled but are included to comply with Android requirements."

            // Register channels
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannels(
                listOf(
                    criticalChannel,
                    focusChannel,
                    bedtimeChannel,
                    serviceChannel
                )
            )
        }
    }

    /**
     * Builds and returns a notification for a foreground service with the specified content.
     *
     * @param context The application context used to access system services.
     * @param content The content text of the notification.
     * @return A Notification object representing the foreground service notification.
     */
    fun buildFgServiceNotification(context: Context, content: String?): Notification {
        return NotificationCompat.Builder(context, NOTIFICATION_SERVICE_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_mindful)
            .setOngoing(true)
            .setAutoCancel(true)
            .setContentTitle(context.getString(R.string.service_running_notification_title))
            .setContentIntent(AppUtils.getPendingIntentForMindfulUri(context))
            .setContentText(content)
            .build()
    }

    /**
     * Displays a notification that prompts the user to enable overlay permission.
     */
    fun pushAskOverlayPermissionNotification(
        context: Context,
    ) {
        val notificationManager =
            context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val permissionIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)

        permissionIntent.setData(Uri.parse("package:${context.packageName}"))
        val pendingIntent = PendingIntent.getActivity(
            context.applicationContext,
            0,
            permissionIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val msg = context.getString(R.string.overlay_permission_denied_notification_info)
        notificationManager.notify(
            AppConstants.OVERLAY_SERVICE_NOTIFICATION_ID,
            NotificationCompat.Builder(
                context,
                NOTIFICATION_CRITICAL_CHANNEL_ID
            )
                .setSmallIcon(R.drawable.ic_mindful)
                .setAutoCancel(true)
                .setContentTitle(context.getString(R.string.overlay_permission_denied_notification_title))
                .setContentText(msg)
                .setContentIntent(pendingIntent)
                .setStyle(NotificationCompat.BigTextStyle().bigText(msg))
                .addAction(
                    0, // No icon = text-only button
                    "Allow",
                    pendingIntent
                )
                .build()
        )
    }

    /**
     * Toggles the Do Not Disturb (DND) mode on or off based on the provided flag.
     *
     * @param context     The application context used to access system services.
     * @param featureLock     The feature which is requesting to toggle dnd.
     * @param shouldStart If true, enables DND mode; if false, disables it.
     */
    fun toggleDnd(
        context: Context,
        featureLock: DndWakeLock,
        shouldStart: Boolean,
    ) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Check if permission for DND mode is granted
        if (notificationManager.isNotificationPolicyAccessGranted) {
            if (shouldStart) {

                /// Return if dnd lock is not free
                val currentLock = SharedPrefsHelper.getSetDndWakeLock(context, null)
                if (currentLock != DndWakeLock.None && currentLock != featureLock) {
                    showDndLockToast(context, currentLock)
                    return
                }

                /// Otherwise start DND
                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                SharedPrefsHelper.getSetDndWakeLock(context, featureLock)
                Log.d(TAG, "toggleDnd: DND mode started by $featureLock")
            } else {
                /// Return if dnd is being utilized by another feature but requested by another feature
                val currentLock = SharedPrefsHelper.getSetDndWakeLock(context, null)
                if (currentLock != featureLock) {
                    showDndLockToast(context, currentLock)
                    return
                }

                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                SharedPrefsHelper.getSetDndWakeLock(context, DndWakeLock.None)
                Log.d(TAG, "toggleDnd: DND mode stopped by $featureLock")
            }
        } else {
            Log.d(TAG, "toggleDnd: Do not have permission to modify DND mode")
        }
    }


    private fun showDndLockToast(
        context: Context,
        currentLock: DndWakeLock,
    ) {
        val feature = when (currentLock) {
            DndWakeLock.FocusMode -> context.getString(R.string.app_paused_restriction_focus_mode)
            DndWakeLock.BedtimeMode -> context.getString(R.string.app_paused_restriction_bedtime_mode)
            else -> ""
        }

        if (feature.isNotEmpty()) {
            runOnMainThread {
                Toast.makeText(
                    context,
                    context.getString(R.string.toast_dnd_utilized_by_feature, feature),
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }
}
