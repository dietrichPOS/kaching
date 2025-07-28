//a 4x4 grid of buttons that will be used as a numeric keypad to return numbers to the parent widget
//the buttons need to be evenly spaced with equal width and height and will be used at the bottom of the display
//the buttons will be used to enter a number between 0 and 9

import 'package:flutter/material.dart';
import 'package:kaching/styles/app_styles.dart';

class NumberEntryGridWidget extends StatefulWidget {
  const NumberEntryGridWidget({required Key key, required this.onChanged})
      : super(key: key);
  final ValueChanged<String> onChanged;

  @override
  createState() => _NumberEntryGridWidgetState();
}

class _NumberEntryGridWidgetState extends State<NumberEntryGridWidget> {
  int randomNumber = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.green,
        child: Row(
          children: [
            Column(children: [
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(7.toString());
                        });
                      },
                      child: Text('7', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(8.toString());
                        });
                      },
                      child: Text('8', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(9.toString());
                        });
                      },
                      child: Text('9', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(4.toString());
                        });
                      },
                      child: Text('4', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(5.toString());
                        });
                      },
                      child: Text('5', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(6.toString());
                        });
                      },
                      child: Text('6', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(1.toString());
                        });
                      },
                      child: Text('1', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(2.toString());
                        });
                      },
                      child: Text('2', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(3.toString());
                        });
                      },
                      child: Text('3', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4 * 2,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(00.toString());
                        });
                      },
                      child: Text('00', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.numericButtonBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(
                                width: 0.1, // the thickness
                                color: Colors.grey // the color of the border
                                )),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onChanged(".".toString());
                        });
                      },
                      child: Text('.', style: AppStyles.numericButtonTextStyle),
                    ),
                  ),
                ],
              )
            ]),
            Column(children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width / 4,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.numericButtonBackgroundColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                          side: const BorderSide(
                              width: 0.1, // the thickness
                              color: Colors.grey // the color of the border
                              )),
                    ),
                    onPressed: () {
                      setState(() {
                        widget.onChanged('BACK');
                      });
                    },
                    child: const Icon(
                      Icons.backspace_rounded,
                      size: 32,
                      color: Colors.black,
                    )
                    ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width / 4,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.numericButtonBackgroundColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                            width: 0.1, // the thickness
                            color: Colors.grey // the color of the border
                            )),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.onChanged('0');
                    });
                  },
                  child: Text('0', style: AppStyles.numericButtonTextStyle),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width / 4 * 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.numericButtonBackgroundColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                        side: const BorderSide(
                            width: 0.1, // the thickness
                            color: Colors.grey // the color of the border
                            )),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.onChanged('OK');
                    });
                  },
                  child: Container(
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.fromLTRB(
                        0, MediaQuery.of(context).size.width / 16, 0, 0),
                    child: Text('OK', style: AppStyles.numericButtonTextStyle),
                  ),
                ),
              ),
            ]),
          ],
        ));
  }
}