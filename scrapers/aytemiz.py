"""Aytemiz akaryakıt fiyat scraper'ı — ASP.NET WebForms POST + HTML tablo."""

from __future__ import annotations

from bs4 import BeautifulSoup

from scrapers.base import BaseScraper
from config import (
    AYTEMIZ_URL,
    AYTEMIZ_HEADERS,
    AYTEMIZ_CITY_IDS,
    get_display_name,
    normalize_city,
)
from models import FuelPrice


# Tablo başlığı anahtar kelimesi → standart yakıt adı (spesifik önce gelir!)
_HEADER_MAP: list[tuple[str, str]] = [
    ("k#benzin 95 oktan optimum", "Benzin (95)"),      # Aytemiz OPTIMUM benzin
    ("k#benzin 95 oktan premium", "Benzin (95) Premium"),  # Aytemiz Premium benzin
    ("motorin optimum", "Motorin (Optimum)"),
    ("motorin", "Motorin"),
    ("benzin", "Benzin (95)"),
    ("gazyağı", "Gazyağı"),
    ("gazyagi", "Gazyağı"),
    ("yüksek kükürtlü", "Fuel Oil (YK)"),
    ("yuksek kukurtlu", "Fuel Oil (YK)"),
    ("kalorifer", "Kalorifer Yakıtı"),
    ("fuel oil", "Fuel Oil"),
    ("oto lpg", "LPG"),
    ("lpg", "LPG"),
    ("otogaz", "LPG"),
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


class AytemizScraper(BaseScraper):
    """Aytemiz fiyatlarını ASP.NET POST + HTML parse üzerinden çeker.

    Sayfa birden fazla select içerir (akaryakıt tarihi + LPG tarihi).
    İlk seçili değerleri aynen göndererek tek POST ile tüm ana yakıt
    fiyatlarını alırız.
    """

    name = "Aytemiz"

    def get_prices(self, city: str) -> list[FuelPrice]:
        city_key = normalize_city(city)
        city_id = AYTEMIZ_CITY_IDS.get(city_key)

        if city_id is None:
            raise ValueError(f"Aytemiz: '{city}' için şehir ID bulunamadı.")

        # 1) GET ile form durumunu al (session başlat / cookie al)
        get_headers = {
            "User-Agent": AYTEMIZ_HEADERS["User-Agent"],
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "tr-TR,tr;q=0.9",
        }
        init_resp = self.session.get(AYTEMIZ_URL, headers=get_headers, timeout=15)
        init_resp.raise_for_status()
        soup = BeautifulSoup(init_resp.text, "lxml")

        # Tüm form alanlarını otomatik olarak topla (hidden input'lar + select'lerin ilk değerleri)
        form_data: dict[str, str] = {}

        for inp in soup.find_all("input"):
            name = inp.get("name")
            if not name:
                continue
            t = inp.get("type", "text").lower()
            if t in ("hidden", "submit"):
                form_data[name] = inp.get("value", "")
            elif t == "radio":
                # KDV dahil (value=1) seç
                if inp.get("value") == "1":
                    form_data[name] = "1"

        # Select alanları: her biri için ilk option değerini seç (formdaki default)
        for sel in soup.find_all("select"):
            name = sel.get("name")
            if not name:
                continue
            opts = sel.find_all("option")
            # Seçili option varsa onu kullan, yoksa ilk option
            selected = sel.find("option", selected=True)
            if selected and selected.get("value"):
                form_data[name] = selected["value"]
            elif opts:
                # Boş seçenek değil, ilk gerçek option değerini al
                real_opts = [o for o in opts if o.get("value")]
                val = real_opts[0]["value"] if real_opts else ""
                form_data[name] = val

        # Şehir ID'sini override et
        city_sel = soup.find("select", id=lambda x: x and "selCities" in x if x else False)
        if city_sel and city_sel.get("name"):
            form_data[city_sel.get("name")] = city_id

        # Submit butonu ekle
        btn = soup.find("input", {"type": "submit"})
        if btn and btn.get("name"):
            form_data[btn.get("name")] = btn.get("value", "Sorgula")
        
        # __EVENTTARGET ve __EVENTARGUMENT
        form_data.setdefault("__EVENTTARGET", "")
        form_data.setdefault("__EVENTARGUMENT", "")

        # 2) POST
        post_h = {
            "User-Agent": AYTEMIZ_HEADERS["User-Agent"],
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": AYTEMIZ_URL,
            "Accept": "text/html,application/xhtml+xml",
            "Accept-Language": "tr-TR,tr;q=0.9",
        }
        resp = self.session.post(AYTEMIZ_URL, headers=post_h, data=form_data, timeout=15)
        resp.raise_for_status()

        return self._parse_html(resp.text, city)

    def _parse_html(self, html: str, city: str) -> list[FuelPrice]:
        """HTML tablosunu parse eder."""
        soup = BeautifulSoup(html, "lxml")
        prices: list[FuelPrice] = []
        display_name = get_display_name(city)

        # En fazla satırı olan tabloyu bul
        best_table = None
        max_rows = 0
        for table in soup.find_all("table"):
            rows = table.find_all("tr")
            if len(rows) > max_rows:
                max_rows = len(rows)
                best_table = table

        if not best_table or max_rows < 3:
            return prices

        rows = best_table.find_all("tr")

        # Başlık satırını bul ve sütun → yakıt türü eşleşmesi oluştur
        header_map: dict[int, str] = {}
        header_row_idx = -1

        def _is_district_cell(text: str) -> bool:
            """'İLÇE' gibi metinlerde Turkish İ → i sorununu aşar."""
            import unicodedata
            # Normalize edip combining karakterleri sil
            nfkd = unicodedata.normalize("NFKD", text)
            cleaned = "".join(c for c in nfkd if not unicodedata.combining(c)).lower()
            return "ilce" in cleaned or "ilçe" in cleaned

        for ri, row in enumerate(rows):
            cells = row.find_all(["th", "td"])
            if not cells:
                continue
            texts = [c.get_text(separator=" ", strip=True) for c in cells]
            if any(_is_district_cell(t) for t in texts):
                header_row_idx = ri
                for ci, t in enumerate(texts):
                    fuel = _match_header(t)
                    if fuel:
                        header_map[ci] = fuel
                break

        if not header_map:
            return prices

        # Veri satırlarını parse et
        for row in rows[header_row_idx + 1:]:
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
