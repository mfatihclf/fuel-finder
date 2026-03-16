"""
Fuel Finder — Türkiye Akaryakıt Fiyat Karşılaştırma Aracı

Kullanım:
    python main.py                              # İstanbul, tüm istasyonlar, tüm ilçeler
    python main.py -c ankara                    # Ankara, tüm ilçeler
    python main.py -c ankara -d cankaya         # Ankara Çankaya ilçesi
    python main.py -c istanbul -d kadikoy       # İstanbul Kadıköy ilçesi
    python main.py -c izmir -s opet shell total # Seçili istasyonlar
    python main.py -c bursa -f csv              # Bursa, CSV formatı
    python main.py -c istanbul -f json          # İstanbul, JSON formatı
    python main.py -c ankara -o fiyatlar.csv    # Dosyaya kaydet
    python main.py --iller                      # Desteklenen illeri listele
"""

from __future__ import annotations

import argparse
import os
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# Windows konsol encoding düzeltmesi
if sys.platform == "win32":
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from config import CITY_DISPLAY_NAMES, normalize_city, get_display_name
from models import FuelPrice
from scrapers import (
    OpetScraper, PetrolOfisiScraper, BPScraper, ShellScraper,
    TotalEnergiesScraper, AytemizScraper, TPScraper,
)
from utils import format_table, format_csv, format_json, save_to_file


# Mevcut scraper'lar
SCRAPERS = {
    "opet": OpetScraper,
    "po": PetrolOfisiScraper,
    "petrolofisi": PetrolOfisiScraper,
    "bp": BPScraper,
    "shell": ShellScraper,
    "total": TotalEnergiesScraper,
    "totalenergies": TotalEnergiesScraper,
    "aytemiz": AytemizScraper,
    "tp": TPScraper,
}

SCRAPER_DISPLAY_NAMES = {
    "opet": "Opet",
    "po": "Petrol Ofisi",
    "petrolofisi": "Petrol Ofisi",
    "bp": "BP",
    "shell": "Shell",
    "total": "TotalEnergies",
    "totalenergies": "TotalEnergies",
    "aytemiz": "Aytemiz",
    "tp": "TP",
}


def _normalize_district(district: str) -> str:
    """İlçe adını karşılaştırma için normalize eder."""
    import unicodedata
    d = unicodedata.normalize("NFKD", district)
    d = "".join(c for c in d if not unicodedata.combining(c))
    replacements = {
        "ı": "i", "İ": "i", "ğ": "g", "Ğ": "g",
        "ü": "u", "Ü": "u", "ş": "s", "Ş": "s",
        "ö": "o", "Ö": "o", "ç": "c", "Ç": "c",
    }
    d = d.strip().lower()
    for tr, en in replacements.items():
        d = d.replace(tr, en)
    d = d.replace(" ", "").replace("_", "")
    return d


def fetch_prices(city: str, station_names: list[str] | None = None) -> list[FuelPrice]:
    """Belirtilen şehir için tüm (veya seçilen) istasyonlardan fiyat çeker."""

    if station_names:
        selected = {}
        for name in station_names:
            key = name.strip().lower()
            if key in SCRAPERS:
                selected[key] = SCRAPERS[key]
            else:
                print(f"  ⚠️  Bilinmeyen istasyon: '{name}'. Geçerli: {', '.join(SCRAPERS.keys())}")
        if not selected:
            print("  ❌ Hiçbir geçerli istasyon seçilmedi.")
            return []
    else:
        # Varsayılan: tüm benzersiz scraper sınıfları
        selected = {
            "opet": OpetScraper,
            "po": PetrolOfisiScraper,
            "bp": BPScraper,
            "shell": ShellScraper,
            "total": TotalEnergiesScraper,
            "aytemiz": AytemizScraper,
            "tp": TPScraper,
        }

    all_prices: list[FuelPrice] = []

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {}
        for key, scraper_cls in selected.items():
            display = SCRAPER_DISPLAY_NAMES.get(key, key)
            scraper = scraper_cls()
            futures[executor.submit(scraper.get_prices, city)] = display

        for future in as_completed(futures):
            display_name = futures[future]
            try:
                prices = future.result()
                if prices:
                    all_prices.extend(prices)
                    # Benzersiz ilçe sayısı
                    districts = set(p.district for p in prices)
                    print(f"  ✅ {display_name}: {len(prices)} fiyat, {len(districts)} ilçe")
                else:
                    print(f"  ⚠️  {display_name}: Fiyat bulunamadı")
            except Exception as e:
                print(f"  ❌ {display_name}: Hata — {e}")

    return all_prices


