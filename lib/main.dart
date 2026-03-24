import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/database_helper.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFFF7F9FC),
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFFF7F9FC),
              body: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No fue posible inicializar la app local. Reinicia la aplicacion.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(snapshot.data!),
          ],
          child: const ChecklistDemoApp(),
        );
      },
    );
  }
}

Future<SharedPreferences> _initializeApp() async {
  await DatabaseHelper.initializeFactory();
  return SharedPreferences.getInstance();
}
