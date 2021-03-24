import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:provider/provider.dart';

class Post {
  List<String> images;
  int likes;
  List<String> comments;
  String caption;
  Post({this.images, this.likes, this.comments, this.caption});

  get map {
    return {
      'caption': this.caption,
      'images': this.images,
      'comments': this.comments,
      'likes': this.likes,
    };
  }
}

getPosts({limit: 10}) async {
  try {
    CollectionReference post = FirebaseFirestore.instance.collection('posts');
    QuerySnapshot posts = await post.limit(limit).get();

    return posts;
  } catch (error) {}
}

getMorePosts({documentSnapshot, limit: 10}) async {
  try {
    CollectionReference post = FirebaseFirestore.instance.collection('posts');
    QuerySnapshot posts =
        await post.startAfterDocument(documentSnapshot).limit(limit).get();
    return posts;
  } catch (error) {}
}
