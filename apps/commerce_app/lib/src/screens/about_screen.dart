// Pantalla Acerca de para Katuya Comercio
// by Silvio Lionel Nieva

import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de información sobre la aplicación
/// 
/// Muestra información de la marca, versión, créditos y enlace a la licencia.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        backgroundColor: KatuyaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Logo grande
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: KatuyaColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.delivery_dining,
                size: 60,
                color: KatuyaColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Nombre de la app
            const Text(
              'Katuya Comercio',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Slogan
            Text(
              'Send it fast',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Firma destacada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KatuyaColors.primary.withOpacity(0.1),
                    KatuyaColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KatuyaColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.code,
                    color: KatuyaColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'by Silvio Lionel Nieva',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desarrollador Principal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Información de versión
            _buildInfoCard(),
            
            const SizedBox(height: 24),
            
            // Descripción
            _buildDescriptionCard(),
            
            const SizedBox(height: 24),
            
            // Enlaces
            _buildLinksCard(),
            
            const SizedBox(height: 32),
            
            // Footer
            Text(
              '© ${DateTime.now().year} Katuya. Todos los derechos reservados.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Hecho con ❤️ en Argentina',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir tarjeta de información de versión
  Widget _buildInfoCard() {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la versión',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Versión', '1.0.0'),
          const Divider(height: 24),
          _buildInfoRow('Build', '1'),
          const Divider(height: 24),
          _buildInfoRow('Plataforma', 'Flutter'),
          const Divider(height: 24),
          _buildInfoRow('Framework', 'Material 3'),
        ],
      ),
    );
  }

  /// Construir fila de información
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[700]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Construir tarjeta de descripción
  Widget _buildDescriptionCard() {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre Katuya',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Katuya es una plataforma de delivery rápida y eficiente que conecta comercios con repartidores en tiempo real.',
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Esta aplicación está diseñada para que los comercios puedan gestionar sus pedidos de manera simple y efectiva, siguiendo el principio "Send it fast".',
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Construir tarjeta de enlaces
  Widget _buildLinksCard() {
    return KatuyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enlaces útiles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLinkTile(
            icon: Icons.description_outlined,
            title: 'Licencia MIT',
            subtitle: 'Ver términos de uso',
            onTap: () => _launchUrl('https://opensource.org/licenses/MIT'),
          ),
          const Divider(height: 24),
          _buildLinkTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de Privacidad',
            subtitle: 'Cómo protegemos tus datos',
            onTap: () {
              // TODO: Implementar navegación a política de privacidad
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
          const Divider(height: 24),
          _buildLinkTile(
            icon: Icons.support_outlined,
            title: 'Soporte Técnico',
            subtitle: '¿Necesitas ayuda?',
            onTap: () {
              // TODO: Implementar navegación a soporte
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Construir tile de enlace
  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KatuyaColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: KatuyaColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// Lanzar URL externa
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir la URL: $url');
    }
  }
}
