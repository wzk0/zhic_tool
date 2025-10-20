import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String loginUrl = 'https://eams.tjzhic.edu.cn/student/login';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登陆')),
      body: _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(loginUrl)),
      onWebViewCreated: (controller) {},
      onLoadStart: (controller, url) async {
        if (url != null && url.toString().contains('/home')) {
          final uri = WebUri(loginUrl);
          final cookies = await CookieManager.instance().getCookies(url: uri);
          final cookieString = cookies
              .map((c) => '${c.name}=${c.value}')
              .join('; ');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cookies', cookieString);
          if (mounted) {
            Navigator.pop(context, true);
            Fluttertoast.showToast(msg: '登录成功!');
          }
        }
      },
    );
  }
}
