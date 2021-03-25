import 'dart:io';
import 'package:flutter_101/Firebase/storeage.dart';
import 'package:flutter_101/gql/post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../GStyle.dart';

class NewPost extends StatefulWidget {
  File image;
  NewPost({Key key, this.image}) : super(key: key);

  @override
  _NewPostState createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  List<File> _image;
  TextEditingController captionController = TextEditingController(text: "");
  String _error;
  bool _loading = false;

  @override
  initState() {
    setState(() {
      _image = [widget.image];
    });
    super.initState();
  }

  Future makePost(client) async {
    try {
      setState(() {
        _loading = true;
      });
      var images = await uploadImages(_image);

      Map<String, dynamic> variables = {
        "images": images,
        "caption": captionController.text,
      };

      QueryResult res = await createPost(client: client, variables: variables);
      if (res.hasException) {
        throw res.exception;
      }
      return res.data;
    } catch (error) {
      print(error);

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
          floatingActionButton: FloatingActionButton(
            backgroundColor: Gs().secondaryColor,
            child:
                Icon(Icons.upload_rounded, color: Gs().primaryColor, size: 30),
            onPressed: () {
              makePost(client).then((res) {
                Navigator.pushNamedAndRemoveUntil(
                    context, 'home', (route) => false);
              });
            },
          ),
          backgroundColor: Gs().primaryColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Gs().secondaryColor,
            leading: Row(children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Gs().primaryColor,
                ),
                onPressed: () => Navigator.pop(context),
                iconSize: 25,
              ),
            ]),
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
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(_image[0],
                                          height: 200,
                                          width: 200,
                                          fit: BoxFit.cover)),
                                ),
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
