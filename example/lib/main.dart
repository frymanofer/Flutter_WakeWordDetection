import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io'; // Added this import
import 'package:flutter/services.dart';
import 'package:flutter_wake_word/flutter_wake_word.dart';
import 'package:flutter_wake_word/use_model.dart';
import 'package:flutter_wake_word/instance_config.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: const WakeWordApp()));
}

// Old way:
// final List<InstanceConfig> instanceConfigs = [
//   InstanceConfig(
//     id: 'hey_look_deep',
//     modelName: 'hey_lookdeep.onnx',
//     threshold: 0.999,
//     bufferCnt: 5,
//     sticky: false,
//   ),
// ];

// New Efficient way:
final MultiInstanceConfig multiInstanceConfig = MultiInstanceConfig(
  id: 'wakeword_group_1',
  modelNames: [
    'hey_lookdeep.onnx',
    'coca_cola_model_28_05052025.onnx',
    'need_help_now.onnx',
  ],
  thresholds: [0.999, 0.999, 0.999],
  bufferCnts: [4, 4, 4],
  msBetweenCallback: [1000, 1000, 1000],
  sticky: false,
);

const String _keywordDetectionLicense = String.fromEnvironment(
  'WAKE_WORD_LICENSE',
  defaultValue:
      'MTc4Mjg1MzIwMDAwMA==-QYH+tF+Y9UvHypFSSYJNi/RwYHcabxWtw/Ir3Y5CoI8=',
);

String message = _listeningMessage();

String _listeningMessage() {
  return 'Listening to WakeWords:\n${multiInstanceConfig.modelNames.map(_displayWakeWordName).join('\n')}';
}

String _displayWakeWordName(String modelName) {
  return modelName
      .replaceAll(RegExp(r'_model.*$'), '')
      .replaceAll(RegExp(r'_\d.*$'), '')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\.onnx'), '')
      .trim();
}

class WakeWordApp extends StatefulWidget {
  const WakeWordApp({super.key});

  @override
  State<WakeWordApp> createState() => _WakeWordAppState();
}

// We use a class just for clarity, or we can store a Map:
class _MemoryReading {
  final DateTime timestamp;
  final double memoryMB;
  _MemoryReading(this.timestamp, this.memoryMB);
}

class _WakeWordAppState extends State<WakeWordApp> {
  //String message = "Listening to WakeWord...";
  final _flutterWakeWordPlugin = FlutterWakeWord();
  bool isFlashing = false;
  bool _isListening = false;
  String _platformVersion = 'Unknown';
  final useModel = UseModel(); // Single instance of UseModel
  // START: Memory Monitoring Code
  // Inside your _WakeWordAppState:

  DateTime? _appStartTime; // When the app starts
  final List<_MemoryReading> _memoryReadings = [];
  Timer? _memoryTimer;

