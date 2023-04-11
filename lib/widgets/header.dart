import 'package:flutter/material.dart';
import 'package:scroll_app_bar/scroll_app_bar.dart';
import 'package:fluttershare/pages/home.dart';

ScrollAppBar header(
  context, {
  bool isAppTitle = false,
  String titleText,
  bool removeBackButton = false,
}) {
  return ScrollAppBar(
    controller: controller,
    automaticallyImplyLeading: removeBackButton ? false : true,
    leading: removeBackButton == false
        ? GestureDetector(
          onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          )
        : Text(''),
    title: Text(
      isAppTitle ? 'CloseShare' : titleText,
      style: TextStyle(
        color: Colors.black,
        fontFamily: isAppTitle ? "Signatra" : '',
        fontSize: isAppTitle ? 50.0 : 22.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Colors.white,
  );
}
