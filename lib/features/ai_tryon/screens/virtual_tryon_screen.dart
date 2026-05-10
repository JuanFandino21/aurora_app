import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../cart/provider/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final String productType;
  final Map<String, dynamic> product;

  const VirtualTryOnScreen({
    super.key,
    required this.productType,
    required this.product,
  });

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  final ImagePicker _picker = ImagePicker();
  late final FaceDetector _faceDetector;

  File? _selectedImage;
  ui.Image? _uiImage;
  List<Face> _faces = [];

  bool _isProcessing = false;
  bool _showResult = false;

  int _selectedTone = 0;
  bool _announced = false;

  final List<Color> _lipstickTones = const [
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
      widget.productType == 'labial' ? _lipstickTones : _blushTones;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_announced) {
      _announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AccessibilityProvider>().speak(
                'Prueba virtual del producto ${widget.product['name']}',
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      _selectedImage = file;
      _showResult = false;
      _faces = [];
    });

    context.read<AccessibilityProvider>().speak('Imagen seleccionada');

    await _loadUiImage(file);
  }

  Future<void> _loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (image) => completer.complete(image));
    _uiImage = await completer.future;
  }

  Future<void> _runTryOn() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    context.read<AccessibilityProvider>().speak('Procesando imagen');

    final inputImage = InputImage.fromFilePath(_selectedImage!.path);

    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _faces = faces;
        _showResult = true;
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
    }
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
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/logo.png', height: 40),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Sube tu foto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accessibility.textColor,
                  ),
                ),
                const SizedBox(height: 15),
                _button(
                  accessibility,
                  text: 'Subir selfie',
                  onTap: _pickImage,
                ),
                const SizedBox(height: 16),
                _imageCard(
                  accessibility,
                  child: _selectedImage == null
                      ? Icon(
                          Icons.image,
                          size: 70,
                          color: accessibility.mutedTextColor,
                        )
                      : Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
                const SizedBox(height: 18),
                _button(
                  accessibility,
                  text: _isProcessing ? 'Procesando...' : 'Probar tono',
                  onTap: _isProcessing ? null : _runTryOn,
                  filled: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Tu resultado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accessibility.textColor,
                  ),
                ),
                const SizedBox(height: 14),
                _imageCard(
                  accessibility,
                  child: !_showResult
                      ? Icon(
                          Icons.face_retouching_natural,
                          size: 70,
                          color: accessibility.mutedTextColor,
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedImage!, fit: BoxFit.cover),
                            if (_uiImage != null && _faces.isNotEmpty)
                              CustomPaint(
                                painter: MakeupOverlayPainter(
                                  faces: _faces,
                                  image: _uiImage!,
                                  tone: _currentTone,
                                  productType: widget.productType,
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_tones.length, (index) {
                    final color = _tones[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTone = index;
                        });
                        accessibility.speak('Tono seleccionado');
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: _selectedTone == index
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                _button(
                  accessibility,
                  text: 'Confirmar tono',
                  onTap: _showResult ? _confirmTone : null,
                  filled: true,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(
    AccessibilityProvider accessibility, {
    required String text,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? accessibility.secondaryColor : Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: accessibility.highContrast
                  ? Colors.white24
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _imageCard(AccessibilityProvider accessibility, {required Widget child}) {
    return Container(
      height: 260,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accessibility.surfaceColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class MakeupOverlayPainter extends CustomPainter {
  final List<Face> faces;
  final ui.Image image;
  final Color tone;
  final String productType;

  MakeupOverlayPainter({
    required this.faces,
    required this.image,
    required this.tone,
    required this.productType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, srcSize, size);

    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & srcSize,
    );

    final destinationRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );

    Offset mapPoint(Offset p) {
      final dx = destinationRect.left +
          (p.dx - sourceRect.left) *
              destinationRect.width /
              sourceRect.width;
      final dy = destinationRect.top +
          (p.dy - sourceRect.top) *
              destinationRect.height /
              sourceRect.height;
      return Offset(dx, dy);
    }

    for (final face in faces) {
      if (productType == 'labial') {
        _paintLips(canvas, face, mapPoint);
      } else {
        _paintBlush(canvas, face, mapPoint);
      }
    }
  }

  void _paintLips(
    Canvas canvas,
    Face face,
    Offset Function(Offset) mapPoint,
  ) {
    final lipContours = [
      FaceContourType.upperLipTop,
      FaceContourType.upperLipBottom,
      FaceContourType.lowerLipTop,
      FaceContourType.lowerLipBottom,
    ];

    final points = <Offset>[];

    for (final contourType in lipContours) {
      final contour = face.contours[contourType];
      if (contour == null) continue;

      points.addAll(
        contour.points.map(
          (p) => mapPoint(Offset(p.x.toDouble(), p.y.toDouble())),
        ),
      );
    }

    if (points.length < 10) return;

    final path = _buildSmoothPath(points);

    final shadow = Paint()
      ..color = tone.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, shadow);

    final fill = Paint()
      ..color = tone.withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fill);

    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.10);

    canvas.drawPath(_shrink(path, 0.92), gloss);
  }

  void _paintBlush(
    Canvas canvas,
    Face face,
    Offset Function(Offset) mapPoint,
  ) {
    final bbox = face.boundingBox;

    final leftLandmark = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightLandmark = face.landmarks[FaceLandmarkType.rightCheek]?.position;

    final left = leftLandmark != null
        ? mapPoint(Offset(
            leftLandmark.x.toDouble(),
            leftLandmark.y.toDouble(),
          ))
        : mapPoint(
            Offset(
              bbox.left + bbox.width * 0.30,
              bbox.top + bbox.height * 0.58,
            ),
          );

    final right = rightLandmark != null
        ? mapPoint(Offset(
            rightLandmark.x.toDouble(),
            rightLandmark.y.toDouble(),
          ))
        : mapPoint(
            Offset(
              bbox.left + bbox.width * 0.70,
              bbox.top + bbox.height * 0.58,
            ),
          );

    final radius = math.max(bbox.width, bbox.height) * 0.18;

    for (final center in [left, right]) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            tone.withValues(alpha: 0.36),
            tone.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, radius, paint);
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final center = Offset(
      points.map((e) => e.dx).reduce((a, b) => a + b) / points.length,
      points.map((e) => e.dy).reduce((a, b) => a + b) / points.length,
    );

    final sorted = [...points]
      ..sort((a, b) {
        final angleA = math.atan2(a.dy - center.dy, a.dx - center.dx);
        final angleB = math.atan2(b.dy - center.dy, b.dx - center.dx);
        return angleA.compareTo(angleB);
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

  Path _shrink(Path path, double scale) {
    final bounds = path.getBounds();
    final center = bounds.center;

    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(scale)
      ..translate(-center.dx, -center.dy);

    return path.transform(matrix.storage);
  }

  @override
  bool shouldRepaint(covariant MakeupOverlayPainter oldDelegate) {
    return true;
  }
}