import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_101/Components/internetConnectivity.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_101/Firebase/auth.dart';
import 'package:flutter_101/routeGenerate.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'GStyle.dart';

class MyApp extends StatelessWidget {
  final GraphQLClient client;
  final FirebaseApp app;

  MyApp({this.client, this.app});

  Future<dynamic> serverHealth() async {
    final endpoint =
        kReleaseMode ? env["PROD_ENDPOINT"] : env["LOCAL_ENDPOINT"];
    var uriGet = (uri) => kReleaseMode
        ? Uri.https(uri, '/.well-known/apollo/server-health')
        : Uri.http(uri, '/.well-known/apollo/server-health');
    var endPoint = endpoint.replaceAllMapped(
        new RegExp(r'(.+\/\/)(.+)(\/.+)'), (Match m) => "${m[2]}");
    try {
      final response = await http.get(uriGet(endPoint));

      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        String status = jsonDecode(response.body)['status'];
        return status;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Server is down');
      }
    } catch (err) {}
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return InternetConnectivity(
        child: MultiProvider(
      providers: [
        Provider<GraphQLClient>(
          create: (_) => client,
        )
      ],
      child: FutureBuilder(
          future: Future.wait([Firebase.initializeApp(), serverHealth()]),
          builder: (_, AsyncSnapshot<dynamic> snapshot) {
            String serverStatus = snapshot.data != null ? snapshot.data[1] : '';
            if (snapshot.hasData && serverStatus == 'pass') {
              return GraphQLProvider(
                client: ValueNotifier(client),
                child: MultiProvider(
                  providers: [
                    Provider<Auth>(
                        create: (_) => Auth(auth: FirebaseAuth.instance)),
                    StreamProvider(
                        create: (ctx) => ctx.read<Auth>().authStateChanges,
                        initialData: null)
                  ],
                  builder: (ctx, _) => MaterialApp(
                    debugShowCheckedModeBanner: false,
                    initialRoute: 'home',
                    onGenerateRoute: (RouteSettings setting) =>
                        RouteGenerate.generateAuthRoute(setting, ctx),
                  ),
                ),

                // builder: (BuildContext context, Widget child) => child,
              );
            }

            if (serverStatus == 'fail') {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 80),
                alignment: Alignment.center,
                child: Text(
                  'It looks like we are facing issues from our end, place stand by.',
                  style: TextStyle(color: Colors.white),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Container(
              color: Gs().primaryColor,
              child: Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
              )),
            );
          }),
      builder: (_, child) => child,
    ));
  }
}
