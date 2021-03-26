import 'dart:io';
import 'package:flutter_101/Firebase/storeage.dart';
import 'package:flutter_101/gql/post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_101/screens/imageSelection.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import '../GStyle.dart';

class NewPost extends StatefulWidget {
  Map file;
  NewPost({Key key, this.file}) : super(key: key);

  @override
  _NewPostState createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  List<Map> _files;
  List _thumbNail;
  TextEditingController captionController = TextEditingController(text: "");
  String _error;
  bool _loading = false;

  @override
  initState() {
    setState(() {
      _files = [widget.file];
    });
    onVideo();
    super.initState();
  }

  onVideo() async {
    if (widget.file['type'] == AssetType.video) {
      List thumbData = await widget.file['asset'].thumbData;
      setState(() {
        _thumbNail = thumbData;
      });
    }
  }

  Future makePost(client) async {
    try {
      setState(() {
        _loading = true;
      });
      var files = await uploadImages(_files);

      Map<String, dynamic> variables = {
        "files": files,
        "caption": captionController.text,
      };

      QueryResult res = await createPost(client: client, variables: variables);
      if (res.hasException) {
        throw res.exception;
      }
      return res.data['createPost'];
    } catch (error) {
      print('error -------- $error');

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeigth = MediaQuery.of(context).size.height;

    return GraphQLConsumer(builder: (client) {
      return Scaffold(
          floatingActionButton: AbsorbPointer(
              absorbing: _loading,
              child: FloatingActionButton(
                backgroundColor: Gs().secondaryColor,
                child: Icon(Icons.upload_rounded,
                    color: Gs().primaryColor, size: 30),
                onPressed: () {
                  makePost(client).then((res) {
                    if (res) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, 'home', (route) => false);
                    }
                  });
                },
              )),
          backgroundColor: Gs().primaryColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Gs().secondaryColor,
            leading: AbsorbPointer(
                absorbing: _loading,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Gs().primaryColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                  iconSize: 25,
                )),
            flexibleSpace: Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(
                  left: 35, top: MediaQuery.of(context).padding.top),
              child: TextButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, 'profile');
                },
                child: Hero(
                  tag: 'dp',
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    backgroundImage: NetworkImage(
                        FirebaseAuth.instance.currentUser.photoURL),
                  ),
                ),
              ),
            ),
          ),
          body: Container(
              child: !_loading
                  ? ListView(children: [
                      Container(
                          height: 200,
                          child: ListView(
                            shrinkWrap: false,
                            scrollDirection: Axis.horizontal,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                    padding: EdgeInsets.only(left: 20, top: 20),
                                    child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child:
                                            _files[0]['type'] == AssetType.image
                                                ? Image.file(_files[0]['path'],
                                                    height: 200,
                                                    width: 200,
                                                    fit: BoxFit.cover)
                                                : _thumbNail != null
                                                    ? Container(
                                                        color: Colors.red,
                                                        height: 200,
                                                        width: 200,
                                                        child: VideoThumbNail(
                                                          isSelected: false,
                                                          onClick: () => null,
                                                          thumbNail: _thumbNail,
                                                        ))
                                                    : Container())),
                              ),
                            ],
                          )),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                            padding: EdgeInsets.all(15),
                            child: TextField(
                              controller: captionController,
                              maxLines: 10,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                    borderSide: BorderSide(
                                      color: Gs().secondaryColor,
                                    )),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                    borderSide: BorderSide(
                                      color: Gs().primaryColor,
                                    )),
                                hintText: "Enter text here...",
                                filled: true,
                                labelText: "Caption",
                                labelStyle: TextStyle(
                                  color: Gs().secondaryColor,
                                ),
                                alignLabelWithHint: true,
                                fillColor: Colors.white,
                              ),
                            )),
                      )
                    ])
                  : Loading()));
    });
  }
}

class Loading extends StatelessWidget {
  Widget build(context) {
    return Container(
        child: Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
      ),
    ));
  }
}
