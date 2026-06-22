import praw
from ..config import REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET, REDDIT_USER_AGENT, SUBREDDITS


def get_trending_reddit_posts() -> list[dict]:
    if not all([REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET]):
        return []

    reddit = praw.Reddit(
        client_id=REDDIT_CLIENT_ID,
        client_secret=REDDIT_CLIENT_SECRET,
        user_agent=REDDIT_USER_AGENT,
    )

    resultados = []
    vistos = set()

    for subreddit_name in SUBREDDITS:
        try:
            subreddit = reddit.subreddit(subreddit_name)
            for post in subreddit.hot(limit=10):
                if post.title in vistos:
                    continue
                vistos.add(post.title)

                if post.score >= 1000:
                    resultados.append({
                        "titulo": post.title,
                        "url": f"https://reddit.com{post.permalink}",
                        "score": post.score,
                        "subreddit": subreddit_name,
                        "num_comentarios": post.num_comments,
                    })
        except Exception:
            continue

    resultados.sort(key=lambda x: x["score"], reverse=True)
    return resultados[:20]
