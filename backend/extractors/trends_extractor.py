from pytrends.request import TrendReq
from ..config import STOIC_CONCEPTS_FOR_TRENDS


def get_trending_topics() -> list[dict]:
    try:
        pytrends = TrendReq(hl="es-ES", tz=360)
    except Exception:
        return []

    resultados = []
    batch_size = 5

    for i in range(0, len(STOIC_CONCEPTS_FOR_TRENDS), batch_size):
        batch = STOIC_CONCEPTS_FOR_TRENDS[i:i + batch_size]
        try:
            pytrends.build_payload(batch, cat=0, timeframe="now 7-d", geo="", gprop="")
            data = pytrends.interest_over_time()
            if data.empty:
                continue

            for concepto in batch:
                if concepto not in data.columns:
                    continue
                col = data[concepto]
                current = int(col.iloc[-1]) if len(col) > 0 else 0
                prev = int(col.iloc[0]) if len(col) > 0 else 0

                aumento = ""
                if prev > 0:
                    pct = ((current - prev) / prev) * 100
                    if pct > 0:
                        aumento = f"+{pct:.0f}%"
                    elif pct < 0:
                        aumento = f"{pct:.0f}%"
                    else:
                        aumento = "estable"

                if current >= 40 or (aumento and aumento.startswith("+")):
                    resultados.append({
                        "concepto": concepto,
                        "puntaje_actual": current,
                        "aumento": aumento,
                    })
        except Exception:
            continue

    resultados.sort(key=lambda x: x["puntaje_actual"], reverse=True)
    return resultados
