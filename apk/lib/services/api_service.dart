import 'package:http/http.dart' as http;
import 'dart:convert';

class TopicItem {
  final int id;
  final String titulo;
  final String fuente;
  final int score;
  final bool curado;
  final String? porQueFunciona;
  final String? anguloSugerido;
  final String? url;

  TopicItem({
    required this.id,
    required this.titulo,
    required this.fuente,
    required this.score,
    required this.curado,
    this.porQueFunciona,
    this.anguloSugerido,
    this.url,
  });

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    return TopicItem(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      fuente: json['fuente'] ?? 'unknown',
      score: json['score'] ?? 0,
      curado: json['curado'] ?? false,
      porQueFunciona: json['por_que_funciona'],
      anguloSugerido: json['angulo_sugerido'],
      url: json['url'],
    );
  }
}

class BatchResponse {
  final List<TopicItem> temas;
  final int total;
  final String timestamp;
  final String proximaRenovacion;
  final Map<String, dynamic> fuentesConsultadas;

  BatchResponse({
    required this.temas,
    required this.total,
    required this.timestamp,
    required this.proximaRenovacion,
    required this.fuentesConsultadas,
  });

  factory BatchResponse.fromJson(Map<String, dynamic> json) {
    return BatchResponse(
      temas: (json['temas'] as List)
          .map((t) => TopicItem.fromJson(t))
          .toList(),
      total: json['total'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      proximaRenovacion: json['proxima_renovacion'] ?? '',
      fuentesConsultadas: json['fuentes_consultadas'] ?? {},
    );
  }
}

class ApiService {
  static const String baseUrl =
      'https://temas-youtube-production.up.railway.app';

  Future<BatchResponse> getTemas({bool refresh = false}) async {
    final endpoint = refresh ? '/temas/refresh' : '/temas';
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return BatchResponse.fromJson(data['data']);
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }
}
