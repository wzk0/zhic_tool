// lib/updatedialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Updatedialog extends StatelessWidget {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  const Updatedialog({
    super.key,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('发现新版本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最新版本: $latestVersion'),
          const SizedBox(height: 8),
          const Text('更新内容:', style: TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: SingleChildScrollView(
              child: Text(releaseNotes.isEmpty ? '暂无更新说明。' : releaseNotes),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('稍后再说'),
        ),
        TextButton(
          onPressed: () {
            _launchUrl(downloadUrl);
            Navigator.of(context).pop();
          },
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
