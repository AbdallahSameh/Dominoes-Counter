import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    List predictions = [];
    return Column(
      children: [
        // Camera Preview
        Expanded(flex: 4, child: Placeholder()),
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
    );
  }
}
