import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Schedule extends StatefulWidget {
  final List data;
  final int weekday;
  final int week;
  final int weekIndex;
  final String startDate;

  const Schedule({
    super.key,
    required this.data,
    required this.week,
    required this.weekday,
    required this.weekIndex,
    required this.startDate,
  });

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  static const int totalUnits = 12;
  static const double unitHeight = 58;
  final List<String> weekDay = ['Mon.', 'Tue.', 'Wed.', 'Thu.', 'Fri.', 'Sat.'];
  final List<String> weekDayCN = ['周一', '周二', '周三', '周四', '周五', '周六'];
  final List<String> timeTab = [
    '8:00',
    '9:25',
    '9:50',
    '11:15',
    '12:00',
    '13:30',
    '14:55',
    '15:05',
    '16:30',
    '17:15',
    '18:00',
    '19:25',
  ];
  DateTime _parseStartDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date format. Expected YYYY-MM-DD');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final semesterStart = _parseStartDate(widget.startDate);
    final mondayOfTargetWeek = semesterStart.add(
      Duration(days: (widget.week - 1) * 7),
    );
    final weekDates = List.generate(
      6,
      (i) => mondayOfTargetWeek.add(Duration(days: i)),
    );

    return Row(
      spacing: 3,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColTitle(),
        ...List.generate(6, (i) {
          final date = weekDates[i];
          final isToday =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return Expanded(
            child: Column(
              spacing: 3,
              children: [
                Text(
                  weekDay[i],
                  style: TextStyle(
                    color: isToday
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  "${date.month}.${date.day}",
                  style: TextStyle(
                    color: isToday
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                ..._buildCol(i + 1),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmpty(double height) => SizedBox(height: height);

  Widget _buildCraft(Map data, double height) {
    return SizedBox(
      height: height,
      child: GestureDetector(
        onTap: () {
          Fluttertoast.showToast(
            msg:
                '上课时间: ${data['startTime']}~${data['endTime']}\n授课老师: ${data['teachers'][0]}',
          );
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: widget.weekday == data['weekday']
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['courseName'],
                style: TextStyle(
                  fontSize: 11,
                  color: widget.weekday == data['weekday']
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                data['room'],
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCol(int weekday) {
    List<Widget> today = [];
    List data = widget.data;
    data.sort(
      (a, b) => (a['startUnit'] as int).compareTo(b['startUnit'] as int),
    );
    int currentUnit = 1;
    for (Map d in data) {
      if (!d['weekIndexes'].contains(widget.week) || d['weekday'] != weekday) {
        continue;
      }
      int start = d['startUnit'];
      int end = d['endUnit'];
      if (start > currentUnit) {
        today.add(_buildEmpty((start - currentUnit) * unitHeight));
      }
      today.add(_buildCraft(d, (end - start + 1) * unitHeight));
      currentUnit = end + 1;
    }
    if (currentUnit <= totalUnits) {
      today.add(_buildEmpty((totalUnits - currentUnit + 1) * unitHeight));
    }
    return today;
  }

  Widget _buildColTitle() {
    return Column(
      children: [
        const SizedBox(height: 36),
        ...List.generate(12, (index) {
          return Container(
            height: unitHeight,
            alignment: Alignment.center,
            child: Text(
              "第${index + 1}节\n${timeTab[index]}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }),
      ],
    );
  }
}
