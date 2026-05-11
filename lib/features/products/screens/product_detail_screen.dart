import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../ai_tryon/screens/live_makeup_camera.dart';
import '../../ai_tryon/screens/virtual_tryon_screen.dart';
import '../../cart/provider/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController reviewController = TextEditingController();

  int selectedStars = 5;
  bool _announced = false;

  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'User',
      'comment':
          'Me encantó 😍 me dio mucha confianza. ¡Lo recomiendo totalmente!',
      'stars': 5,
      'image': 'https://randomuser.me/api/portraits/women/44.jpg',
    },
  ];

  late final Product product;

  @override
  void initState() {
    super.initState();
    product = Product.fromJson(widget.product);
  }

  String get productType => product.tryOnType;

  bool get canUseTryOn => product.canUseTryOn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_announced) {
      _announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AccessibilityProvider>().speak(
            'Producto ${product.name}',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String _money(double value) => '\$${value.toStringAsFixed(0)}';

  String _description() {
    if (product.description.trim().isNotEmpty) {
      return product.description;
    }

    if (product.isCare) {
      return 'Producto de cuidado personal ideal para uso diario, pensado para mantener tu piel y rutina en excelente estado.';
    }

    if (product.tryOnType == 'labial') {
      return 'Labial de alta pigmentación con acabado suave y duradero, diseñado para realzar tu belleza con un solo trazo.';
    }

    if (product.tryOnType == 'rubor') {
      return 'Rubor suave y elegante diseñado para darle vida a tus mejillas con un acabado natural.';
    }

    return 'Producto de belleza diseñado para complementar tu rutina diaria.';
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/logo.png', height: 40),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              accessibility.speak('Abrir carrito');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imageSection(accessibility),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: accessibility.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _money(product.price),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: accessibility.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.readableCategory,
                    style: TextStyle(
                      color: accessibility.mutedTextColor,
                      fontSize: 16,
                    ),
                  ),
                  if (product.stock > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Disponibles: ${product.stock}',
                      style: TextStyle(
                        color: accessibility.mutedTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star, color: Colors.black),
                      Icon(Icons.star_half, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'Reseñas (20)',
                        style: TextStyle(
                          color: accessibility.mutedTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: accessibility.mutedTextColor),
                  const SizedBox(height: 10),
                  Text(
                    _description(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.35,
                      color: accessibility.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    canUseTryOn
                        ? 'Disponible para prueba virtual IA. Puedes subir una selfie o usar la cámara en vivo.'
                        : 'Este producto no usa prueba virtual. La prueba virtual solo está disponible para Labial Matte Pro y Rubor Glow.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: canUseTryOn
                          ? accessibility.primaryColor
                          : accessibility.mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: accessibility.mutedTextColor),
                  const SizedBox(height: 10),
                  Text(
                    'Reseñas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: accessibility.textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: reviews.map((review) {
                      return reviewCard(accessibility, review);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  reviewBox(accessibility),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
          _bottomActions(accessibility),
        ],
      ),
    );
  }

  Widget _imageSection(AccessibilityProvider accessibility) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            miniImage(accessibility),
            const SizedBox(height: 12),
            miniImage(accessibility),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: accessibility.surfaceColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomActions(AccessibilityProvider accessibility) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accessibility.appBackground,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          if (canUseTryOn)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      accessibility.speak('Abrir prueba virtual');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VirtualTryOnScreen(
                            productType: productType,
                            product: product.toJson(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accessibility.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      'Subir selfie',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      accessibility.speak('Abrir cámara en vivo');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveMakeupCameraScreen(
                            productType: productType,
                            product: product.toJson(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accessibility.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      'Cámara en vivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (canUseTryOn) const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                context.read<CartProvider>().addProduct(
                  product.toJson(),
                  productType: product.tryOnType.isNotEmpty
                      ? product.tryOnType
                      : product.category,
                );

                accessibility.speak('Producto agregado al carrito');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.pink,
                    content: Text('${product.name} agregado al carrito 🛒'),
                  ),
                );

                await Future.delayed(const Duration(milliseconds: 250));

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFE1A4F0)],
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Comprar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget miniImage(AccessibilityProvider accessibility) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: accessibility.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.network(
          product.imageUrl,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  Widget reviewCard(
    AccessibilityProvider accessibility,
    Map<String, dynamic> review,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: accessibility.surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(review['image']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accessibility.textColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: List.generate(
                        review['stars'],
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  review['comment'],
                  style: TextStyle(color: accessibility.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget reviewBox(AccessibilityProvider accessibility) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accessibility.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escribe una reseña',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: accessibility.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    selectedStars = index + 1;
                  });
                },
                icon: Icon(
                  Icons.star,
                  color: index < selectedStars ? Colors.orange : Colors.grey,
                ),
              );
            }),
          ),
          TextField(
            controller: reviewController,
            maxLines: 3,
            style: TextStyle(color: accessibility.textColor),
            decoration: InputDecoration(
              hintText: 'Escribe tu experiencia...',
              hintStyle: TextStyle(color: accessibility.mutedTextColor),
              filled: true,
              fillColor: accessibility.highContrast
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE278E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (reviewController.text.trim().isNotEmpty) {
                  setState(() {
                    reviews.add({
                      'name': 'Tú',
                      'comment': reviewController.text.trim(),
                      'stars': selectedStars,
                      'image': 'https://randomuser.me/api/portraits/men/32.jpg',
                    });
                  });

                  reviewController.clear();
                  accessibility.speak('Reseña publicada');
                }
              },
              child: const Text(
                'Publicar reseña',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
