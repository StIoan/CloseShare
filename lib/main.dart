import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';

void main() {
  runApp(MyApp());
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
    print('Timestamps enable in snapshots\n');
  }, onError: (_) {
    print('Error enabling timestamps in snapshots\n');
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloseShare',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
