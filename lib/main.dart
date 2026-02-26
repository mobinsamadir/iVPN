import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:hiddify/bootstrap.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:win32/win32.dart';

final _logFile = File('app_debug_log.txt');

void _log(String message, {bool isError = false}) {
  final timestamp = DateTime.now().toIso8601String();
  final logMsg = '[$timestamp] ${isError ? "[ERROR] " : ""}$message\n';

  try {
    _logFile.writeAsStringSync(logMsg, mode: FileMode.append);
  } catch (_) {}

  if (!kIsWeb && Platform.isWindows) {
    if (isError) {
      stderr.write(logMsg);
    } else {
      stdout.write(logMsg);
    }
  } else {
    debugPrint(message);
  }
}

Future<void> main() async {
  if (!kIsWeb && Platform.isWindows) {
    try {
      _logFile.writeAsStringSync('=== APPLICATION START ===\n', mode: FileMode.write);
      AttachConsole(ATTACH_PARENT_PROCESS);
      stdout.writeln('\n\n[FLUTTER START] Console Attached Successfully\n');
      _log('Console Attached Successfully');
    } catch (e) {
      _log('Failed to attach console or init log file: $e', isError: true);
    }
  }

  await runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    // final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
    // debugPaintSizeEnabled = true;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
    );

    _log('Bootstrap starting...');
    await lazyBootstrap(widgetsBinding, Environment.dev);
  }, (error, stack) {
    _log('Uncaught error: $error\n$stack', isError: true);
  });
}
