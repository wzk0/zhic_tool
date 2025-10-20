import 'package:flutter/material.dart';
import 'package:zhic_tool/widgets/colorcraft.dart';

class ColorlensPage extends StatefulWidget {
  const ColorlensPage({super.key});

  @override
  State<ColorlensPage> createState() => _ColorlensPageState();
}

class _ColorlensPageState extends State<ColorlensPage> {
  @override
  Widget build(BuildContext context) {
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.lime,
    ];
    return Scaffold(
      appBar: AppBar(title: Text('主题色')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 12, children: _buildColor(colors)),
            const Divider(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: const Text('示例'),
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.color_lens_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Primary',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  'Secondary',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                trailing: Container(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: 4,
                    left: 8,
                    right: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Tertiary',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildColor(List colors) {
    List<Widget> widgetList = [];
    for (Color c in colors) {
      widgetList.add(Colorcraft(colorSeed: c));
    }
    return widgetList;
  }
}
