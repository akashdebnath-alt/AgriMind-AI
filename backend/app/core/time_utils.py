from datetime import date, datetime
from zoneinfo import ZoneInfo

from app.core.config import settings


def now_local() -> datetime:
    """Naive datetime in the configured timezone (all DB times are stored this way)."""
    return datetime.now(ZoneInfo(settings.timezone)).replace(tzinfo=None)


def today_local() -> date:
    return now_local().date()
