/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mindful/core/database/converters/list_converters.dart';
import 'package:mindful/core/enums/session_type.dart';

@DataClassName("FocusProfile")
class FocusProfileTable extends Table {
  /// Selected session type
  IntColumn get sessionType => intEnum<SessionType>()();

  @override
  Set<Column<Object>>? get primaryKey => {sessionType};

  /// Duration in SECONDS for the focus session
  IntColumn get sessionDuration => integer().withDefault(const Constant(0))();

  /// Flag indicating if to enforce the session or not.
  /// If 'True' user cannot end session until the time ends.
  BoolColumn get enforceSession =>
      boolean().withDefault(const Constant(false))();

  /// Flag indicating if to pin to Mindful or not.
  BoolColumn get pinMindful => boolean().withDefault(const Constant(false))();

  /// Flag indicating if to start DND during the focus session
  BoolColumn get shouldStartDnd =>
      boolean().withDefault(const Constant(false))();

  /// List of app's packages which are selected as distracting apps.
  TextColumn get distractingApps => text()
      .map(const ListStringConverter())
      .withDefault(Constant(jsonEncode([])))();
}
