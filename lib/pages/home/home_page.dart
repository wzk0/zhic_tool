import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhic_tool/func/get_data.dart';
import 'package:zhic_tool/pages/color_lens/colorlens_page.dart';
import 'package:zhic_tool/pages/empty_classroom/emptysearch_page.dart';
import 'package:zhic_tool/pages/login/login_page.dart';
import 'package:zhic_tool/pages/score/score_page.dart';
import 'package:zhic_tool/pages/vocation/vocation_page.dart';
import 'package:zhic_tool/widgets/schedule.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _cookies = '';
  String appBarTitle = '掌环';
  String appBarSubtitle = '课表速览, 离线缓存';
  int weekIndex = 0;
  String startDate = '2025-09-08';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 19, vsync: this);
    _loadCookies();
    _loadInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    final data = await getData(
      'https://eams.tjzhic.edu.cn/student/home/get-current-teach-week',
    );
    final startInfo = await getData(
      'https://eams.tjzhic.edu.cn/student/ws/semester/get/82',
    );
    if (data.isNotEmpty) {
      final newWeekIndex = data['weekIndex'] as int;
      setState(() {
        appBarTitle = '第$newWeekIndex周│${data['isInSemester'] ? '📚' : '🥤'}';
        appBarSubtitle = data['currentSemester'];
        weekIndex = newWeekIndex;
        startDate = startInfo['startDate'];
      });
      if (newWeekIndex >= 1 && newWeekIndex <= 19 && mounted) {
        _tabController.animateTo(newWeekIndex - 1);
      }
    }
  }

  Future<void> _loadCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final cookies = prefs.getString('cookies') ?? '';
    setState(() {
      _cookies = cookies;
    });
  }

  Future<void> _removeCookies() async {
    final cookieManager = CookieManager.instance();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cookies');
    final success = await cookieManager.deleteAllCookies();
    Fluttertoast.showToast(msg: success ? '已登出' : '登出失败');
    if (mounted) {
      setState(() {
        _cookies = '';
      });
    }
  }

  Future<Map<String, dynamic>> _loadScheduleData() async {
    return await getData(
      'https://eams.tjzhic.edu.cn/student/for-std/course-table/semester/82/print-data?semesterId=82&hasExperiment=true',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _cookies.isEmpty
          ? const Drawer(child: Center(child: Text('未登录，请先登录')))
          : FutureBuilder<Map<String, dynamic>>(
              future: _loadScheduleData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Drawer(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Drawer(child: Center(child: Text('加载失败，请重新登录')));
                } else {
                  return _buildDrawer(snapshot.data!);
                }
              },
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey<String>(appBarTitle),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(appBarTitle, style: const TextStyle(fontSize: 18)),
                if (_cookies.isNotEmpty)
                  Text(
                    appBarSubtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            tabAlignment: TabAlignment.center,
            tabs: List.generate(19, (week) => Text('第${week + 1}周')),
          ),
          actions: [
            IconButton(
              icon: Icon(_cookies.isNotEmpty ? Icons.refresh : Icons.login),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
                if (result == true) {
                  _loadCookies();
                }
              },
              tooltip: '登录',
            ),
            if (_cookies.isNotEmpty)
              IconButton(
                onPressed: _removeCookies,
                icon: const Icon(Icons.logout),
                tooltip: '登出',
              ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cookies.isNotEmpty ? _loadScheduleData() : null,
        builder: (context, snapshot) {
          Widget child;
          if (_cookies.isEmpty) {
            child = const Center(child: Text('没有登陆, 请点击右上角登陆'));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            child = const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            child = const Center(child: Text('数据获取失败, 请尝试登陆'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            child = const Center(child: Text('没有数据, 请尝试登陆'));
          } else {
            final data = snapshot.data!;
            child = TabBarView(
              controller: _tabController,
              children: List.generate(19, (week) {
                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: Schedule(
                    data: data['studentTableVms'][0]['activities'],
                    week: week + 1,
                    weekday: DateTime.now().weekday,
                    weekIndex: weekIndex,
                    startDate: startDate,
                  ),
                );
              }),
            );
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildDrawer(Map<String, dynamic> data) {
    final student = data['studentTableVms'][0];
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 40),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: ListTile(
                    title: Text(
                      student['name'],
                      style: TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      '${student['department']}\n${student['adminclass']}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        student['name'].substring(0, 1),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      student['code'],
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _buildTile('空教室', Icons.timelapse, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return EmptysearchPage(week: weekIndex);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildTile('我的成绩', Icons.auto_graph_rounded, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const ScorePage();
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildTile('考试信息', Icons.edit, () {
                    Fluttertoast.showToast(msg: '暂未开放');
                  }),
                  const SizedBox(height: 10),
                  _buildTile('选课', Icons.class_, () {
                    Fluttertoast.showToast(msg: '暂未开放');
                  }),
                  const SizedBox(height: 10),
                  _buildTile('评教', Icons.comment, () {
                    Fluttertoast.showToast(msg: '暂未开放');
                  }),
                  const SizedBox(height: 10),
                  _buildTile('请假', Icons.directions_bike, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return VocationPage();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildTile('主题色', Icons.color_lens, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const ColorlensPage();
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(title: Text(title), leading: Icon(icon), dense: true),
    );
  }
}
