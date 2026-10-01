import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/backend_app.dart';
import 'firebase_options.dart';
import 'injection/app_dependencies.dart';
import 'injection/backend_data_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const backendUrl = String.fromEnvironment('CHAT_API_BASE_URL');
  if (backendUrl.isNotEmpty) {
    final dependencies = BackendDataDependencies.fromEnvironment();
    runApp(BackendChatApp(services: dependencies.appServices));
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final dependencies = AppDependencies.firebase();

  runApp(ChatApp(dependencies: dependencies));
}
