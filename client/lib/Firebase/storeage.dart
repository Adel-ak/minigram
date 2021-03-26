import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

Future<List<Map>> uploadImages(List<Map> imageFiles) async {
  var images = imageFiles.map((image) async {
    String fileName = basename(image['path'].path);

    FirebaseStorage storage = FirebaseStorage.instance;
    var userUid = FirebaseAuth.instance.currentUser.uid;
    var uuid = Uuid().v1();
    var ref = storage.ref('posts/$userUid/$uuid-$fileName');

    if (image['type'] == AssetType.video) {
      final mediaInfo = await VideoCompress.compressVideo(
        image['path'].path,
        quality: VideoQuality.LowQuality, // default(100)
      );
      await ref.putFile(mediaInfo.file);
    } else {
      await ref.putFile(image['path']);
    }

    var link = await ref.getDownloadURL();
    print('link ------ $link');
    return {
      'type': image['type'] == AssetType.video ? 'video' : 'image',
      'uri': link,
    };
  });

  return await Future.wait(images);
}

Future<void> uploadAvatar(image) async {
  FirebaseStorage storage = FirebaseStorage.instance;
  var userUid = FirebaseAuth.instance.currentUser.uid;
  var ref = storage.ref('avatar/$userUid/${image.name}');
  ByteData byteData = await image.getByteData();

  await ref.putData(byteData.buffer.asUint8List());
  var link = await ref.getDownloadURL();
  await FirebaseAuth.instance.currentUser.updateProfile(photoURL: link);
  await FirebaseAuth.instance.currentUser.reload();
}
