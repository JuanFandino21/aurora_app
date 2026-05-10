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
  bool _announced = false;

  List<Face> _faces = [];
  Size? _imageSize;

  int _selectedTone = 0;

  final List<Color> _labialTones = const [
    Color(0xFF8B0015),
    Color(0xFFC2185B),
    Color(0xFFFF1744),
  ];

  final List<Color> _blushTones = const [
    Color(0xFFFFB6C1),
    Color(0xFFFF8DA1),
    Color(0xFFE75480),
  ];

  List<Color> get _tones =>
      widget.productType == 'labial' ? _labialTones : _blushTones;

  Color get _currentTone => _tones[_selectedTone];

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    _initCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_announced) {
      _announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AccessibilityProvider>().speak('Cámara en vivo');
        }
      });
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processImage);

    if (!mounted) return;

    setState(() {
      _ready = true;
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_busy) return;

    _busy = true;

    try {
      final inputImage = _inputImageFromCamera(image);

      if (inputImage == null) {
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _faces = faces;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final camera = _controller;
    if (camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.description.sensorOrientation,
    );

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) return null;

    final bytes = BytesBuilder();
    for (final plane in image.planes) {
      bytes.add(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.toBytes(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _confirmTone() async {
    context.read<CartProvider>().addProduct(
          widget.product,
          tone: _currentTone,
          productType: widget.productType,
        );

    context.read<AccessibilityProvider>().speak('Tono confirmado y agregado al carrito');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.pink,
        content: Text('${widget.product['name']} agregado al carrito 💄'),
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
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: LiveMakeupPainter(
                      faces: _faces,
                      imageSize: _imageSize,
                      tone: _currentTone,
                      productType: widget.productType,
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_tones.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTone = index;
                              });
                              accessibility.speak('Tono seleccionado');
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _tones[index],
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
                      const SizedBox(height: 18),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(color: Colors.white, width: 5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
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
  final String productType;

  LiveMakeupPainter({
    required this.faces,
    required this.imageSize,
    required this.tone,
    required this.productType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null) return;

    final sx = size.width / imageSize!.width;
    final sy = size.height / imageSize!.height;

    Offset map(Offset p) {
      return Offset(size.width - (p.dx * sx), p.dy * sy);
    }

    for (final face in faces) {
      if (productType == 'labial') {
        final points = _lipPoints(face, map);
        if (points.length < 10) continue;

        final path = _smooth(points);

        final shadow = Paint()
          ..color = tone.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

        canvas.drawPath(path, shadow);

        final fill = Paint()..color = tone.withOpacity(0.68);
        canvas.drawPath(path, fill);
      } else {
        _blush(face, canvas, map);
      }
    }
  }

  List<Offset> _lipPoints(Face face, Offset Function(Offset) map) {
    final contours = [
      FaceContourType.upperLipTop,
      FaceContourType.upperLipBottom,
      FaceContourType.lowerLipTop,
      FaceContourType.lowerLipBottom,
    ];

    final points = <Offset>[];

    for (final type in contours) {
      final contour = face.contours[type];
      if (contour == null) continue;

      points.addAll(
        contour.points.map(
          (e) => map(Offset(e.x.toDouble(), e.y.toDouble())),
        ),
      );
    }

    return points;
  }

  void _blush(Face face, Canvas canvas, Offset Function(Offset) map) {
    final bbox = face.boundingBox;

    final leftLandmark = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightLandmark = face.landmarks[FaceLandmarkType.rightCheek]?.position;

    final left = leftLandmark != null
        ? map(Offset(
            leftLandmark.x.toDouble(),
            leftLandmark.y.toDouble(),
          ))
        : map(Offset(
            bbox.left + bbox.width * 0.30,
            bbox.top + bbox.height * 0.58,
          ));

    final right = rightLandmark != null
        ? map(Offset(
            rightLandmark.x.toDouble(),
            rightLandmark.y.toDouble(),
          ))
        : map(Offset(
            bbox.left + bbox.width * 0.70,
            bbox.top + bbox.height * 0.58,
          ));

    final radius = math.max(bbox.width, bbox.height) * 0.18;

    for (final center in [left, right]) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            tone.withOpacity(0.36),
            tone.withOpacity(0.16),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, radius, paint);
    }
  }

  Path _smooth(List<Offset> points) {
    final center = Offset(
      points.map((e) => e.dx).reduce((a, b) => a + b) / points.length,
      points.map((e) => e.dy).reduce((a, b) => a + b) / points.length,
    );

    final sorted = [...points]
      ..sort((a, b) {
        final aa = math.atan2(a.dy - center.dy, a.dx - center.dx);
        final bb = math.atan2(b.dy - center.dy, b.dx - center.dx);
        return aa.compareTo(bb);
      });

    final path = Path();
    path.moveTo(sorted.first.dx, sorted.first.dy);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}