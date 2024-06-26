import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _filePath;
  double _currentPosition = 0;
  double _totalDuration = 0;
  bool _isLoading = false;
  String? _check;
  final picker = FilePicker.platform;
  PlatformFile? _pickedAudio;
  bool _fileChosen = false;

  @override
  void dispose() {
    _textEditingController.dispose(); // Dispose the text controller
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // tts function
  Future<void> speak(String text) async {
    // Speak the provided text
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "Assist Dysarthria",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _pickAudioFile,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(
                          top: 12,
                        ),
                        width: 100,
                        height: 35,
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.black),
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.file_copy),
                      ),
                      if (_pickedAudio != null)
                        Column(
                          children: [
                            Text(
                              "Chosen",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (_pickedAudio != null) {
                                  await sendRecordedAudioToAPI2(
                                      _pickedAudio!.path!);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                height: 30,
                                width: 70,
                                child: Center(
                                  // Show loader if _isLoading is true
                                  child: _isLoading
                                      ? CircularProgressIndicator()
                                      : Text(
                                          'Send',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Choose Audio File"),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else {
                      _startRecording();
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 30),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic_rounded,
                          size: 30,
                          color: _isRecording ? Colors.red : Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isRecording
                            ? Row(
                                children: [
                                  // Spacer
                                  Text(
                                    "Recording...",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              )
                            : _isLoading
                                ? CircularProgressIndicator() // Loader
                                : Text(
                                    "Tap to Record",
                                    style: TextStyle(color: Colors.black),
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              margin: EdgeInsets.all(30),
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  _check ?? "Prediction Label",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 1 / 3,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                            hintText: 'Enter your text here',
                          ),
                          onChanged: (text) {
                            // Handle text changes here if needed
                          },
                          enabled: !_isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              margin: EdgeInsets.all(8),
              height: 50,
              width: MediaQuery.of(context).size.width * 1.9 / 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: const Color.fromARGB(255, 216, 216, 216),
              ),
              child: TextButton.icon(
                onPressed: () {
                  // Check if _transcriptionText is not null before speaking
                  if (_textEditingController.text.isNotEmpty) {
                    speak(_textEditingController
                        .text); // Call the speak function with the entered text
                  } else {
                    print("No text to speak");
                  }
                },
                icon: Icon(
                  Icons.volume_up,
                  color: Colors.black,
                ),
                label: Text(
                  'Speaker',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Your existing methods...

  Future<void> _startRecording() async {
    final bool isPermissionGranted = await _recorder.hasPermission();
    if (!isPermissionGranted) {
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _filePath = '${directory.path}/$fileName';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _recorder.start(config, path: _filePath!);
    setState(() {
      _isRecording = true;
      _pickedAudio = null; // Reset picked audio
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _pickedAudio = null;
    });

    if (path != null) {
      await sendRecordedAudioToAPI(path); // Call sendRecordedAudioToAPI
      await sendRecordedAudioToAPI2(path); // Call sendRecordedAudioToAPI2
    }
  }

  Future<void> _pickAudioFile() async {
    final pickedAudio = await picker.pickFiles(type: FileType.audio);
    setState(() {
      _pickedAudio = pickedAudio?.files.first;
      _fileChosen = true; // Set file chosen status to true
    });

    // Call the method to send the recorded audio to the API
    if (_pickedAudio != null) {
      await sendRecordedAudioToAPI(_pickedAudio!.path!);
      await sendRecordedAudioToAPI2(_pickedAudio!.path!);
    }
  }

  // 1st API function
  Future<void> sendRecordedAudioToAPI(String? filePath) async {
    if (filePath == null) {
      print('Error: File path is null');
      return;
    }

    // Set _isLoading to true when sending the request
    setState(() {
      _isLoading = true;
    });

    // Create a multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://dysarthiaapp.pythonanywhere.com/transcribe'),
    );

    // Add the audio file to the request
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        // If the request is successful, read the response body asynchronously
        String responseBody = await response.stream.bytesToString();

        // Parse the JSON response
        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Extract the transcript from the JSON response
        String transcript = jsonResponse['transcript'];

        // Update the state with the received transcription text
        setState(() {
          _textEditingController.text = transcript;
        });
      } else {
        // If there's an error, print the error message
        print('Error: ${await response.stream.bytesToString()}');
      }
    } catch (e) {
      // If there's an exception, print the error
      print('Error sending audio: $e');
    } finally {
      // After receiving the response or in case of error, set _isLoading to false
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2nd API function
  Future<void> sendRecordedAudioToAPI2(String filePath) async {
    // Set _isLoading to true when sending the request
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://0052-111-68-97-103.ngrok-free.app/predict'),
      );

      // Add the audio file to the request
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      if (response.statusCode == 200) {
        // If the request is successful, read the response body asynchronously
        String responseBody = await response.stream.bytesToString();
        print('Response from API: $responseBody');

        // Parse the JSON response
        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Extract the prediction label from the JSON response
        String predictionLabel = jsonResponse['prediction'];

        // Update the state with the received prediction label
        setState(() {
          _check = predictionLabel;
        });
      } else {
        // If there's an error, print the error message
        print(
            'Error: ${response.statusCode} - ${await response.stream.bytesToString()}');
      }
    } catch (e) {
      // If there's an exception, print the error
      print('Error sending audio: $e');
    } finally {
      // After receiving the response or in case of error, set _isLoading to false
      setState(() {
        _isLoading = false;
      });
    }
  }
}
