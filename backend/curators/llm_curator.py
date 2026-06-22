import json
from openai import OpenAI
from ..config import OPENROUTER_API_KEY, OPENROUTER_BASE_URL, OPENROUTER_MODEL, OPENROUTER_FALLBACK_MODEL
from ..models.schemas import CurationResult, ExtractedData

SYSTEM_PROMPT = """Rol: Eres el Curador de Contenido de un canal de estoicismo y filosofía. Tu trabajo es analizar una lista de temas en tendencia de las últimas horas y seleccionar el mejor para convertir en un video corto, profundo e impactante.

Filosofía del canal: Contenido estoico, filosófico, reflexivo. Tomas conceptos antiguos y los conectas con la vida moderna. Buscas hacer pensar a la audiencia.

Filtros de Selección:
1. El tema debe permitir un enfoque estoico, filosófico o de profunda curiosidad intelectual.
2. Debe tener un "gancho intrínseco" — un dato que haga decir "¿En serio?".
3. Debe poder contarse en 1-2 minutos con impacto emocional o intelectual.
4. Prioriza temas que conecten con la vida moderna desde una perspectiva estoica.

Output requerido (SOLO JSON, sin markdown, sin explicaciones adicionales):
{
  "tema_elegido": "El dato o historia seleccionado",
  "por_que_funciona": "Explicación breve de por qué enganchará a la audiencia desde el ángulo estoico",
  "angulo_sugerido": "Cómo abordarlo: con una lección estoica, una paradoja filosófica, o una revelación histórica",
  "fuente_principal": "reddit | youtube | trends",
  "metricas_clave": { "reddit_score": 0, "yt_views": 0, "trend_interest": 0 }
}"""


def curate_content(extracted: ExtractedData) -> CurationResult:
    if not OPENROUTER_API_KEY:
        return _fallback_curation(extracted)

    client = OpenAI(
        base_url=OPENROUTER_BASE_URL,
        api_key=OPENROUTER_API_KEY,
    )

    user_message = _build_user_message(extracted)

    for model in [OPENROUTER_MODEL, OPENROUTER_FALLBACK_MODEL]:
        try:
            response = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_message},
                ],
                response_format={"type": "json_object"},
                temperature=0.7,
                max_tokens=600,
                extra_headers={
                    "HTTP-Referer": "https://github.com/tuapp",
                    "X-Title": "Curador Estoico",
                },
            )
            raw = response.choices[0].message.content.strip()
            data = json.loads(raw)
            return CurationResult(
                tema_elegido=data.get("tema_elegido", "Sin tema"),
                por_que_funciona=data.get("por_que_funciona", ""),
                angulo_sugerido=data.get("angulo_sugerido", ""),
                fuente_principal=data.get("fuente_principal", "reddit"),
                metricas_clave=data.get("metricas_clave", {}),
                fuentes_consultadas=_build_sources(extracted),
                raw_data_summary=_build_summary(extracted),
            )
        except Exception:
            continue

    return _fallback_curation(extracted)


def _build_user_message(extracted: ExtractedData) -> str:
    parts = ["Estos son los datos extraídos hoy. Selecciona el MEJOR tema:\n"]

    if extracted.reddit_posts:
        parts.append("=== REDDIT (posts populares) ===")
        for p in extracted.reddit_posts[:10]:
            parts.append(f"- [{p.score} pts] r/{p.subreddit}: {p.titulo}")
        parts.append("")

    if extracted.youtube_videos:
        parts.append("=== YOUTUBE (videos en tendencia) ===")
        for v in extracted.youtube_videos[:8]:
            parts.append(f"- [{v.vistas} views] {v.titulo} (canal: {v.canal})")
        parts.append("")

    if extracted.trends:
        parts.append("=== GOOGLE TRENDS (interés semanal) ===")
        for t in extracted.trends:
            parts.append(f"- {t.concepto}: puntaje={t.puntaje_actual} ({t.aumento})")
        parts.append("")

    if extracted.errores:
        parts.append(f"Nota: algunas fuentes fallaron: {', '.join(extracted.errores)}")

    return "\n".join(parts)


def _build_sources(extracted: ExtractedData) -> dict:
    return {
        "reddit": [p.titulo for p in extracted.reddit_posts[:5]],
        "youtube": [v.titulo for v in extracted.youtube_videos[:5]],
        "trends": [t.concepto for t in extracted.trends[:5]],
    }


def _build_summary(extracted: ExtractedData) -> dict:
    return {
        "total_reddit": len(extracted.reddit_posts),
        "total_youtube": len(extracted.youtube_videos),
        "total_trends": len(extracted.trends),
        "errores": extracted.errores,
    }


def _fallback_curation(extracted: ExtractedData) -> CurationResult:
    best_post = extracted.reddit_posts[0] if extracted.reddit_posts else None
    best_video = extracted.youtube_videos[0] if extracted.youtube_videos else None

    tema = "Exploración estoica del día"
    if best_post:
        tema = best_post.titulo
    elif best_video:
        tema = best_video.titulo

    return CurationResult(
        tema_elegido=tema,
        por_que_funciona="Tema popular del día con potencial estoico",
        angulo_sugerido="Conectar con una enseñanza de Marco Aurelio o Séneca",
        fuente_principal="reddit" if best_post else "youtube",
        metricas_clave={
            "reddit_score": best_post.score if best_post else 0,
            "yt_views": best_video.vistas if best_video else 0,
        },
        fuentes_consultadas=_build_sources(extracted),
        raw_data_summary=_build_summary(extracted),
    )
