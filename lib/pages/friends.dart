import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/progress.dart';

class FriendsScreen extends StatefulWidget {
  final String profileId;
  const FriendsScreen({Key key, this.profileId}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<QuerySnapshot> searchResultsFuture;
  Future<QuerySnapshot> friendsResult;

  @override
  void initState() {
    super.initState();
    getFriends();
  }

  getFriends() {
    Future<QuerySnapshot> snapshot = friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .getDocuments();
    setState(() {
      searchResultsFuture = snapshot;
    });
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          currentUser.id != user.id ? searchResults.add(searchResult) : searchResults.remove(searchResult);
        });
        return ListView(
          padding: EdgeInsets.only(top: 5.0),
          children: searchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Friends'),
      body: searchResultsFuture == null ? Container() : buildSearchResults(),
    );
  }
}
