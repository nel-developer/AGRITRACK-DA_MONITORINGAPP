import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — field enumerators use phones upright
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so splash background bleeds through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                     Colors.transparent,
      statusBarIconBrightness:            Brightness.light,
      systemNavigationBarColor:           Colors.white,
      systemNavigationBarIconBrightness:  Brightness.dark,
    ),
  );

  runApp(const AgriTrackApp());
}