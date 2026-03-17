import 'package:flutter/material.dart';

class RPSCustomPainter extends CustomPainter {
  final double rotation; // Rotation in radians
  final Size? customSize; // Custom size for the shape
  
  RPSCustomPainter({
    this.rotation = 0.0,
    this.customSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Use custom size if provided, otherwise use canvas size
    final drawSize = customSize ?? size;
    
    // Calculate offset to center the shape if custom size is used
    final offsetX = customSize != null ? (size.width - customSize!.width) / 2 : 0.0;
    final offsetY = customSize != null ? (size.height - customSize!.height) / 2 : 0.0;
    
    // Save canvas state
    canvas.save();
    
    // Translate to center if custom size is used
    if (customSize != null) {
      canvas.translate(offsetX, offsetY);
    }
    
    // Apply rotation around center
    final center = Offset(drawSize.width / 2, drawSize.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    
    // Layer 1 - Fill
    Paint paint_fill_0 = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..strokeWidth = drawSize.width * 0.00
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    Path path_0 = Path();
    path_0.moveTo(drawSize.width * 0.1250000, drawSize.height * 0.9928571);
    path_0.lineTo(drawSize.width * 0.4991667, drawSize.height * 0.5700000);
    path_0.lineTo(drawSize.width * 0.8758333, drawSize.height * 0.9971429);
    path_0.close(); // Close the path to form a triangle
    
    canvas.drawPath(path_0, paint_fill_0);

    // Layer 1 - Stroke
    Paint paint_stroke_0 = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color.fromARGB(0, 33, 150, 243)
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path_0, paint_stroke_0);
    
    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RPSCustomPainter oldDelegate) {
    return oldDelegate.rotation != rotation || 
           oldDelegate.customSize != customSize;
  }
}

