import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';
import 'package:interpolate/interpolate.dart';

import '../GStyle.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ScrollController _sc = ScrollController();

  @override
  Widget build(BuildContext ctx) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
      elevation: 5,
      backgroundColor: Gs().secondaryColor,
      flexibleSpace: Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        width: 60,
        height: 60,
        child: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, 'profile');
          },
          child: Hero(
            tag: 'dp',
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                  'https://i1.sndcdn.com/avatars-000587714706-vjdrog-t240x240.jpg'),
            ),
          ),
        ),
      ),
    ));
  }
}
