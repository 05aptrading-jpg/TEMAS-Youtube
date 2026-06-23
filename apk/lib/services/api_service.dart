import 'package:http/http.dart' as http;
import 'dart:convert';

class CurationResult {
  final String temaElegido;
  final String porQueFunciona;
  final String anguloSugerido;
  final String fuentePrincipal;
  final Map<String, dynamic> metricasClave;

  CurationResult({
    required this.temaElegido,
    required this.porQueFunciona,
    required this.anguloSugerido,
    required this.fuentePrincipal,
    required this.metricasClave,
  });

  factory CurationResult.fromJson(Map<String, dynamic> json) {
    return CurationResult(
      temaElegido: json['tema_elegido'] ?? 'Sin tema',
      porQueFunciona: json['por_que_funciona'] ?? '',
      anguloSugerido: json['angulo_sugerido'] ?? '',
      fuentePrincipal: json['fuente_principal'] ?? 'youtube',
      metricasClave: json['metricas_clave'] ?? {},
    );
  }
}

class ApiService {
  static const String baseUrl =
      'https://temas-youtube-production.up.railway.app';

  Future<CurationResult> getCuratedTopic() async {
    final response = await http.get(
      Uri.parse('$baseUrl/curar'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CurationResult.fromJson(data['data']);
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }
}
