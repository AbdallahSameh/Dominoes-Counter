import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:dominos_counter/models/log.dart';
import 'package:dominos_counter/ui/painter/bounding_boxes_paint.dart';
import 'package:dominos_counter/ui/screens/results.dart';
import 'package:dominos_counter/yolo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  late YoloService yoloService;
  late final Future<void> initialized;
  List<Map<String, dynamic>> predictions = [];
  int predictionsCount = 0;
  bool cameraOn = true;
  var input;
  late Size previewSize;
  bool flashOn = false;
  SharedPreferences? prefs;
  List<String> logs = [];
  int score = 0;

  initCamera() async {
    List<CameraDescription> _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      setState(() {
        cameras = _cameras;
        controller = CameraController(cameras[0], ResolutionPreset.medium);
        controller!
            .initialize()
            .then((_) {
              if (!mounted) {
                return;
              }
              setState(() {});
            })
            .catchError((e) {
              if (e is CameraException) {
                print('Camera permission denied');
              }
            });
      });
    }
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      logs = prefs?.getStringList('logs') ?? [];
      score = prefs?.getInt('score') ?? 0;
    });
  }

  @override
  void initState() {
    super.initState();
    yoloService = YoloService();
    initialized = yoloService.initializeModel();
    initPrefs();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    initCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(child: Text('Logs')),
            Expanded(
              child: ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (index, context) => SizedBox(height: 10),
                itemBuilder: (context, index) {
                  Log item = Log.fromJson(jsonDecode(logs[index]));
                  return ListTile(
                    title: Text(item.count.toString()),
                    trailing: Text(
                      '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await prefs?.setStringList('logs', []);
                await initPrefs();
              },
              child: Text('Reset Logs'),
            ),
            ElevatedButton(
              onPressed: () async {
                await prefs?.setInt('score', 0);
                await initPrefs();
              },
              child: Text('Reset Score'),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BackgroundImage.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/CameraCard.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.all(Radius.elliptical(32, 50)),
                      boxShadow: [
                        BoxShadow(offset: Offset(0, 2), blurRadius: 10),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(7.2, 10, 7.2, 12),
                      child: Stack(
                        children: [
                          controller == null || !controller!.value.isInitialized
                              ? Center(child: CircularProgressIndicator())
                              : Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.elliptical(32, 50),
                                    ),
                                    child: cameraOn
                                        ? CameraPreview(controller!)
                                        : Results(
                                            image: input,
                                            painter: BoundingBoxesPaint(
                                              boxes: predictions,
                                              previewSize: previewSize,
                                            ),
                                          ),
                                  ),
                                ),

                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () async {
                                if (controller == null ||
                                    !controller!.value.isInitialized)
                                  return;

                                setState(() {
                                  flashOn = !flashOn;
                                });

                                await controller!.setFlashMode(
                                  flashOn ? FlashMode.torch : FlashMode.off,
                                );
                              },
                              icon: flashOn
                                  ? Icon(Icons.flash_on)
                                  : Icon(Icons.flash_off),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              child: Text(
                                'Detected: $predictionsCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 50,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 215,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/images/ScoreBoard(stretched_to_the_limit).png',
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xfff7d98a),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                predictionsCount++;
                              });
                            },
                            child: Icon(Icons.add),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                predictionsCount--;
                              });
                            },
                            child: Icon(Icons.minimize),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              Log log = Log(
                                count: predictionsCount,
                                time: DateTime.now(),
                              );

                              logs.add(jsonEncode(log.toJson()));
                              score += predictionsCount;
                              predictionsCount = 0;

                              await prefs?.setInt('score', score);
                              await prefs?.setStringList('logs', logs);
                              cameraOn = true;
                              await initPrefs();
                            },
                            child: Text('Confirm'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                cameraOn = true;
                                predictionsCount = 0;
                              });
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await initialized;
                          previewSize = Size(
                            controller!.value.previewSize!.height,
                            controller!.value.previewSize!.width,
                          );
                          input = await controller!.takePicture();

                          final results = await yoloService.detectObjects(
                            await input.readAsBytes(),
                          );

                          yoloService.boundingBoxes(results);
                          setState(() {
                            predictions = results;
                            predictionsCount = results.length;
                            cameraOn = false;
                          });
                        },
                        child: Text('Run Model'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
