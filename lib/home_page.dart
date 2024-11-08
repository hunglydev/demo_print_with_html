import 'dart:convert';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'common.dart';
import 'const.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _globalKey = GlobalKey();
  late WebViewController _controller;

  String htmlContent = "";
  @override
  void initState() {
    super.initState();
    htmlContent = decodeBase64ToHtml(htmlBase64);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            // Actions to perform when page starts loading
          },
          onPageFinished: (String url) {
            // Actions to perform when page finishes loading
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource errors
            if (kDebugMode) {
              print("WebView Error: ${error.description}");
            }
          },
        ),
      )
      ..loadRequest(
        Uri.dataFromString(
          htmlContent,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8'),
        ),
      );
  }

  Widget _buildTemplate() {
    return SizedBox(
      height: 400, //need provide
      child: WebViewWidget(controller: _controller),
    );
  }

  Future<void> _captureAndPrintImage() async {
    try {
      // Chụp ảnh từ widget và chuyển thành hình ảnh ui.Image
      final ui.Image? image = await _captureWidgetAsImage();
      if (image == null) {
        if (kDebugMode) {
          print("Không thể chụp widget thành hình ảnh");
        }
        return;
      }

      // Chuyển đổi ui.Image thành Uint8List
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (kDebugMode) {
          print("Không thể chuyển đổi hình ảnh thành dữ liệu byte");
        }
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final img.Image? decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) {
        if (kDebugMode) {
          print("Không thể giải mã hình ảnh từ Uint8List");
        }
        return;
      }

      final img.Image scaledForPrint = img.copyResize(
        decodedImage,
        width: 580,
      );

      // Thiết lập máy in
      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final PosPrintResult res =
          await printer.connect('192.168.29.150', port: 9100);

      if (res == PosPrintResult.success) {
        // In hình ảnh đã chụp được
        printer.image(scaledForPrint);
        printer.feed(2);
        printer.cut();

        // Ngắt kết nối sau khi in
        printer.disconnect();
        if (kDebugMode) {
          print("In thành công");
        }
      } else {
        if (kDebugMode) {
          print("Không thể kết nối tới máy in: ${res.msg}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Lỗi khi chụp và in hình ảnh: $e");
      }
    }
  }

  Future<ui.Image?> _captureWidgetAsImage() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (kDebugMode) {
          print("RenderRepaintBoundary không tồn tại");
        }
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 6.0);
      return image;
    } catch (e) {
      if (kDebugMode) {
        print("Lỗi khi chụp widget thành hình ảnh: $e");
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            RepaintBoundary(
              key: _globalKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildTemplate(),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _captureAndPrintImage();
              },
              child: const Text("Print"),
            ),
          ],
        ),
      ),
    );
  }
}
