// lib/version_checker.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class VersionChecker {
  static const String _owner = 'wzk0'; // 你的 GitHub 用户名
  static const String _repo = 'zhic_tool'; // 你的仓库名
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// 检查是否有新版本
  /// 如果有新版本，返回包含最新版本信息的 [UpdateInfo] 对象
  /// 如果没有更新或检查失败，返回 null
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          // 可选：如果你的仓库是私有的，需要提供认证信息
          // 'Authorization': 'token YOUR_GITHUB_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> releaseData = json.decode(response.body);

        final String latestTag = releaseData['tag_name'] ?? '';
        final String releaseNotes = releaseData['body'] ?? '';
        final String htmlUrl = releaseData['html_url'] ?? '';

        if (latestTag.isEmpty) {
          debugPrint(
            'Error: Could not parse latest tag from GitHub API response.',
          );
          return null;
        }

        // 获取当前应用版本
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        // 使用 Version 包进行比较，需要去除可能的 'v' 前缀
        Version currentVer = Version.parse(
          currentVersion.startsWith('v')
              ? currentVersion.substring(1)
              : currentVersion,
        );
        Version latestVer = Version.parse(
          latestTag.startsWith('v') ? latestTag.substring(1) : latestTag,
        );

        if (latestVer > currentVer) {
          return UpdateInfo(
            latestVersion: latestTag,
            releaseNotes: releaseNotes,
            downloadUrl: htmlUrl,
          );
        } else {
          debugPrint('No new version available.');
        }
      } else {
        debugPrint(
          'Failed to fetch latest release: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error during update check: $e');
    }
    return null; // 检查失败或无更新
  }
}

/// 存储更新信息的数据类
class UpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}