def filter_by_district(prices: list[FuelPrice], district: str) -> list[FuelPrice]:
    """Fiyatları ilçe adına göre filtreler (fuzzy match)."""
    target = _normalize_district(district)
    return [
        p for p in prices
        if target in _normalize_district(p.district)
        or _normalize_district(p.district) in target
    ]


def list_cities():
    """Desteklenen illeri listeler."""
    print("\n📋 Desteklenen İller:\n")
    for key in sorted(CITY_DISPLAY_NAMES.keys()):
        display = CITY_DISPLAY_NAMES[key]
        print(f"  • {key:20s} → {display}")
    print(f"\n  Toplam: {len(CITY_DISPLAY_NAMES)} il")


def main():
    parser = argparse.ArgumentParser(
        description="⛽ Fuel Finder — Türkiye Akaryakıt Fiyat Karşılaştırma",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Örnekler:
  python main.py                              # İstanbul, tüm istasyonlar
  python main.py -c ankara -d cankaya         # Ankara Çankaya
  python main.py -c istanbul -d kadikoy       # İstanbul Kadıköy
  python main.py -c izmir -s opet shell total # Seçili istasyonlar
  python main.py -c bursa -f csv              # CSV formatında çıktı
  python main.py --iller                      # Desteklenen illeri listele
        """,
    )

    parser.add_argument(
        "-c", "--city",
        default="istanbul",
        help="Şehir adı (varsayılan: istanbul)",
    )
    parser.add_argument(
        "-d", "--district",
        help="İlçe adı ile filtrele (ör: kadikoy, cankaya, besiktas)",
    )
    parser.add_argument(
        "-s", "--stations",
        nargs="+",
        help="İstasyon adları (opet, po, bp, shell, total, aytemiz, tp). Belirtilmezse hepsi.",
    )
    parser.add_argument(
        "-f", "--format",
        choices=["table", "csv", "json"],
        default="table",
        help="Çıktı formatı (varsayılan: table)",
    )
    parser.add_argument(
        "-o", "--output",
        help="Sonuçları dosyaya kaydet (ör: fiyatlar.csv)",
    )
    parser.add_argument(
        "--iller",
        action="store_true",
        help="Desteklenen illeri listele",
    )

    args = parser.parse_args()

    if args.iller:
        list_cities()
        return

    city = args.city
    city_key = normalize_city(city)
    display = get_display_name(city)

    header = f"\n⛽ Fuel Finder — {display} Akaryakıt Fiyatları"
    if args.district:
        header += f" ({args.district.title()})"
    print(header)
    print("=" * 50)
    print(f"  📍 Şehir: {display}")
    if args.district:
        print(f"  📍 İlçe filtresi: {args.district.title()}")
    print(f"  🔍 Fiyatlar alınıyor...\n")

    prices = fetch_prices(city, args.stations)

    # İlçe filtresi uygula
    if args.district and prices:
        prices = filter_by_district(prices, args.district)
        if not prices:
            print(f"\n  ⚠️  '{args.district}' ilçesi için sonuç bulunamadı.")
            print("  💡 İpucu: İlçe adını Türkçe karaktersiz deneyin (ör: kadikoy, cankaya)")
            sys.exit(1)

    if not prices:
        print("\n  ❌ Hiçbir fiyat bulunamadı.")
        sys.exit(1)

    print()

    # Formatlama
    if args.format == "csv":
        output = format_csv(prices)
    elif args.format == "json":
        output = format_json(prices)
    else:
        output = format_table(prices)

    print(output)

    # Dosyaya kaydet
    if args.output:
        save_to_file(output, args.output)


if __name__ == "__main__":
    main()
