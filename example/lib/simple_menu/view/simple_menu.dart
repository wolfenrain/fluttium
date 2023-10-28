import 'package:flutter/material.dart';

class SimpleMenuPage extends StatefulWidget {
  const SimpleMenuPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const SimpleMenuPage(),
    );
  }

  @override
  State<SimpleMenuPage> createState() => _SimpleMenuPageState();
}

class _SimpleMenuPageState extends State<SimpleMenuPage> {
  final widgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Menu')),
      body: Center(
        child: GestureDetector(
          key: widgetKey,
          child: Container(
            height: 60,
            width: 120,
            color: Colors.lightBlueAccent,
            child: const Center(child: Text('Show Menu')),
          ),
          onLongPress: () {
            showMenu(
              items: [
                const PopupMenuItem<void>(
                  child: Row(
                    children: [Text('Menu Item 1')],
                  ),
                ),
              ],
              context: context,
              position: _getRelativeRect(widgetKey),
            );
          },
        ),
      ),
    );
  }

  RelativeRect _getRelativeRect(GlobalKey key) {
    final renderBox = key.currentContext!.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    return RelativeRect.fromLTRB(
      offset.dx + 20,
      offset.dy + 20,
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height,
    );
  }
}
