import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MinimalServerApp());
}

class MinimalServerApp extends StatelessWidget {
  const MinimalServerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ServerScreen(),
    );
  }
}

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});
  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  String status = "جاري بدء السيرفر...";
  List<WebSocket> clients = [];

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      // 1. جلب IP الشبكة (الهوت سبوت)
      List<String> ips = [];
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) ips.add(addr.address);
        }
      }
      
      String hostIp = ips.isNotEmpty ? ips.first : '127.0.0.1';

      // 2. قراءة ملف الواجهة
      String htmlContent = await rootBundle.loadString('assets/index.html');

      // 3. تشغيل السيرفر على البورت 8080
      HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      
      setState(() {
        status = "✅ السيرفر يعمل بنجاح!\n\nللاعبين الآخرين:\nhttp://$hostIp:8080\n\nلك أنت (لتلعب):\nافتح كروم واكتب:\nhttp://127.0.0.1:8080";
      });

      // 4. الاستماع للاتصالات
      server.listen((HttpRequest request) {
        if (request.uri.path == '/ws') {
          // ترقية الاتصال إلى WebSocket
          WebSocketTransformer.upgrade(request).then((WebSocket ws) {
            clients.add(ws);
            ws.add("مرحباً بك! أنت متصل بالسيرفر الآن."); // رسالة ترحيبية فورية

            ws.listen((data) {
              // إعادة إرسال أي رسالة لجميع المتصلين للتأكيد
              for (var client in clients) {
                if (client.readyState == WebSocket.open) {
                  client.add(data);
                }
              }
            }, onDone: () => clients.remove(ws));
          }).catchError((e) {
            print("خطأ في WebSocket: $e");
          });
        } else {
          // إرسال صفحة الـ HTML
          request.response
            ..headers.contentType = ContentType.html
            ..write(htmlContent)
            ..close();
        }
      });
    } catch (e) {
      setState(() {
        status = "❌ فشل تشغيل السيرفر:\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, height: 1.8),
          ),
        ),
      ),
    );
  }
}
