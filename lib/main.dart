import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';   // Fixed line
import 'theme/app_theme.dart'; // Fixed line
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: QuizMasterApp()));
}

class QuizMasterApp extends ConsumerWidget {
  const QuizMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: Ensure your 'routerProvider' is defined in your providers folder
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QuizMaster',
      theme: AppTheme.theme, // This uses your app_theme.dart settings
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}