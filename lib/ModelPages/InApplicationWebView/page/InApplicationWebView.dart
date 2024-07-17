import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:axpertflutter/Constants/MyColors.dart';
import 'package:axpertflutter/ModelPages/LandingMenuPages/MenuHomePagePage/Controllers/MenuHomePageController.dart';
import 'package:axpertflutter/Utils/ServerConnections/ServerConnections.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class InApplicationWebViewer extends StatefulWidget {
  InApplicationWebViewer(this.data);
  String data;
  @override
  State<InApplicationWebViewer> createState() => _InApplicationWebViewerState();
}

class _InApplicationWebViewerState extends State<InApplicationWebViewer> {
  dynamic argumentData = Get.arguments;
  var fileExt = "", fileName = "";
  MenuHomePageController menuHomePageController = Get.find();
  // final Completer<InAppWebViewController> _controller = Completer<InAppWebViewController>();
  late InAppWebViewController _webViewController;
  // final _key = UniqueKey();
  var hasAppBar = false;
  bool _progressBarActive = true;
  late StreamSubscription subscription;
  CookieManager cookieManager = CookieManager.instance();
  final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'ico', 'xlsx', 'xls', 'docx', 'doc', 'pdf'];

  @override
  void initState() {
    super.initState();
    try {
      if (argumentData != null) widget.data = argumentData[0];
      if (argumentData != null) hasAppBar = argumentData[1] ?? false;
    } catch (e) {}

    // widget.data = "https://amazon.in"
    print(widget.data);
    clearCookie();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      menuHomePageController.switchPage.value = false;
    });
    //Navigator.pop(context);
  }

  InAppWebViewSettings settings = InAppWebViewSettings(
    transparentBackground: true,
    javaScriptEnabled: true,
    // incognito: true,
    javaScriptCanOpenWindowsAutomatically: true,
    useOnDownloadStart: true,
    useShouldOverrideUrlLoading: true,
    // mediaPlaybackRequiresUserGesture: false,
    useHybridComposition: false,
    hardwareAcceleration: false,
  );

  void _download(String url) async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      var status;
      if (deviceInfo.version.sdkInt > 32) {
        status = await Permission.photos.request().isGranted;
        print(">32");
      } else {
        status = await Permission.storage.request().isGranted;
      }
      if (status) {
        Fluttertoast.showToast(
            msg: "Download Started...",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green.shade200,
            textColor: Colors.black,
            fontSize: 16.0);

        await FileDownloader.downloadFile(
          url: url,
          onProgress: (fileName, progress) {
            // print("On Progressssss");
          },
          onDownloadError: (errorMessage) {
            Get.snackbar("Error", "Download file error " + errorMessage,
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade300, colorText: Colors.white);
          },
          onDownloadCompleted: (path) {
            // print("Download Completed:   $path");
            //OpenFile.open(path);
            OpenFile.open(path);
          },
        );
      } else {
        print('Permission Denied');
      }
    }
    if (Platform.isIOS) {
      var status = await Permission.storage.request().isGranted;
      if (status) {
        Directory documents = await getApplicationDocumentsDirectory();
        print(documents.path);
        await FlutterDownloader.enqueue(
          url: url,
          // fileName: "Download.pdf",
          savedDir: documents.path,
          showNotification: true, // show download progress in status bar (for Android)
          openFileFromNotification: true, // click on notification to open downloaded file (for Android)
        );
        // print("Task id: $taskId");
      } else {
        print("Permission Denied");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: hasAppBar == true
            ? AppBar(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                centerTitle: false,
                title: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/pay_azzure_text.png",
                        height: 25,
                      ),
                      // Text(
                      //   "xpert",
                      //   style: TextStyle(fontFamily: 'Gellix-Black', color: HexColor("#133884"), fontWeight: FontWeight.bold),
                      // ),
                    ],
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: Builder(builder: (BuildContext context) {
            return Stack(children: <Widget>[
              InAppWebView(
                // initialUrlRequest: URLRequest(
                // url: WebUri.uri(Uri.parse("https://datatables.net/extensions/buttons/examples/initialisation/export.html"))),
                initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(widget.data))),
                initialSettings: settings,
                onWebViewCreated: (controller) {
                  try {
                    controller.addJavaScriptHandler(
                      handlerName: "downloadBlobFile",
                      callback: (data) async {
                        if (data.isNotEmpty) {
                          final String receivedFileInBase64 = data[0];
                          final String receivedMimeType = data[1];

                          // NOTE: create a method that will handle your extensions
                          final String yourExtension = "pdf"; //_mapMimeTypeToYourExtension(receivedMimeType); // 'pdf'

                          _createFileFromBase64(receivedFileInBase64, fileName);
                          Get.snackbar("Downloaded", fileName, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white)
                              .show();
                        }
                      },
                    );
                  } catch (e) {}
                  _webViewController = controller;
                },
                onDownloadStartRequest: (controller, downloadStartRequest) async {
                  // _download(downloadStartRequest.url.toString());

                  print("Download mimeType: ${downloadStartRequest.mimeType.toString()}");
                  print("Requested url: ${downloadStartRequest.url.toString()}");
                  fileName = downloadStartRequest.suggestedFilename.toString();
                  var jsContent = await rootBundle.loadString("assets/js/base64.js");
                  await controller.evaluateJavascript(
                      source: jsContent.replaceAll("blobUrlPlaceholder", downloadStartRequest.url.toString()));
                  // await _webViewController.evaluateJavascript(source: "downloadBlobFile()");
                },
                onCreateWindow: (controller, createWindowAction) async {
                  print("Created: ${await controller.getUrl()}");
                  return Future.value(true);
                },
                onProgressChanged: (controller, value) {
                  print('Progress---: $value : DT ${DateTime.now()}');
                  if (value == 100) {
                    setState(() {
                      _progressBarActive = false;
                    });
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  print("Override url: $uri");
                  if (imageExtensions.any((ext) => uri.toString().endsWith(ext))) {
                    _download(uri.toString());
                    return Future.value(NavigationActionPolicy.CANCEL);
                  }
                  return Future.value(NavigationActionPolicy.ALLOW);
                },
              ),
              _progressBarActive
                  ? Container(
                      color: Colors.white,
                      child: Center(
                        child: SpinKitRotatingCircle(
                          size: 40,
                          itemBuilder: (context, index) {
                            final colors = [MyColors.blue2, MyColors.blue2, MyColors.blue2];
                            final color = colors[index % colors.length];
                            return DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle));
                          },
                        ),
                      ))
                  : Stack(),
            ]);
          }),
        ),
        //floatingActionButton: favoriteButton(),
      ),
    );
  }

  void clearCookie() async {
    await cookieManager.deleteAllCookies();
    print("Cookie cleared");
  }

  _createFileFromBase64(String base64content, String fileName) async {
    var bytes = base64Decode(base64content.replaceAll('\n', ''));
    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/$fileName");
    await file.writeAsBytes(bytes.buffer.asUint8List());
    print("${output.path}/${fileName}");
    await OpenFile.open("${output.path}/$fileName");
    setState(() {});
  }
}
