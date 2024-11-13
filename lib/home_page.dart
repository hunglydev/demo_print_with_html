import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image/image.dart' as img;
import 'common.dart';
import 'const.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final GlobalKey _globalKey = GlobalKey();
  InAppWebViewController? _webViewController;
  double _webViewHeight = 800;
  String htmlContent = "";

  Uint8List? _uiImageBytes;
  Uint8List? _imagePackageBytes;

  @override
  void initState() {
    super.initState();
    htmlContent = decodeBase64ToHtml(htmlBase64);
  }

  Widget _buildTemplate() {
    return SizedBox(
      height: _webViewHeight,
      width: MediaQuery.of(context).size.width,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: htmlContent,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStop: (controller, url) async {
          String? heightString = await controller.evaluateJavascript(
              source: "document.body.scrollHeight.toString();");
          double height = double.tryParse(heightString ?? '800') ?? 800;
          setState(() {
            _webViewHeight = height.toDouble();
          });
        },
        onProgressChanged: (controller, progress) {
        },
        onConsoleMessage: (controller, consoleMessage) {
          if (kDebugMode) {
            print("Console Message: ${consoleMessage.message}");
          }
        },
      ),
    );
  }

  Future<void> _captureAndPrintImage() async {
    try {
      Uint8List? imageBytes;

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        // Sử dụng phương thức takeScreenshot của InAppWebView
        if (_webViewController != null) {
          imageBytes = await _webViewController!.takeScreenshot();
        }
      }

      if (imageBytes == null) {
        if (kDebugMode) {
          print("Captured image is null");
        }
        return;
      }

      // Decode using image package
      final img.Image? decodedImage = img.decodeImage(imageBytes);
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

      // // Convert scaled image to Uint8List
      // final Uint8List scaledPngBytes =
      //     Uint8List.fromList(img.encodePng(scaledForPrint));

      // setState(() {
      //   _uiImageBytes = imageBytes;
      //   _imagePackageBytes = scaledPngBytes;
      // });

      // Proceed to print
      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final PosPrintResult res =
          await printer.connect('192.168.29.150', port: 9100);

      if (res == PosPrintResult.success) {
        printer.image(scaledForPrint);
        printer.feed(2);
        printer.cut();

        printer.disconnect();
        if (kDebugMode) {
          print("Print successful");
        }
      } else {
        if (kDebugMode) {
          print("Cannot connect to printer: ${res.msg}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error capturing and printing image: $e");
      }
    }
  }

  // Future<ui.Image?> _captureWidgetAsImage() async {
  //   try {
  //     final boundary = _globalKey.currentContext?.findRenderObject()
  //         as RenderRepaintBoundary?;
  //     if (boundary == null) {
  //       if (kDebugMode) {
  //         print("RenderRepaintBoundary không tồn tại");
  //       }
  //       return null;
  //     }
  //
  //     final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  //     return image;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print("Lỗi khi chụp widget thành hình ảnh: $e");
  //     }
  //     return null;
  //   }
  // }

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
              SizedBox(
                width: MediaQuery.of(context).size.width + 20,
                height: _webViewHeight,
                child: _buildTemplate(),
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
                  "Ảnh cuối:",
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
