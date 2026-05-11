import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../cart/provider/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';

class LiveMakeupCameraScreen extends StatefulWidget {
  final String productType;
  final Map<String, dynamic> product;

  const LiveMakeupCameraScreen({
    super.key,
    required this.productType,
    required this.product,
  });

  @override
  State<LiveMakeupCameraScreen> createState() => _LiveMakeupCameraScreenState();
}

class _LiveMakeupCameraScreenState extends State<LiveMakeupCameraScreen> {
  CameraController? _controller;
  late final FaceDetector _faceDetector;

  bool _ready = false;
  bool _busy = false;
  bool _cameraError = false;

  String _status = 'Iniciando cámara...';

  List<Face> _faces = [];
  Size? _imageSize;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  CameraLensDirection _lensDirection = CameraLensDirection.front;

  int _selectedTone = 0;

  final List<Color> _labialTones = const [
    Color(0xFF8B0015),
    Color(0xFFC2185B),
    Color(0xFFFF1744),
  ];

  final List<Color> _ruborTones = const [
    Color(0xFFFFB6C1),
    Color(0xFFFF7F9C),
    Color(0xFFE75480),
  ];

  String get _productName =>
      widget.product['name']?.toString().toLowerCase().trim() ?? '';

  String get _type => widget.productType.toLowerCase().trim();

  bool get _isLabial =>
      _type.contains('labial') || _productName.contains('labial');

  bool get _isRubor =>
      _type.contains('rubor') || _productName.contains('rubor');

  List<Color> get _tones => _isLabial ? _labialTones : _ruborTones;

