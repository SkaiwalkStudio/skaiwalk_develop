import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ui_helper.dart';

class AppDialogs {
  static loadingDialog({required Widget child}) => UIHelper.blurredBackground(
      child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(top: 40.0, left: 5.0, right: 5.0),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          elevation: 0.0,
          child: child));
  static choiceDialog(
          {Key? key,
          required String content,
          required String textLeft,
          required String textRight,
          required VoidCallback callbackLeft,
          required VoidCallback callbackRight}) =>
      UIHelper.blurredBackground(
          child: CupertinoAlertDialog(
        content: Text(
          content,
          style: const TextStyle(fontSize: 20),
        ),
        actions: <Widget>[
          CupertinoButton(
            onPressed: callbackLeft,
            child: Text(textLeft),
          ),
          CupertinoButton(
            onPressed: callbackRight,
            child: Text(textRight),
          ),
        ],
      ));

  // This shows a CupertinoModalPopup with a reasonable fixed height which hosts
  // a CupertinoTimerPicker.
  static void showPopupDialog(BuildContext context,
      {required Widget child, required Function saveTarget}) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              // The bottom margin is provided to align the popup above the system
              // navigation bar.
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              // Provide a background color for the popup.
              color: CupertinoColors.systemBackground.resolveFrom(context),
              // Use a SafeArea widget to avoid system overlaps.
              child: SafeArea(
                top: false,
                child: child,
              ),
            )).then((_) => saveTarget());
  }
}

Future<T?> showCustomDialog<T>(
    {required BuildContext context,
    bool barrierDismissible = true,
    required WidgetBuilder builder,
    ThemeData? the}) {
  final ThemeData theme = Theme.of(context);
  return showGeneralDialog(
    context: context,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final Widget pageChild = Builder(builder: builder);
      return SafeArea(
        child: Builder(builder: (BuildContext context) {
          return Theme(data: theme, child: pageChild);
        }),
      );
    },
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black87, // 自定遮罩颜色
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: _buildMaterialDialogTransitions,
  );
}

Widget _buildMaterialDialogTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child) {
  // 使用缩放动画
  return ScaleTransition(
    scale: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ),
    child: child,
  );
}
