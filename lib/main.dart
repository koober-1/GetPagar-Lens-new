import 'package:flutter/material.dart';
import 'package:getpagar_lens/app/app.dart';
import 'package:getpagar_lens/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize login/session state
  await authNotifier.init();

  runApp(const App());
}
