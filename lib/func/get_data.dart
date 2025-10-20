// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

Future<String?> loadCookies() async {
  final prefs = await SharedPreferences.getInstance();
  final cookies = prefs.getString('cookies') ?? '';
  if (cookies.isEmpty) return null;
  return cookies.replaceAll('"', '');
}

Future<String?> getIdFromRedirect() async {
  final cookie = await loadCookies();
  final url = Uri.parse(
    'https://eams.tjzhic.edu.cn/student/for-std/grade/sheet/',
  );
  final cookies = cookie;
  final request = http.Request('GET', url);
  request.headers['Cookie'] = cookies!;
  request.followRedirects = false;
  try {
    final response = await http.Client().send(request);
    await response.stream.bytesToString();
    if (response.statusCode == 302 || response.statusCode == 301) {
      final location = response.headers['location'];
      if (location != null) {
        final uri = Uri.parse(location);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 6 &&
            pathSegments[pathSegments.length - 2] == 'semester-index') {
          final secretId = pathSegments.last;
          if (RegExp(r'^\d+$').hasMatch(secretId)) {
            return secretId;
          }
        }
      }
    } else {
      Fluttertoast.showToast(msg: '未发生重定向，状态码: ${response.statusCode}');
    }
  } catch (e) {
    Fluttertoast.showToast(msg: '请求失败: $e');
  }
  return null;
}

Future<dynamic> getData(String link, {int week = 1}) async {
  final uri = Uri.parse(link);
  final cookies = await loadCookies();
  final linkHash = md5.convert(utf8.encode(link)).toString();
  final cacheFileName = 'cache-$linkHash.json';
  try {
    final response = uri.toString().contains('search')
        ? await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookies ?? '',
            },
            body: jsonEncode({
              "teachingWeek": week,
              "campus": 2,
              "buildingAssocs": [],
              "roomAssocs": [],
              "seatsForLessonLowerLimit": "",
              "seatsForLessonUpperLimit": "",
              "enabled": 1,
            }),
          )
        : await http.get(
            uri,
            headers: {'Cookie': cookies ?? '', 'Accept': 'application/json'},
          );
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map || decoded is List) {
          await _saveCache(cacheFileName, decoded);
          await _updateCacheMap(link, cacheFileName);
          return decoded;
        }
      } catch (e) {}
    } else {}
  } catch (e) {}
  final cached = await _loadCacheFromMap(link);
  if (cached != null) {
    return cached;
  }
  Fluttertoast.showToast(msg: '无网络且无缓存，加载失败');
  return {};
}

Future<void> _saveCache(String fileName, dynamic data) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonEncode(data));
  } catch (e) {
    Fluttertoast.showToast(msg: '缓存保存失败: $e');
  }
}

Future<dynamic> _loadCache(String fileName) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      final contents = await file.readAsString();
      return jsonDecode(contents);
    }
  } catch (e) {
    Fluttertoast.showToast(msg: '缓存读取失败: $e');
  }
  return null;
}

Future<void> _updateCacheMap(String link, String fileName) async {
  final prefs = await SharedPreferences.getInstance();
  final String raw = prefs.getString('cache_map') ?? '{}';
  final dynamic cacheMap = jsonDecode(raw);
  cacheMap[link] = fileName;
  await prefs.setString('cache_map', jsonEncode(cacheMap));
}

Future<dynamic> _loadCacheFromMap(String link) async {
  final prefs = await SharedPreferences.getInstance();
  final String raw = prefs.getString('cache_map') ?? '{}';
  final dynamic cacheMap = jsonDecode(raw);
  if (cacheMap.containsKey(link)) {
    return _loadCache(cacheMap[link]);
  }
  return null;
}

Future<void> clearAllCache() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('cache_map') ?? '{}';
  final cacheMap = jsonDecode(raw);

  final dir = await getApplicationDocumentsDirectory();
  for (final file in cacheMap.values) {
    final f = File('${dir.path}/$file');
    if (await f.exists()) await f.delete();
  }

  await prefs.remove('cache_map');
  Fluttertoast.showToast(msg: '缓存已全部清除');
}
