import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VocationPage extends StatefulWidget {
  const VocationPage({super.key});

  @override
  State<VocationPage> createState() => _VocationPageState();
}

class _VocationPageState extends State<VocationPage> {
  String loginUrl = 'http://work.tjzhic.edu.cn:7565/dormitory/index';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('请假')),
      body: _buildWebView(),
    );
  }

  Widget _buildWebView() {
    Fluttertoast.showToast(msg: '初始密码: tjzhic2015');
    return InAppWebView(initialUrlRequest: URLRequest(url: WebUri(loginUrl)));
  }
}