  Color get _currentTone => _tones[_selectedTone];

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.10,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraError = true;
          _status = 'No se encontró cámara disponible';
        });
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _lensDirection = selectedCamera.lensDirection;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.startImageStream(_processImage);

      if (!mounted) return;

      setState(() {
        _ready = true;
        _cameraError = false;
        _status = 'Buscando rostro...';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _cameraError = true;
        _status = 'No fue posible iniciar la cámara';
      });
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_busy) return;

    _busy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);

      if (inputImage == null) {
        _busy = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      final validFaces = faces.where((face) {
        final area = face.boundingBox.width * face.boundingBox.height;
        return area > 2500;
      }).toList();

      setState(() {
        _faces = validFaces;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _status = validFaces.isEmpty
            ? 'Buscando rostro...'
            : 'Rostro detectado: ${validFaces.length}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _faces = [];
        _status = 'Buscando rostro...';
      });
    } finally {
      _busy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = _controller;
    if (controller == null) return null;

    final camera = controller.description;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );

    if (rotation == null) return null;

    _rotation = rotation;

    if (Platform.isAndroid) {
      final bytes = _yuv420ToNv21(image);

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null || image.planes.isEmpty) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final bytes = Uint8List(width * height + (width * height ~/ 2));

    int index = 0;

    for (int row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      for (int col = 0; col < width; col++) {
        bytes[index++] = yPlane.bytes[rowStart + col];
      }
    }

    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;

    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < chromaHeight; row++) {
      for (int col = 0; col < chromaWidth; col++) {
        final uIndex = row * uPlane.bytesPerRow + col * uPixelStride;
        final vIndex = row * vPlane.bytesPerRow + col * vPixelStride;

        bytes[index++] = vPlane.bytes[vIndex];
        bytes[index++] = uPlane.bytes[uIndex];
      }
    }

    return bytes;
  }

  Future<void> _confirmTone() async {
    context.read<CartProvider>().addProduct(
      widget.product,
      tone: _currentTone,
      productType: _isLabial ? 'labial' : 'rubor',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.pink,
        content: Text('${widget.product['name']} agregado al carrito'),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraError
          ? Center(
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : !_ready || _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                CustomPaint(
                  painter: LiveMakeupPainter(
                    faces: _faces,
                    imageSize: _imageSize,
                    tone: _currentTone,
                    isLabial: _isLabial,
                    rotation: _rotation,
                    lensDirection: _lensDirection,
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                Positioned(
                  top: 105,
                  left: 22,
                  right: 22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.48),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_tones.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedTone = index);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _tones[index],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedTone == index
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _confirmTone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accessibility.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Confirmar tono',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class LiveMakeupPainter extends CustomPainter {
  final List<Face> faces;
  final Size? imageSize;
  final Color tone;
  final bool isLabial;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  LiveMakeupPainter({
    required this.faces,
    required this.imageSize,
    required this.tone,
    required this.isLabial,
    required this.rotation,
    required this.lensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null || faces.isEmpty) return;

    for (final face in faces) {
      if (isLabial) {
        _drawLipstick(canvas, size, face);
      } else {
        _drawBlush(canvas, size, face);
      }
    }
  }

  double _translateX(double x, Size size) {
    final imageW = imageSize!.width;
    final imageH = imageSize!.height;

    switch (rotation) {
      case InputImageRotation.rotation90deg:
        final value = x * size.width / imageH;
        return lensDirection == CameraLensDirection.front
            ? size.width - value
            : value;

      case InputImageRotation.rotation270deg:
        final value = size.width - x * size.width / imageH;
        return lensDirection == CameraLensDirection.front
            ? size.width - value
            : value;

      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        final value = x * size.width / imageW;
        return lensDirection == CameraLensDirection.front
            ? size.width - value
            : value;
    }
  }

  double _translateY(double y, Size size) {
    final imageW = imageSize!.width;
    final imageH = imageSize!.height;

    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / imageW;

      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * size.height / imageH;
    }
  }

  Offset _map(dynamic point, Size size) {
    return Offset(
      _translateX(point.x.toDouble(), size),
      _translateY(point.y.toDouble(), size),
    );
  }

  Rect _mapRect(Rect rect, Size size) {
    final p1 = Offset(
      _translateX(rect.left, size),
      _translateY(rect.top, size),
    );
    final p2 = Offset(
      _translateX(rect.right, size),
      _translateY(rect.bottom, size),
    );

    return Rect.fromLTRB(
      math.min(p1.dx, p2.dx),
      math.min(p1.dy, p2.dy),
      math.max(p1.dx, p2.dx),
      math.max(p1.dy, p2.dy),
    );
  }

  void _drawLipstick(Canvas canvas, Size size, Face face) {
    final all = <Offset>[];

    final contourTypes = [
      FaceContourType.upperLipTop,
      FaceContourType.upperLipBottom,
      FaceContourType.lowerLipTop,
      FaceContourType.lowerLipBottom,
    ];

    for (final type in contourTypes) {
      final contour = face.contours[type];
      if (contour == null) continue;

      for (final point in contour.points) {
        all.add(_map(point, size));
      }
    }

    if (all.length >= 8) {
      final path = _smoothPath(all);

      final paint = Paint()
        ..color = tone.withOpacity(0.82)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

      canvas.drawPath(path, paint);
      return;
    }

    final left = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final right = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    if (left != null && right != null && bottom != null) {
      final l = _map(left, size);
      final r = _map(right, size);
      final b = _map(bottom, size);

      final center = Offset((l.dx + r.dx) / 2, (l.dy + r.dy + b.dy) / 3);
      final width = (r.dx - l.dx).abs() * 1.25;
      final height = math.max(12.0, (b.dy - center.dy).abs() * 2.2);

      final rect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );

      final paint = Paint()
        ..color = tone.withOpacity(0.82)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawOval(rect, paint);
      return;
    }

    final box = _mapRect(face.boundingBox, size);

    final rect = Rect.fromCenter(
      center: Offset(box.center.dx, box.top + box.height * 0.69),
      width: box.width * 0.34,
      height: box.height * 0.08,
    );

    final paint = Paint()
      ..color = tone.withOpacity(0.82)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawOval(rect, paint);
  }

  void _drawBlush(Canvas canvas, Size size, Face face) {
    final box = _mapRect(face.boundingBox, size);

    Offset left = Offset(
      box.left + box.width * 0.32,
      box.top + box.height * 0.56,
    );

    Offset right = Offset(
      box.left + box.width * 0.68,
      box.top + box.height * 0.56,
    );

    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;

    if (leftCheek != null && rightCheek != null) {
      left = _map(leftCheek, size);
      right = _map(rightCheek, size);
    }

    final radius = math.max(24.0, box.width * 0.12);

    _drawSoftCircle(canvas, left, radius);
    _drawSoftCircle(canvas, right, radius);
  }

  void _drawSoftCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [tone.withOpacity(0.48), tone.withOpacity(0.25), Colors.transparent],
        const [0.0, 0.55, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, paint);
  }

  Path _smoothPath(List<Offset> points) {
    final center = Offset(
      points.map((p) => p.dx).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.dy).reduce((a, b) => a + b) / points.length,
    );

    final sorted = [...points];

    sorted.sort((a, b) {
      final angleA = math.atan2(a.dy - center.dy, a.dx - center.dx);
      final angleB = math.atan2(b.dy - center.dy, b.dx - center.dx);
      return angleA.compareTo(angleB);
    });

    final path = Path()..moveTo(sorted.first.dx, sorted.first.dy);

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final next = sorted[(i + 1) % sorted.length];

      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );

      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant LiveMakeupPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.tone != tone ||
        oldDelegate.isLabial != isLabial ||
        oldDelegate.rotation != rotation ||
        oldDelegate.lensDirection != lensDirection;
  }
}
