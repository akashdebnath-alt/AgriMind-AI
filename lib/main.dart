import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/services/auth_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage.init();
  runApp(const AgriMindApp());
}
