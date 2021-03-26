import 'dart:io';
import 'dart:math';
import 'package:chewie/chewie.dart';
import 'package:flutter_101/Components/videoPlayer.dart';
import 'package:interpolate/interpolate.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:thumbnails/thumbnails.dart' as TN;
import 'package:video_player/video_player.dart';
import '../GStyle.dart';

class ImageSelection extends StatefulWidget {
  ImageSelection({Key key}) : super(key: key);

  @override
  _ImageSelectionState createState() => _ImageSelectionState();
}

class _ImageSelectionState extends State<ImageSelection> {
  List<dynamic> _images;
  List<Map> _albums;
  String _selectedAlbum = "Recent";
  String _selectedAlbumID;
  Map _selectedImage;
  String _error = "";

  int _page = 0;
  bool _hasMore = true;
  ScrollController _scrollController = new ScrollController();
  @override
  initState() {
    loadAssets(assetName: _selectedAlbum);
    super.initState();
  }

  Future<void> loadAssets(
      {String assetName, String assetID, resetImage = false}) async {
    try {
      var result = await PhotoManager.requestPermission();
      if (result) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
            type: RequestType.common, hasAll: true);

        Iterable<Map<dynamic, dynamic>> albumsNames = albums.map((album) => {
              'albumID': album.id,
              'name': album.name,
              'count': album.assetCount,
              'list': album.getAssetListPaged,
              'type': album.type
            });

        Map<dynamic, dynamic> selectedAblum = albumsNames.where((element) {
          if (assetID != null) {
            return element['albumID'] == assetID;
          } else {
            return element['name'] == assetName;
          }
        }).first;

        var pageNum = resetImage ? 0 : _page;

        List<AssetEntity> assets = await selectedAblum['list'](pageNum, 25);

        List<Map> assetsList = await Future.wait(assets.map((asset) async {
          String thumbNail;
          File file = await asset.file;
          if (asset.type == AssetType.video) {
            try {
              thumbNail = await TN.Thumbnails.getThumbnail(
                  videoFile: file.path,
                  imageType: TN.ThumbFormat.JPEG,
                  quality: 60);
            } catch (error) {
              print(error);
            }
          }

          return {'path': file, 'type': asset.type, 'thumbNail': thumbNail};
        }));

        setState(() {
          if (_albums == null) {
            _albums = albumsNames.toList();
          }

          if (_selectedImage == null) {
            _selectedImage = assetsList[0];
          }

          if (assetsList.isEmpty && !resetImage) {
            _hasMore = false;
          }

          if (_images == null || resetImage) {
            _images = assetsList;
            _selectedImage = assetsList[0];
            _images = assetsList;
            _selectedAlbum = selectedAblum['name'];
            _selectedAlbumID = selectedAblum['albumID'];
            _page = 1;
            _hasMore = true;
          } else {
            _images.addAll(assetsList);
            _page++;
          }
        });
        // success
      } else {
        PhotoManager.openSetting();
        // fail
        /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
      }
    } catch (error) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  showAlbums() {
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return Container(
              color: Gs().primaryColor,
              child: ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (_, index) {
                    if (_albums[index]["albumID"] == _selectedAlbumID) {
                      return Container();
                    }

                    return TextButton(
                        style: ButtonStyle(
                            alignment: Alignment.centerLeft,
                            padding: MaterialStateProperty.all(
                                EdgeInsets.only(left: 20))),
                        onPressed: () {
                          loadAssets(
                              assetID: _albums[index]['albumID'],
                              resetImage: true);
                          Navigator.pop(context);
                        },
                        child: Text(
                          '${_albums[index]["name"]}  -  ${_albums[index]["count"]}',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ));
                  }));
        });
  }

  Widget buildGridView() {
    if (_images != null)
      return GridView.count(
        crossAxisCount: 3,
        children: List.generate(_images.length, (index) {
          File asset = _images[index];
          return Image.file(asset);
        }),
      );
    else
      return Container();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GraphQLConsumer(builder: (client) {
      return Scaffold(
          floatingActionButton: Stack(
            children: <Widget>[
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  Interpolate interpolateRightUserName = Interpolate(
                    inputRange: [300, 500],
                    outputRange: [-60, 0],
                    extrapolate: Extrapolate.clamp,
                  );
                  return Positioned(
                      bottom: interpolateRightUserName
                          .eval(_scrollController.offset),
                      left: 30,
                      child: child);
                },
                child: FloatingActionButton(
                  backgroundColor: Gs().secondaryColor,
                  child: Icon(Icons.arrow_upward_rounded,
                      color: Gs().primaryColor, size: 25),
                  onPressed: () {
                    _scrollController.animateTo(0,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.ease);
                  },
                ),
              ),
              Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    backgroundColor: Gs().secondaryColor,
                    child: Icon(Icons.arrow_right_rounded,
                        color: Gs().primaryColor, size: 50),
                    onPressed: () {
                      Navigator.pushNamed(context, 'newPost', arguments: {
                        'image': _selectedImage,
                      });
                    },
                  )),
            ],
          ),
          backgroundColor: Gs().primaryColor,
          appBar: AppBar(
            backgroundColor: Gs().secondaryColor,
            elevation: 0,
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
                  Navigator.pushNamed(context, 'profile');
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
          body: CustomScrollView(
            controller: _scrollController,
            slivers: _images != null
                ? [
                    SelectedThumbNail(
                      selectedImage: _selectedImage,
                      scrollController: _scrollController,
                    ),
                    SliverAppBar(
                        backgroundColor: Gs().secondaryColor,
                        floating: true,
                        automaticallyImplyLeading: false,
                        flexibleSpace: TextButton(
                            onPressed: () {
                              showAlbums();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(_selectedAlbum,
                                    style: TextStyle(
                                        color: Gs().primaryColor,
                                        fontSize: 20)),
                                Icon(Icons.arrow_drop_down,
                                    color: Gs().primaryColor, size: 30)
                              ],
                            )),
                        pinned: true,
                        toolbarHeight: 45),
                    SliverGrid(
                      delegate: SliverChildBuilderDelegate((_, index) {
                        if (index >= _images.length) {
                          if (!_hasMore) {
                            return Container();
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            loadAssets(
                                assetName: _selectedAlbum,
                                assetID: _selectedAlbumID);
                          });
                          return Loading();
                        }

                        AssetType assetType = _images[index]['type'];

                        if (assetType == AssetType.video) {
                          var asset = _images[index];
                          return VideoThumbNail(
                              thumbNail: File(asset['thumbNail']),
                              onClick: () {
                                setState(() {
                                  _selectedImage = asset;
                                });
                              });
                        }

                        if (assetType == AssetType.image) {
                          File asset = _images[index]['path'];

                          var isSelected = asset == _selectedImage['path'];
                          return ImageThumbNail(
                              isSelected: isSelected,
                              thumbNail: asset,
                              onClick: () {
                                setState(() {
                                  _selectedImage = _images[index];
                                });
                              });
                        }
                      }, childCount: _images.length + 1),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: screenWidth / 3,
                        childAspectRatio: 100 / 100,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                    )
                  ]
                : [
                    SliverFillRemaining(
                      child: Loading(),
                    )
                  ],
          ));
    });
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

