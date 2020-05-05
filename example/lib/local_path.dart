import 'dart:async';
import 'dart:io';

import 'package:fijkplayer_example/video_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';

class LocalPathScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Local Path"),
      body: LocalPath(),
    );
  }
}

final RegExp _mediaReg = RegExp(".\(flv|mp4|mkv|mp3|mp4\)\$");

class LocalPath extends StatefulWidget {
  @override
  _LocalPathState createState() => _LocalPathState();
}

class _LocalPathState extends State<LocalPath> {
  bool root = true;

  List<FileSystemEntity> files = List();
  Directory current = Directory.current;

  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
  }

  void cantOpenSnackBar() {
    Scaffold.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: 1),
      content: Text('Something error when openning this file/dir'),
    ));
  }

  void listDir(String path) {
    bool opened = true;
    List<FileSystemEntity> tmpFiles = List();
    FileSystemEntity.isDirectory(path).then((f) {
      if (f) {
        final Directory dir = Directory(path);
        tmpFiles.add(dir.parent);
        _subscription = dir.list(followLinks: false).listen((child) {
          if (FileSystemEntity.isDirectorySync(child.path) ||
              _mediaReg.hasMatch(child.path)) {
            tmpFiles.add(child);
          }
        }, onDone: () {
          if (opened == true) {
            setState(() {
              files = tmpFiles;
              current = dir;
            });
          }
        }, onError: (e) {
          opened = false;
          cantOpenSnackBar();
        });
      }
    }).catchError((e) {
      cantOpenSnackBar();
    });
  }

  Widget buildItem(FileSystemEntity entity, int parentLength, bool isDir) {
    final String path = entity.absolute.path;
    final bool parent = path.length <= parentLength;
    final text = parent ? ".." : path.substring(parentLength + 1);
    final IconData icon = isDir ? Icons.folder : Icons.music_video;

    return FlatButton(
      key: ValueKey(path),
      padding: EdgeInsets.only(left: 5, right: 5),
      child: Row(children: <Widget>[
        Icon(icon),
        Padding(padding: EdgeInsets.only(left: 5)),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ]),
      onPressed: () {
        if (isDir)
          listDir(entity.absolute.path);
        else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      VideoScreen(url: entity.absolute.path)));
        }
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    int currentLength = current.absolute.path.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          title: Text(current != null ? current.path : "/",
              style: TextStyle(
                color: Theme.of(context).dividerColor,
                fontSize: 14,
              )),
          contentPadding: EdgeInsets.only(left: 10),
        ),
        Expanded(
          child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (BuildContext context, int index) {
                FileSystemEntity entity = files[index];
                bool isDir = FileSystemEntity.isDirectorySync(entity.path);
                print("builditem ${entity.path}, $currentLength, $isDir");
                return buildItem(entity, currentLength, isDir);
              }),
        )
      ],
    );
  }
}
