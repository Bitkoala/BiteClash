import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/tray/tray_service.dart';
import 'ui/screens/main_scaffold.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrayService.instance.init();

  runApp(
    const ProviderScope(
      child: BiteClashApp(),
    ),
  );
}

class BiteClashApp extends StatelessWidget {
  const BiteClashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiteClash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScaffold(),
    );
  }
}
