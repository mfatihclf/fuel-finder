"""Shell akaryakıt fiyat scraper'ı — ASP.NET WebForms callback."""

from __future__ import annotations

import re
import json

from bs4 import BeautifulSoup

from scrapers.base import BaseScraper
from config import (
    SHELL_BASE_URL,
    SHELL_HEADERS,
    get_shell_code,
    get_display_name,
)
from models import FuelPrice


def _parse_price(text: str) -> float | None:
    """'60,82' → 60.82"""
    text = text.strip()
    if not text or text == "-":
        return None
    try:
        return round(float(text.replace(",", ".")), 2)
    except (ValueError, AttributeError):
        return None


class ShellScraper(BaseScraper):
    """Shell fiyatlarını turkiyeshell.com ASP.NET callback üzerinden çeker."""

    name = "Shell"

    # Tablo sütun sırası (sabit):
    # İlçe | K.Benzin 95 | Motorin | GazYağı | Kalyak | YK Fuel Oil | Fuel Oil | Otogaz
    _FUEL_COLUMNS = [
        "Benzin (95)",
        "Motorin",
        "Gazyağı",
        "Kalorifer Yakıtı",
        "Fuel Oil (YK)",
        "Fuel Oil",
        "LPG",
    ]

    def get_prices(self, city: str) -> list[FuelPrice]:
        shell_code = get_shell_code(city)
        if shell_code is None:
            raise ValueError(f"Shell: '{city}' için şehir kodu bulunamadı.")

        # 1) İlk GET ile __VIEWSTATE ve __EVENTVALIDATION değerlerini al
        init_headers = {
            "User-Agent": SHELL_HEADERS["User-Agent"],
        }
        resp = self._get(SHELL_BASE_URL, headers=init_headers)
        viewstate, event_validation = self._extract_asp_fields(resp.text)

        # 2) POST ile şehir seçimi yap
        callback_param = json.dumps({
            "Action": "OnProvinceSelect",
            "Params": {
                "county_code": None,
                "province_code": shell_code,
            }
        }, separators=(",", ":"))

        form_data = {
            "__CALLBACKID": "cb_all",
            "__CALLBACKPARAM": f"c0:{callback_param}",
            "__VIEWSTATE": viewstate,
        }
        if event_validation:
            form_data["__EVENTVALIDATION"] = event_validation

        resp = self._post(SHELL_BASE_URL, headers=SHELL_HEADERS, data=form_data)

        return self._parse_response(resp.text, city)

    def _extract_asp_fields(self, html: str) -> tuple[str, str]:
        """__VIEWSTATE ve __EVENTVALIDATION değerlerini çıkarır."""
        soup = BeautifulSoup(html, "lxml")

        vs_input = soup.find("input", attrs={"name": "__VIEWSTATE"})
        viewstate = vs_input["value"] if vs_input else ""

        ev_input = soup.find("input", attrs={"name": "__EVENTVALIDATION"})
        event_validation = ev_input["value"] if ev_input else ""

        return viewstate, event_validation

    def _parse_response(self, text: str, city: str) -> list[FuelPrice]:
        """ASP.NET callback yanıtını parse eder.

        Shell'in tablo yapısı karmaşık: hücreler iç içe geçmiş ve düz sırada.
        Token-based parsing ile tüm ilçe verilerini çıkarır.

        Yanıt formatı (tokenize edilmiş):
            ...DISTRICT_NAME price1 price2 ... price7 DISTRICT_NAME price1 ...
        Her ilçe 8 token: isim + 7 yakıt fiyatı (veya -)
        """
        prices: list[FuelPrice] = []
        display_name = get_display_name(city)

        # 'result' alanını çek
        match = re.search(r"'result':'(.*)'", text, re.DOTALL)
        if not match:
            return prices

        raw = match.group(1)

        # Tüm fiyat değerlerini ve ilçe adlarını sırayla çek
        # Token: ya bir fiyat (NN,NN) ya bir ilçe adı (harf dizisi) ya bir tire
        token_pattern = re.compile(
            r"(\d{1,3},\d{2})"     # fiyat: 60,82
            r"|(-)"                 # tire: -
            r"|([A-Z][A-Z0-9_.]{2,})"  # ilçe adı: ALTINDAG
        )

        tokens: list[str] = token_pattern.findall(raw)
        # Her match (price, dash, name) tuple üretir; birini seç
        flat_tokens: list[str] = []
        for price, dash_val, name in tokens:
            if price:
                flat_tokens.append(price)
            elif dash_val:
                flat_tokens.append("-")
            elif name:
                # "Loading", "Shell", form field adları gibi gürültüyü filtrele
                if name in ("Loading", "DXR", "INPUT", "TABLE", "SCRIPT", "LINK",
                            "DIV", "SPAN", "SELECT", "OPTION", "FORM"):
                    continue
                # Çok kısa adlar (< 3 harf, "TD" gibi) ve Shell alanlarını atla
                if len(name) < 3 or name.startswith("__") or name.startswith("DX"):
                    continue
                flat_tokens.append(name)

        # Şimdi flat_tokens'ta: [ilçe, fiyat/dash x7, ilçe, fiyat/dash x7, ...]
        # Tüm ilçeleri bul ve her biri için 7 fiyat token'ı oku
        i = 0
        while i < len(flat_tokens):
            token = flat_tokens[i]

            # Bu bir ilçe adı mı? (yani fiyat veya dash değil)
            is_price = token.replace(",", "").replace(".", "").isdigit()
            if not is_price and token != "-":
                # Sonraki 7 token fiyat olmalı
                if i + 7 < len(flat_tokens):
                    price_values = flat_tokens[i + 1: i + 8]

                    # Tüm 7 değerin fiyat veya dash olduğunu kontrol et
                    all_valid = all(
                        v == "-" or re.match(r"^\d{1,3},\d{2}$", v)
                        for v in price_values
                    )

                    if all_valid:
                        # En az 1 gerçek fiyat var mı?
                        real_prices = [v for v in price_values if v != "-"]
                        if len(real_prices) >= 1:
                            district_name = token.replace("_", " ").title()
                            for j, fuel_name in enumerate(self._FUEL_COLUMNS):
                                price_val = _parse_price(price_values[j])
                                if price_val and price_val > 0:
                                    prices.append(
                                        FuelPrice(
                                            station=self.name,
                                            city=display_name,
                                            district=district_name,
                                            fuel_type=fuel_name,
                                            price=price_val,
                                        )
                                    )

                i += 8  # ilçe + 7 fiyat
            else:
                i += 1

        return prices
