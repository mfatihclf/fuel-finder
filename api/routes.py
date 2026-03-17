"""API route handler'lari."""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed

from fastapi import APIRouter, HTTPException, Query

from config import CITY_DISPLAY_NAMES, normalize_city, get_display_name
from scrapers import (
    OpetScraper, PetrolOfisiScraper, BPScraper, ShellScraper,
    TotalEnergiesScraper, AytemizScraper, TPScraper,
)
from .cache import TTLCache
from .schemas import FuelPriceResponse, PricesResponse, CityResponse

router = APIRouter(prefix="/api")

# Sehir bazinda 10 dakika cache
_cache = TTLCache(default_ttl=600)

_SCRAPERS = {
    "opet": OpetScraper,
    "po": PetrolOfisiScraper,
    "bp": BPScraper,
    "shell": ShellScraper,
    "total": TotalEnergiesScraper,
    "aytemiz": AytemizScraper,
    "tp": TPScraper,
}

FUEL_TYPES = [
    "Benzin (95)",
    "Benzin (97)",
    "Motorin",
    "LPG",
    "Motorin (UltraForce)",
    "Motorin (EcoForce)",
    "Motorin (Excellium)",
    "Motorin (Optimum)",
    "Gazyagi",
    "Kalorifer Yakiti",
    "Fuel Oil",
    "Fuel Oil (YK)",
]


@router.get("/prices", response_model=PricesResponse)
def get_prices(
    city: str = Query(..., description="Il adi (orn: istanbul, ankara)"),
    fuel_type: str | None = Query(None, description="Yakit turu filtresi (orn: Motorin, LPG)"),
):
    """Belirtilen sehir icin akaryakit fiyatlarini dondurur."""
    city_key = normalize_city(city)
    if city_key not in CITY_DISPLAY_NAMES:
        raise HTTPException(status_code=404, detail=f"Il bulunamadi: '{city}'")

    cached = _cache.get(city_key)
    if cached:
        all_prices, age = cached
        is_cached = True
    else:
        all_prices = _fetch_all(city_key)
        _cache.set(city_key, all_prices)
        age = 0
        is_cached = False

    prices = all_prices
    if fuel_type:
        ft_lower = fuel_type.lower()
        prices = [p for p in all_prices if ft_lower in p.fuel_type.lower()]

    return PricesResponse(
        city=get_display_name(city_key),
        fuel_type=fuel_type,
        count=len(prices),
        prices=[
            FuelPriceResponse(
                station=p.station,
                city=p.city,
                district=p.district,
                fuel_type=p.fuel_type,
                price=p.price,
                date=p.date,
            )
            for p in prices
        ],
        cached=is_cached,
        cache_age_seconds=age if is_cached else None,
    )


@router.get("/cities", response_model=list[CityResponse])
def get_cities():
    """Desteklenen tum illeri dondurur."""
    return [
        CityResponse(key=k, display_name=v)
        for k, v in sorted(CITY_DISPLAY_NAMES.items())
    ]


@router.get("/fuel-types", response_model=list[str])
def get_fuel_types():
    """Desteklenen yakit turlerini dondurur."""
    return FUEL_TYPES


def _fetch_all(city: str) -> list:
    """Tum scraperlardan esit zamanli fiyat ceker."""
    results: list = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {
            executor.submit(cls().get_prices, city): name
            for name, cls in _SCRAPERS.items()
        }
        for future in as_completed(futures):
            try:
                prices = future.result()
                if prices:
                    results.extend(prices)
            except Exception:
                pass
    return results
