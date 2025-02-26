/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:drift/drift.dart';
import 'dart:convert';

class ListBoolConverter extends TypeConverter<List<bool>, String> {
  const ListBoolConverter();

  @override
  List<bool> fromSql(String fromDb) {
    List<dynamic> jsonList = json.decode(fromDb);
    return jsonList.map((item) => item as bool).toList();
  }

  @override
  String toSql(List<bool> value) {
    return json.encode(value);
  }
}

class ListStringConverter extends TypeConverter<List<String>, String> {
  const ListStringConverter();

  @override
  List<String> fromSql(String fromDb) {
    List<dynamic> jsonList = json.decode(fromDb);
    return jsonList.map((item) => item as String).toList();
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value.toSet().toList());
  }
}

class ListEnumNamesConverter<T extends Enum>
    extends TypeConverter<List<T>, String> {
  /// All values of the enum [enum.values].
  final List<T> values;

  /// Constant default constructor.
  const ListEnumNamesConverter(this.values);

  @override
  List<T> fromSql(String fromDb) {
    List<dynamic> jsonList = json.decode(fromDb);
    return jsonList.map((e) => values.byName(e)).toList();
  }

  @override
  String toSql(List<T> value) {
    return jsonEncode(value.map((e) => e.name).toSet().toList());
  }
}
