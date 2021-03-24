import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_101/screens/home.dart';
import 'package:flutter_101/screens/login.dart';
import 'package:flutter_101/screens/imageSelection.dart';
import 'package:flutter_101/screens/newPost.dart';
import 'package:flutter_101/screens/sign_up.dart';
import 'package:flutter_101/screens/profile.dart';

class RouteGenerate {
  static generateAuthRoute(RouteSettings setting, BuildContext ctx) {
    String routeName = setting.name;
    User user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (routeName == 'signUp') {
      } else {
        routeName = 'login';
      }
    }

    switch (routeName) {
      case 'home':
        return MaterialPageRoute(builder: (_) => Home());
      case 'profile':
        return MaterialPageRoute(builder: (_) => Profile());
      case 'login':
        return MaterialPageRoute(builder: (_) => Login());
      case 'signUp':
        return MaterialPageRoute(builder: (_) => SignUp());
      case 'imageSelection':
        return MaterialPageRoute(builder: (_) => ImageSelection());
      case 'newPost':
        var arguments = setting.arguments as Map;

        return MaterialPageRoute(
            builder: (_) => NewPost(image: arguments['image']));
      default:
    }
  }
}
