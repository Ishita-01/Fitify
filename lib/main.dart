import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/analysis_repository.dart';
import 'data/repositories/assistant_repository.dart';
import 'data/repositories/groq_assistant_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/services/coach_copy.dart';
import 'data/services/local_storage_service.dart';
import 'features/app/main_shell.dart';
import 'features/app/providers/analysis_provider.dart';
import 'features/app/providers/assistant_provider.dart';
import 'features/app/providers/plan_provider.dart';
import 'features/app/providers/theme_provider.dart';
import 'features/app/providers/units_controller.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/welcome_screen.dart';

/// DEV: skip the onboarding flow and launch straight into the main app while
/// iterating on it. Flip back to `false` to test the full onboarding flow.
const bool kSkipOnboarding = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the Groq key (optional). If the file/key is missing the app falls
  // back to the offline smart-mock coach.
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    /* no .env bundled — fine, we'll use the mock coach */
  }
  runApp(const FitifyApp());
}

class FitifyApp extends StatelessWidget {
  const FitifyApp({super.key});

  AssistantRepository _buildAssistantRepo() {
    final key = dotenv.maybeGet('GROQ_API_KEY')?.trim() ?? '';
    return key.isEmpty
        ? MockAssistantRepository()
        : GroqAssistantRepository(key);
  }

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService();
    return MultiProvider(
      providers: [
        Provider<WorkoutRepository>(create: (_) => InMemoryWorkoutRepository()),
        ChangeNotifierProvider(create: (_) => ThemeController(storage)),
        ChangeNotifierProvider(create: (_) => UnitsController(storage)),
        ChangeNotifierProvider(create: (_) => OnboardingProvider(storage)),
        ChangeNotifierProvider(
            create: (_) => AnalysisProvider(MockAnalysisRepository())),

        // Plan is regenerated whenever the profile changes.
        ChangeNotifierProxyProvider<OnboardingProvider, PlanProvider>(
          create: (_) => PlanProvider(storage),
          update: (_, onb, plan) => plan!..updateProfile(onb.profile),
        ),

        // Assistant gets a personalization brief from profile + plan.
        ChangeNotifierProxyProvider2<OnboardingProvider, PlanProvider,
            AssistantProvider>(
          create: (_) => AssistantProvider(_buildAssistantRepo()),
          update: (_, onb, plan, assistant) => assistant!
            ..setContext(
              CoachCopy.assistantBrief(onb.profile, plan.plan),
              name: onb.profile.name,
            ),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (_, theme, _) => MaterialApp(
          title: 'Fitify',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.current,
          home: kSkipOnboarding ? const MainShell() : const WelcomeScreen(),
        ),
      ),
    );
  }
}
