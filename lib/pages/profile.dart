import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/friends.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isFriend = false;
  String postOrientation = 'grid';
  String userDisplayName;
  String userPhotoUrl;
  bool isLoading = false;
  bool sentFriendRequest = false;
  bool requestExists = false;
  int postCount = 0;
  int friendsCount = 0;
  DocumentSnapshot profileUser;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFriends();
    checkIfFriend();
    checkRequest();
    getUser();
  }

  getUser() async {
    DocumentSnapshot doc = await usersRef.document(widget.profileId).get();
    User profileUser = User.fromDocument(doc);
    setState(() {
      userDisplayName = profileUser.displayName;
      userPhotoUrl = profileUser.photoUrl;
    });
  }

  checkRequest() async {
    DocumentSnapshot doc = await requestsRef
        .document(widget.profileId)
        .collection('requestsSent')
        .document(currentUserId)
        .get();
    setState(() {
      requestExists = doc.exists;
    });

    doc = await requestsRef
        .document(currentUserId)
        .collection('requestsSent')
        .document(widget.profileId)
        .get();
    setState(() {
      sentFriendRequest = doc.exists;
    });
  }

  getFriends() async {
    QuerySnapshot snapshot = await friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .getDocuments();
    setState(() {
      friendsCount = snapshot.documents.length;
    });
  }

  checkIfFriend() async {
    DocumentSnapshot doc = await friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .document(currentUserId)
        .get();
    setState(() {
      isFriend = doc.exists;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: GestureDetector(
        onTap: function,
        child: Container(
          margin: EdgeInsets.only(left: 100, right: 100, top: 10),
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFriend ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFriend ? Colors.white : Colors.blueGrey,
            border: Border.all(
              color: isFriend ? Colors.grey : Colors.blueGrey,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  handleUnfriendUser() {
    setState(() {
      isFriend = false;
    });
    friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    friendsRef
        .document(currentUserId)
        .collection('userFriends')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;

    if (isProfileOwner) {
      return Container();
    } else if (isFriend) {
      return buildButton(
        text: "Unfriend",
        function: handleUnfriendUser,
      );
    } else if (!requestExists) {
      if (!sentFriendRequest) {
        return buildButton(
          text: "Send friend requiest",
          function: handleFriendRequestUser,
        );
      } else {
        return buildButton(
          text: "Unsend friend requiest",
          function: handleFriendUnrequestUser,
        );
      }
    } else {
      return buildDecideButton();
    }
  }

  buildDecideButton() {
    return Container(
      margin: EdgeInsets.only(top: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 10.0,
          ),
          Text(
            "This user sent you a friend request.",
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
          GestureDetector(
            onTap: onAcceptRequest,
            child: Container(
              margin: EdgeInsets.only(top: 10.0),
              width: 250.0,
              height: 27.0,
              child: Text(
                "Accept",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                border: Border.all(
                  color: Colors.blueGrey,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDeclineRequest,
            child: Container(
              margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
              width: 250.0,
              height: 27.0,
              child: Text(
                "Declin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                border: Border.all(
                  color: Colors.blueGrey,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  onDeclineRequest() {
    setState(() {
      requestExists = false;
    });
    requestsRef
        .document(widget.profileId)
        .collection('requestsSent')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  onAcceptRequest() {
    setState(() {
      isFriend = true;
    });
    requestsRef
        .document(widget.profileId)
        .collection('requestsSent')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    friendsRef
        .document(widget.profileId)
        .collection('userFriends')
        .document(currentUserId)
        .setData({
      'displayName': currentUser.displayName,
      'photoUrl': currentUser.photoUrl,
      'id': currentUserId,
    });
    friendsRef
        .document(currentUserId)
        .collection('userFriends')
        .document(widget.profileId)
        .setData({
        'displayName': userDisplayName,
        'photoUrl': userPhotoUrl,
        'id': widget.profileId,
    });
  }

  handleFriendUnrequestUser() {
    setState(() {
      sentFriendRequest = false;
    });
    requestsRef
        .document(currentUserId)
        .collection('requestsSent')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFriendRequestUser() {
    setState(() {
      sentFriendRequest = true;
    });
    requestsRef
        .document(currentUserId)
        .collection('requestsSent')
        .document(widget.profileId)
        .setData({});
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      'type': 'friendRequest',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImage': currentUser.photoUrl,
      'timestamp': timestamp,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Container(
          padding: EdgeInsets.only(top: 30.0),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 55.0,
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              Container(
                height: 15.0,
              ),
              Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              Container(
                height: 5.0,
              ),
              Text(
                user.bio,
              ),
              Container(
                height: 25.0,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  buildCountColumn('posts', postCount),
                  GestureDetector(
                    child: buildCountColumn('friends', friendsCount),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                FriendsScreen(profileId: currentUser?.id))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg', height: 260.0),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                'No posts',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
          child: PostTile(post),
        ));
      });
      return Container(
        padding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: gridTiles,
          ),
        ),
      );
    } else if (postOrientation == 'list') {
      return Column(children: posts);
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTooglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          onPressed: () => setPostOrientation('grid'),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          icon: Icon(Icons.list),
          onPressed: () => setPostOrientation('list'),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        'Profile',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          padding: EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        EditProfile(currentUserId: currentUserId))),
            child: Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.profileId == currentUserId
          ? appBar()
          : header(context, titleText: 'Profile'),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          buildProfileButton(),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