class ImageThumbNail extends StatelessWidget {
  final File thumbNail;
  final Function onClick;
  final bool isSelected;

  ImageThumbNail({this.thumbNail, this.onClick, this.isSelected});

  Widget build(context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
        child: Stack(
          children: [
            Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Image.file(
                  thumbNail,
                  fit: BoxFit.cover,
                  cacheWidth: screenWidth ~/ 2,
                )),
            Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Container(color: isSelected ? Colors.black54 : null)),
            Positioned(
                top: 5,
                right: 15,
                child: isSelected
                    ? Icon(Icons.done_rounded, color: Gs().secondaryColor)
                    : Container())
          ],
        ),
        onTap: onClick);
  }
}

class SelectedThumbNail extends StatelessWidget {
  Map<dynamic, dynamic> selectedImage;
  ScrollController scrollController;
  SelectedThumbNail({this.selectedImage, this.scrollController});

  Widget build(context) {
    print(selectedImage);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeigth = MediaQuery.of(context).size.height;
    // return Container();

    return SliverAppBar(
      elevation: 0,
      toolbarHeight: 0,
      expandedHeight: screenHeigth / 2.5,
      collapsedHeight: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Gs().primaryColor,
      flexibleSpace: Builder(builder: (_) {
        if (selectedImage['type'] == AssetType.image) {
          return Image.file(
            selectedImage['path'],
            fit: BoxFit.contain,
            width: screenWidth / 1,
            height: screenHeigth / 2.5,
          );
        }
        if (selectedImage['type'] == AssetType.video) {
          return VideoPlayerThumbNail(
            key: ValueKey(selectedImage['path']),
            videoPath: selectedImage['path'],
          );
        }
      }),
    );
  }
}

class VideoThumbNail extends StatelessWidget {
  final File thumbNail;
  final Function onClick;
  final bool isSelected;

  VideoThumbNail({this.thumbNail, this.onClick, this.isSelected = false});

  @override
  Widget build(context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (thumbNail == null) {
      return Container(
          child: Icon(
        Icons.error,
        color: Colors.white,
      ));
    }

    return InkWell(
        child: Stack(
          children: [
            Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Image.file(
                  thumbNail,
                  fit: BoxFit.cover,
                  cacheWidth: screenWidth ~/ 2,
                )),
            Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Container(color: isSelected ? Colors.black54 : null)),
            Positioned(
                top: 5,
                right: 15,
                child: isSelected
                    ? Icon(Icons.done_rounded, color: Gs().secondaryColor)
                    : Container()),
            Positioned(
                bottom: 5,
                left: 5,
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Gs().primaryColor,
                      borderRadius: BorderRadius.all(Radius.circular(100))),
                  child: Icon(Icons.play_arrow_rounded,
                      color: Gs().secondaryColor),
                ))
          ],
        ),
        onTap: onClick);
  }
}
