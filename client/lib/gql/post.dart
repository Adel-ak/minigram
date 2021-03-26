import 'package:graphql_flutter/graphql_flutter.dart';

Future<QueryResult> createPost(
    {GraphQLClient client, Map<String, dynamic> variables}) async {
  String document = """
      mutation CreatePost(\$form: NewPost){
        createPost(form: \$form)
      }
    """;

  MutationOptions options = MutationOptions(
      document: gql(document), variables: {'form': variables ?? {}});
  QueryResult res = await client.mutate(options);

  return res;
}

Future<bool> deletePost(
    {GraphQLClient client, Map<String, dynamic> variables}) async {
  String document = """
      mutation DeletePost(\$docId: ID){
        deletePost(docId: \$docId)
      }
    """;

  MutationOptions options =
      MutationOptions(document: gql(document), variables: variables ?? {});
  QueryResult res = await client.mutate(options);
  if (res.hasException) throw res.exception;
  return res.data['deletePost'];
}
