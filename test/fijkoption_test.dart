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
//

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FijkOption test", () {
    test("Constructor", () async {
      FijkOption fijkOption = FijkOption();

      var data = fijkOption.data;
      expect(data, isInstanceOf<Map>());
      expect(data[0], isInstanceOf<Map>());
      expect(data[1], isInstanceOf<Map>());
      expect(data[2], isInstanceOf<Map>());
      expect(data[3], isInstanceOf<Map>());
      expect(data[4], isInstanceOf<Map>());
      expect(data[5], isInstanceOf<Map>());

      expect(data.length, 6);
    });

    test("throwsArgumentError", () async {
      FijkOption fijkOption = FijkOption();
      fijkOption.setPlayerOption("start", 1);
      fijkOption.setPlayerOption("hello", "world");
      expect(fijkOption.data[FijkOption.playerCategory]!.length, 2);
      expect(
          () => fijkOption.setFormatOption("hi", false), throwsArgumentError);
      expect(() => fijkOption.setPlayerOption("hi", double.infinity),
          throwsArgumentError);
      expect(
          () => fijkOption.setCodecOption("hi", Error()), throwsArgumentError);
      expect(() => fijkOption.setSwrOption("hi", null), throwsArgumentError);
      expect(
          () => fijkOption.setSwsOption("hi", Object()), throwsArgumentError);

      expect(fijkOption.data[FijkOption.playerCategory]!.length, 2);
    });

    test("value update", () async {
      FijkOption fijkOption = FijkOption();

      fijkOption.setPlayerOption("hello", "world");
      fijkOption.setPlayerOption("hello", 1);

      var data = fijkOption.data;
      expect(data, isInstanceOf<Map>());

      expect(data.containsKey(4), true);
      var playerData = data[4]!;
      expect(playerData.containsKey("hello"), true);
      expect(playerData["hello"], 1);
    });

    test("get deep copy value", () async {
      FijkOption fijkOption = FijkOption();

      fijkOption.setPlayerOption("hello", "world");

      var data = fijkOption.data;
      expect(data, isInstanceOf<Map>());

      expect(data.containsKey(4), true);
      var playerData = data[4]!;
      expect(playerData.containsKey("hello"), true);
      expect(playerData["hello"], "world");

      data[4]!["hello"] = 1;

      expect(data[4]!["hello"], 1);

      data = fijkOption.data;
      expect(data[4]!["hello"], "world");
    });
  });
}
