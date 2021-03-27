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
  Function controler;
  String _error;
  @override
  void initState() {
    if (widget.videoPath != null) {
      initializePlayer();
    }
    super.initState();
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) _videoPlayerController.dispose();

    if (_chewieController != null) _chewieController.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    try {
      VideoPlayerController videoPlayerController =
          VideoPlayerController.file(widget.videoPath);
      await videoPlayerController.initialize();
      final chewieController = ChewieController(
          videoPlayerController: videoPlayerController,
          autoPlay: false,
          looping: true,
          showControls: false,
          errorBuilder: (_, string) {
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
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
          child: Center(child: Icon(Icons.error, color: Colors.white)));
    }
    if (_chewieController != null &&
        _chewieController.videoPlayerController.value.initialized) {
      return _playerWidget;
    }
    return Loading();
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
