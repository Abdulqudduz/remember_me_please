
# RememberMePlease 🧠 
**The 100% Offline Cognitive Companion**

[![Gemma 4 Good Hackathon](https://img.shields.io/badge/Hackathon-Gemma_4_Good-blue)](https://kaggle.com)
[![Flutter](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Local AI](https://img.shields.io/badge/AI-100%25_Offline-success)](#)

*A privacy-first, fully local AI assistant that securely captures, identifies, and summarizes daily conversations to empower individuals living with Mild Cognitive Impairment (MCI).*

🎥 **[Watch the 3-Minute Demo Video Here]https://m.youtube.com/shorts/SBJAksCpoHU

---

## The Vision: Privacy as a Human Right
Standard cloud-based AI tools are highly capable, but they fail vulnerable users in two critical areas: they require an uninterrupted internet connection, and they force users to upload highly intimate, everyday family conversations to remote servers. 

**RememberMe** was engineered to solve this. It functions as a fully autonomous edge companion. By bringing the entire computational pipeline—audio transcription, speaker diarization, face tracking, and RAG synthesis—directly onto the device, we ensure that personal data never leaves the local hardware.

---

## Core Features & Engineering ⚙️

### 1. Multi-Modal Identity Mapping ("Who Said What")
A raw, un-attributed text block introduces cognitive load. RememberMe bridges audio separation with a visual tracking intercept to identify speakers locally.
* **Audio:** On-device `sherpa-onnx` diarization partitions the acoustic timeline.
* **Vision:** Google ML Kit Face Detection continuously scans the camera frame, matching faces against local database profiles.
* **Synthesis:** Both streams are fed to **Gemma 4**, which dynamically replaces generic speaker tags with the actual names of the participants in the finalized summary.

### 2. Isolate-Driven Audio Processing
Running Whisper text transcription and diarization on a mobile device natively causes severe UI freezing. 
* The entire audio analysis layer operates within background **Flutter Isolates**.
* The main UI thread renders flawlessly at 60 FPS while heavy mathematical computations for Whisper inference run entirely in the background, ensuring a zero-friction experience for the user.

### 3. Pipeline Short-Circuit Guards
To protect battery life and prevent the local database from clogging with silent recordings, the app utilizes an empty-audio short-circuit guard.
* Before waking the AI models, the system samples the audio file's RMS amplitude.
* If the signal registers below a strict voice activity threshold, the pipeline halts immediately and clears the cache, saving significant CPU cycles.

### 4. Offline Empathetic Text-to-Speech (TTS)
Native mobile OS voices are robotic and can cause anxiety for users with cognitive decline. RememberMe utilizes a human-sounding, emotive voice completely offline.
* Integrates a quantized **Kokoro 8-bit ONNX** engine.
* Bypasses strict asset-bundle limits by extracting multi-gigabyte neural networks directly into the application's secure documents directory, safely loading emotive voice models straight into RAM via native C-bindings.

---

## Tech Stack 🛠️

* **Frontend:** Flutter & Dart (Provider state management)
* **Local Intelligence (LLM):** Gemma 4 (On-device RAG Engine)
* **Speech-to-Text:** Local Whisper Isolate
* **Speaker Diarization:** Sherpa ONNX
* **Vision / Face Tracking:** Google ML Kit
* **Text-to-Speech:** Kokoro 8-bit ONNX
* **Database:** ObjectBox (NoSQL Edge Database)

---

## Getting Started 🚀

### Prerequisites
* Flutter SDK (`>=3.0.0`)
* A physical Android or iOS device (Emulators lack the hardware acceleration required for fluid local inference).

### Installation
1. **Clone the repo:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/remember-me-please.git](https://github.com/YOUR_USERNAME/remember-me-please.git)
   cd remember-me-please

```

2. **Install dependencies:**
```bash
flutter pub get

```


3. **Generate ObjectBox Bindings:**
```bash
dart run build_runner build --delete-conflicting-outputs

```


4. **Model Setup (CRITICAL):**

Upon launching the app for the first time, complete the onboarding process, after which you will be automatically navigated to the Download Page
 * Download the required quantized weights.
 * Download the `gemma-4-E2B-it-litert-lm model`, or Import it if you already have it saved on your device.
 * Once the Gemma weight is loaded, the app will automatically download the remaining 264 MB additional model files required to
function.


5. **Run the app:**
```bash
flutter build apk --release --target-platform android-arm64

```


*(Note: Always run in `--release` mode for accurate AI inference profiling).*

---

## Hackathon Submission

This project was built for the **Gemma 4 Good Hackathon**.

**Track:** Impact Track / Special Technology Track

**Focus:** On-device AI, Edge Computing, Cognitive Accessibility.

---

## License 📄

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

```

```
