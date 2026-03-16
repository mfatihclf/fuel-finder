"""TotalEnergies akaryakıt fiyat scraper'ı — JSON API."""

from __future__ import annotations

from scrapers.base import BaseScraper
from config import (
    TOTAL_CITIES_URL,
    TOTAL_PRICES_URL,
    TOTAL_HEADERS,
    TOTAL_CITY_IDS,
    get_display_name,
    normalize_city,
)
from models import FuelPrice


# Alan adı → standart yakıt adı
_FIELD_MAP: dict[str, str] = {
    "kursunsuz_95_excellium_95": "Benzin (95)",
    "motorin": "Motorin",
    "motorin_excellium": "Motorin (Excellium)",
    "gazyagi": "Gazyağı",
    "kalorifer_yakiti": "Kalorifer Yakıtı",
    "fuel_oil": "Fuel Oil",
    "yuksek_kukurtlu_fuel_oil": "Fuel Oil (YK)",
    "otogaz": "LPG",
}


class TotalEnergiesScraper(BaseScraper):
    """TotalEnergies fiyatlarını guzelenerji.com.tr JSON API üzerinden çeker."""

    name = "TotalEnergies"

    def __init__(self):
        super().__init__()
        self._city_map: dict[str, int] | None = None  # normalized_name → city_id

    def _load_city_map(self) -> dict[str, int]:
        """API'den şehir listesini çekip cache'ler."""
        if self._city_map is not None:
            return self._city_map

        try:
            resp = self._get(TOTAL_CITIES_URL, headers=TOTAL_HEADERS)
            data = resp.json()
            mapping: dict[str, int] = {}
            for item in data:
                city_id = item.get("city_id")
                city_name = item.get("city_name", "")
                if city_id and city_name:
                    mapping[normalize_city(city_name)] = int(city_id)
            self._city_map = mapping
        except Exception:
            # API erişilemezse statik haritaya geri dön
            self._city_map = {k: v for k, v in TOTAL_CITY_IDS.items()}
        return self._city_map

    def get_prices(self, city: str) -> list[FuelPrice]:
        city_map = self._load_city_map()
        city_key = normalize_city(city)
        city_id = city_map.get(city_key)

        if city_id is None:
            raise ValueError(
                f"TotalEnergies: '{city}' için şehir ID bulunamadı."
            )

        url = TOTAL_PRICES_URL.format(city_id=city_id)
        resp = self._get(url, headers=TOTAL_HEADERS)
        data = resp.json()  # list of district dicts

        prices: list[FuelPrice] = []
        display_name = get_display_name(city)

        for district in data:
            district_name = district.get("county_name", "").strip().title()

            for field, fuel_label in _FIELD_MAP.items():
                val = district.get(field)
                # 0, null veya eksik değerleri atla
                if val is None or val == 0:
                    continue
                try:
                    price_val = round(float(val), 2)
                except (TypeError, ValueError):
                    continue
                if price_val > 0:
                    prices.append(
                        FuelPrice(
                            station=self.name,
                            city=display_name,
                            district=district_name,
                            fuel_type=fuel_label,
                            price=price_val,
                        )
                    )

        return prices
