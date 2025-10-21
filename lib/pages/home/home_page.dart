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
  Map weatherData = {};

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
    Map weatherdata = await _getWeather();
    if (data.isNotEmpty) {
      final newWeekIndex = data['weekIndex'] as int;
      setState(() {
        appBarTitle = '第$newWeekIndex周│${data['isInSemester'] ? '📚' : '🥤'}';
        appBarSubtitle = data['currentSemester'];
        weekIndex = newWeekIndex;
        startDate = startInfo['startDate'];
        weatherData = weatherdata;
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
        padding: const EdgeInsets.only(top: 50, left: 8, right: 8, bottom: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
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
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          student['code'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
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
            _buildWeatherContainer(),
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

  Future<Map> _getWeather() async {
    final data = await getData(
      'http://t.weather.itboy.net/api/weather/city/101030500',
    );
    if (data.isNotEmpty) {
      return data;
    } else {
      return {};
    }
  }

  Widget _buildWeatherContainer() {
    debugPrint(weatherData.toString());

    if (weatherData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        child: const Center(child: Text('数据加载失败')),
      );
    }

    final wData = weatherData['data'];
    final cityInfo = weatherData['cityInfo'];
    final todayForecast = wData['forecast']?[0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${cityInfo['parent']}·${cityInfo['city']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.update,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    weatherData['time'] ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _getWeatherIcon(todayForecast['type']),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${todayForecast['low']?.split(' ')[1]?.replaceAll('℃', '') ?? '?'} ~ ${todayForecast['high']?.split(' ')[1]?.replaceAll('℃', '') ?? '?'}°C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    todayForecast['type'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '湿度 ${wData['shidu'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      wData['quality'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 8,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                todayForecast['notice'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.air_outlined,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${todayForecast['fx'] ?? 'N/A'} ${todayForecast['fl'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Icon _getWeatherIcon(String? type) {
    if (type == null) return const Icon(Icons.cloud_outlined, size: 35);

    switch (type) {
      case '多云':
        return Icon(
          Icons.cloud_outlined,
          size: 35,
          color: Theme.of(context).colorScheme.primary,
        );
      case '晴':
        return Icon(
          Icons.wb_sunny_outlined,
          size: 35,
          color: Theme.of(context).colorScheme.primary,
        );
      case '阴':
        return Icon(
          Icons.cloud_queue_outlined,
          size: 35,
          color: Theme.of(context).colorScheme.primary,
        );
      case '霾':
        return Icon(
          Icons.smoking_rooms_outlined,
          size: 35,
          color: Theme.of(context).colorScheme.primary,
        );
      default:
        return Icon(
          Icons.cloud_outlined,
          size: 35,
          color: Theme.of(context).colorScheme.primary,
        );
    }
  }
}
