"""Çıktı formatlama yardımcı fonksiyonları — tablo, CSV, JSON."""

from __future__ import annotations

import csv
import io
import json

from models import FuelPrice


def format_table(prices: list[FuelPrice]) -> str:
    """Fiyatları okunabilir tablo formatında döndürür (rich kullanarak)."""
    if not prices:
        return "Sonuç bulunamadı."

    try:
        from rich.table import Table
        from rich.console import Console

        table = Table(
            title="⛽ Akaryakıt Fiyatları",
            show_header=True,
            header_style="bold bright_cyan",
            border_style="bright_black",
            title_style="bold bright_yellow",
            row_styles=["", "dim"],
        )

        table.add_column("İstasyon", style="bold bright_green", min_width=14)
        table.add_column("Şehir", style="white", min_width=10)
        table.add_column("İlçe", style="bright_white", min_width=14)
        table.add_column("Yakıt Türü", style="bright_magenta", min_width=16)
        table.add_column("Fiyat (TL/L)", style="bold bright_yellow", justify="right", min_width=12)

        for p in sorted(prices, key=lambda x: (x.district, x.fuel_type, x.station)):
            table.add_row(p.station, p.city, p.district, p.fuel_type, f"{p.price:.2f}")

        console = Console()
        with console.capture() as capture:
            console.print(table)
        return capture.get()

    except ImportError:
        # rich yoksa tabulate ile fallback
        try:
            from tabulate import tabulate
            headers = ["İstasyon", "Şehir", "İlçe", "Yakıt Türü", "Fiyat (TL/L)"]
            rows = [[p.station, p.city, p.district, p.fuel_type, f"{p.price:.2f}"] for p in prices]
            return tabulate(rows, headers=headers, tablefmt="pretty")
        except ImportError:
            # Hiçbiri yoksa basit metin
            lines = ["İstasyon | Şehir | İlçe | Yakıt Türü | Fiyat (TL/L)"]
            lines.append("-" * 80)
            for p in prices:
                lines.append(f"{p.station:14s} | {p.city:10s} | {p.district:14s} | {p.fuel_type:16s} | {p.price:.2f}")
            return "\n".join(lines)


def format_csv(prices: list[FuelPrice]) -> str:
    """Fiyatları CSV formatında döndürür."""
    if not prices:
        return ""
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=["istasyon", "sehir", "ilce", "yakit_turu", "fiyat_tl", "tarih"])
    writer.writeheader()
    for p in prices:
        writer.writerow(p.to_dict())
    return output.getvalue()


def format_json(prices: list[FuelPrice]) -> str:
    """Fiyatları JSON formatında döndürür."""
    return json.dumps([p.to_dict() for p in prices], ensure_ascii=False, indent=2)


def save_to_file(content: str, filepath: str) -> None:
    """İçeriği dosyaya kaydeder."""
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  📁 Kaydedildi: {filepath}")
