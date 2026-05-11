import 'dart:io';
import 'dart:math' as math;
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
  bool _cameraError = false;

  String _status = 'Iniciando cámara...';

  List<Face> _faces = [];
  Size? _imageSize;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

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

  List<Color> get _tones {
    final type = widget.productType.toLowerCase();
    return type == 'labial' ? _labialTones : _blushTones;
  }

  Color get _currentTone => _tones[_selectedTone];

  bool get _isLipstick => widget.productType.toLowerCase() == 'labial';

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.12,
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
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
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

      _cameraLensDirection = selectedCamera.lensDirection;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
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
        _cameraError = true;
        _ready = false;
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

      setState(() {
        _faces = faces;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _status = faces.isEmpty
            ? 'Buscando rostro...'
            : 'Rostro detectado: ${faces.length}';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'Ajusta tu rostro frente a la cámara';
        });
      }
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

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) return null;

    if (Platform.isAndroid && format != InputImageFormat.nv21) {
      return null;
    }

    if (Platform.isIOS && format != InputImageFormat.bgra8888) {
      return null;
    }

    if (image.planes.isEmpty) return null;

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

  Future<void> _confirmTone() async {
    context.read<CartProvider>().addProduct(
      widget.product,
      tone: _currentTone,
      productType: widget.productType,
    );

    context.read<AccessibilityProvider>().speak(
      'Tono confirmado y agregado al carrito',
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : !_ready || _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Positioned.fill(
                  child: CustomPaint(
                    painter: LiveMakeupPainter(
                      faces: _faces,
                      imageSize: _imageSize,
                      tone: _currentTone,
                      productType: widget.productType,
                      lensDirection: _cameraLensDirection,
                    ),
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
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.60),
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
                  bottom: 38,
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
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_tones.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTone = index;
                                });

                                accessibility.speak('Tono seleccionado');
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                width: 36,
                                height: 36,
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
                      ),
                      const SizedBox(height: 18),
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
                            child: Text(
                              _faces.isEmpty
                                  ? 'Agregar tono al carrito'
                                  : 'Confirmar tono',
                              style: const TextStyle(
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
  final CameraLensDirection lensDirection;

  LiveMakeupPainter({
    required this.faces,
    required this.imageSize,
    required this.tone,
    required this.productType,
    required this.lensDirection,
  });

  bool get _isLipstick => productType.toLowerCase() == 'labial';

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null || faces.isEmpty) return;

    for (final face in faces) {
      if (_isLipstick) {
        _paintLips(canvas, size, face);
      } else {
        _paintBlush(canvas, size, face);
      }
    }
  }

  Offset _mapPoint(Offset point, Size canvasSize) {
    final imageW = imageSize!.width;
    final imageH = imageSize!.height;

    final scaleX = canvasSize.width / imageW;
    final scaleY = canvasSize.height / imageH;

    double x = point.dx * scaleX;
    double y = point.dy * scaleY;

    if (lensDirection == CameraLensDirection.front) {
      x = canvasSize.width - x;
    }

    return Offset(x, y);
  }

  Rect _mapRect(Rect rect, Size canvasSize) {
    final topLeft = _mapPoint(rect.topLeft, canvasSize);
    final bottomRight = _mapPoint(rect.bottomRight, canvasSize);

    return Rect.fromLTRB(
      math.min(topLeft.dx, bottomRight.dx),
      math.min(topLeft.dy, bottomRight.dy),
      math.max(topLeft.dx, bottomRight.dx),
      math.max(topLeft.dy, bottomRight.dy),
    );
  }

  void _paintLips(Canvas canvas, Size size, Face face) {
    final lipTypes = [
      FaceContourType.upperLipTop,
      FaceContourType.upperLipBottom,
      FaceContourType.lowerLipTop,
      FaceContourType.lowerLipBottom,
    ];

    final points = <Offset>[];

    for (final type in lipTypes) {
      final contour = face.contours[type];
      if (contour == null) continue;

      for (final point in contour.points) {
        points.add(
          _mapPoint(Offset(point.x.toDouble(), point.y.toDouble()), size),
        );
      }
    }

    if (points.length < 8) {
      final box = _mapRect(face.boundingBox, size);

      final fallback = Rect.fromCenter(
        center: Offset(box.center.dx, box.top + box.height * 0.67),
        width: box.width * 0.34,
        height: box.height * 0.09,
      );

      final paint = Paint()
        ..color = tone.withOpacity(0.58)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawOval(fallback, paint);
      return;
    }

    final path = _smoothClosedPath(points);

    final shadow = Paint()
      ..color = tone.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawPath(path, shadow);

    final fill = Paint()
      ..color = tone.withOpacity(0.68)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fill);
  }

  void _paintBlush(Canvas canvas, Size size, Face face) {
    final box = _mapRect(face.boundingBox, size);

    final leftCenter = Offset(
      box.left + box.width * 0.30,
      box.top + box.height * 0.58,
    );

    final rightCenter = Offset(
      box.left + box.width * 0.70,
      box.top + box.height * 0.58,
    );

    final radius = math.max(box.width, box.height) * 0.12;

    for (final center in [leftCenter, rightCenter]) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [tone.withOpacity(0.40), tone.withOpacity(0.18), Colors.transparent],
          const [0.0, 0.55, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

      canvas.drawCircle(center, radius, paint);
    }
  }

  Path _smoothClosedPath(List<Offset> points) {
    final center = Offset(
      points.map((p) => p.dx).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.dy).reduce((a, b) => a + b) / points.length,
    );

    points.sort((a, b) {
      final angleA = math.atan2(a.dy - center.dy, a.dx - center.dx);
      final angleB = math.atan2(b.dy - center.dy, b.dx - center.dx);
      return angleA.compareTo(angleB);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];

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
        oldDelegate.tone != tone ||
        oldDelegate.productType != productType ||
        oldDelegate.imageSize != imageSize;
  }
}
