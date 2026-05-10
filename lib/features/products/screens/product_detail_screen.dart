import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../ai_tryon/screens/live_makeup_camera.dart';
import '../../ai_tryon/screens/virtual_tryon_screen.dart';
import '../../cart/provider/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';

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

  String get productType {
    final name = widget.product['name'].toString().toLowerCase();
    final category = widget.product['category']?.toString().toLowerCase() ?? '';

    if (category == 'cuidado') {
      return 'cuidado';
    }

    if (name.contains('labial')) {
      return 'labial';
    }

    return 'rubor';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_announced) {
      _announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AccessibilityProvider>().speak(
            'Producto ${widget.product['name']}',
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

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();
    final isCare = productType == 'cuidado';

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
                  Row(
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
                            child: Image.network(widget.product['imageUrl']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product['name'],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: accessibility.textColor,
                          ),
                        ),
                      ),
                      Text(
                        '\$${widget.product['price']}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: accessibility.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCare ? 'Cuidado personal' : 'Cosmética',
                    style: TextStyle(
                      color: accessibility.mutedTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star, color: Colors.black),
                      const Icon(Icons.star_half, color: Colors.white),
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
                    isCare
                        ? 'Producto de cuidado personal ideal para uso diario, pensado para mantener tu piel y rutina en excelente estado.'
                        : productType == 'labial'
                        ? 'Labial de alta pigmentación con acabado suave y duradero, diseñado para realzar tu belleza con un solo trazo.'
                        : 'Rubor suave y elegante diseñado para darle vida a tus mejillas con un acabado natural.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: accessibility.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isCare
                        ? 'Este producto no usa prueba virtual.'
                        : 'Descubre tu tono perfecto con nuestra tecnología de prueba virtual IA.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: accessibility.textColor,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accessibility.appBackground,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                if (!isCare)
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
                                  product: widget.product,
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
                                  product: widget.product,
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
                            'Probar producto IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!isCare) const SizedBox(height: 14),
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
                        widget.product,
                        productType: productType,
                      );

                      accessibility.speak('Producto agregado al carrito');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.pink,
                          content: Text(
                            '${widget.product['name']} agregado al carrito 🛒',
                          ),
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
        child: Image.network(widget.product['imageUrl']),
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
                if (reviewController.text.isNotEmpty) {
                  setState(() {
                    reviews.add({
                      'name': 'Tú',
                      'comment': reviewController.text,
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
