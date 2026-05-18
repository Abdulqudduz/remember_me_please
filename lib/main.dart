import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/database/objectbox.dart';
import 'package:remember_me_please/core/providers/playback_provider.dart';
import 'package:remember_me_please/core/services/audio_player_service.dart';
import 'package:remember_me_please/core/services/tts_service.dart';
import 'package:remember_me_please/features/conversations/pages/provider/conversation_provider.dart';
import 'package:remember_me_please/features/llm_model_download/provider/llm_download_page_provider.dart';
import 'package:remember_me_please/core/providers/record_provider.dart';
import 'package:remember_me_please/core/services/audio_service.dart';
import 'package:remember_me_please/data/repositories/person_repository.dart';
import 'package:remember_me_please/data/sources/local/objectbox_service.dart';
import 'package:remember_me_please/features/people/providers/camera_view_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/providers/navigation_provider.dart';
import 'features/home/providers/reminder_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'features/people/providers/people_provider.dart';
import 'features/onboarding/pages/landing_page.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

ObjectBox? objectBox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  objectBox = await ObjectBox.create();
  sherpa_onnx.initBindings();
  try {
    await FlutterGemma.initialize();
  } catch (e) {
    debugPrint('FlutterGemma initialization error: $e');
  }

  // Initialize the offline TTS engine in the background.
  // The service is safe to call even when the Kokoro model folder is absent;
  // it will log a warning and remain in an uninitialised state until the
  // model is downloaded and the app is restarted.
  TtsService().init().catchError(
    (e) => debugPrint('TtsService startup error: $e'),
  );

  final ObjectBoxService objectBoxService = ObjectBoxService();
  final PersonRepository personRepository = PersonRepository(
    objectBoxservice: objectBoxService,
  );
  final AudioService audioService = AudioService();
  await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: true);

  runApp(
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
      child: const RememberMeApp(),
    ),
  );
}

class RememberMeApp extends StatelessWidget {
  const RememberMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mindful Sanctuary',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: languageProvider.locale,
      home: const LandingPage(),
    );
  }
}
