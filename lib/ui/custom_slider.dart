part of fijkplayer;

/// FijkSlider is like Slider in Flutter SDK.
/// FijkSlider support [cacheValue] which can be used
/// to show the player's cached buffer.
/// The [colors] is used to make colorful painter to draw the line and circle.
class CustomSlider extends StatefulWidget {
  final double value;
  final double cacheValue;

  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;

  final double min;
  final double max;

  final FijkSliderColors colors;

  const CustomSlider({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.cacheValue = 0.0,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.colors = const FijkSliderColors(),
  })  : assert(value != null),
        assert(cacheValue != null),
        assert(min != null),
        assert(max != null),
        assert(min <= max),
        assert(value >= min && value <= max),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CustomSliderState();
  }
}

class _CustomSliderState extends State<CustomSlider> {
  bool dragging = false;

  double dragValue;

  static const double margin = 2.0;

  @override
  Widget build(BuildContext context) {
    double v = widget.value / (widget.max - widget.min);
    double cv = widget.cacheValue / (widget.max - widget.min);

    return Listener(
      child: GestureDetector(
        child: Container(
          margin: EdgeInsets.only(left: margin, right: margin),
          height: double.infinity,
          width: double.infinity,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _SliderPainter(v, cv, dragging, colors: widget.colors),
          ),
        ),
        onTap: (){
          //这里空实现，防止父组件响应点击事件
        },
        onHorizontalDragStart: (e){
          //这里空实现，防止父组件响应事件
        },
        onHorizontalDragUpdate: (e){
          //这里空实现，防止父组件响应事件
        },
        onHorizontalDragEnd: (e){
          //这里空实现，防止父组件响应事件
        },
      ),
      onPointerDown: (PointerDownEvent event) {
        setState(() {
          dragging = true;
        });
        final box = context.findRenderObject() as RenderBox;
        final dx = event.localPosition.dx;
        dragValue = (dx - margin) / (box.size.width - 2 * margin);
        dragValue = max(0, min(1, dragValue));
        dragValue = dragValue * (widget.max - widget.min) + widget.min;
        if (widget.onChangeStart != null) {
          widget.onChangeStart(dragValue);
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        final box = context.findRenderObject() as RenderBox;
        final dx = event.localPosition.dx;
        dragValue = (dx - margin) / (box.size.width - 2 * margin);
        dragValue = max(0, min(1, dragValue));
        dragValue = dragValue * (widget.max - widget.min) + widget.min;
        if (widget.onChanged != null) {
          widget.onChanged(dragValue);
        }
      },
      onPointerUp: (PointerUpEvent event) {
        setState(() {
          dragging = false;
        });
        if (widget.onChangeEnd != null) {
          widget.onChangeEnd(dragValue);
        }
      },
    );
  }
}
