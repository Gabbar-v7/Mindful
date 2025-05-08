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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:mindful/core/enums/app_theme_mode.dart';

class AppConstants {
  // App Defaults
  static const defaultThemeMode = AppThemeMode.system;
  static const defaultMaterialColor = "Indigo";
  static const defaultLocale = "en";
  static const defaultUsername = "Achiever";
  static const defaultCurve = Curves.fastEaseInToSlowEaseOut;
  static const defaultAnimDuration = Duration(milliseconds: 350);

  // Custom packages
  static const removedAppPackage = "com.android.removed";
  static const tetheringAppPackage = "com.android.tethering";

  /// Urls
  static const githubUrl = "https://github.com/akaMrNagar/Mindful/";
  static const bmcUrl = "https://buymeacoffee.com/akamrnagar";
  static const instagramUrl = "https://www.instagram.com/lasthopedevelopers/";
  static const telegramUrl = "https://t.me/fossmindful";
  static const supportEmailUrl = "mailto:help.lasthopedevs@gmail.com";
  static const privacyPolicyUrl = "https://bemindful.vercel.app/privacy";
  static const faqsUrl = "https://bemindful.vercel.app/#faqs";

  static String githubChangeLogUrl(String appVersion) =>
      "https://github.com/akaMrNagar/Mindful/releases/tag/$appVersion";

  static const githubIssueDirectUrl =
      "https://github.com/akaMrNagar/Mindful/issues/new?template=bug_report.md";

  static const githubSuggestionDirectUrl =
      "https://github.com/akaMrNagar/Mindful/issues/new?template=feature_request.md";

  static const gitHubDonationSectionUrl =
      "https://github.com/akaMrNagar/Mindful?tab=readme-ov-file#donate";

  static const githubFeedbackSectionUrl =
      "https://github.com/akaMrNagar/Mindful?tab=readme-ov-file#feedback-and-support";

  /// Returns localized list of days in a week in short
  ///  e.g., ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  static List<String> daysShort(BuildContext context) {
    List<String> shortDays = [];

    final firstMonday = DateTime(0, 1, 2);
    for (int i = 1; i <= 7; i++) {
      String shortDay =
          DateFormat.E(Localizations.localeOf(context).languageCode)
              .format(firstMonday.add(i.days));
      shortDays.add(shortDay);
    }

    return shortDays;
  }
}
