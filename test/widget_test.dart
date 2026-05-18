import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remember_me_please/main.dart' as app;
import 'package:remember_me_please/features/navigation/providers/navigation_provider.dart';
import 'package:remember_me_please/features/home/providers/reminder_provider.dart';
import 'package:remember_me_please/features/people/providers/people_provider.dart';
import 'package:remember_me_please/features/settings/providers/settings_provider.dart';
import 'package:remember_me_please/core/providers/theme_provider.dart';
import 'package:remember_me_please/core/providers/language_provider.dart';
import 'package:remember_me_please/core/providers/record_provider.dart';
import 'package:remember_me_please/features/llm_model_download/provider/llm_download_page_provider.dart';
import 'package:remember_me_please/features/conversations/pages/provider/conversation_provider.dart';
import 'package:remember_me_please/core/providers/playback_provider.dart';
import 'package:remember_me_please/features/people/providers/camera_view_provider.dart';
import 'package:remember_me_please/core/services/audio_service.dart';
import 'package:remember_me_please/core/services/audio_player_service.dart';
import 'package:remember_me_please/data/repositories/person_repository.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';

void main() {
  setUpAll(() async {
    // Mock SharedPreferences values before test initialization.
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });

    // Set objectBox to null to explicitly trigger the fallback stub mode
    // in ObjectBoxService for host/unit tests where libobjectbox is unavailable.
    app.objectBox = null;
  });

  testWidgets('HomePage smoke test with mocked services and providers', (WidgetTester tester) async {
    final objectBoxService = ObjectBoxService();
    final personRepository = PersonRepository(
      objectBoxservice: objectBoxService,
    );
    final audioService = AudioService();

    // Pump the app wrapped in the same MultiProvider list as main.dart to ensure
    // all page state dependencies are properly met.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => ReminderProvider()),
          ChangeNotifierProvider(
            create: (_) => PeopleProvider(personRepository: personRepository),
          ),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => RecordProvider(audioService)),
          ChangeNotifierProvider(create: (_) => LlmDownloadProvider()),
          ChangeNotifierProvider(create: (_) => ConversationProvider()),
          ChangeNotifierProvider(
            create: (_) => PlaybackProvider(AudioPlayerService()),
          ),
          ChangeNotifierProvider(
            create: (_) => CameraProvider(personRepository: personRepository),
          ),
        ],
        child: const app.RememberMeApp(),
      ),
    );

    // Allow the onboarding check timer and navigation transition to settle.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify that our HomePage content is successfully displayed.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
  });
}
