import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:rud_fits_ai/core/configure_debug_ssl.dart';
import 'package:rud_fits_ai/features/auth/screens/login_screen.dart';
import 'package:rud_fits_ai/themes/themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDebugSsl();
  runApp(const RudFitApp());
}

class RudFitApp extends StatelessWidget {
  const RudFitApp({super.key});

  static const Locale _ptBr = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RudFitAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: _ptBr,
      supportedLocales: const [_ptBr],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginScreen(),
    );
  }
}
