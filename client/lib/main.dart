import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'app.dart';
import 'gql/client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await initHiveForFlutter();
    await DotEnv.load(fileName: ".env");
    var client = await gqlClient();
    runApp(MyApp(client: client));
  } catch (error) {
    print(error);
  }
}
