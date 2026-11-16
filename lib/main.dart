import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/shell.dart';
import 'screens/splash.dart';
import 'services/api_client.dart';
import 'services/repo.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Menu + saved login are loaded before the first screen is drawn.
  await Api.loadToken();
  await Repo.bootstrap();
  final signedIn = await Repo.restoreSession();

  // If the server ever rejects our token, send the customer back to sign-in.
  Api.onUnauthorized = () {
    Repo.signOut();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  };

  runApp(LickItApp(signedIn: signedIn));
}

class LickItApp extends StatelessWidget {
  final bool signedIn;
  const LickItApp({super.key, this.signedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lick It',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Keep the layout close to the 390pt design on very large text settings.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.15),
          ),
          child: child!,
        );
      },
      home: signedIn ? const Shell() : const SplashScreen(),
    );
  }
}
