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
  group("FijkValue test", () {
    test("Constructor", () {
      FijkValue value = FijkValue.uninitialized();
      expect(value, isNotNull);
    });

    test("eq", () {
      FijkValue value1 = FijkValue.uninitialized();
      FijkValue value2 = FijkValue.uninitialized();
      expect(value1, value2);
      expect(value1.hashCode, value2.hashCode);

      value1 = value1.copyWith(prepared: true);

      expect(value1 == value2, false);
      expect(value1.hashCode == value2.hashCode, false);

      value2 = value2.copyWith(prepared: true);
      expect(value1, value2);
      expect(value1.hashCode, value2.hashCode);
    });
  });

  test("FijkState must has same value as native state", () {
    expect(FijkState.idle.index, 0);
    expect(FijkState.initialized.index, 1);
    expect(FijkState.asyncPreparing.index, 2);
    expect(FijkState.prepared.index, 3);
    expect(FijkState.started.index, 4);
    expect(FijkState.paused.index, 5);
    expect(FijkState.completed.index, 6);
    expect(FijkState.stopped.index, 7);
    expect(FijkState.error.index, 8);
    expect(FijkState.end.index, 9);
  });

  test("FijkData set get contains", () {
    FijkData data = FijkData();

    expect(data.contains("hello"), false);

    data.setValue("hello", "world");
    expect(data.contains("hello"), true);

    expect(data.getValue("hello"), "world");
    data.clearValue("dart");
    data.clearValue("hello");

    expect(data.contains("hello"), false);
  });
}
