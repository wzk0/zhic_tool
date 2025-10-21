import 'package:flutter/material.dart';
import 'package:zhic_tool/func/get_data.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的成绩')),
      body: FutureBuilder(
        future: getIdFromRedirect(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), Text('正在获取ID..')],
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('获取ID失败'));
          } else if (snapshot.hasData) {
            return FutureBuilder(
              future: getData(
                'https://eams.tjzhic.edu.cn/student/for-std/grade/sheet/info/${snapshot.data}?semester=81',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [CircularProgressIndicator(), Text('正在获取成绩..')],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(child: Text('获取成绩失败'));
                } else if (snapshot.hasData) {
                  List data = snapshot.data['semesterId2studentGrades']['81'];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.separated(
                      itemCount: data.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          Map me = calculateSummary(data);
                          return Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  top: 15,
                                  bottom: 15,
                                  left: 10,
                                  right: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '总学分: ${me['credits'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '平均成绩: ${me['averageScore'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    'GPA: ${me['GPA'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return _buildTile(data[index]);
                        }
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text('没有数据, 请尝试登陆'));
                }
              },
            );
          } else {
            return const Center(child: Text('没有数据, 请尝试登陆'));
          }
        },
      ),
    );
  }

  Widget _buildTile(Map data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      child: ListTile(
        dense: true,
        title: Text(data['courseName']),
        subtitle: Text('${data['courseCode']}│${data['courseProperty']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 15,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('学分'), Text('${data['credits']}')],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('绩点'), Text('${data['gp']}')],
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: data['passed']
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          child: Text(
            data['gaGrade'],
            style: TextStyle(
              fontSize: 12,
              color: data['passed']
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> calculateSummary(List courses) {
    double totalGpWeight = 0.0;
    double totalScoreWeight = 0.0;
    double totalCredits = 0.0;
    for (final course in courses) {
      if (course['passed'] != true) continue;
      final credits = (course['credits'] as num?)?.toDouble() ?? 0.0;
      if (credits <= 0) continue;
      final gp = (course['gp'] as num?)?.toDouble() ?? 0.0;
      debugPrint(gp.toString());
      final gradeStr = course['gaGrade'] as String?;
      final grade = double.tryParse(gradeStr ?? '') ?? 0.0;
      totalGpWeight += gp * credits;
      totalScoreWeight += grade * credits;
      totalCredits += credits;
    }
    final gpa = totalCredits > 0 ? (totalGpWeight / totalCredits) : 0.0;
    final averageScore = totalCredits > 0
        ? (totalScoreWeight / totalCredits)
        : 0.0;
    debugPrint(gpa.toString());
    return {'GPA': gpa, 'credits': totalCredits, 'averageScore': averageScore};
  }
}
