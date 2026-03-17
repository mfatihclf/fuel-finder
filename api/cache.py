"""Basit TTL (zamanasimi) cache."""

import time
from dataclasses import dataclass
from typing import Any


@dataclass
class _Entry:
    data: Any
    created_at: float
    ttl: int

    def is_expired(self) -> bool:
        return time.time() - self.created_at > self.ttl

    def age(self) -> int:
        return int(time.time() - self.created_at)


class TTLCache:
    """Thread-safe olmayan, bellekte tutulan TTL cache."""

    def __init__(self, default_ttl: int = 600):
        self._store: dict[str, _Entry] = {}
        self.default_ttl = default_ttl

    def get(self, key: str) -> tuple[Any, int] | None:
        """Gecerli bir cache entry varsa (data, yas_saniye) dondurur, yoksa None."""
        entry = self._store.get(key)
        if entry is None:
            return None
        if entry.is_expired():
            del self._store[key]
            return None
        return entry.data, entry.age()

    def set(self, key: str, value: Any, ttl: int | None = None) -> None:
        self._store[key] = _Entry(
            data=value,
            created_at=time.time(),
            ttl=ttl if ttl is not None else self.default_ttl,
        )

    def clear(self) -> None:
        self._store.clear()
