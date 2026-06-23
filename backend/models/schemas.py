from pydantic import BaseModel
from typing import Optional
from datetime import datetime


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


class TopicItem(BaseModel):
    id: int
    titulo: str
    fuente: str
    score: int
    curado: bool
    por_que_funciona: Optional[str] = None
    angulo_sugerido: Optional[str] = None
    url: Optional[str] = None


class BatchResult(BaseModel):
    temas: list[TopicItem]
    total: int
    timestamp: str
    proxima_renovacion: str
    fuentes_consultadas: dict
