import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  CurationResult? _result;
  bool _loading = false;
  String? _error;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopic() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _api.getCuratedTopic();
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor. Intenta de nuevo.';
        _loading = false;
      });
    }
  }

  String _getSourceEmoji(String source) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo / Title
              const Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Color(0xFFD4A053),
              ),
              const SizedBox(height: 16),
              Text(
                'CURADOR ESTOICO',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Descubre tu próximo tema',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              // Generate Button
              GestureDetector(
                onTap: _loading ? null : _fetchTopic,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _loading ? _pulseAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _loading
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF8B7355),
                                Color(0xFFD4A053),
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFF1A1A2E),
                                Color(0xFF2A2A3E),
                              ],
                            ),
                      border: Border.all(
                        color: const Color(0xFFD4A053),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4A053).withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF0A0A0F),
                              strokeWidth: 3,
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 40,
                                  color: Color(0xFFD4A053),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'GENERAR',
                                  style: TextStyle(
                                    color: Color(0xFFD4A053),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Result or Error
              if (_error != null) _buildError(),
              if (_result != null) _buildResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      children: [
        // Source badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4A053).withOpacity(0.3)),
          ),
          child: Text(
            '${_getSourceEmoji(_result!.fuentePrincipal)} ${_result!.fuentePrincipal.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFFD4A053),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Theme card
        _buildCard(
          'TEMA ELEGIDO',
          _result!.temaElegido,
          Icons.lightbulb_outline,
        ),
        const SizedBox(height: 16),
        // Why it works
        _buildCard(
          'POR QUÉ FUNCIONA',
          _result!.porQueFunciona,
          Icons.psychology_outlined,
        ),
        const SizedBox(height: 16),
        // Suggested angle
        _buildCard(
          'ÁNGULO SUGERIDO',
          _result!.anguloSugerido,
          Icons.explore_outlined,
        ),
        const SizedBox(height: 16),
        // Metrics
        if (_result!.metricasClave.isNotEmpty) _buildMetrics(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCard(String title, String content, IconData icon) {
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

  Widget _buildMetrics() {
    final views = _result!.metricasClave['yt_views'] ?? 0;
    final score = _result!.metricasClave['reddit_score'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4A053).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (views > 0)
            _metricItem('Vistas YT', '${(views / 1000).toStringAsFixed(0)}K'),
          if (score > 0)
            _metricItem('Reddit', score.toString()),
          _metricItem('Fuentes', '${_result!.metricasClave.length}'),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD4A053),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0A899),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
