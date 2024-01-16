import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? topRightWidget;
  final Color? hoverColor;
  final void Function()? onTap;
  const MenuCard({
    Key? key,
    this.title,
    required this.child,
    this.topRightWidget,
    this.hoverColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: hoverColor ?? Theme.of(context).canvasColor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        width: double.infinity,
        child: Stack(alignment: AlignmentDirectional.topCenter, children: [
          if ((topRightWidget != null))
            Positioned(
              top: 1,
              right: 1,
              child: topRightWidget!,
            ),
          Column(
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 10)
              ],
              child,
            ],
          ),
        ]),
      ),
    );
  }
}
