import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

Future<List<String>> uploadImages(List<File> imageFiles) async {
  var images = imageFiles.map((image) async {
    String fileName = basename(image.path);
    FirebaseStorage storage = FirebaseStorage.instance;
    var userUid = FirebaseAuth.instance.currentUser.uid;
    var uuid = Uuid().v1();
    var ref = storage.ref('posts/$userUid/$uuid-$fileName');
    await ref.putFile(image);

    var link = await ref.getDownloadURL();

    return link;
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
