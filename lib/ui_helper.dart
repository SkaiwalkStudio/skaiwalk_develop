import 'dart:ui';

import 'package:flutter/material.dart';

const defalutHorizontalPadding = 15.0;

const Widget horizontalSpaceTiny = SizedBox(width: 5.0);
const Widget horizontalSpaceSmall = SizedBox(width: 10.0);
const Widget horizontalSpaceRegular = SizedBox(width: 18.0);
const Widget horizontalSpaceMedium = SizedBox(width: 25.0);
const Widget horizontalSpaceLarge = SizedBox(width: 50.0);

const Widget verticalSpaceTiny = SizedBox(height: 5.0);
const Widget verticalSpaceSmall = SizedBox(height: 10.0);
const Widget verticalSpaceRegular = SizedBox(height: 20.0);
const Widget verticalSpaceMedium = SizedBox(height: 25.0);
const Widget verticalSpaceLarge = SizedBox(height: 50.0);

const EdgeInsets horizontalPaddingTiny = EdgeInsets.only(left: 5.0, right: 5.0);
const EdgeInsets horizontalPaddingSmall =
    EdgeInsets.only(left: 10.0, right: 10.0);
const EdgeInsets horizontalPaddingRegular =
    EdgeInsets.only(left: 25.0, right: 25.0);
const EdgeInsets horizontalPaddingMedium =
    EdgeInsets.only(left: 50.0, right: 50.0);

const RoundedRectangleBorder defaultRoundedRectangleBorder =
    RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(20.0)),
);

double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

double screenWidthPercentage(BuildContext context, {double percentage = 1.0}) =>
    screenWidth(context) * percentage;
double screenHeightPercentage(BuildContext context,
        {double percentage = 1.0}) =>
    screenHeight(context) * percentage;

double widgetLengthPercentage(double widgetLength, {double percentage = 1.0}) =>
    widgetLength * percentage;

class UIHelper {
  static Widget blurredBackground(
      {required Widget child, bool withGoBack = true}) {
    Widget background = Stack(
      children: [
        // Add a blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0),
            ),
          ),
        ),
        child,
      ],
    );
    return background;
  }
}
