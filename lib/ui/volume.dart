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

part of ui;

/// Default builder generate default FijkVolToast UI
Widget defaultFijkVolumeToast() {
  return _FijkVolToast();
}

class _FijkVolToast extends StatefulWidget {
  @override
  __FijkVolToastState createState() => __FijkVolToastState();
}

class __FijkVolToastState extends State<_FijkVolToast> {
  double vol;

  @override
  void initState() {
    super.initState();
    vol = FijkVolume.value.vol;
    FijkVolume.addListener(volChanged);
    FijkVolume.setUIMode(FijkVolume.hideUIWhenPlayable);
  }

  void volChanged() {
    FijkVolumeVal value = FijkVolume.value;
    setState(() {
      vol = value.vol;
    });
  }

  @override
  void dispose() {
    super.dispose();
    FijkVolume.removeListener(volChanged);
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData = Icons.volume_up;

    if (vol <= 0) {
      iconData = Icons.volume_mute;
    } else if (vol < 0.5) {
      iconData = Icons.volume_down;
    } else {
      iconData = Icons.volume_up;
    }

    String v = (vol * 100).toStringAsFixed(0);
    return Align(
      alignment: Alignment(0, -0.6),
      child: Container(
          color: Color(0x44554444),
          padding: EdgeInsets.all(5),
          decoration: null,
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                iconData,
                color: Colors.white,
                size: 30.0,
              ),
              Text(
                v,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  decoration: null,
                ),
              )
            ],
          )),
    );
  }
}
