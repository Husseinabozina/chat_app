import 'package:flutter/material.dart';

import 'app/backend_app.dart';
import 'injection/backend_data_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = BackendDataDependencies.fromEnvironment();
  runApp(BackendChatApp(services: dependencies.appServices));
}
