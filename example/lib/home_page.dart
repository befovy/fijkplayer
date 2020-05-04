import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'input_url.dart';
import 'listview.dart';
import 'local_path.dart';
import 'recent_list.dart';

class HomeItem extends StatelessWidget {
  HomeItem({
    @required this.onPressed,
    @required this.text,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      height: 45,
      child: FlatButton(
          key: ValueKey(text),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.all(0),
          onPressed: this.onPressed,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(left: 15, right: 15),
            child: Text(this.text),
          )),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final RecentMediaList list = RecentMediaList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(
        title: "FijkPlayer",
      ),
      body: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              color: Theme.of(context).primaryColorLight,
              padding: EdgeInsets.only(left: 15, top: 3, bottom: 3, right: 15),
              child: Text(
                "Open From",
                style: TextStyle(fontSize: 15),
              ),
            ),
            HomeItem(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => InputScreen()));
              },
              text: "Input Url",
            ),
            HomeItem(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LocalPathScreen()));
              },
              text: "Local Folder",
            ),
            HomeItem(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SamplesScreen()));
              },
              text: "Online Samples",
            ),
            HomeItem(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ListScreen()));
              },
              text: "List View",
            )
            /*
            Container(
              color: Theme.of(context).primaryColorLight,
              padding: EdgeInsets.only(left: 15, top: 3, bottom: 3, right: 15),
              child: Text(
                "Recent",
                style: TextStyle(fontSize: 15),
              ),
            ),
            Expanded(
              child: list,
            ),
             */
          ],
        ),
      ),
    );
  }
}

void displaySnackBar(BuildContext context) {
  Scaffold.of(context).showSnackBar(SnackBar(
    duration: Duration(seconds: 1),
    content: Text('Not implemented, pull request is welcome 👏👏🍺🍺'),
  ));
}
