import 'dart:io';

import 'package:flutter/foundation.dart';

void configureDebugSsl() {
  if (!kDebugMode) return;
  HttpOverrides.global = _DevHttpOverrides();
}

final class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}
