"""Opet akaryakıt fiyat scraper'ı — JSON API kullanır."""

from __future__ import annotations

from scrapers.base import BaseScraper
from config import (
    OPET_HEADERS,
    OPET_PRICES_URL,
    OPET_PROVINCES_URL,
    get_display_name,
    normalize_city,
)
from models import FuelPrice


# Opet yakıt türü adlarını standartlaştırma
_FUEL_TYPE_MAP: dict[str, str] = {
    "kurşunsuz benzin 95": "Benzin (95)",
    "kurşunsuz 95": "Benzin (95)",
    "kurşunsuz 97": "Benzin (97)",
    "gazyağı": "Gazyağı",
    "motorin": "Motorin",
    "motorin ultraforce": "Motorin (UltraForce)",
    "motorin ecoforce": "Motorin (EcoForce)",
    "eurodizel": "Motorin (Euro)",
    "lpg (otogaz)": "LPG",
    "kalorifer yakıtı": "Kalorifer Yakıtı",
    "fuel oil": "Fuel Oil",
    "yüksek kükürtlü fuel oil": "Fuel Oil (YK)",
}


def _normalize_fuel_type(raw: str) -> str:
    key = raw.strip().lower()
    return _FUEL_TYPE_MAP.get(key, raw.strip())


class OpetScraper(BaseScraper):
    """Opet JSON API üzerinden fiyat çeker."""

    name = "Opet"

    def __init__(self):
        super().__init__()
        self._provinces: dict[str, str] | None = None  # normalized_name → code

    # ------------------------------------------------------------------
    # İl listesini API'den çek ve cache'le
    # ------------------------------------------------------------------
    def _load_provinces(self) -> dict[str, str]:
        if self._provinces is not None:
            return self._provinces

        resp = self._get(OPET_PROVINCES_URL, headers=OPET_HEADERS)
        data = resp.json()

        mapping: dict[str, str] = {}
        for item in data:
            code = item.get("code") or item.get("Code") or ""
            name = item.get("name") or item.get("Name") or ""
            if code and name:
                mapping[normalize_city(name)] = str(code)
        self._provinces = mapping
        return mapping

    # ------------------------------------------------------------------
    # Fiyatları çek
    # ------------------------------------------------------------------
    def get_prices(self, city: str) -> list[FuelPrice]:
        provinces = self._load_provinces()
        city_key = normalize_city(city)
        province_code = provinces.get(city_key)

        # İstanbul gibi ikiye bölünmüş iller için partial match
        if province_code is None:
            matches = {k: v for k, v in provinces.items() if k.startswith(city_key)}
            if matches:
                # İlk eşleşmeyi al (ör: istanbulavrupa)
                first_key = sorted(matches.keys())[0]
                province_code = matches[first_key]

        if province_code is None:
            raise ValueError(
                f"Opet: '{city}' için il kodu bulunamadı. "
                f"Geçerli iller: {', '.join(sorted(provinces.keys()))}"
            )

        params = {"ProvinceCode": province_code, "IncludeAllProducts": "true"}
        resp = self._get(OPET_PRICES_URL, headers=OPET_HEADERS, params=params)
        data = resp.json()

        prices: list[FuelPrice] = []
        display_name = get_display_name(city)

        # Response: list of districts
        # Her district: {provinceName, districtName, prices: [{productName, amount}, ...]}
        for district in data:
            district_name = (
                district.get("districtName")
                or district.get("DistrictName")
                or ""
            ).strip().title()

            product_list = (
                district.get("prices")
                or district.get("products")
                or district.get("Products")
                or []
            )
            for product in product_list:
                raw_name = (
                    product.get("productName")
                    or product.get("name")
                    or product.get("Name")
                    or ""
                )
                price_val = (
                    product.get("amount")
                    or product.get("Amount")
                    or product.get("price")
                    or 0
                )

                if price_val and float(price_val) > 0:
                    prices.append(
                        FuelPrice(
                            station=self.name,
                            city=display_name,
                            district=district_name,
                            fuel_type=_normalize_fuel_type(raw_name),
                            price=round(float(price_val), 2),
                        )
                    )

        return prices
