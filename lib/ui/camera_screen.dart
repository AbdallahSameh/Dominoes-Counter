import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  List predictions = [];

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
    initCamera();
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
            child: ListView.separated(
              itemBuilder: (context, index) {
                return Text(predictions[index]);
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: 12);
              },
              itemCount: predictions.length,
            ),
          ),
        ],
      ),
    );
  }
}
