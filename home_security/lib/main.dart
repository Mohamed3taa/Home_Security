import 'package:home_security/app_routes.dart';
import 'package:home_security/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'util.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = createTextTheme(context, "Cairo", "Abel");
    return MaterialApp(
      title: 'Home Security',
      theme: ThemeData(
        colorScheme: MaterialTheme.lightScheme(),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: MaterialTheme.darkScheme(),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      highContrastTheme: ThemeData(
        colorScheme: MaterialTheme.lightHighContrastScheme(),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      highContrastDarkTheme: ThemeData(
        colorScheme: MaterialTheme.darkHighContrastScheme(),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      // Initial Route
      initialRoute: AppRoutes.splash,

      // If you keep your routes in `app_routes.dart`, pass it here
      routes: appRoutes,
    );
  }
}
