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
  late final Future<void> initialized;
  List<Map<String, dynamic>> predictions = [];
  bool cameraOn = true;
  var input;
  late final Size previewSize;
  bool flashOn = false;

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
  void dispose() async {
    controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    controller == null && !controller!.value.isInitialized
                        ? Center(child: CircularProgressIndicator())
                        : cameraOn
                        ? Positioned.fill(child: CameraPreview(controller!))
                        : Results(
                            image: input,
                            painter: BoundingBoxesPaint(
                              boxes: predictions,
                              previewSize: previewSize,
                            ),
                          ),
                    Align(
                      alignment: Alignment.bottomRight,
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
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 50,
                  children: [
                    Container(
                      child: Column(
                        children: [
                          Text('Detected'),
                          Text('${predictions.length}'),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: Icon(Icons.add),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: Icon(Icons.minimize),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(onPressed: () {}, child: Text('Add')),
                        ElevatedButton(onPressed: () {}, child: Text('Cancel')),
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
    );
  }
}
