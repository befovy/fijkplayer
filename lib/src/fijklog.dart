//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import 'package:flutter/foundation.dart';

@immutable
class FijkLogLevel {
  final int level;
  final String name;

  const FijkLogLevel._(int l, String n)
      : assert(l != null),
        level = l,
        name = n;

  static const FijkLogLevel All = FijkLogLevel._(000, 'all');
  static const FijkLogLevel Detail = FijkLogLevel._(100, 'det');
  static const FijkLogLevel Verbose = FijkLogLevel._(200, 'veb');
  static const FijkLogLevel Debug = FijkLogLevel._(300, 'dbg');
  static const FijkLogLevel Info = FijkLogLevel._(400, 'inf');
  static const FijkLogLevel Warn = FijkLogLevel._(500, 'war');
  static const FijkLogLevel Error = FijkLogLevel._(600, 'err');
  static const FijkLogLevel Fatal = FijkLogLevel._(700, 'fal');
  static const FijkLogLevel Silent = FijkLogLevel._(800, 'sil');
}

class FijkLog {
  static FijkLogLevel _level = FijkLogLevel.Info;

  static setLevel(final FijkLogLevel level) {
    assert(level != null);
    _level = level;
  }

  static log(FijkLogLevel level, String msg, String tag) {
    if (level.level >= _level.level) {
      DateTime now = DateTime.now();
      print("[${level.name}] ${now.toLocal()} [$tag] $msg");
    }
  }

  static debug(String msg, {String tag = 'fijk'}) {
    log(FijkLogLevel.Debug, msg, tag);
  }

  static info(String msg, {String tag = 'fijk'}) {
    log(FijkLogLevel.Info, msg, tag);
  }

  static warn(String msg, {String tag = 'fijk'}) {
    log(FijkLogLevel.Warn, msg, tag);
  }

  static error(String msg, {String tag = 'fijk'}) {
    log(FijkLogLevel.Error, msg, tag);
  }
}
