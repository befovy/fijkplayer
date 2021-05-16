part of fijkplayer;

Widget customVideoProgressToast(double value, double total) {
  return _CustomVideoProgressToast(
    initial: value,
    total: total,
  );
}

class _CustomVideoProgressToast extends StatefulWidget {
  final double initial;
  final double total;

  const _CustomVideoProgressToast({Key key, this.initial, this.total})
      : super(key: key);

  @override
  _CustomVideoProgressToastState createState() =>
      _CustomVideoProgressToastState();
}

class _CustomVideoProgressToastState extends State<_CustomVideoProgressToast> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Align(
      alignment: Alignment(0, -0.4),
      child: Card(
        color: Color(0x33000000),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 100,
                height: 1.5,
                margin: EdgeInsets.only(left: 8),
                child: LinearProgressIndicator(
                  value: widget.initial / widget.total,
                  backgroundColor: Colors.black,
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                '${duration2String(Duration(milliseconds: widget.initial.toInt()))}',
                style: TextStyle(color: Colors.white),)
            ],
          ),
        ),
      ),
    );
  }
}
