import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../accessibility/provider/accessibility_provider.dart';
import '../../accessibility/screens/accessibility_screen.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../../auth/provider/auth_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../menu/widgets/app_drawer.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../orders/screens/purchase_history_screen.dart';
import '../data/product_provider.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 2;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'cosmetica';

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () =>
          Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onBottomTap(int index) {
    final accessibility = context.read<AccessibilityProvider>();

    setState(() {
      selectedIndex = index;
    });

    if (index == 0) {
      accessibility.speak('Historial de compras');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
      ).then((_) {
        if (mounted) setState(() => selectedIndex = 2);
      });
      return;
    }

    if (index == 1) {
      accessibility.speak('Accesibilidad');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccessibilityScreen()),
      ).then((_) {
        if (mounted) setState(() => selectedIndex = 2);
      });
      return;
    }

    if (index == 3) {
      accessibility.speak('Carrito');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ).then((_) {
        if (mounted) setState(() => selectedIndex = 2);
      });
      return;
    }

    if (index == 4) {
      accessibility.speak('Editar perfil');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
      ).then((_) {
        if (mounted) setState(() => selectedIndex = 2);
      });
      return;
    }

    accessibility.speak('Inicio');
  }

  String _firstName(String fullName) {
    final clean = fullName.trim();

    if (clean.isEmpty) return 'usuario';

    return clean.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();
    final accessibility = context.watch<AccessibilityProvider>();

    final userName =
        (authProvider.user?['name']?.toString().trim().isNotEmpty ?? false)
        ? authProvider.user!['name'].toString().trim()
        : 'Usuario';

    final userEmail =
        (authProvider.user?['email']?.toString().trim().isNotEmpty ?? false)
        ? authProvider.user!['email'].toString().trim()
        : '';

    final profileImagePath =
        authProvider.profileImagePath ??
        authProvider.user?['profileImagePath']?.toString();

    final filteredProducts = provider.search(searchQuery, selectedCategory);

    return Scaffold(
      backgroundColor: accessibility.appBackground,
      drawer: AppDrawer(
        userName: userName,
        userEmail: userEmail,
        profileImagePath: profileImagePath,
        onEditProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ).then((result) {
            if (!mounted) return;

            setState(() {
              selectedIndex = 2;
            });

            if (result == true) {
              context.read<AuthProvider>().loadUser();
            }
          });
        },
        onAccessibility: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccessibilityScreen()),
          ).then((_) {
            if (mounted) setState(() => selectedIndex = 2);
          });
        },
        onLogout: () async {
          await authProvider.logout();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: accessibility.appBarColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Image.asset('assets/logo.png', height: 40),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              accessibility.speak('Abrir carrito');

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ).then((_) {
                if (mounted) setState(() => selectedIndex = 2);
              });
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<ProductProvider>().fetchProducts(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hola @${_firstName(userName)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accessibility.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Innovación que realza tu belleza',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: accessibility.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFE91E63),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _categoryTab(
                          title: 'Cosmética',
                          selected: selectedCategory == 'cosmetica',
                          onTap: () {
                            setState(() {
                              selectedCategory = 'cosmetica';
                            });
                          },
                        ),
                        const SizedBox(width: 45),
                        _categoryTab(
                          title: 'Cuidado personal',
                          selected: selectedCategory == 'cuidado',
                          onTap: () {
                            setState(() {
                              selectedCategory = 'cuidado';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (filteredProducts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 70, bottom: 120),
                        child: Text(
                          'No hay productos para mostrar',
                          style: TextStyle(
                            color: accessibility.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          return _productCard(context, accessibility, product);
                        },
                      ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: accessibility.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(accessibility, Icons.history, 0),
            navItem(accessibility, Icons.accessibility, 1),
            navItem(accessibility, Icons.home, 2),
            navItem(accessibility, Icons.shopping_cart, 3),
            navItem(accessibility, Icons.person, 4),
          ],
        ),
      ),
    );
  }

  Widget _productCard(
    BuildContext context,
    AccessibilityProvider accessibility,
    Product product,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product.toJson()),
          ),
        ).then((_) {
          if (mounted) setState(() => selectedIndex = 2);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: accessibility.surfaceColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 40),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: accessibility.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (product.canUseTryOn) ...[
              const SizedBox(height: 5),
              const Text(
                'Try-On IA',
                style: TextStyle(
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accessibility = context.watch<AccessibilityProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected
                  ? accessibility.primaryColor
                  : accessibility.mutedTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 110,
            child: Divider(
              thickness: 3,
              color: selected ? accessibility.primaryColor : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget navItem(
    AccessibilityProvider accessibility,
    IconData icon,
    int index,
  ) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onBottomTap(index),
      child: Icon(
        icon,
        color: isSelected
            ? accessibility.primaryColor
            : accessibility.mutedTextColor,
        size: 28,
      ),
    );
  }
}
