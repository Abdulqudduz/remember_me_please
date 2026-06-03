# iOS Configuration Report

Based on a thorough inspection of your project (`pubspec.yaml`, `ios/Runner/Info.plist`, and `ios/Runner/AppDelegate.swift`), the following iOS configurations are required by the installed packages to build, run, and function correctly on iOS. All necessary changes have been generated or already applied to your files.

## Summary of Applied Changes
- **`ios/Runner/Info.plist`**: Added missing camera, photo library, apple music, and speech recognition permissions. Configured background modes (`fetch`, `processing`, `audio`, `remote-notification`).
- **`ios/Runner/AppDelegate.swift`**: Imported `flutter_downloader` and added the plugin registrant callback required for background downloading.

## Package-by-Package Report

### 1. `image_picker`
- **Required Configuration:** `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`.
- **Current Status:** Configured (Applied automatically).
- **Changes Needed:** Added the following keys to `Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need access to your camera to take pictures and detect faces.</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need access to your photo library to pick images.</string>
  ```

### 2. `camera`
- **Required Configuration:** `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`.
- **Current Status:** Configured (Applied automatically).
- **Changes Needed:** Met by the `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` entries in `Info.plist`.

### 3. `file_picker`
- **Required Configuration:** Background modes (`fetch`, `remote-notification`) for background picking, `NSPhotoLibraryUsageDescription` for images/video, `NSAppleMusicUsageDescription` for audio files.
- **Current Status:** Configured (Applied automatically).
- **Changes Needed:** Added `NSAppleMusicUsageDescription` and updated `UIBackgroundModes` in `Info.plist`.

### 4. `speech_to_text`
- **Required Configuration:** `NSSpeechRecognitionUsageDescription`, `NSMicrophoneUsageDescription`.
- **Current Status:** Configured (Applied automatically).
- **Changes Needed:** Added the following key to `Info.plist`:
  ```xml
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>We need access to speech recognition to convert your voice into text.</string>
  ```

### 5. `record`
- **Required Configuration:** `NSMicrophoneUsageDescription`.
- **Current Status:** Configured (Already present, updated description).
- **Changes Needed:** Updated the existing `NSMicrophoneUsageDescription` to be comprehensive.

### 6. `flutter_downloader`
- **Required Configuration:** `AppDelegate.swift` setup, Background Modes (`fetch`, `processing`), `libsqlite3` in Xcode.
- **Current Status:** Mostly Configured (Code added automatically; Xcode step pending).
- **Changes Needed:** 
  1. Updated `AppDelegate.swift` with:
     ```swift
     import flutter_downloader
     
     // inside didFinishLaunchingWithOptions:
     FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
     
     // At the bottom of the file:
     private func registerPlugins(registry: FlutterPluginRegistry) {
         if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
            FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
         }
     }
     ```
  2. Added `fetch` and `processing` to `UIBackgroundModes` in `Info.plist`.
  3. **Manual Action Needed:** Open Xcode (`ios/Runner.xcworkspace`), go to the Target's General tab, and under "Frameworks, Libraries, and Embedded Content", add `libsqlite3.0.tbd` or `libsqlite3.tbd`.

### 7. `audioplayers`
- **Required Configuration:** Background Audio capability (if playing in background).
- **Current Status:** Configured (Applied automatically).
- **Changes Needed:** Added `audio` to `UIBackgroundModes` in `Info.plist`.

### 8. `google_mlkit_face_detection`
- **Required Configuration:** Minimum iOS Deployment Target `15.5`. 64-bit architecture only (x86_64, arm64).
- **Current Status:** Pending (Requires `Podfile` generation).
- **Changes Needed:** 
  Since you haven't run `flutter build ios` or `pod install` yet, the `ios/Podfile` does not exist. Once it is generated, you **must** update it manually.
  Open `ios/Podfile` and change:
  ```ruby
  # platform :ios, '11.0'
  ```
  To:
  ```ruby
  platform :ios, '15.5'
  ```
  You must also exclude the `armv7` architecture in your Xcode Build Settings or within the Podfile `post_install` block.

### 9. `flutter_web_auth_2`
- **Required Configuration:** Minimum iOS Deployment Target `11.0` (or `12.0` depending on ASWebAuthenticationSession). URL Scheme registration is **not required** because it relies on ASWebAuthenticationSession.
- **Current Status:** Configured. No special setup needed in `Info.plist`.

### 10. `flutter_tts`, `sherpa_onnx`, `whisper_ggml_plus`
- **Required Configuration:** Access to microphone for STT. (Already covered). Background Audio if outputting TTS in background (Covered).
- **Current Status:** Configured.

### 11. Other Packages (e.g., `provider`, `objectbox`, `shared_preferences`, `crypto`)
- **Required Configuration:** None specific to iOS outside standard Flutter support.

---

## Action Items Before You Build for iOS
1. Run `flutter build ios --config-only` to generate the `ios/Podfile` (if not done yet).
2. Edit the newly generated `ios/Podfile` to uncomment and set `platform :ios, '15.5'`.
3. Open `ios/Runner.xcworkspace` in Xcode, and ensure `libsqlite3.tbd` (or `libsqlite3.0.tbd`) is added to "Frameworks, Libraries, and Embedded Content" for the `flutter_downloader` package.
4. Test the app on an iOS 15.5+ physical device or simulator.
