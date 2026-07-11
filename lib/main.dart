import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'models/clothing_item.dart';
import 'models/makeup_item.dart';
import 'models/skincare_item.dart';
import 'models/wishlist_item.dart';
import 'models/outfit.dart';
import 'localization/app_strings.dart';
import 'services/sync_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(ClothingItemAdapter());
  Hive.registerAdapter(MakeupItemAdapter());
  Hive.registerAdapter(SkincareItemAdapter());
  Hive.registerAdapter(WishlistItemAdapter());
  Hive.registerAdapter(OutfitAdapter());
  await Hive.openBox<ClothingItem>('clothingBox');
  await Hive.openBox<MakeupItem>('makeupBox');
  await Hive.openBox<SkincareItem>('skincareBox');
  await Hive.openBox<WishlistItem>('wishlistBox');
  await Hive.openBox<Outfit>('outfitBox');
  await Hive.openBox('settingsBox');
  await loadSavedLanguage();
  await loadSavedTheme();
  await loadGuestMode();

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      SyncService().syncAll();
    }
  });

  runApp(const NoveliaApp());
}

class NoveliaApp extends StatelessWidget {
  const NoveliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkMode,
          builder: (context, dark, _) {
            return MaterialApp(
              title: 'LYNÉA',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: onboardingComplete,
      builder: (context, onboarded, _) {
        if (!onboarded) {
          return const OnboardingScreen();
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            return ValueListenableBuilder<bool>(
              valueListenable: isGuestMode,
              builder: (context, guest, _) {
                final isLoggedIn = snapshot.data != null;
                if (isLoggedIn || guest) {
                  return const MainNavigationScreen();
                }
                return const LoginScreen();
              },
            );
          },
        );
      },
    );
  }
}