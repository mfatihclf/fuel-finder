"""Soyut temel scraper sınıfı."""

from abc import ABC, abstractmethod

import requests

from config import REQUEST_TIMEOUT
from models import FuelPrice


class BaseScraper(ABC):
    """Tüm scraper'lar bu temel sınıftan türer."""

    name: str = "Base"

    def __init__(self):
        self.session = requests.Session()

    @abstractmethod
    def get_prices(self, city: str) -> list[FuelPrice]:
        """Belirtilen şehir için fiyat listesi döndürür."""
        ...

    def _get(self, url: str, headers: dict | None = None, params: dict | None = None, verify: bool = True) -> requests.Response:
        resp = self.session.get(url, headers=headers, params=params, timeout=REQUEST_TIMEOUT, verify=verify)
        resp.raise_for_status()
        return resp

    def _post(self, url: str, headers: dict | None = None, data=None) -> requests.Response:
        resp = self.session.post(url, headers=headers, data=data, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        return resp
