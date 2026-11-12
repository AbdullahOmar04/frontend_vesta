import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pages on the website the app links to.
const privacyPolicyUrl = 'https://vestaapp.co/privacy';
const termsUrl = 'https://vestaapp.co/terms';

/// Opens [url] in a browser tab over the app, and says so when it can't.
Future<void> openWebPage(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
  } catch (e) {
    debugPrint("Couldn't open $url: $e");
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text("Couldn't open the page. Visit $url instead.")),
    );
  }
}
