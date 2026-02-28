import 'package:camera/camera.dart';
import 'package:dominos_counter/ui/painter/bounding_boxes_paint.dart';
import 'package:dominos_counter/ui/screens/results.dart';
import 'package:dominos_counter/yolo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final initialized;
  List<Map<String, dynamic>> predictions = [];

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

  @override
  void initState() {
    super.initState();
    yoloService = YoloService();
    initialized = yoloService.initializeModel();
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
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: controller == null || !controller!.value.isInitialized
                ? Center(child: CircularProgressIndicator())
                : CameraPreview(controller!),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: Text('Count: ${predictions.length}')),
                ElevatedButton(
                  onPressed: () async {
                    await initialized;
                    var input = await controller!.takePicture();

                    final results = await yoloService.detectObjects(
                      await input.readAsBytes(),
                    );

                    yoloService.boundingBoxes(results);
                    setState(() {
                      predictions = results;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          final previewSize = Size(
                            controller!.value.previewSize!.height,
                            controller!.value.previewSize!.width,
                          );
                          return Results(
                            image: input,
                            painter: BoundingBoxesPaint(
                              boxes: predictions,
                              previewSize: previewSize,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: Text('Run Model'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
