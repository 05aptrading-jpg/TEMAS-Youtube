import asyncio
from concurrent.futures import ThreadPoolExecutor
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .extractors.reddit_extractor import get_trending_reddit_posts
from .extractors.youtube_extractor import get_trending_youtube_videos
from .extractors.trends_extractor import get_trending_topics
from .curators.llm_curator import curate_content
from .models.schemas import RedditPost, YouTubeVideo, TrendData, ExtractedData, CurationResult

app = FastAPI(
    title="Curador Estoico API",
    description="Backend de curaduría de contenido estoico. Extrae tendencias de Reddit, YouTube y Google Trends, y las filtra vía IA.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

executor = ThreadPoolExecutor(max_workers=3)


async def run_in_thread(fn, *args, **kwargs):
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(executor, lambda: fn(*args, **kwargs))


@app.get("/")
def health_check():
    return {"status": "ok", "app": "Curador Estoico API"}


@app.get("/curar", response_model=dict)
async def curar():
    errores = []

    reddit_task = run_in_thread(get_trending_reddit_posts)
    youtube_task = run_in_thread(get_trending_youtube_videos)
    trends_task = run_in_thread(get_trending_topics)

    reddit_posts_raw, youtube_videos_raw, trends_raw = await asyncio.gather(
        reddit_task, youtube_task, trends_task, return_exceptions=True
    )

    reddit_posts = []
    if isinstance(reddit_posts_raw, Exception):
        errores.append(f"reddit: {str(reddit_posts_raw)}")
    else:
        reddit_posts = [RedditPost(**p) for p in reddit_posts_raw]

    youtube_videos = []
    if isinstance(youtube_videos_raw, Exception):
        errores.append(f"youtube: {str(youtube_videos_raw)}")
    else:
        youtube_videos = [YouTubeVideo(**v) for v in youtube_videos_raw]

    trends = []
    if isinstance(trends_raw, Exception):
        errores.append(f"trends: {str(trends_raw)}")
    else:
        trends = [TrendData(**t) for t in trends_raw]

    extracted = ExtractedData(
        reddit_posts=reddit_posts,
        youtube_videos=youtube_videos,
        trends=trends,
        errores=errores,
    )

    result = await run_in_thread(curate_content, extracted)

    return {"success": True, "data": result.model_dump()}
