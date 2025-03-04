/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/providers/system/permissions_provider.dart';
import 'package:mindful/ui/common/sliver_primary_action_container.dart';
import 'package:mindful/ui/permissions/permission_sheet.dart';

class AccessibilityPermissionCard extends ConsumerWidget {
  const AccessibilityPermissionCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final havePermission = ref
        .watch(permissionProvider.select((v) => v.haveAccessibilityPermission));

    return SliverPrimaryActionContainer(
      isVisible: !havePermission,
      margin: const EdgeInsets.symmetric(vertical: 4),
      icon: FluentIcons.accessibility_20_regular,
      title: context.locale.permission_accessibility_title,
      information: context.locale.permission_accessibility_required,
      negativeBtn: TextButton(
        onPressed: () =>
            MethodChannelService.instance.launchUrl(AppConstants.faqsUrl),
        child: Text(context.locale.permission_button_help),
      ),
      positiveBtn: FilledButton(
        child: Text(context.locale.permission_button_grant_permission),
        onPressed: () => showAccessibilityPermissionSheet(context, ref),
      ),
    );
  }

  void showAccessibilityPermissionSheet(
    BuildContext context,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PermissionSheet(
        icon: FluentIcons.accessibility_20_filled,
        isAccessibilityPerm: true,
        title: context.locale.permission_accessibility_title,
        description: context.locale.permission_accessibility_info,
        deviceSwitchTileLabel:
            context.locale.permission_accessibility_device_tile_label,
        onTapGrantPermission: () {
          Navigator.of(sheetContext).maybePop();
          ref.read(permissionProvider.notifier).askAccessibilityPermission();
        },
      ),
    );
  }
}
