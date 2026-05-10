import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/accessibility/provider/accessibility_provider.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/cart/provider/cart_provider.dart';
import 'features/products/data/product_provider.dart';
import 'features/products/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuroraApp());
}

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AccessibilityProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (context, accessibility, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Aurora Beauty',
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Roboto',
              scaffoldBackgroundColor: accessibility.appBackground,
              colorScheme: ColorScheme.fromSeed(
                seedColor: accessibility.primaryColor,
                brightness: accessibility.highContrast
                    ? Brightness.dark
                    : Brightness.light,
              ),
            ),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(accessibility.textScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isLoggedIn) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}
