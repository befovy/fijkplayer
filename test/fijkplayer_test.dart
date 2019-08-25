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

import 'dart:async';
import 'dart:collection';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FijkPlayerTester {
  final int id;
  final MethodChannel playerEvent;
  final MethodChannel playerMethod;

  FijkPlayerTester({this.id})
      : playerEvent = MethodChannel("befovy.com/fijkplayer/event/$id"),
        playerMethod = MethodChannel("befovy.com/fijkplayer/$id") {
    playerEvent.setMockMethodCallHandler(this.eventHandler);
    playerMethod.setMockMethodCallHandler(this.playerHandler);
  }

  MethodCodec get codec {
    return playerEvent.codec;
  }

  Future<dynamic> eventHandler(MethodCall call) {
    switch (call.method) {
      case 'listen':
      case 'cancel':
        return null;
      default:
        return Future.error("event Method invalid call name ${call.method}");
    }
  }

  Future<dynamic> playerHandler(MethodCall call) async {
    switch (call.method) {
      case 'setupSurface':
        return 1;
      case 'setDateSource':
        await sendEvent(<String, dynamic>{'event': 'prepared'});
        await sendEvent(
            <String, dynamic>{'event': 'state_change', 'new': 1, 'old': 0});
        return null;
      case 'prepareAsync':
        await sendEvent(
            <String, dynamic>{'event': 'state_change', 'new': 2, 'old': 1});
        Future.delayed(Duration(milliseconds: 100), () {
          sendEvent(
              <String, dynamic>{'event': 'state_change', 'new': 3, 'old': 2});
        });
        return null;
      case 'start':
        return null;
      case 'stop':
        return null;
      case 'setLoop':
        return null;
      case 'setSpeed':
        return null;
      default:
        return Future.error("invalid call name ${call.method}");
    }
  }

  void release() {
    playerEvent.setMockMethodCallHandler(null);
    playerMethod.setMockMethodCallHandler(null);
  }

  Future<void> sendEvent(dynamic event) {
    return defaultBinaryMessenger.handlePlatformMessage(
        "befovy.com/fijkplayer/event/$id",
        codec.encodeSuccessEnvelope(event),
        (ByteData data) {});
  }
}

/// how to mock EventChannel from native side
/// https://github.com/flutter/flutter/issues/38954
void main() {
  const MethodChannel pluginChannel = MethodChannel('befovy.com/fijk');

  Map<int, FijkPlayerTester> playerTesters = HashMap();

  int playerIncId = 0;

  setUpAll(() {
    pluginChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'createPlayer':
          playerIncId = playerIncId + 1;
          FijkPlayerTester tester = FijkPlayerTester(id: playerIncId);
          playerTesters[playerIncId] = tester;
          return Future.value(playerIncId);
        case 'releasePlayer':
          Map args = methodCall.arguments as Map;
          int pid = args["pid"];
          expect(pid, isNotNull);
          FijkPlayerTester tester = playerTesters.remove(pid);
          tester?.release();
          return null;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    pluginChannel.setMockMethodCallHandler(null);
  });

  group("test FijkPlayer State", () {
    test("Fijkplayer state", () async {
      FijkPlayer player = FijkPlayer();
      await player.setupSurface();
      expect(player.state, FijkState.idle);
      expect(player.value.prepared, false);
      expect(player.value.completed, false);
      await player.setDataSource("assets://butterfly.mp4");
      expect(player.state, FijkState.initialized);

      Completer<void> prepared = Completer();
      player.addListener(() {
        FijkValue value = player.value;
        if (value.state == FijkState.prepared) {
          prepared.complete();
        }
      });

      await player.prepareAsync();
      expect(player.state, FijkState.asyncPreparing);
      await prepared.future;
      expect(player.state, FijkState.prepared);

      expect(() async {
        await player.setLoop(-1);
      }, throwsArgumentError);

      expect(() async {
        await player.setLoop(null);
      }, throwsArgumentError);

      await player.setLoop(1);

      await player.release();

      expect(player.state, FijkState.end);
    });
  });

  group("test FijkPlayer api", () {
    test("create, release", () async {
      FijkPlayer player = FijkPlayer();
      expect(player, isNotNull);
      player.release();
    });

    test("read only value", () async {
      FijkPlayer player = FijkPlayer();
      bool changed = false;
      player.addListener(() {
        changed = true;
      });
      FijkValue value = player.value;
      expect(player.value.prepared, false);
      value = value.copyWith(prepared: true);
      expect(player.value.prepared, false);
      expect(changed, false);
      await player.release();
    });

    test("setupSurface", () async {
      FijkPlayer player = FijkPlayer();
      int tid = await player.setupSurface();
      expect(tid > 0, true);
    });

    test("setDataSource", () async {
      FijkPlayer player = FijkPlayer();
      expect(() async {
        await player.setDataSource(null);
      }, throwsArgumentError);
      expect(() async {
        await player.setDataSource("");
      }, throwsArgumentError);

      await player.setDataSource("asset://butterfly.mp4");
      expect(player.state, FijkState.initialized);
      await player.setDataSource("asset://butterfly.mp4");
      expect(player.state, FijkState.initialized);

      await player.prepareAsync();

      expect(() async {
        await player.setDataSource("asset://butterfly.mp4");
      }, throwsStateError);
    });

    test("setLoop", () async {
      FijkPlayer player = FijkPlayer();
      await player.setLoop(1);
      await player.setLoop(0);
      await player.setLoop(2);
      expect(() async {
        await player.setLoop(-1);
      }, throwsArgumentError);
      expect(() async {
        await player.setLoop(null);
      }, throwsArgumentError);
    });

    test("setSpeed", () async {
      FijkPlayer player = FijkPlayer();
      expect(() async {
        await player.setSpeed(null);
      }, throwsArgumentError);
      expect(() async {
        await player.setSpeed(0);
      }, throwsArgumentError);
      expect(() async {
        await player.setSpeed(-1);
      }, throwsArgumentError);
      await player.setSpeed(1.5);
    });

    test("isPlayable", () async {
      FijkPlayer player = FijkPlayer();
      expect(player.isPlayable(), false);
      await player.setupSurface();
      expect(player.isPlayable(), false);

      Completer<void> prepared = Completer();
      player.addListener(() {
        FijkValue value = player.value;
        if (value.state == FijkState.prepared) {
          prepared.complete();
        }
      });

      await player.setDataSource("asset://butterfly.mp4");
      expect(player.isPlayable(), false);
      expect(player.state, FijkState.initialized);

      await player.prepareAsync();
      expect(player.isPlayable(), false);

      await prepared.future;
      expect(player.isPlayable(), true);

      await player.start();
      expect(player.isPlayable(), true);
    });
  });
}
