import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'dart:ui' show PlatformDispatcher;

import 'src/routing/app_router.dart';
import 'src/application/settings/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Dynamically intercept and suppress the framework's HID KeyUp synchronization bug
  // This occurs exclusively when a rapid USB Barcode Scanner simulates keystrokes 
  // faster than the Linux/Windows event loop can track 'Shift' down/up states.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final errStr = details.exceptionAsString();
    if (errStr.contains('A KeyUpEvent is dispatched, but the state shows that the physical key is not pressed')) {
      // Safely ignore hardware keyboard state desyncs to keep terminal clean
      return;
    }
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('A KeyUpEvent is dispatched, but the state shows that the physical key is not pressed')) {
      return true; // Handled
    }
    return false; // Let it crash/log
  };

  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MarkoGroupApp(),
    ),
  );
}

class MarkoGroupApp extends ConsumerWidget {
  const MarkoGroupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final seedColor = Colors.indigo;

    return MaterialApp.router(
      title: 'Marko Group',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xfff8fafc),
        colorScheme: const ColorScheme.light(
          primary: Color(0xff0f172a),
          primaryContainer: Color(0xfff1f5f9),
          secondary: Color(0xff334155),
          surface: Colors.white,
          error: Color(0xffef4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xff020617),
          onSurfaceVariant: Color(0xff475569),
          onError: Colors.white,
          outline: Color(0xffe2e8f0),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xff0f172a),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xff0f172a)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xffe2e8f0), width: 1),
          ),
          margin: const EdgeInsets.all(8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff0f172a),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff0f172a),
            side: const BorderSide(color: Color(0xffe2e8f0)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xff0f172a),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xffe2e8f0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xffe2e8f0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xff0f172a), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xff64748b)),
          hintStyle: const TextStyle(color: Color(0xff94a3b8)),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xfff8fafc)),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xff475569)),
          dividerThickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xff64748b),
          textColor: Color(0xff0f172a),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xffe2e8f0),
          thickness: 1,
          space: 1,
        ),
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xff020617), // Slate 950
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          primaryContainer: Color(0xff1e293b),
          secondary: Color(0xff94a3b8),
          surface: Color(0xff0f172a), // Slate 900
          error: Color(0xffef4444),
          onPrimary: Color(0xff0f172a),
          onSecondary: Colors.white,
          onSurface: Color(0xfff8fafc),
          onSurfaceVariant: Color(0xff94a3b8),
          onError: Colors.white,
          outline: Color(0xff1e293b), // Slate 800
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff020617),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xff0f172a),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xff1e293b), width: 1),
          ),
          margin: const EdgeInsets.all(8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff0f172a),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xff1e293b)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xff1e293b)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xff1e293b)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xff020617),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xff94a3b8)),
          hintStyle: const TextStyle(color: Color(0xff475569)),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xff0f172a)),
          dataRowColor: WidgetStateProperty.all(const Color(0xff0f172a)),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xffcbd5e1)),
          dividerThickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xffcbd5e1),
          textColor: Colors.white,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xff1e293b),
          thickness: 1,
          space: 1,
        ),
      ),
      routerConfig: router,
    );
  }
}
