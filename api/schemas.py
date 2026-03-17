"""Pydantic response modelleri."""

from pydantic import BaseModel


class FuelPriceResponse(BaseModel):
    station: str
    city: str
    district: str
    fuel_type: str
    price: float
    date: str


class CityResponse(BaseModel):
    key: str
    display_name: str


class PricesResponse(BaseModel):
    city: str
    fuel_type: str | None
    count: int
    prices: list[FuelPriceResponse]
    cached: bool
    cache_age_seconds: int | None


class HealthResponse(BaseModel):
    status: str
