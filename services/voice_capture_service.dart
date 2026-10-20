import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class VoiceCaptureService {
  static final VoiceCaptureService _instance = VoiceCaptureService._internal();
  factory VoiceCaptureService() => _instance;
  VoiceCaptureService._internal();

  SpeechToText? _speech;
  bool _isInitialized = false;
  bool _isListening = false;
  String _capturedText = '';
  Timer? _silenceTimer;

  // Voice capture states
  final ValueNotifier<bool> isListening = ValueNotifier(false);
  final ValueNotifier<String> capturedText = ValueNotifier('');
  final ValueNotifier<String> status = ValueNotifier('Ready to capture');

  // Initialize voice capture
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      var permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        status.value = 'Microphone permission denied';
        return false;
      }

      _speech = SpeechToText();
      _isInitialized = await _speech!.initialize(
        onError: (error) {
          print('Voice capture error: $error');
          status.value = 'Error: ${error.errorMsg}';
          _stopListening();
        },
        onStatus: (status) {
          print('Voice status: $status');
          if (status == 'done' || status == 'notListening') {
            _stopListening();
          }
        },
      );

      if (_isInitialized) {
        status.value = 'Voice capture ready';
        print('✅ Voice capture initialized successfully');
      } else {
        status.value = 'Failed to initialize voice capture';
      }

      return _isInitialized;
    } catch (e) {
      print('❌ Voice initialization error: $e');
      status.value = 'Initialization failed: $e';
      return false;
    }
  }

  // Start voice capture
  Future<void> startListening() async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) {
      print('Already listening...');
      return;
    }

    try {
      _isListening = true;
      isListening.value = true;
      status.value = 'Listening...';

      await _speech!.listen(
        onResult: (result) {
          _capturedText = result.recognizedWords;
          capturedText.value = _capturedText;
          
          // Reset silence timer on each result
          _resetSilenceTimer();
          
          print('🎤 Captured: $_capturedText');
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        onSoundLevelChange: (level) {
          // Optional: Handle sound level changes
        },
        onDevice: true,
      );

      // Start silence detection timer
      _resetSilenceTimer();
    } catch (e) {
      print('❌ Voice capture error: $e');
      status.value = 'Capture failed: $e';
      _stopListening();
    }
  }

  // Stop voice capture
  Future<void> stopListening() async {
    if (_speech != null && _isListening) {
      await _speech!.stop();
    }
    _stopListening();
  }

  // Internal stop listening method
  void _stopListening() {
    _isListening = false;
    isListening.value = false;
    _silenceTimer?.cancel();
    status.value = 'Capture complete';
  }

  // Reset silence timer (auto-stop after 5 seconds of silence)
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (_isListening) {
        print('⏰ Auto-stopping due to silence');
        stopListening();
      }
    });
  }

  // Clear captured text
  void clearCapturedText() {
    _capturedText = '';
    capturedText.value = '';
    status.value = 'Ready to capture';
  }

  // Get captured text
  String get currentText => _capturedText;

  // Dispose resources
  void dispose() {
    _silenceTimer?.cancel();
    _speech?.stop();
    isListening.dispose();
    capturedText.dispose();
    status.dispose();
  }
}

// Voice capture widget for UI
class VoiceCaptureWidget extends StatefulWidget {
  final Function(String) onVoiceCaptured;
  final String? hintText;
  final bool showStatus;

  const VoiceCaptureWidget({
    Key? key,
    required this.onVoiceCaptured,
    this.hintText,
    this.showStatus = true,
  }) : super(key: key);

  @override
  State<VoiceCaptureWidget> createState() => _VoiceCaptureWidgetState();
}

class _VoiceCaptureWidgetState extends State<VoiceCaptureWidget> {
  final VoiceCaptureService _voiceService = VoiceCaptureService();

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice capture button
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _voiceService.isListening,
                builder: (context, isListening, child) {
                  return GestureDetector(
                    onTap: isListening 
                        ? _voiceService.stopListening 
                        : _voiceService.startListening,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isListening ? Colors.red : Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening ? Colors.red : Colors.blue).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hintText ?? 'Tap to capture voice',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (widget.showStatus)
                      ValueListenableBuilder<String>(
                        valueListenable: _voiceService.status,
                        builder: (context, status, child) {
                          return Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: status.contains('Error') ? Colors.red : Colors.grey[500],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Captured text display
          ValueListenableBuilder<String>(
            valueListenable: _voiceService.capturedText,
            builder: (context, capturedText, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Captured Text:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capturedText.isEmpty ? 'No voice captured yet' : capturedText,
                      style: TextStyle(
                        fontSize: 16,
                        color: capturedText.isEmpty ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final text = _voiceService.currentText;
                    if (text.isNotEmpty) {
                      widget.onVoiceCaptured(text);
                      _voiceService.clearCapturedText();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Use This Text'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _voiceService.clearCapturedText,
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
