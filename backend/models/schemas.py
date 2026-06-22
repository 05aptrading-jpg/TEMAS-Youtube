from pydantic import BaseModel
from typing import Optional


class RedditPost(BaseModel):
    titulo: str
    url: str
    score: int
    subreddit: str
    num_comentarios: int


class YouTubeVideo(BaseModel):
    titulo: str
    url: str
    vistas: int
    likes: int
    canal: str
    fecha_publicacion: str


class TrendData(BaseModel):
    concepto: str
    puntaje_actual: int
    aumento: str


class ExtractedData(BaseModel):
    reddit_posts: list[RedditPost]
    youtube_videos: list[YouTubeVideo]
    trends: list[TrendData]
    errores: list[str]


class CurationResult(BaseModel):
    tema_elegido: str
    por_que_funciona: str
    angulo_sugerido: str
    fuente_principal: str
    metricas_clave: dict
    fuentes_consultadas: dict
    raw_data_summary: Optional[dict] = None
