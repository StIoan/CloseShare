const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { error } = require('firebase-functions/lib/logger');
admin.initializeApp();

exports.onCreateFriend = functions.firestore
    .document("/friends/{userId}/userFriends/{friendId}")
    .onCreate(async (snapshot, context) => {
        console.log("Friend Created", snapshot.id);
        const userId = context.params.userId;
        const friendId = context.params.friendId;
        const friendUserPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('userPosts');
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(friendId)
            .collection('timelinePosts');
        const querySnapshot = await friendUserPostsRef.get();
        querySnapshot.forEach(doc => {
            if(doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        });
    });

exports.onDeleteFriend = functions.firestore
    .document("/friends/{userId}/userFriends/{friendId}")
    .onDelete(async (snapshot, context) => {
        console.log("Friend Deleted", snapshot.id);
        const userId = context.params.userId;
        const friendId = context.params.friendId;
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(friendId)
            .collection('timelinePosts')
            .where("ownerId", "==", userId);
        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if(doc.exists) {
                doc.ref.delete();
            }
        });
    });

exports.onCreatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onCreate(async (snapshot, context) => {
        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
        const userFriendsRef = admin.firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');
        const querySnapshot = await userFriendsRef.get();
        querySnapshot.forEach(doc => {
            const friendId = doc.id;
            admin
                .firestore()
                .collection('timeline')
                .doc(friendId)
                .collection('timelinePosts')
                .doc(postId)
                .set(postCreated);
        });
    });

exports.onUpdatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onUpdate(async (change, context) => {
        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
        const userFriendsRef = admin.firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');
        const querySnapshot = await userFriendsRef.get();
        querySnapshot.forEach(doc => {
            const friendId = doc.id;
            admin
                .firestore()
                .collection('timeline')
                .doc(friendId)
                .collection('timelinePosts')
                .doc(postId)
                .get()
                .then(doc => {
                    if(doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                });
        });
    });

exports.onDeletePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onDelete(async (snapshot, context) => {
        const userId = context.params.userId;
        const postId = context.params.postId;
        const userFriendsRef = admin.firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');
        const querySnapshot = await userFriendsRef.get();
        querySnapshot.forEach(doc => {
            const friendId = doc.id;
            admin
                .firestore()
                .collection('timeline')
                .doc(friendId)
                .collection('timelinePosts')
                .doc(postId)
                .get()
                .then(doc => {
                    if(doc.exists) {
                        doc.ref.delete();
                    }
                });
        });
    });

exports.onCreateActivityFeedItem = functions.firestore
    .document('/feed/{userId}/feedItems/{activityFeedItem}')
    .onCreate(async (snapshot, context) => {
        console.log('Activity Feed Item Created', snapshot.data());
        const userId = context.params.userId;
        const userRef = admin.firestore().doc(`user/${userId}`);
        const doc = await userRef.get();
        const androidNotificationToken = doc.data().androidNotificationToken;
        const createdActivityFeedItem = snapshot.data();
        if(androidNotificationToken) {
            sendNotification(androidNotificationToken, createdActivityFeedItem);
        } else {
            console.log("No token for user, cannot send notification");
        }
        function sendNotification(androidNotificationToken, activityFeedItem) {
            let body;
            switch (activityFeedItem.type) {
                case "comment":
                    body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                    break;
                case "like":
                    body = `${activityFeedItem.username} liked your post`;
                    break;
                case "friendRequest":
                    body = `${activityFeedItem.username} sent you a friend request`;
                    break;
                default:
                    break;
            }
            const message = {
                notification: { body },
                token: androidNotificationToken,
                data: { recipient: userId },
            };
            admin.messaging().send(message).then(response => {
                console.log("Succesfully sent message", response);
            }).catch(error => {
                console.log("Error sending message", error);
            });
        }
    });