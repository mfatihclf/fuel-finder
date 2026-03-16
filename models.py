"""Veri modelleri — tüm scraper'lar bu ortak yapıyı kullanır."""

from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class FuelPrice:
    """Tek bir yakıt fiyat kaydı."""

    station: str          # İstasyon markası (Opet, Shell, vb.)
    city: str             # Şehir adı
    district: str         # İlçe adı
    fuel_type: str        # Yakıt türü (Benzin, Motorin, LPG, vb.)
    price: float          # Litre fiyatı (TL)
    date: str = ""        # Fiyat tarihi (varsa)

    def to_dict(self) -> dict:
        return {
            "istasyon": self.station,
            "sehir": self.city,
            "ilce": self.district,
            "yakit_turu": self.fuel_type,
            "fiyat_tl": self.price,
            "tarih": self.date,
        }
