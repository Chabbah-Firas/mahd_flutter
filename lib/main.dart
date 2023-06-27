import 'package:flutter/material.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

final info = NetworkInfo();

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  String selectedIP = '';

  Set<String> discoveredIPs = {};

  Future<void> scanNetwork() async {
    final wifiIP = await NetworkInfo().getWifiIP();
    if (wifiIP == null) {
      print('Failed to retrieve Wi-Fi IP address.');
      return;
    }

    final subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));
    const port = 22;

    for (var i = 1; i <= 255; i++) {
      final ip = '$subnet.$i';

      try {
        await Socket.connect(ip, port, timeout: Duration(milliseconds: 50));
      } on SocketException catch (error) {
        if (error.osError?.errorCode == 111) {
          setState(() {
            discoveredIPs.add(ip);
          });
        }
      }
    }

    print('Done');
  }

  void openWebView() {
    final url = 'http://$selectedIP';
    flutterWebviewPlugin.launch(
      url,
      rect: Rect.fromLTWH(
        0.0,
        0.0,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
    );
  }

  @override
  void dispose() {
    flutterWebviewPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedIP.isNotEmpty) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        openWebView();
        selectedIP = ''; // Reset the selected IP address
      });
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Network Scanner'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  scanNetwork(); // Call the network scanning function here
                },
                child: const Text('Scan0 Network'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: discoveredIPs.length,
                  itemBuilder: (context, index) {
                    final ip = discoveredIPs.toList()[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIP = ip;
                        });
                      },
                      child: ListTile(
                        title: Text(ip),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}