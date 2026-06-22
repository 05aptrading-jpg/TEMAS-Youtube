import os
from dotenv import load_dotenv

load_dotenv()

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "qwen/qwen3.6-35b-a3b:free")
OPENROUTER_FALLBACK_MODEL = "deepseek/deepseek-v4-flash"

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")

REDDIT_CLIENT_ID = os.getenv("REDDIT_CLIENT_ID")
REDDIT_CLIENT_SECRET = os.getenv("REDDIT_CLIENT_SECRET")
REDDIT_USER_AGENT = os.getenv("REDDIT_USER_AGENT", "SkillCuratorEstoico/v1.0")

SUBREDDITS = [
    "Stoicism",
    "todayilearned",
    "Showerthoughts",
    "philosophy",
    "HistoryPorn",
    "ancientrome",
]

YOUTUBE_SEARCH_TERMS = [
    "estoicismo",
    "filosofia estoica",
    "Marco Aurelio",
    "Seneca estoicismo",
    "filosofia antigua",
    "stoicism philosophy",
    "epictetus",
    "filosofia para la vida",
]

STOIC_CONCEPTS_FOR_TRENDS = [
    "estoicismo",
    "Marco Aurelio",
    "Seneca",
    "Epicteto",
    "filosofia estoica",
    "stoicism",
    "Meditaciones",
    "memento mori",
]
