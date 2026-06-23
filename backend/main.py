import asyncio
import json
import os
import time
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from .extractors.reddit_extractor import get_trending_reddit_posts
from .extractors.youtube_extractor import get_trending_youtube_videos
from .extractors.trends_extractor import get_trending_topics
from .curators.llm_curator import curate_content, curate_batch
from .models.schemas import (
    RedditPost, YouTubeVideo, TrendData, ExtractedData,
    CurationResult, TopicItem, BatchResult,
)

HISTORY_FILE = os.path.join(os.path.dirname(__file__), "historial.json")
MAX_HISTORY = 500

app = FastAPI(
    title="Curador Estoico API",
    description="Backend de curaduría de contenido estoico.",
    version="3.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

executor = ThreadPoolExecutor(max_workers=5)

_cache = {
    "data": None,
    "timestamp": 0,
    "ttl": 6 * 3600,
}

_historial: list[dict] = []


def _load_historial():
    global _historial
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                _historial = json.load(f)
        except Exception:
            _historial = []
    else:
        _historial = []


def _save_historial():
    try:
        with open(HISTORY_FILE, "w", encoding="utf-8") as f:
            json.dump(_historial, f, ensure_ascii=False, indent=2)
    except Exception:
        pass


def _add_to_historial(temas: list[dict]):
    global _historial
    existing_titles = {t["titulo"] for t in _historial}
    for tema in temas:
        if tema["titulo"] not in existing_titles:
            existing_titles.add(tema["titulo"])
            _historial.insert(0, {
                "titulo": tema["titulo"],
                "fuente": tema.get("fuente", "unknown"),
                "por_que_funciona": tema.get("por_que_funciona"),
                "angulo_sugerido": tema.get("angulo_sugerido"),
                "url": tema.get("url"),
                "fecha_guardado": datetime.now().isoformat(),
            })
    if len(_historial) > MAX_HISTORY:
        _historial = _historial[:MAX_HISTORY]
    _save_historial()


_load_historial()


async def run_in_thread(fn, *args, **kwargs):
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(executor, lambda: fn(*args, **kwargs))


async def _extract_all() -> ExtractedData:
    errores = []

    reddit_raw, youtube_raw, trends_raw = await asyncio.gather(
        run_in_thread(get_trending_reddit_posts),
        run_in_thread(get_trending_youtube_videos),
        run_in_thread(get_trending_topics),
        return_exceptions=True,
    )

    reddit_posts = []
    if isinstance(reddit_raw, Exception):
        errores.append(f"reddit: {str(reddit_raw)}")
    else:
        reddit_posts = [RedditPost(**p) for p in reddit_raw]

    youtube_videos = []
    if isinstance(youtube_raw, Exception):
        errores.append(f"youtube: {str(youtube_raw)}")
    else:
        youtube_videos = [YouTubeVideo(**v) for v in youtube_raw]

    trends = []
    if isinstance(trends_raw, Exception):
        errores.append(f"trends: {str(trends_raw)}")
    else:
        trends = [TrendData(**t) for t in trends_raw]

    return ExtractedData(
        reddit_posts=reddit_posts,
        youtube_videos=youtube_videos,
        trends=trends,
        errores=errores,
    )


@app.get("/")
def health_check():
    return {"status": "ok", "app": "Curador Estoico API", "version": "3.0.0"}


@app.get("/curar", response_model=dict)
async def curar():
    extracted = await _extract_all()
    result = await run_in_thread(curate_content, extracted)
    return {"success": True, "data": result.model_dump()}


@app.get("/temas", response_model=dict)
async def temas():
    now = time.time()

    if _cache["data"] and (now - _cache["timestamp"]) < _cache["ttl"]:
        remaining = _cache["ttl"] - (now - _cache["timestamp"])
        return {
            "success": True,
            "cached": True,
            "segundos_para_renovar": int(remaining),
            "data": _cache["data"],
        }

    extracted = await _extract_all()
    batch_raw = await run_in_thread(curate_batch, extracted)

    topic_id = 0
    temas_curados = []
    seen = set()

    for t in batch_raw:
        titulo = t.get("titulo", "")
        if titulo and titulo not in seen:
            seen.add(titulo)
            topic_id += 1
            temas_curados.append(TopicItem(
                id=topic_id,
                titulo=titulo,
                fuente=t.get("fuente", "unknown"),
                score=0,
                curado=True,
                por_que_funciona=t.get("por_que_funciona", ""),
                angulo_sugerido=t.get("angulo_sugerido", ""),
                url=None,
            ))

    for v in extracted.youtube_videos:
        if v.titulo not in seen:
            seen.add(v.titulo)
            topic_id += 1
            temas_curados.append(TopicItem(
                id=topic_id,
                titulo=v.titulo,
                fuente="youtube",
                score=v.vistas,
                curado=False,
                por_que_funciona=None,
                angulo_sugerido=None,
                url=v.url,
            ))

    for p in extracted.reddit_posts:
        if p.titulo not in seen:
            seen.add(p.titulo)
            topic_id += 1
            temas_curados.append(TopicItem(
                id=topic_id,
                titulo=p.titulo,
                fuente="reddit",
                score=p.score,
                curado=False,
                por_que_funciona=None,
                angulo_sugerido=None,
                url=p.url,
            ))

    for t in extracted.trends:
        if t.concepto not in seen:
            seen.add(t.concepto)
            topic_id += 1
            temas_curados.append(TopicItem(
                id=topic_id,
                titulo=f"Tendencia: {t.concepto} ({t.aumento})",
                fuente="trends",
                score=t.puntaje_actual,
                curado=False,
                por_que_funciona=None,
                angulo_sugerido=None,
                url=None,
            ))

    ahora = datetime.now()
    renovacion = ahora + timedelta(seconds=_cache["ttl"])

    batch_result = BatchResult(
        temas=temas_curados,
        total=len(temas_curados),
        timestamp=ahora.isoformat(),
        proxima_renovacion=renovacion.isoformat(),
        fuentes_consultadas={
            "reddit": len(extracted.reddit_posts),
            "youtube": len(extracted.youtube_videos),
            "trends": len(extracted.trends),
            "curados_llm": len(batch_raw),
        },
    )

    _cache["data"] = batch_result.model_dump()
    _cache["timestamp"] = now

    _add_to_historial([t.model_dump() for t in temas_curados])

    return {
        "success": True,
        "cached": False,
        "segundos_para_renovar": _cache["ttl"],
        "data": batch_result.model_dump(),
    }


@app.get("/temas/refresh", response_model=dict)
async def temas_refresh():
    _cache["data"] = None
    _cache["timestamp"] = 0
    return await temas()


@app.get("/historial", response_model=dict)
def historial():
    return {
        "success": True,
        "total": len(_historial),
        "temas": _historial,
    }


@app.post("/historial/limpiar", response_model=dict)
def historial_limpiar():
    global _historial
    _historial = []
    _save_historial()
    return {"success": True, "mensaje": "Historial limpiado"}
