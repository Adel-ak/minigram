import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<GraphQLClient> gqlClient() async {
  String websocketEndpoint;

  final _httpLink = HttpLink(
    kReleaseMode ? env["PROD_ENDPOINT"] : env["LOCAL_ENDPOINT"],
  );

  final _authLink = AuthLink(
    getToken: () async {
      try {
        User auth = FirebaseAuth.instance.currentUser;

        String token = auth != null ? await auth.getIdToken() : null;

        return 'Bearer $token';
      } catch (error) {
        return null;
      }
    },
  );
  Link _link = _authLink.concat(_httpLink);

  /// subscriptions must be split otherwise `HttpLink` will. swallow them
  if (websocketEndpoint != null) {
    final _wsLink = WebSocketLink(websocketEndpoint);
    _link = Link.split((request) => request.isSubscription, _wsLink, _link);
  }

  GraphQLClient client = GraphQLClient(
    link: _link,
    cache: GraphQLCache(),
  );

  return client;
}
