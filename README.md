# Assist Dysarthria
Assist Dysarthria is a Flutter application designed to aid individuals with dysarthria by providing features for audio recording, audio file selection, speech-to-text transcription, and text-to-speech conversion.
## Features
- **Record Audio:** Record audio directly within the application.
- **Select Audio File:** Choose an existing audio file from the device.
- **Transcribe Audio:** Send recorded or selected audio to a server for transcription.
- **Text-to-Speech:** Convert entered text to speech using a text-to-speech engine.
## Screen Short
  ![dysarthria](https://github.com/Mohsin0855/Assist-Dysarthria/assets/60180890/dd00fedd-44a9-4be1-b3f7-5e0671857934)

## Usage
1. Recording Audio:
- Tap the microphone icon to start recording.
- Tap the stop icon to stop recording.
- The recorded audio will be sent to the server for transcription and prediction.

2. Selecting an Audio File:
- Tap the file icon to open the file picker.
- Select an audio file from your device.
- The selected audio will be sent to the server for transcription and prediction.

3. Text-to-Speech:
- Enter text in the provided text field.
- Tap the speaker icon to hear the text spoken aloud.
## API Endpoints
- **Transcription API: https://dysarthiaapp.pythonanywhere.com/transcribe**
- **Prediction API: https://0052-111-68-97-103.ngrok-free.app/predict**
