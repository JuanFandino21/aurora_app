import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/accessibility_provider.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccessibilityProvider>();

    final bg = provider.highContrast
        ? const Color(0xFF111111)
        : const Color(0xFFD8B1DA);

    final text = provider.highContrast ? Colors.white : Colors.black;

    final card = provider.highContrast ? const Color(0xFF222222) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/logo.png', height: 35),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accesibilidad',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                Icon(Icons.accessibility_new, color: text, size: 34),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Tamaño del texto',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sizeButton(context, 'A-', 0.85, card),
                _sizeButton(context, 'A', 1.0, card),
                _sizeButton(context, 'A+', 1.25, card),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Modo de contraste',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _radio(
              title: 'Normal',
              selected: !provider.highContrast,
              textColor: text,
              onTap: () {
                provider.setHighContrast(false);
                provider.speak('Modo normal activado');
              },
            ),
            const SizedBox(height: 12),
            _radio(
              title: 'Alto contraste',
              selected: provider.highContrast,
              textColor: text,
              onTap: () {
                provider.setHighContrast(true);
                provider.speak('Alto contraste activado');
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Lectura asistida',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _radio(
              title: 'Activado',
              selected: provider.voiceAssist,
              textColor: text,
              onTap: () async {
                provider.setVoiceAssist(true);
                await Future.delayed(const Duration(milliseconds: 250));
                provider.speak('Lectura asistida activada');
              },
            ),
            const SizedBox(height: 12),
            _radio(
              title: 'Desactivado',
              selected: !provider.voiceAssist,
              textColor: text,
              onTap: () {
                provider.setVoiceAssist(false);
              },
            ),
            const SizedBox(height: 28),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  provider.speak('Bienvenido a Aurora Beauty');
                },
                icon: Icon(Icons.volume_up, color: text),
                label: Text(
                  'Probar lectura',
                  style: TextStyle(color: text),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 260,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    provider.speak('Cambios guardados');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cambios guardados')),
                    );
                  },
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeButton(
    BuildContext context,
    String label,
    double scale,
    Color bg,
  ) {
    final provider = context.read<AccessibilityProvider>();

    return GestureDetector(
      onTap: () {
        provider.setTextScale(scale);
        provider.speak('Tamaño de texto cambiado');
      },
      child: Container(
        width: 82,
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _radio({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor:
                selected ? const Color(0xFF9C27B0) : Colors.white,
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}