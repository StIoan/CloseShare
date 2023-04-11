import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/chat.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';

final usersRef = Firestore.instance.collection('users');

class MessageScreen extends StatefulWidget {
  MessageScreen({Key key}) : super(key: key);

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<String> friendsList = [];

  @override
  void initState() {
    super.initState();
    getFriends();
  }

  getFriends() async {
    QuerySnapshot snapshot = await friendsRef
        .document(currentUser.id)
        .collection('userFriends')
        .getDocuments();
    setState(() {
      friendsList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildFriendsResults() {
    return StreamBuilder(
      stream: usersRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserMessage> friendsResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFriendUser = friendsList.contains(user.id);
          if (isAuthUser) {
            return;
          } else if (isFriendUser) {
            UserMessage userResult = UserMessage(user);
            friendsResults.add(userResult);
          } else {
            return;
          }
        });
        return Column(
          children: friendsResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Messages', removeBackButton: true),
      body: Container(
        padding: EdgeInsets.only(top: 7.0),
        child: buildFriendsResults(),
      ),
    );
  }
}

class UserMessage extends StatelessWidget {
  final User user;
  UserMessage(this.user);

  sendUserToChatPage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Chat(
                  receiverId: user.id,
                  receiverAvatar: user.photoUrl,
                  receiverName: user.username,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => sendUserToChatPage(context),
      child: Padding(
        padding: EdgeInsets.only(right: 10.0, left: 10.0, top: 2.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.grey.withOpacity(0.1),
            border: Border.all(
            color: Colors.black.withOpacity(0.2),
          ),
          ),
          child: ListTile(
            title: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            ),
            subtitle: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
