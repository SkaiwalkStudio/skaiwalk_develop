import 'package:flutter/material.dart';

class LogTextView extends StatefulWidget {
  final List<String> logs;
  final double maxHeight;

  const LogTextView({super.key, required this.logs, this.maxHeight = 300});

  @override
  State<LogTextView> createState() => _LogTextViewState();
}

class _LogTextViewState extends State<LogTextView> {
  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 0.0);

  @override
  void didUpdateWidget(covariant LogTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to the bottom of the list whenever the logs change
    if (widget.logs.length != oldWidget.logs.length) {
      scroll2Bottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.logs.isNotEmpty,
      child: SizedBox(
        height: widget.maxHeight,
        child: Stack(
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.logs.length,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Text(
                    widget.logs[index],
                  ),
                );
              },
              //Add scrollbar
              physics: const ClampingScrollPhysics(),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: RawMaterialButton(
                onPressed: () {
                  scroll2Bottom();
                },
                elevation: 2.0,
                padding: const EdgeInsets.all(10.0),
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.expand_more,
                  color: Colors.blue,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void scroll2Bottom() async {
    await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut);
  }
}
