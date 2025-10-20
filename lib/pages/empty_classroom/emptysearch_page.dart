import 'package:flutter/material.dart';
import 'package:zhic_tool/func/get_data.dart';
import 'package:zhic_tool/pages/empty_classroom/emptyshow_page.dart';

class EmptysearchPage extends StatefulWidget {
  final int week;
  const EmptysearchPage({super.key, required this.week});

  @override
  State<EmptysearchPage> createState() => _EmptysearchPageState();
}

class _EmptysearchPageState extends State<EmptysearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('空教室')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<dynamic>(
          future: getData(
            'https://eams.tjzhic.edu.cn/student/for-std/room-week-occupation/semester/82/search',
            week: widget.week,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              List widgetList = _buildTiles(snapshot.data);
              return ListView.separated(
                itemBuilder: (context, index) {
                  return widgetList[index];
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 8);
                },
                itemCount: widgetList.length,
              );
            } else {
              return SizedBox();
            }
          },
        ),
      ),
    );
  }

  List<Widget> _buildTiles(List data) {
    return List.generate(data.length, (i) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        child: ListTile(
          title: Text(data[i]['roomNameZh']),
          trailing: IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EmptyshowPage(data: data[i]),
                ),
              );
            },
            icon: Icon(Icons.arrow_forward),
          ),
        ),
      );
    });
  }
}
