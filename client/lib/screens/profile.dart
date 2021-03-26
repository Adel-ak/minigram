import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_101/gql/post.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:interpolate/interpolate.dart';
import 'package:flutter_101/Components/post.dart';
import 'package:provider/provider.dart';
import '../GStyle.dart';

class Profile extends StatefulWidget {
  final String heroTag;
  final String avatar;
  final String userUid;
  final String userName;
  Profile({Key key, this.heroTag, this.avatar, this.userUid, this.userName})
      : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ScrollController _sc = ScrollController();
  List<dynamic> posts;
  int _gridNum = 3;
  bool _loading = false;
  Map _removing = {};

  setGird(number) {
    setState(() {
      _gridNum = number;
    });
  }

  Widget buildImage(imagesUri) {
    return Container(
        margin: EdgeInsets.zero,
        color: Colors.black,
        child: CachedNetworkImage(
          fit: _gridNum != 1 ? BoxFit.cover : BoxFit.contain,
          imageUrl: imagesUri,
          progressIndicatorBuilder: (context, url, downloadProgress) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
            ),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ));
  }

  downloadImage(imageUri) async {
    Fluttertoast.showToast(
      msg: "Downloading",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );

    var imageId = await ImageDownloader.downloadImage(imageUri);
    Fluttertoast.cancel();
    if (imageId == null) {
      Fluttertoast.showToast(
        msg: "Download failed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Saved",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  _showBottomSheet(context, String image, userUid, postId, callBack) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,

        // isScrollControlled: true,
        context: context,
        builder: (context) {
          User currentUser = FirebaseAuth.instance.currentUser;

          double statusBarHeigth = MediaQuery.of(context).padding.top;

          double screenHeigth =
              MediaQuery.of(context).size.height - statusBarHeigth;

          return Container(
              color: Gs().primaryColor,
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Icon(Icons.horizontal_rule_rounded),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20))),
                  ),
                  Expanded(
                      child: Container(
                          margin: EdgeInsets.zero,
                          color: Colors.black,
                          child: CachedNetworkImage(
                            fit: BoxFit.contain,
                            imageUrl: image,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Gs().secondaryColor),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ))),
                  Container(
                      color: Gs().primaryColor,
                      width: MediaQuery.of(context).size.width,
                      child: TextButton(
                        child: Text(
                          'Save image',
                          style: TextStyle(
                              color: Gs().secondaryColor, fontSize: 18),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          downloadImage(image);
                        },
                      )),
                  currentUser != null && currentUser.uid == userUid
                      ? Container(
                          padding: EdgeInsets.zero,
                          color: Gs().primaryColor,
                          width: MediaQuery.of(context).size.width,
                          child: TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red)),
                            child: Text(
                              'Delete',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            onPressed: () {
                              var client = Provider.of<GraphQLClient>(context,
                                  listen: false);
                              setState(() {
                                // _loading = true;
                                _removing.addAll({postId: true});
                              });
                              deletePost(
                                  client: client,
                                  variables: {'docId': postId}).then((res) {
                                if (res) {
                                  callBack();
                                } else {
                                  setState(() {
                                    _removing.remove(postId);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Cant delete at the moment 😵')));
                                }
                              }).catchError((error) {
                                setState(() {
                                  _removing.remove(postId);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Cant delete at the moment 😵')));
                              });

                              Navigator.pop(context);
                            },
                          ))
                      : Container()
                ],
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String userUid = widget.userUid != null
        ? widget.userUid
        : FirebaseAuth.instance.currentUser.uid;

    QueryOptions options = QueryOptions(document: gql("""
     query GetPosts(\$startAt: ID, \$uid : ID){
        getUserPosts(uid:\$uid, startAt: \$startAt) {
            posts {
            createdDate
            files {
              type
              uri
            }
            uid
            _id
            user {
              displayName
              avatar
            }
          }
        }
      }
      """), variables: {'uid': userUid}, fetchPolicy: FetchPolicy.networkOnly);

    return Scaffold(
        backgroundColor: Gs().primaryColor,
        body: Query(
            options: options,
            builder: (QueryResult res, {fetchMore, refetch}) {
              var data =
                  res.data != null ? res.data['getUserPosts']["posts"] : null;

              return Column(children: [
                Expanded(
                    child: CustomScrollView(
                  controller: _sc,
                  slivers: [
                    SliverAppBar(
                      elevation: 0,
                      brightness: Brightness.light,
                      backgroundColor: Gs().secondaryColor,
                      expandedHeight: MediaQuery.of(context).size.height / 3.5,
                      collapsedHeight: kToolbarHeight,
                      pinned: true,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Gs().primaryColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 25,
                      ),
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
                      flexibleSpace: Center(
                        child: HeaderAppBar(
                          sc: _sc,
                          heroTag: widget.heroTag,
                          avatar: widget.avatar,
                          userName: widget.userName,
                        ),
                      ),
                    ),
                    SliverAppBar(
                      toolbarHeight: MediaQuery.of(context).padding.top,
                      backgroundColor: Gs().secondaryColor,
                      automaticallyImplyLeading: false,
                      flexibleSpace: Row(
                        children: [
                          IconButton(
                              icon: Icon(Icons.grid_off),
                              onPressed: () => setGird(1)),
                          IconButton(
                              icon: Icon(Icons.grid_view),
                              onPressed: () => setGird(3))
                        ],
                      ),
                    ),
                    data != null
                        ? SliverGrid(
                            delegate: SliverChildBuilderDelegate((_, index) {
                              return Container(
                                  margin: _gridNum == 1
                                      ? EdgeInsets.only(top: 10)
                                      : null,
                                  child: Builder(
                                      builder: (BuildContext context) =>
                                          !_removing.containsKey(
                                                  data[index]['_id'])
                                              ? InkWell(
                                                  child: buildImage(data[index]
                                                      ['files'][0]['uri']),
                                                  onTap: () => _showBottomSheet(
                                                      context,
                                                      data[index]['files'][0]
                                                          ['uri'],
                                                      data[index]['uid'],
                                                      data[index]['_id'],
                                                      () async {
                                                    await refetch();
                                                  }),
                                                )
                                              : Loading()));
                            }, childCount: data.length),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: screenWidth / _gridNum,
                                    childAspectRatio: 100 / 100,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2),
                          )
                        : SliverFillRemaining(
                            child: Loading(),
                          )
                  ],
                ))
              ]);
            }));
  }
}

