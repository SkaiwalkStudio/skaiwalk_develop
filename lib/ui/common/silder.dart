import 'package:flutter/material.dart';

class CommonSlider extends StatefulWidget {
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final Function(double) onChanged;
  final String? hint;

  const CommonSlider({
    Key? key,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.hint = "Value",
  }) : super(key: key);

  @override
  State<CommonSlider> createState() => _CommonSliderState();
}

class _CommonSliderState extends State<CommonSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.min.toString(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Slider(
                value: _value,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                label: _value.toString(),
                onChanged: (double newValue) {
                  if (_value != newValue) {
                    setState(() {
                      _value = newValue;
                    });
                    widget.onChanged(_value);
                  }
                },
              ),
            ),
            const SizedBox(width: 20),
            Text(
              widget.max.toString(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "${widget.hint}: $_value",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}