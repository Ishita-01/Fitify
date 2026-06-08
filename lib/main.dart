import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/analysis_repository.dart';
import 'data/repositories/assistant_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/services/local_storage_service.dart';
import 'features/app/main_shell.dart';
import 'features/app/providers/analysis_provider.dart';
import 'features/app/providers/assistant_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/welcome_screen.dart';

/// DEV: skip the onboarding flow and launch straight into the main app while
/// iterating on it. Flip back to `false` to test the full onboarding flow.
const bool kSkipOnboarding = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitifyApp());
}

class FitifyApp extends StatelessWidget {
  const FitifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WorkoutRepository>(create: (_) => InMemoryWorkoutRepository()),
        ChangeNotifierProvider(
            create: (_) => OnboardingProvider(LocalStorageService())),
        ChangeNotifierProvider(
            create: (_) => AnalysisProvider(MockAnalysisRepository())),
        ChangeNotifierProvider(
            create: (_) => AssistantProvider(MockAssistantRepository())),
      ],
      child: MaterialApp(
        title: 'Fitify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: kSkipOnboarding ? const MainShell() : const WelcomeScreen(),
      ),
    );
  }
}
