import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class DetailScreen extends StatelessWidget {
  final TopicItem tema;

  const DetailScreen({super.key, required this.tema});

  String _getSourceIcon(String source) {
    switch (source) {
      case 'reddit':
        return '🔥';
      case 'youtube':
        return '▶️';
      case 'trends':
        return '📈';
      default:
        return '💡';
    }
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'reddit':
        return const Color(0xFFFF4500);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'trends':
        return const Color(0xFF4285F4);
      default:
        return const Color(0xFFD4A053);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4A053)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (tema.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Color(0xFFD4A053)),
              onPressed: () {
                // TODO: open URL with url_launcher
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSourceColor(tema.fuente).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_getSourceIcon(tema.fuente)} ${tema.fuente.toUpperCase()}',
                    style: TextStyle(
                      color: _getSourceColor(tema.fuente),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (tema.curado) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A053).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '✨ CURADO POR IA',
                      style: TextStyle(
                        color: Color(0xFFD4A053),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              tema.titulo,
              style: const TextStyle(
                color: Color(0xFFE8E0D4),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            // Detail sections
            if (tema.porQueFunciona != null) ...[
              _buildSection(
                'POR QUÉ FUNCIONA',
                tema.porQueFunciona!,
                Icons.psychology_outlined,
              ),
              const SizedBox(height: 20),
            ],
            if (tema.anguloSugerido != null) ...[
              _buildSection(
                'ÁNGULO ESTOICO SUGERIDO',
                tema.anguloSugerido!,
                Icons.explore_outlined,
              ),
              const SizedBox(height: 20),
            ],
            if (tema.score > 0) ...[
              _buildSection(
                'MÉTRICAS',
                'Puntuación: ${_formatScore(tema.score)}',
                Icons.analytics_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4A053).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4A053), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD4A053),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFE8E0D4),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(0)}K';
    }
    return score.toString();
  }
}
