"""Petrol Ofisi ve BP akaryakıt fiyat scraper'ı — POST + HTML parse."""

from __future__ import annotations

from bs4 import BeautifulSoup

from scrapers.base import BaseScraper
from config import (
    PO_FUEL_SEARCH_URL,
    PO_HEADERS,
    get_plate_code,
    get_display_name,
)
from models import FuelPrice


class PetrolOfisiScraper(BaseScraper):
    """Petrol Ofisi fiyatlarını çeker."""

    name = "Petrol Ofisi"
    _is_bp = False

    def get_prices(self, city: str) -> list[FuelPrice]:
        plate_code = get_plate_code(city)
        if plate_code is None:
            raise ValueError(f"{self.name}: '{city}' için plaka kodu bulunamadı.")

        form_data = {
            "template": "1",
            "cityId": plate_code,
            "districtId": "",
            "isBp": str(self._is_bp).lower(),
        }

        resp = self._post(PO_FUEL_SEARCH_URL, headers=PO_HEADERS, data=form_data)
        return self._parse_html(resp.text, city)

    def _parse_html(self, html: str, city: str) -> list[FuelPrice]:
        """PO/BP'nin döndürdüğü HTML tablosunu parse eder.

        HTML yapısı:
          <table class="table table-prices">
            <thead>
              <tr><th>Şehir</th><th>V/Max Kurşunsuz 95</th><th>V/Max Diesel</th>...</tr>
            </thead>
            <tbody>
              <tr data-disctrict-name="ANKARA">
                <td>ANKARA</td>
                <td><span class="with-tax">62.38</span>...</td>
                ...
              </tr>
              <tr data-disctrict-name="AKYURT">
                <td>AKYURT</td>
                <td><span class="with-tax">62.38</span>...</td>
                ...
              </tr>
            </tbody>
          </table>
        """
        soup = BeautifulSoup(html, "lxml")
        prices: list[FuelPrice] = []
        display_name = get_display_name(city)

        # Tablo başlıklarını al — yakıt türleri
        table = soup.select_one("table.table-prices")
        if not table:
            table = soup.select_one("table")
        if not table:
            return prices

        # Header: Şehir, V/Max Kurşunsuz 95, V/Max Diesel, Gazyağı, ...
        headers: list[str] = []
        thead = table.select_one("thead")
        if thead:
            for th in thead.select("th"):
                headers.append(th.get_text(strip=True))

        if not headers:
            return prices

        # Tüm ilçe satırlarını parse et
        tbody = table.select_one("tbody")
        if not tbody:
            return prices

        for row in tbody.select("tr"):
            cells = row.find_all("td")
            if not cells:
                continue

            # İlk hücre = ilçe adı
            district_name = cells[0].get_text(strip=True).title()

            # Sonraki hücreler = yakıt fiyatları
            for i, cell in enumerate(cells):
                if i == 0:
                    continue  # İlçe adı sütunu, atla

                # Header index i ile eşleş (header[0]=Şehir, header[1]=ilk yakıt)
                if i < len(headers):
                    fuel_type = headers[i]
                else:
                    continue

                # KDV dahil fiyatı al
                price_span = cell.select_one("span.with-tax")
                if price_span:
                    price_text = price_span.get_text(strip=True)
                else:
                    price_text = cell.get_text(strip=True)

                price_val = self._parse_price(price_text)
                if price_val and price_val > 0:
                    prices.append(
                        FuelPrice(
                            station=self.name,
                            city=display_name,
                            district=district_name,
                            fuel_type=self._normalize_fuel(fuel_type),
                            price=price_val,
                        )
                    )

        return prices

    @staticmethod
    def _parse_price(text: str) -> float | None:
        """'62.38' veya '62,38' → 62.38"""
        try:
            cleaned = text.strip().replace(",", ".").replace("TL", "").replace("₺", "").strip()
            return round(float(cleaned), 2)
        except (ValueError, AttributeError):
            return None

    @staticmethod
    def _normalize_fuel(raw: str) -> str:
        """Yakıt türü adını standartlaştırır."""
        mapping = {
            "v/max kurşunsuz 95": "Benzin (95)",
            "kurşunsuz 95": "Benzin (95)",
            "v/max diesel": "Motorin",
            "motorin": "Motorin",
            "dizel": "Motorin",
            "po/gaz otogaz": "LPG",
            "po/gaz": "LPG",
            "lpg": "LPG",
            "otogaz": "LPG",
            "gazyağı": "Gazyağı",
            "kalorifer yakıtı": "Kalorifer Yakıtı",
            "fuel oil": "Fuel Oil",
            "yüksek kükürtlü fuel oil": "Fuel Oil (YK)",
        }
        key = raw.strip().lower()
        return mapping.get(key, raw.strip())


class BPScraper(PetrolOfisiScraper):
    """BP fiyatlarını çeker — Petrol Ofisi altyapısını kullanır."""

    name = "BP"
    _is_bp = True
