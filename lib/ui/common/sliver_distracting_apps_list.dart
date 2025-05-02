/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/models/usage_filter_model.dart';
import 'package:mindful/providers/apps/apps_info_provider.dart';
import 'package:mindful/providers/apps/filtered_packages_provider.dart';
import 'package:mindful/ui/common/application_icon.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/search_filter_panel.dart';
import 'package:mindful/ui/common/sliver_implicitly_animated_list.dart';
import 'package:mindful/ui/common/sliver_shimmer_list.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverDistractingAppsList extends ConsumerStatefulWidget {
  const SliverDistractingAppsList({
    super.key,
    required this.distractingApps,
    required this.onSelectionChanged,
    this.hiddenApps = const [],
    this.isInsideModalSheet = true,
  });

  final List<String> distractingApps;
  final List<String> hiddenApps;
  final Function(String package, bool isSelected) onSelectionChanged;
  final bool isInsideModalSheet;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SliverDistractingAppsListState();
}

class _SliverDistractingAppsListState
    extends ConsumerState<SliverDistractingAppsList> {
  UsageFilterModel _filter = UsageFilterModel.constant();

  _onFilterChanged(UsageFilterModel filter) {
    if (!mounted) return;
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final allApps = ref.watch(filteredPackagesProvider(_filter));

    /// Selected apps which are installed
    final selectedApps =
        allApps.value?.where((e) => widget.distractingApps.contains(e)) ?? [];

    /// Unselected apps which are installed
    final unselectedApps = (allApps.value ?? []).where(
      (e) =>
          !widget.distractingApps.contains(e) && !widget.hiddenApps.contains(e),
    );

    return MultiSliver(
      children: [
        /// Search and filter panel
        widget.isInsideModalSheet
            ? PinnedHeaderSliver(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SearchFilterPanel(
                    filter: _filter,
                    onFilterChanged: _onFilterChanged,
                  ),
                ),
              )
            : SearchFilterPanel(
                filter: _filter,
                onFilterChanged: _onFilterChanged,
              ),

        /// Header
        ContentSectionHeader(
          title: widget.distractingApps.isEmpty
              ? context.locale.select_distracting_apps_heading
              : context.locale.your_distracting_apps_heading,
        ),

        /// Apps list
        SliverAnimatedSwitcher(
          duration: AppConstants.defaultAnimDuration,
          switchInCurve: AppConstants.defaultCurve,
          switchOutCurve: AppConstants.defaultCurve.flipped,
          child: allApps.hasValue
              ? SliverImplicitlyAnimatedList<String>(
                  itemExtent: 56,
                  items: [
                    ...selectedApps,

                    /// Will act as a separator
                    if (widget.distractingApps.isNotEmpty) ...["separator"],

                    ...unselectedApps,
                  ],
                  keyBuilder: (item) => item,
                  itemBuilder: (context, i, packageName, _) {
                    /// Fetch app using the package
                    final appInfo =
                        ref.read(appsInfoProvider).value?[packageName];

                    final isSelected =
                        widget.distractingApps.contains(packageName);

                    return packageName == "separator"
                        ? ContentSectionHeader(
                            title: context.locale.select_more_apps_heading,
                          )
                        : appInfo != null
                            ? DefaultListTile(
                                isSelected:
                                    appInfo.isImpSysApp ? null : isSelected,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                position: _resolvePosition(
                                  packageName,
                                  selectedApps,
                                  unselectedApps,
                                ),
                                leading:
                                    ApplicationIcon(appInfo: appInfo, size: 16),
                                titleText: appInfo.name,
                                onPressed: () {
                                  /// If app is important system app
                                  if (appInfo.isImpSysApp) {
                                    context.showSnackAlert(
                                      context.locale
                                          .imp_distracting_apps_snack_alert,
                                    );
                                    return;
                                  }

                                  widget.onSelectionChanged(
                                      packageName, !isSelected);
                                },
                              )
                            : 0.vBox;
                  },
                )
              : const SliverShimmerList(),
        ),
      ],
    );
  }

  ItemPosition _resolvePosition(
    String package,
    Iterable<String> selected,
    Iterable<String> unselected,
  ) =>
      (selected.length == 1 && selected.first == package) ||
              (unselected.length == 1 && unselected.first == package)
          ? ItemPosition.none
          : (selected.isNotEmpty && selected.first == package) ||
                  (unselected.isNotEmpty && unselected.first == package)
              ? ItemPosition.top
              : (selected.isNotEmpty && selected.last == package) ||
                      (unselected.isNotEmpty && unselected.last == package)
                  ? ItemPosition.bottom
                  : ItemPosition.mid;
}
