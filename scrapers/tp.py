"""TP (Türkiye Petrolleri) akaryakıt fiyat scraper'ı — GET + HTML tablo.

Not: tppd.com.tr'nin SSL sertifikası süresi dolmuş; verify=False kullanılır.
"""

from __future__ import annotations

import warnings

from bs4 import BeautifulSoup

from scrapers.base import BaseScraper
from config import (
    TP_BASE_URL,
    TP_HEADERS,
    TP_CITY_SLUGS,
    get_display_name,
    normalize_city,
)
from models import FuelPrice


# Tablo başlığı → standart yakıt adı
_HEADER_MAP: list[tuple[str, str]] = [
    ("kurşunsuz", "Benzin (95)"),
    ("kursun", "Benzin (95)"),
    ("gaz yağı", "Gazyağı"),
    ("gazyagi", "Gazyağı"),
    ("gaz ya", "Gazyağı"),
    ("y.k. fuel", "Fuel Oil (YK)"),
    ("yk fuel", "Fuel Oil (YK)"),
    ("yüksek kükürtlü", "Fuel Oil (YK)"),
    ("motorin", "Motorin"),
    ("kalorifer", "Kalorifer Yakıtı"),
    ("fuel oil", "Fuel Oil"),
    ("lpg", "LPG"),
    ("gaz)", "LPG"),       # "Gaz (TL/Lt)"
]


def _match_header(text: str) -> str | None:
    key = text.strip().lower()
    for pattern, name in _HEADER_MAP:
        if pattern in key:
            return name
    return None


def _parse_price(text: str) -> float | None:
    text = text.strip().replace(",", ".").replace(" ", "")
    if not text or text in ("-", "0.00", "0"):
        return None
    try:
        val = round(float(text), 2)
        return val if val > 0 else None
    except (ValueError, AttributeError):
        return None


class TPScraper(BaseScraper):
    """TP fiyatlarını tppd.com.tr GET + HTML tablosu üzerinden çeker."""

    name = "TP"

    def get_prices(self, city: str) -> list[FuelPrice]:
        city_key = normalize_city(city)
        slug = TP_CITY_SLUGS.get(city_key)

        if slug is None:
            raise ValueError(f"TP: '{city}' için şehir slug'ı bulunamadı.")

        url = TP_BASE_URL.format(city_slug=slug)

        # SSL sertifikası süresi dolmuş → verify=False
        import urllib3
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        resp = self._get(url, headers=TP_HEADERS, verify=False)

        return self._parse_html(resp.text, city)

    def _parse_html(self, html: str, city: str) -> list[FuelPrice]:
        """Tek tablo içeren TP HTML sayfasını parse eder.

        Tablo yapısı:
          <table>
            <tr><th>İLÇE</th><th>KURŞUNSUZ BENZİN</th><th>GAZ YAĞI</th>...</tr>
            <tr><td>ANKARA</td><td>51,75</td>...</tr>
            ...
          </table>
        """
        soup = BeautifulSoup(html, "lxml")
        prices: list[FuelPrice] = []
        display_name = get_display_name(city)

        table = soup.find("table")
        if not table:
            return prices

        rows = table.find_all("tr")
        if len(rows) < 2:
            return prices

        def _is_district_header(text: str) -> bool:
            import unicodedata
            nfkd = unicodedata.normalize("NFKD", text)
            cleaned = "".join(c for c in nfkd if not unicodedata.combining(c)).lower()
            return "ilce" in cleaned or "ilce" in cleaned or cleaned.strip() == "ilce"

        # Başlık satırı
        header_cells = rows[0].find_all(["th", "td"])
        header_map: dict[int, str] = {}
        for ci, cell in enumerate(header_cells):
            text = cell.get_text(separator=" ", strip=True)
            fuel = _match_header(text)
            if fuel:
                header_map[ci] = fuel

        if not header_map:
            return prices

        # Veri satırları
        for row in rows[1:]:
            cells = row.find_all("td")
            if not cells:
                continue
            texts = [c.get_text(strip=True) for c in cells]
            if not texts[0]:
                continue

            district_name = texts[0].strip().title()

            for ci, fuel_name in header_map.items():
                if ci < len(texts):
                    price_val = _parse_price(texts[ci])
                    if price_val:
                        prices.append(
                            FuelPrice(
                                station=self.name,
                                city=display_name,
                                district=district_name,
                                fuel_type=fuel_name,
                                price=price_val,
                            )
                        )

        return prices
