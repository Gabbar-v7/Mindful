/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/database/daos/dynamic_records_dao.dart';
import 'package:mindful/core/database/daos/unique_records_dao.dart';
import 'package:mindful/core/enums/session_state.dart';
import 'package:mindful/core/enums/session_type.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/services/drift_db_service.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/core/utils/default_models_utils.dart';
import 'package:mindful/models/focus_mode_model.dart';

/// A Riverpod state notifier provider that manages [FocusModeModel].
final focusModeProvider =
    StateNotifierProvider<FocusModeNotifier, FocusModeModel>(
  (ref) => FocusModeNotifier(),
);

class FocusModeNotifier extends StateNotifier<FocusModeModel>
    with WidgetsBindingObserver {
  late DynamicRecordsDao _dynamicDao;
  late UniqueRecordsDao _uniqueDao;
  Timer? _activeSessionTimer;
  VoidCallback? _sessionSuccessCallback;
  bool _isAppPaused = false;

  FocusModeNotifier()
      : super(FocusModeModel(
          focusMode: defaultFocusModeModel,
          focusProfile: defaultFocusProfileModel,
        )) {
    _init();
  }

  /// Initializes state by loading data from the database and setting up listeners.
  /// If an active session is found, resumes the session timer.
  void _init() async {
    _dynamicDao = DriftDbService.instance.driftDb.dynamicRecordsDao;
    _uniqueDao = DriftDbService.instance.driftDb.uniqueRecordsDao;

    /// load from database
    final focusMode = await _uniqueDao.loadFocusModeSettings();
    final focusProfile =
        await _dynamicDao.fetchFocusProfileBySessionType(focusMode.sessionType);
    final activeSession = await _dynamicDao.fetchLastActiveFocusSession();

    /// update state
    state = state.copyWith(
      focusMode: focusMode,
      focusProfile: focusProfile,
      activeSession: activeSession,
    );

    /// Run after a delay to avoid database deadlock
    await Future.delayed(1.seconds, () {
      /// restart session service if needed
      if (activeSession != null) {
        _startSessionServiceAndTimer(activeSession);
      }

      /// Reset streak if needed
      _incrementOrResetStreaks(shouldIncrement: false);
    });

    WidgetsBinding.instance.addObserver(this);
  }

  /// Starts a session timer and service for managing focus sessions.
  ///
  /// If the session duration is set to zero, an infinite timer is started.
  void _startSessionServiceAndTimer(FocusSession session) async {
    _activeSessionTimer?.cancel();
    final isFiniteSession = session.durationSecs > 0;
    final elapsedSeconds =
        DateTime.now().difference(session.startDateTime).inSeconds;

    /// check if it is already completed
    if (isFiniteSession && elapsedSeconds >= session.durationSecs) {
      giveUpOrFinishFocusSession(
        isTheSessionSuccessful: true,
        isFiniteSession: isFiniteSession,
      );
      return;
    }

    /// Start service
    await MethodChannelService.instance.updateFocusSession(
      session: session,
      profile: state.focusProfile,
    );

    /// Start timer
    _activeSessionTimer = Timer.periodic(
      1.seconds,
      (timer) async {
        /// Update elapsed time
        state = state.copyWith(
          elapsedTimeSec:
              DateTime.now().difference(session.startDateTime).inSeconds,
        );

        /// Check for completion if session is finite
        if (isFiniteSession && state.elapsedTimeSec >= session.durationSecs) {
          giveUpOrFinishFocusSession(
            isTheSessionSuccessful: true,
            isFiniteSession: isFiniteSession,
          );
        }
      },
    );
  }

  /// Sets a callback function to be executed when a session completes successfully.
  void setSessionSuccessCallback(VoidCallback callback) =>
      _sessionSuccessCallback = callback;

  /// set the duration for the session
  void setSessionDuration(int durationSec) {
    state = state.copyWith(
      focusProfile: state.focusProfile.copyWith(sessionDuration: durationSec),
    );

    _updateFocusProfileInDb();
  }

  /// Enables or disables Do Not Disturb during the Focus Session.
  void setShouldStartDnd(bool shouldStartDnd) async {
    state = state.copyWith(
      focusProfile: state.focusProfile.copyWith(shouldStartDnd: shouldStartDnd),
    );

    _updateFocusProfileInDb();
  }

  /// Enables or disables enforced mode for session.
  void setEnforceFocus(bool shouldEnforce) async {
    state = state.copyWith(
      focusProfile: state.focusProfile.copyWith(enforceSession: shouldEnforce),
    );

    _updateFocusProfileInDb();
  }

  /// Enables or disables mindful app pinning.
  void setPinMindful(bool shouldPin) async {
    state = state.copyWith(
      focusProfile: state.focusProfile.copyWith(pinMindful: shouldPin),
    );

    _updateFocusProfileInDb();
  }

  /// Updates session reflection.
  void updateActiveSessionReflection(String reflection) async {
    if (state.activeSession.value != null) {
      state = state.copyWith(
        activeSession: state.activeSession.valueOrNull?.copyWith(
          reflection: reflection,
        ),
      );

      /// Update session in database
      await _dynamicDao.updateFocusSessionById(state.activeSession.value!);
    }
  }

  /// Adds or removes an app from the distracting apps list.
  /// Updates the session service if an active session is present.
  void insertRemoveDistractingApp(String appPackage, bool shouldInsert) async {
    state = state.copyWith(
      focusProfile: state.focusProfile.copyWith(
        distractingApps: shouldInsert
            ? [...state.focusProfile.distractingApps, appPackage]
            : [
                ...state.focusProfile.distractingApps
                    .where((e) => e != appPackage)
              ],
      ),
    );

    _updateFocusProfileInDb();

    /// Update service if session is active
    if (state.activeSession.value != null) {
      await MethodChannelService.instance.updateFocusSession(
        session: state.activeSession.value!,
        profile: state.focusProfile,
      );
    }
  }

  /// Set session type for current focus session.
  void setSessionType(SessionType sessionType) async {
    state = state.copyWith(
      focusMode: state.focusMode.copyWith(sessionType: sessionType),
      focusProfile:
          await _dynamicDao.fetchFocusProfileBySessionType(sessionType),
    );

    /// Update db
    _updateFocusModeInDb();
  }

  /// Starts a new focus session, either finite or infinite, and saves it to the database.
  ///
  /// Returns a [FocusSession] object representing the newly started session.
  Future<void> startNewSession() async {
    /// Insert session to database
    final session = await _dynamicDao.insertFocusSession(
      type: state.focusMode.sessionType,
      durationSecs: state.focusProfile.sessionDuration,
    );

    /// Update state and start service and timer
    state = state.copyWith(
      activeSession: session,
      elapsedTimeSec: 0,
    );
    _startSessionServiceAndTimer(session);
  }

  /// Ends the active focus session, updating its status based on success or failure.
  ///
  /// Updates the session in the database and stops the focus session service.
  Future<void> giveUpOrFinishFocusSession({
    required bool isTheSessionSuccessful,
    required bool isFiniteSession,
  }) async {
    if (state.activeSession.value == null) return;

    /// Cancel active session timer
    _activeSessionTimer?.cancel();

    /// The difference from the session start and now
    final diffFromNow = DateTime.now()
        .difference(state.activeSession.value!.startDateTime)
        .inSeconds;

    /// Valid duration for finite session must be <= active session's duration
    final validDuration = isFiniteSession
        ? min(state.activeSession.value!.durationSecs, diffFromNow)
        : diffFromNow;

    final updatedSession = state.activeSession.value!.copyWith(
      state: isTheSessionSuccessful
          ? SessionState.successful
          : SessionState.failed,
      durationSecs: validDuration,
    );

    /// Update session in database and stop service
    await _dynamicDao.updateFocusSessionById(updatedSession);
    await MethodChannelService.instance.giveUpOrFinishFocusSession(
      isTheSessionSuccessful: isTheSessionSuccessful,
    );

    /// Set active session to null
    state = state.removeActiveSession();

    if (isTheSessionSuccessful) {
      _incrementOrResetStreaks();
      _sessionSuccessCallback?.call();
    }
  }

  /// Updates the user's streak count in the database.
  /// Increments the streak if it hasn’t been updated today or resets if there is a gap day.
  void _incrementOrResetStreaks({bool shouldIncrement = true}) async {
    /// If streak is already updated then return
    final today = DateTime.now().dateOnly;
    final lastUpdatedDay = state.focusMode.lastTimeStreakUpdated.dateOnly;

    /// Return if already updated today
    if (lastUpdatedDay == today) return;

    /// Reset if have gap in streak
    final oldStreak = state.focusMode.currentStreak;
    final newStreak = shouldIncrement
        ? oldStreak + 1
        : today.difference(lastUpdatedDay).inDays > 1
            ? 0
            : oldStreak;

    state = state.copyWith(
      focusMode: state.focusMode.copyWith(
        currentStreak: newStreak,
        longestStreak: max(newStreak, state.focusMode.longestStreak),
        lastTimeStreakUpdated: shouldIncrement ? today : null,
      ),
    );

    _updateFocusModeInDb();
  }

  /// Saves the current focus mode configuration to the database.
  void _updateFocusModeInDb() async =>
      await _uniqueDao.saveFocusModeSettings(state.focusMode);

  /// Saves the current focus profile configuration to the database.
  void _updateFocusProfileInDb() async =>
      await _dynamicDao.insertFocusProfileBySessionType(state.focusProfile);

  @override
  void dispose() {
    super.dispose();
    _activeSessionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Synchronize timer when the app resumes from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) async {
    /// Mark app as invisible or paused
    if (appState == AppLifecycleState.paused) {
      _isAppPaused = true;
    }

    /// Synchronize timer if resumed after pause or not
    if (appState == AppLifecycleState.resumed &&
        _isAppPaused &&
        state.activeSession.value != null) {
      _isAppPaused = false;
      _startSessionServiceAndTimer(state.activeSession.value!);
    }
  }
}
