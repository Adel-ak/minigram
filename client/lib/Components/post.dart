import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_101/gql/post.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../GStyle.dart';

class PostCard extends StatefulWidget {
  final List<dynamic> images;
  final String caption;
  final String userName;
  final String userUid;
  final String userAvatar;
  final String createdDate;
  final String postId;
  final Function removeItemFromPosts;

  PostCard({
    Key key,
    this.images,
    this.caption,
    this.userName,
    this.userUid,
    this.userAvatar,
    this.createdDate,
    this.postId,
    this.removeItemFromPosts,
  }) : super(key: key);

  _PostCard createState() => _PostCard();
}

class _PostCard extends State<PostCard> {
  bool _loading = false;

  showOptionSheet(context) {
    return (imageUri) => showModalBottomSheet(
          isScrollControlled: false,
          context: context,
          builder: (_) {
            User currentUser = FirebaseAuth.instance.currentUser;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
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
                Container(
                    color: Gs().primaryColor,
                    width: MediaQuery.of(context).size.width,
                    child: TextButton(
                      child: Text(
                        'Save image',
                        style:
                            TextStyle(color: Gs().secondaryColor, fontSize: 18),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        downloadImage(imageUri);
                      },
                    )),
                currentUser != null && currentUser.uid == widget.userUid
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
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          onPressed: () {
                            var client = Provider.of<GraphQLClient>(context,
                                listen: false);
                            setState(() {
                              _loading = true;
                            });
                            deletePost(
                                    client: client,
                                    variables: {'docId': widget.postId})
                                .then((res) {
                              if (res) {
                                widget.removeItemFromPosts(widget.postId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Cant delete at the moment 😵')));
                              }
                            }).catchError((error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Cant delete at the moment 😵')));
                            }).whenComplete(() {
                              if (mounted) {
                                setState(() {
                                  _loading = false;
                                });
                              }
                            });

                            Navigator.pop(context);
                          },
                        ))
                    : Container()
              ],
            );
          },
          backgroundColor: Colors.transparent,
        );
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

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        margin: EdgeInsets.only(top: 10, bottom: 0),
        child: AnimatedCrossFade(
          firstChild: Column(
            children: [
              UserInfo(
                  userName: widget.userName,
                  userAvatar: widget.userAvatar,
                  createdDate: widget.createdDate,
                  showOptionSheet: showOptionSheet(context),
                  imageUri: widget.images[0]),
              MyCarouselSlider(
                images: widget.images,
                caption: widget.caption,
              ),
              Align(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    child: Text(
                      widget.caption ?? '',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )),
                alignment: Alignment.centerLeft,
              ),
            ],
          ),
          secondChild: Loading(),
          crossFadeState:
              !_loading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: Duration(milliseconds: 200),
        ));
  }
}

class UserInfo extends StatelessWidget {
  final String userName;
  final String userAvatar;
  final String createdDate;
  final Function showOptionSheet;
  final String imageUri;

  UserInfo(
      {this.userName,
      this.userAvatar,
      this.createdDate,
      this.showOptionSheet,
      this.imageUri});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: userAvatar,
            imageBuilder: (_, imageProvider) {
              return CircleAvatar(
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.black);
            },
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
              ),
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          Divider(
            indent: 10,
          ),
          Padding(
              padding: EdgeInsets.only(top: 2),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                    Divider(
                      height: 3,
                    ),
                    Text(
                      createdDate != null
                          ? timeago.format(DateTime.parse(createdDate))
                          : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  ])),
          Expanded(
              child: Container(
            alignment: Alignment.centerRight,
            child: IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  showOptionSheet(imageUri);
                }),
          ))
        ],
      ),
    );
  }
}

class MyCarouselSlider extends StatefulWidget {
  final List<dynamic> images;
  final String caption;

  MyCarouselSlider({Key key, this.images, this.caption}) : super(key: key);

  @override
  _MyCarouselSliderState createState() => _MyCarouselSliderState();
}

class _MyCarouselSliderState extends State<MyCarouselSlider> {
  double _dotsIndicatorIndex = 0;
  void changeDotIndex(index) {
    setState(() {
      _dotsIndicatorIndex = index;
    });
  }

  Widget buildImage(imagesUri) {
    var screenHeigth = MediaQuery.of(context).size.height;
    return CachedNetworkImage(
      height: screenHeigth / 2.5,
      imageUrl: imagesUri,
      progressIndicatorBuilder: (context, url, downloadProgress) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showSlider = widget.images.length > 1;

    return Column(
      children: [
        false
            ? CarouselSlider.builder(
                options: CarouselOptions(
                    onPageChanged: (index, _) => changeDotIndex(index / 1),
                    viewportFraction: 1.0,
                    aspectRatio: 1,
                    pageSnapping: true,
                    enableInfiniteScroll: false),
                itemCount: widget.images.length,
                itemBuilder: (_, index, __) => buildImage(widget.images[index]),
              )
            : buildImage(widget.images[0]),
        // false
        //     ? Container(
        //         // color: Colors.white70,
        //         width: MediaQuery.of(context).size.width,
        //         child: DotsIndicator(
        //             dotsCount: widget.images.length,
        //             position: _dotsIndicatorIndex,
        //             decorator: DotsDecorator(
        //               activeSize: Size.square(8),
        //               size: Size.square(6),
        //               color: Colors.grey.shade800, // Inactive color
        //               activeColor: Gs().secondaryColor,
        //             )))
        //     : Container(),
      ],
    );
  }
}

class Loading extends StatelessWidget {
  Widget build(context) {
    return Container(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
          ),
        ));
  }
}
