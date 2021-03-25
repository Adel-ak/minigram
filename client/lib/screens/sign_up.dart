import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_101/Firebase/auth.dart';
import 'package:flutter_101/Firebase/storeage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import '../GStyle.dart';

class SignUp extends StatefulWidget {
  SignUp({Key key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController email = TextEditingController(text: '');
  TextEditingController password = TextEditingController(text: '');
  TextEditingController userName = TextEditingController(text: '');
  Map _errors = {};
  bool _loading = false;
  Asset _image;

  Future<void> loadAssets() async {
    List<Asset> resultList;

    try {
      resultList = await MultiImagePicker.pickImages(maxImages: 1);
    } on Exception catch (_) {
      setState(() {
        _errors = {
          'other': 'Opps! something went wrong, cant login at the momment'
        };
      });
    }

    if (!mounted) return;
    setState(() {
      _image = resultList[0];
    });
  }

  void onSignUp(client) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errors = {};
      _loading = true;
    });
    try {
      if (_image == null) {
        throw ('no-image');
      }

      Map<String, dynamic> variables = {
        "displayName": userName.text.trim(),
        "email": email.text.trim(),
        "password": password.text,
      };

      QueryResult res = await signUp(client: client, variables: variables);
      if (res.hasException) {
        throw res.exception;
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: variables['email'], password: variables['password']);
      await uploadAvatar(_image);
      Navigator.popAndPushNamed(context, 'home');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } on OperationException catch (error) {
      String emailError =
          'The email address is already in use by another account.';
      String passwordError =
          'The password must be a string with at least 6 characters.';

      setState(() {
        if (error.toString() == 'no-image') {
          _errors = {'other': "Please select a image"};
        } else if (emailError ==
            error.graphqlErrors[0].extensions['error'].toString()) {
          _errors = {'email': emailError};
        } else if (passwordError ==
            error.graphqlErrors[0].extensions['error'].toString()) {
          _errors = {'password': passwordError};
        } else {
          _errors = {
            'other': 'Opps! something went wrong, cant login at the momment'
          };
        }

        _loading = false;
      });
    } catch (error) {
      setState(() {
        var message;
        if (error == 'no-image') {
          message = "Please select a image";
        } else {
          message = 'Opps! something went wrong, cant login at the momment';
        }
        _errors = {'other': message};

        _loading = false;
      });
    }
  }

  var border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(
        color: Colors.blue,
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: TextButton(
        child: Text("Login",
            style: TextStyle(color: Gs().secondaryColor, fontSize: 25)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      backgroundColor: Gs().primaryColor,
      body: GraphQLConsumer(
        builder: (client) {
          return AbsorbPointer(
              absorbing: _loading,
              child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () async {
                            loadAssets();
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2000)),
                                margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top),
                                child: _image == null
                                    ? Icon(
                                        Icons.account_circle_rounded,
                                        size: 220,
                                        color: Colors.grey,
                                      )
                                    : AssetThumb(
                                        asset: _image, height: 200, width: 200),
                              ),
                              Positioned(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Gs().secondaryColor,
                                  size: 40,
                                ),
                                bottom: 10,
                                right: 10,
                              )
                            ],
                          )),
                      Container(
                        child: Text(
                          _errors['other'] ?? '',
                          style: TextStyle(color: Colors.red),
                        ),
                        margin: EdgeInsets.only(bottom: 15),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          focusedBorder: border,
                          border: border,
                          filled: true,
                          errorText: _errors['userName'] ?? null,
                          labelText: "User name",
                          alignLabelWithHint: true,
                          fillColor: Colors.white,
                        ),
                        controller: userName,
                      ),
                      Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: TextField(
                            decoration: InputDecoration(
                              focusedBorder: border,
                              border: border,
                              filled: true,
                              errorText: _errors['email'] ?? null,
                              labelText: "Email",
                              alignLabelWithHint: true,
                              fillColor: Colors.white,
                            ),
                            controller: email,
                          )),
                      Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: TextField(
                            decoration: InputDecoration(
                                focusedBorder: border,
                                border: border,
                                filled: true,
                                errorText: _errors['password'] ?? null,
                                alignLabelWithHint: true,
                                fillColor: Colors.white,
                                labelText: 'Password'),
                            controller: password,
                            obscureText: true,
                          )),
                      _loading
                          ? Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Gs().secondaryColor),
                              ),
                            )
                          : TextButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Gs().secondaryColor)),
                              onPressed: () => onSignUp(client),
                              child: Container(
                                  width: 100,
                                  child: Center(
                                      child: Text("Sign up",
                                          style: TextStyle(
                                              color: Gs().textColor)))))
                    ],
                  )));
        },
      ),
    );
  }
}
