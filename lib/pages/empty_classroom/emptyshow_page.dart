import 'package:flutter/material.dart';

class EmptyshowPage extends StatefulWidget {
  final Map data;

  const EmptyshowPage({super.key, required this.data});

  @override
  State<EmptyshowPage> createState() => _EmptyshowPageState();
}

class _EmptyshowPageState extends State<EmptyshowPage> {
  static const List<String> weekCN = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.data['roomNameZh'] ?? '')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.separated(
          itemCount: 8,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  title: Text(widget.data['roomNameZh'] ?? '未知教室'),
                  subtitle: Text(
                    '地点: ${widget.data['buildingNameZh'] ?? '未知'}',
                  ),
                  trailing: Text(
                    '可容纳人数: ${widget.data['seatsForLesson'] ?? '0'}',
                  ),
                ),
              );
            } else {
              int weekday = index;
              return _buildDay(weekday);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDay(int weekday) {
    List today =
        (widget.data['roomWeekUnitOccupationVms'] as List?)
            ?.where((d) => (d as Map)['weekday'] == weekday)
            .toList() ??
        [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                weekCN[weekday - 1],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      const SizedBox(width: 4),
                      const Text('被占用', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      const Text('空闲', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(today.length, (i) {
              final item = today[i] as Map;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (item['activityType'] != null)
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '第${item['unit']}节',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
