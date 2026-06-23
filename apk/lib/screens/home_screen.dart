import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<TopicItem> _temas = [];
  bool _loading = true;
  String? _error;
  int _total = 0;
  String _timestamp = '';

  @override
  void initState() {
    super.initState();
    _fetchTemas();
  }

  Future<void> _fetchTemas({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final batch = await _api.getTemas(refresh: refresh);
      setState(() {
        _temas = batch.temas;
        _total = batch.total;
        _timestamp = batch.timestamp;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor.';
        _loading = false;
      });
    }
  }

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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 28,
                    color: Color(0xFFD4A053),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURADOR ESTOICO',
                          style: TextStyle(
                            color: const Color(0xFFD4A053),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        if (!_loading && _temas.isNotEmpty)
                          Text(
                            '$_total temas disponibles',
                            style: const TextStyle(
                              color: Color(0xFFB0A899),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFD4A053)),
                    onPressed: () => _fetchTemas(refresh: true),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A3E), height: 1),
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4A053)),
            SizedBox(height: 16),
            Text(
              'Descubriendo temas...',
              style: TextStyle(color: Color(0xFFB0A899), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _fetchTemas(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A053),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTemas(refresh: true),
      color: const Color(0xFFD4A053),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _temas.length,
        itemBuilder: (context, index) {
          final tema = _temas[index];
          return _buildTopicCard(tema);
        },
      ),
    );
  }

  Widget _buildTopicCard(TopicItem tema) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(tema: tema),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tema.curado
                ? const Color(0xFFD4A053).withOpacity(0.3)
                : const Color(0xFF2A2A3E),
          ),
        ),
        child: Row(
          children: [
            // Source icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getSourceColor(tema.fuente).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _getSourceIcon(tema.fuente),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tema.titulo,
                    style: TextStyle(
                      color: tema.curado
                          ? const Color(0xFFE8E0D4)
                          : const Color(0xFFB0A899),
                      fontSize: 14,
                      fontWeight: tema.curado
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        tema.fuente.toUpperCase(),
                        style: TextStyle(
                          color: _getSourceColor(tema.fuente),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      if (tema.curado) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A053).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURADO IA',
                            style: TextStyle(
                              color: Color(0xFFD4A053),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                      if (tema.score > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatScore(tema.score),
                          style: const TextStyle(
                            color: Color(0xFFB0A899),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFB0A899),
              size: 20,
            ),
          ],
        ),
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
