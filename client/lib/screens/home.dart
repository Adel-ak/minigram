import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_101/Components/post.dart';
import 'package:flutter_101/Firebase/firestore.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import '../GStyle.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _hasMore = true;
  bool _loading = false;
  List<dynamic> _posts;
  String _error;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      fetchPosts(null).then((posts) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      });
    });

    super.initState();
  }

  removeItemFromPosts(postId) {
    var filteredPosts =
        _posts.where((element) => element['_id'] != postId).toList();
    setState(() {
      if (filteredPosts.length < _posts.length) {
        _posts = filteredPosts;
      }
    });
  }

  Future<void> refresh() async {
    try {
      setState(() {
        _posts = null;
      });
      var res = await fetchPosts(null);
      setState(() {
        _posts = res;
        _loading = false;
      });
    } catch (error) {}
  }

  void fetchMorePost() async {
    try {
      var res = await fetchPosts(_posts.last['_id']);

      setState(() {
        _posts.addAll(res);
        _loading = false;
        if (res.length == 0 || res.length < 11) {
          _hasMore = false;
        }
      });
    } catch (error) {}
  }

  Future<List<dynamic>> fetchPosts(String startAt) async {
    QueryOptions options = QueryOptions(document: gql("""
     query GetPosts(\$startAt: ID){
        getPosts(startAt: \$startAt) {
        _id
        user {
          uid
          displayName
          avatar
        }
        images
        caption
        createdDate
        }
      }
    """), variables: {"startAt": startAt}, fetchPolicy: FetchPolicy.noCache);
    try {
      setState(() {
        _loading = true;
      });
      GraphQLClient client = Provider.of<GraphQLClient>(context, listen: false);

      QueryResult res = await client.query(options);

      if (res.hasException) throw res.exception;
      return res.data['getPosts'];
    } on OperationException catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Gs().secondaryColor,
          child: Icon(
            Icons.add,
            size: 30,
            color: Gs().primaryColor,
          ),
          onPressed: () {
            Navigator.of(context).pushNamed('imageSelection');
          },
        ),
        backgroundColor: Gs().primaryColor,
        appBar: AppBar(
          elevation: 5,
          backgroundColor: Gs().secondaryColor,
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Gs().primaryColor,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, 'login', (route) => false);
              },
            )
          ],
          leadingWidth: ((60 + 10) / 1),
          leading: Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 10),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, 'profile');
              },
              child: Hero(
                tag: 'dp',
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage:
                      NetworkImage(FirebaseAuth.instance.currentUser.photoURL),
                ),
              ),
            ),
          ),
        ),
        body: Builder(
          builder: (_) {
            if (_posts == null) {
              return Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
              ));
            }

            var dataLength = _posts.length;

            return RefreshIndicator(
                color: Gs().textColor,
                onRefresh: () async {
                  await refresh();
                },
                child: dataLength > 0
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: (dataLength + 1),
                        itemBuilder: (context, index) {
                          if (index >= _posts.length) {
                            // Don't trigger if one async loading is already under way
                            if (!_hasMore) {
                              return Container(
                                height: 0,
                              );
                            }

                            if (!_loading && _hasMore) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                fetchMorePost();
                              });
                            }

                            return Container(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Gs().secondaryColor),
                                  ),
                                ));
                          }

                          var post = _posts[index];
                          String caption = post['caption'];
                          String postId = post['_id'];
                          List<dynamic> images = post['images'];
                          String createdDate = post['createdDate'];
                          String userAvatar = post['user']['avatar'];
                          String userName = post['user']['displayName'];
                          String userUid = post['user']['uid'];

                          return PostCard(
                            key: ObjectKey('$index-$userUid'),
                            postId: postId,
                            images: images,
                            caption: caption,
                            userName: userName,
                            userUid: userUid,
                            userAvatar: userAvatar,
                            createdDate: createdDate,
                            removeItemFromPosts: removeItemFromPosts,
                          );
                        })
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'No posts found :(',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Divider(
                              height: 20,
                            ),
                            TextButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Gs().secondaryColor)),
                              onPressed: () async {
                                await refresh();
                              },
                              child: Text(
                                "Click here to refresh",
                                style: TextStyle(
                                    color: Gs().primaryColor, fontSize: 20),
                              ),
                            )
                          ],
                        ),
                      ));
          },
        )

        // Query(
        //   options: options,
        //   builder:
        // ),
        );
  }
}
