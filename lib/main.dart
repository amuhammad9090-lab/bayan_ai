import 'package:flutter/widgets.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = await AppDeps.init();
  runApp(BayanAiApp(deps: deps));
}
