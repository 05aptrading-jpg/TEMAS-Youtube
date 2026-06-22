from googleapiclient.discovery import build
from ..config import YOUTUBE_API_KEY, YOUTUBE_SEARCH_TERMS


def get_trending_youtube_videos() -> list[dict]:
    if not YOUTUBE_API_KEY:
        return []

    youtube = build("youtube", "v3", developerKey=YOUTUBE_API_KEY)
    resultados = []
    vistos = set()

    for term in YOUTUBE_SEARCH_TERMS:
        try:
            request = youtube.search().list(
                q=term,
                part="snippet",
                type="video",
                order="viewCount",
                maxResults=5,
                relevanceLanguage="es",
                publishedAfter="2026-06-14T00:00:00Z",
            )
            response = request.execute()

            video_ids = [item["id"]["videoId"] for item in response.get("items", [])]
            if not video_ids:
                continue

            stats_request = youtube.videos().list(
                part="statistics,snippet",
                id=",".join(video_ids),
            )
            stats_response = stats_request.execute()

            for item in stats_response.get("items", []):
                video_id = item["id"]
                if video_id in vistos:
                    continue
                vistos.add(video_id)

                snippet = item["snippet"]
                stats = item.get("statistics", {})
                views = int(stats.get("viewCount", 0))

                if views >= 5000:
                    resultados.append({
                        "titulo": snippet["title"],
                        "url": f"https://youtube.com/watch?v={video_id}",
                        "vistas": views,
                        "likes": int(stats.get("likeCount", 0)),
                        "canal": snippet["channelTitle"],
                        "fecha_publicacion": snippet["publishedAt"],
                    })
        except Exception:
            continue

    resultados.sort(key=lambda x: x["vistas"], reverse=True)
    return resultados[:15]
