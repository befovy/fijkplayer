//MIT License
//
//Copyright (c) [2020] [Befovy]
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

part of fijkplayer;

FijkPanelWidgetBuilder panel2Builder(
    {Key key, bool fill = false, double duration = 3.0}) {
  return (FijkPlayer player, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _FijkPanel2(key: key, player: player,);
  };
}

class _FijkPanel2 extends StatefulWidget {
  const _FijkPanel2({Key key, @required FijkPlayer player})
      : assert(player != null),
        super(key: key);

  @override
  __FijkPanel2State createState() => __FijkPanel2State();
}

class __FijkPanel2State extends State<_FijkPanel2> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
