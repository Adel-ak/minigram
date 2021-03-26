import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../GStyle.dart';

class VideoPlayerThumbNail extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const VideoPlayerThumbNail({Key key, this.videoPath}) : super(key: key);

  final File videoPath;

  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerThumbNailState();
  }
}

class _VideoPlayerThumbNailState extends State<VideoPlayerThumbNail> {
  ChewieController _chewieController;
  VideoPlayerController _videoPlayerController;
  Chewie _playerWidget;

  @override
  void initState() {
    if (widget.videoPath != null) {
      initializePlayer();
    }
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();

    _chewieController.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    VideoPlayerController videoPlayerController =
        VideoPlayerController.file(widget.videoPath);

    await videoPlayerController.initialize();
    final chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        showControls: false,
        errorBuilder: (_, string) {
          print(string);
          return Container(
              child: Center(
            child: Icon(Icons.error),
          ));
        });

    // chewieController.setVolume(10.0);
    Chewie playerWidget = Chewie(
      controller: chewieController,
    );

    setState(() {
      _playerWidget = playerWidget;
      _videoPlayerController = videoPlayerController;
      _chewieController = chewieController;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _chewieController.videoPlayerController.value.isInitialized) {
      return _playerWidget;
    }
    return Loading(
      height: null,
    );
  }
}

class Loading extends StatelessWidget {
  double height = 100;
  Loading({this.height});
  Widget build(context) {
    return Container(
        height: height,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Gs().secondaryColor),
          ),
        ));
  }
}