  void startMemoryMonitoring() {
    _appStartTime ??= DateTime.now();

    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = DateTime.now();
      final memoryUsageMB = ProcessInfo.currentRss / (1024 * 1024);

      // Record new reading
      _memoryReadings.add(_MemoryReading(now, memoryUsageMB));

      // --- 1) Print current memory usage first, short date/time
      final timeStamp = _simpleDateTime(now);
      debugPrint(
        "Curr-Mem Usg: ${memoryUsageMB.toStringAsFixed(2)}MB [$timeStamp]",
      );

      // --- 2) Last hour min/max + delta
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final lastHourReadings = _memoryReadings
          .where((r) => r.timestamp.isAfter(oneHourAgo))
          .toList();
      if (lastHourReadings.isNotEmpty) {
        final minLast = lastHourReadings
            .map((r) => r.memoryMB)
            .reduce((a, b) => a < b ? a : b);
        final maxLast = lastHourReadings
            .map((r) => r.memoryMB)
            .reduce((a, b) => a > b ? a : b);
        final minDelta = (memoryUsageMB - minLast).toStringAsFixed(2);
        final maxDelta = (memoryUsageMB - maxLast).toStringAsFixed(2);

        debugPrint(
          "Last hour Min:${minLast.toStringAsFixed(2)}MB "
          "Max:${maxLast.toStringAsFixed(2)}MB. "
          "Min delta ${minDelta}MB, Max delta ${maxDelta}MB",
        );
      } else {
        debugPrint("(No readings in the last hour yet.)");
      }

      // --- 3) The “InitMaxMin” window from 3 minutes to 13 minutes
      // i.e. we ignore everything before 3min or after 13min of app start
      final initMinStart = _appStartTime!.add(const Duration(minutes: 3));
      final initMinEnd = _appStartTime!.add(const Duration(minutes: 13));

      final initWindowReadings = _memoryReadings.where((r) {
        return r.timestamp.isAfter(initMinStart) &&
            r.timestamp.isBefore(initMinEnd);
      }).toList();

      // Show how long we've been running
      final startedAgo = now.difference(_appStartTime!);
      final startedAgoStr = _humanDuration(startedAgo);

      if (initWindowReadings.isNotEmpty) {
        final minInit = initWindowReadings
            .map((r) => r.memoryMB)
            .reduce((a, b) => a < b ? a : b);
        final maxInit = initWindowReadings
            .map((r) => r.memoryMB)
            .reduce((a, b) => a > b ? a : b);
        final minDeltaInit = (memoryUsageMB - minInit).toStringAsFixed(2);
        final maxDeltaInit = (memoryUsageMB - maxInit).toStringAsFixed(2);

        debugPrint(
          "InitMaxMin(3-13min), started $startedAgoStr ago. "
          "Min:${minInit.toStringAsFixed(2)}MB Max:${maxInit.toStringAsFixed(2)}MB. "
          "Min delta ${minDeltaInit}MB, Max delta ${maxDeltaInit}MB",
        );
      } else {
        debugPrint(
          "InitMaxMin(3-13min): no data in [3..13] min window yet (started $startedAgoStr ago).",
        );
      }
    });
  }

  /// Returns "YYYY-MM-DD HH:MM" from a DateTime
  String _simpleDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  /// Converts a Duration to a short "2h10m" or "5m30s" format
  String _humanDuration(Duration diff) {
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (hours > 0 && minutes > 0) {
      return "${hours}h${minutes}m";
    } else if (hours > 0) {
      return "${hours}h";
    } else if (minutes > 0 && seconds > 0) {
      return "${minutes}m${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m";
    } else {
      return "${seconds}s";
    }
  }

  @override
  void dispose() {
    _memoryTimer?.cancel(); // Stop monitoring when the widget is disposed
    super.dispose();
  }

  // END: Memory Monitoring Code

  Future<void> initializeKeywordDetection(MultiInstanceConfig config) async {
    try {
      _setMessage('Initializing wake word detector...');
      debugPrint("Initializing keyword detection with $useModel");

      await useModel.setKeywordDetectionLicense(_keywordDetectionLicense);

      debugPrint("After useModel.setKeywordDetectionLicense:");

      await useModel.addInstanceMulti(config, onWakeWordDetected);

      debugPrint("After useModel.addInstanceMulti:");
      _isListening = true;
      _setMessage(_listeningMessage());
    } on PlatformException catch (e) {
      _isListening = false;
      final errorMessage = e.code == 'LICENSE_NOT_VALID'
          ? 'Wake word detector is not active.\nLicense is invalid or expired.'
          : 'Wake word detector failed to start.\n${e.message ?? e.code}';
      debugPrint("Error initializing keyword detection: $e");
      _setMessage(errorMessage);
    } catch (e) {
      _isListening = false;
      debugPrint("Error initializing keyword detection: $e");
      _setMessage('Wake word detector failed to start.\n$e');
    }
  }

  void _setMessage(String newMessage) {
    message = newMessage;
    if (!mounted) {
      return;
    }
    setState(() {
      message = newMessage;
    });
  }

  Future<void> openSettings() async {
    if (await Permission.microphone.isPermanentlyDenied) {
      debugPrint('Microphone permission permanently denied.');
      await openAppSettings();
    } else {
      debugPrint('Microphone permission denied.');
    }
  }

  Future<void> requestAudioPermissions() async {
    var status = await Permission.microphone.status;
    final record = AudioRecorder();

    // Check and request permission if needed
    if (await record.hasPermission()) {
      debugPrint('record.hasPermission() true:');
    } else {
      debugPrint('record.hasPermission() false:');
    }

    if (status.isDenied) {
      debugPrint('No Microphone permission requesting:');
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      debugPrint('Microphone permission granted.');
      if (Platform.isAndroid) {
        var foregroundServicePermission = await Permission.systemAlertWindow
            .request();
        if (!foregroundServicePermission.isGranted) {
          foregroundServicePermission = await Permission.systemAlertWindow
              .request();
        }
      }
      await initializeKeywordDetection(multiInstanceConfig);
    } else {
      debugPrint('Microphone permission denied.');
      _setMessage(
        'Wake word detector is not active.\nMicrophone permission denied.',
      );
      openSettings();
    }
  }

  @override
  void initState() {
    super.initState();
    startMemoryMonitoring();
    initPlatformState();
    requestAudioPermissions();
  }

  void onWakeWordDetected(Map<String, dynamic> event) {
    final wakeWord = event['phrase'] as String?;
    var wakeWordDetected = '';
    if (wakeWord != null) {
      wakeWordDetected = _displayWakeWordName(wakeWord);

      debugPrint("onWakeWordDetected(): $wakeWordDetected");
      debugPrint("Calling stopListening(): $wakeWordDetected");
    } else {
      debugPrint("onWakeWordDetected(): Invalid event, 'phrase' key not found");
    }
    useModel.stopListening();
    _isListening = false;

    setState(() {
      message = "WakeWord '$wakeWordDetected' DETECTED";
      isFlashing = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      setState(() {
        useModel.startListening();
        _isListening = true;
        message = _listeningMessage();
        isFlashing = false;
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _flutterWakeWordPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isFlashing
        ? (isDarkMode ? Colors.red[400] : Colors.red[100])
        : (isDarkMode ? Colors.black : Colors.white);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey[800]!, Colors.grey[900]!]
                : [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          children: [
            Container(
              color: backgroundColor,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 20,
            ), // Add space between message and platform version
            Text(
              'Platform Version: $_platformVersion\nWake word: ${_isListening ? 'active' : 'inactive'}',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
