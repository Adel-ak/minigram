import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class Auth {
  final FirebaseAuth auth;
  dynamic user = FirebaseAuth.instance.currentUser;
  Auth({this.auth});

  Stream<User> get authStateChanges => auth.authStateChanges();

  Future<UserCredential> signIn({email, password}) async {
    try {
      return await auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (error) {}
  }

  Future<UserCredential> signUp({email, password}) async {
    var user = await auth.createUserWithEmailAndPassword(
        email: email, password: password);

    return user;
  }

  set authUser(fbUser) {
    user = fbUser;
  }
}

Future<QueryResult> signUp(
    {GraphQLClient client, Map<String, dynamic> variables}) async {
  try {
    String document = """
      mutation SignUp(\$form: UserFormInput){
        signUp(form: \$form)
      }
    """;

    MutationOptions options = MutationOptions(
        document: gql(document), variables: {'form': variables ?? {}});
    var res = await client.mutate(options);

    return res;
  } catch (error) {}
}
