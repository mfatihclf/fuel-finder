"""Akaryakıt fiyat scraper modülleri."""

from .opet import OpetScraper
from .petrol_ofisi import PetrolOfisiScraper, BPScraper
from .shell import ShellScraper
from .total import TotalEnergiesScraper
from .aytemiz import AytemizScraper
from .tp import TPScraper

__all__ = [
    "OpetScraper",
    "PetrolOfisiScraper",
    "BPScraper",
    "ShellScraper",
    "TotalEnergiesScraper",
    "AytemizScraper",
    "TPScraper",
]
