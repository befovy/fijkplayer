import 'dart:async';

import 'package:flutter/services.dart';

import 'fijkplugin.dart';

enum DateSourceType { asset, network, file }

class FijkPlayer {
  final String dataSource;
  final DateSourceType dateSourceType;

  FijkPlayer.network(this.dataSource) : dateSourceType = DateSourceType.network;


  Future<void> initialize() async {
    Map<dynamic, dynamic> dataSourceDescription;

    switch (dateSourceType) {
      case DateSourceType.network:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
        break;
      case DateSourceType.asset:
        break;
      case DateSourceType.file:
        break;
    }

    FijkPlugin.createIjkPlayer();
  }
}
