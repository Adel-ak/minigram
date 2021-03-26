import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import '../GStyle.dart';

class InternetConnectivity extends StatefulWidget {
  Widget child;

  InternetConnectivity({this.child});

  _InternetConnectivity createState() => _InternetConnectivity();
}

class _InternetConnectivity extends State<InternetConnectivity> {
  StreamSubscription subscription;
  bool isConnected = true;
  @override
  initState() {
    super.initState();

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // check().then((res) {
        //   setState(() {
        //     isConnected = res;
        //   });
        // });
        setState(() {
          isConnected = true;
        });
      } else {
        setState(() {
          isConnected = false;
        });
      }
    });
  }

  Future<bool> check() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

// Be sure to cancel subscription after you are done
  @override
  dispose() {
    super.dispose();

    subscription.cancel();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Container(
        color: Gs().primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'No internet connection.',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 20),
            ),
            Container(
              height: 20,
            ),
            Icon(
              Icons.wifi_off,
              textDirection: TextDirection.ltr,
              color: Gs().secondaryColor,
              size: 50,
            )
          ],
        ),
      );
    }

    return widget.child;
  }
}
