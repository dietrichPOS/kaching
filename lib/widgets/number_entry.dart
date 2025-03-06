import 'package:flutter/material.dart';
import 'dart:math';

class NumberEntryWidget extends StatefulWidget {
  const NumberEntryWidget({required Key key, required this.onChanged})
      : super(key: key);
  final ValueChanged<String> onChanged;

  @override
  createState() => _NumberEntryWidgetState();
}

class _NumberEntryWidgetState extends State<NumberEntryWidget> {
  int randomNumber = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            randomNumber = Random().nextInt(100);
            widget.onChanged(randomNumber.toString());
          });
        },
        child: const Text('Generate'),
      ),
    );
  }
}