class Loading extends StatelessWidget {
  Widget build(context) {
    return Container(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
          ),
        ));
  }
}

class HeaderAppBar extends StatelessWidget {
  final ScrollController sc;
  final String heroTag;
  final String avatar;
  final String userName;
  HeaderAppBar({this.sc, this.heroTag, this.avatar, this.userName});

  @override
  Widget build(context) {
    return AnimatedBuilder(
        animation: sc,
        builder: (_, __) {
          double screenWidth = MediaQuery.of(context).size.width;
          double imageSize = 180 - sc.offset;

          Interpolate interpolateRightAvatar = Interpolate(
            inputRange: [0, 150],
            outputRange: [(screenWidth / 3.5), (screenWidth - 90)],
            extrapolate: Extrapolate.clamp,
          );

          Interpolate interpolateBottomAvatar = Interpolate(
            inputRange: [0, 150],
            outputRange: [40, 8],
            extrapolate: Extrapolate.clamp,
          );

          Interpolate interpolateRightUserName = Interpolate(
            inputRange: [0, 150],
            outputRange: [10, 15],
            extrapolate: Extrapolate.clamp,
          );

          String displayName = userName != null
              ? '@$userName'
              : '@${FirebaseAuth.instance.currentUser.displayName}';

          return Stack(
            children: [
              Positioned(
                  bottom: interpolateRightUserName.eval(sc.offset),
                  left: 0,
                  right: 0,
                  child: Align(
                      child: Text(displayName,
                          style: TextStyle(
                              color: Gs().textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500)))),
              Positioned(
                  bottom: interpolateBottomAvatar.eval(sc.offset),
                  right: interpolateRightAvatar.eval(sc.offset),
                  child: Container(
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    width: imageSize < 40 ? 40 : imageSize,
                    height: imageSize < 40 ? 40 : imageSize,
                    child: Hero(
                        tag: heroTag != null ? heroTag : 'dp',
                        child: CachedNetworkImage(
                          imageUrl: avatar != null
                              ? avatar
                              : FirebaseAuth.instance.currentUser.photoURL,
                          imageBuilder: (_, imageProvider) {
                            return CircleAvatar(
                                backgroundImage: imageProvider,
                                backgroundColor: Colors.black);
                          },
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Gs().secondaryColor),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )),
                  )),
            ],
          );
        });
  }
}
