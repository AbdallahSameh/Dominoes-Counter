import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class Results extends StatelessWidget {
  final XFile image;
  final CustomPainter painter;
  const Results({super.key, required this.image, required this.painter});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Image.file(File(image.path), fit: BoxFit.fill),
          CustomPaint(size: Size.infinite, painter: painter),
        ],
      ),
    );
  }
}
