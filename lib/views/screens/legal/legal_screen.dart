import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../models/webview_data_model.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key});

  void _openInWebView(BuildContext context, String? url, String title) {
    if (url == null || url.isEmpty) return;
    context.navigateToWebView(
      webViewData: WebViewDataModel(webURL: url, name: title),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
          data: (data) => data,
          orElse: () => null,
        );

    final setting = sharedPref?.getSetting();
    final termsUrl = setting?.termsAndConditionsURL;
    final privacyUrl = setting?.privacyPolicyURL;

    final termsTitle = getString(appStr.descriptionTermsConditions, 'description_terms_conditions');
    final privacyTitle = getString(appStr.descriptionPrivacyPolicy, 'description_privacy_policy');

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingLegal, 'heading_legal'),
            ),

            // Legal items
            _LegalMenuItem(
              title: termsTitle,
              onTap: () => _openInWebView(context, termsUrl, termsTitle),
            ),
            _LegalMenuItem(
              title: privacyTitle,
              onTap: () => _openInWebView(context, privacyUrl, privacyTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LegalMenuItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        child: SizedBox(
          width: double.infinity,
          child: AppText.body(
            title,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
