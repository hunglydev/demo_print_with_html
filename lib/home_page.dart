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
  double _webViewHeight = 800;
  String htmlContent = "";

  Uint8List? _uiImageBytes;
  Uint8List? _imagePackageBytes;

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
          onPageFinished: (String url) async {
            final height = await _controller.runJavaScriptReturningResult(
              'document.documentElement.scrollHeight;',
            );
            setState(() {
              _webViewHeight = double.parse(height.toString());
            });
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
    return Transform.scale(
      scale: 1.1,
      child: Container(
        width: MediaQuery.of(context).size.width + 20,
        color: Colors.white,
        height: _webViewHeight, //need provide
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  Future<void> _captureAndPrintImage() async {
    try {
      // Capture the widget as ui.Image
      final ui.Image? uiImage = await _captureWidgetAsImage();
      if (uiImage == null) {
        if (kDebugMode) {
          print("Cannot capture widget as image");
        }
        return;
      }

      final ByteData? byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (kDebugMode) {
          print("Cannot convert image to byte data");
        }
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Uint8List? jpegData = await convertPngToJpeg(pngBytes);
      // Decode using image package
      final img.Image? decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) {
        if (kDebugMode) {
          print("Cannot decode image using image package");
        }
        return;
      }

      // Optionally, resize for display or printing
      final img.Image scaledForPrint = img.copyResize(
        decodedImage,
        width: 580,
      );

      // Convert scaled image to Uint8List
      final Uint8List scaledPngBytes =
          Uint8List.fromList(img.encodePng(scaledForPrint));

      setState(() {
        _uiImageBytes = jpegData;
        _imagePackageBytes = scaledPngBytes;
      });

      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final PosPrintResult res =
          await printer.connect('192.168.29.150', port: 9100);

      // if (res == PosPrintResult.success) {
      //   printer.image(scaledForPrint);
      //   printer.feed(2);
      //   printer.cut();
      //
      //   printer.disconnect();
      //   if (kDebugMode) {
      //     print("Print successful");
      //   }
      // } else {
      //   if (kDebugMode) {
      //     print("Cannot connect to printer: ${res.msg}");
      //   }
      // }
    } catch (e) {
      if (kDebugMode) {
        print("Error capturing and printing image: $e");
      }
    }
  }

  Future<Uint8List?> convertPngToJpeg(Uint8List pngBytes,
      {int quality = 80}) async {
    img.Image? image = img.decodePng(pngBytes);
    if (image == null) {
      return null;
    }
    List<int> jpegBytes = img.encodeJpg(image, quality: quality);
    return Uint8List.fromList(jpegBytes);
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
      appBar: AppBar(
        title: const Text("Hiển Thị Hình Ảnh và Base64"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTemplate(),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _captureAndPrintImage();
                    },
                    child: const Text("In"),
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text("Set State"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (_uiImageBytes != null) ...[
                const Text(
                  "Ảnh raw:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Image.memory(
                  _uiImageBytes!,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
              ],
              if (_imagePackageBytes != null) ...[
                const Text(
                  "Ảnh cuôis:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Image.memory(
                  _imagePackageBytes!,
                  fit: BoxFit.cover,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
