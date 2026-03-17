import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();
  runApp(const FuelFinderApp());
}

class FuelFinderApp extends StatelessWidget {
  const FuelFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) => MaterialApp(
        title: 'Fuel Finder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: SettingsService.instance.themeMode,
        home: const HomeScreen(),
      ),
    );
  }
}
