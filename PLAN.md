# Fuel Finder - Flutter Mobil Uygulama Gelistirme Plani

## Mevcut Durum
Python 3.11 ile yazilmis CLI araci. 7 akaryakit markasindan (Opet, Petrol Ofisi, BP, Shell, TotalEnergies, Aytemiz, TP) Turkiye'nin 81 ilindeki guncel akaryakit fiyatlarini cekiyor. Veritabani, API sunucusu veya cache yok.

## Hedef
Kullanicinin mevcut konumuna gore, sectigi yaricap icerisindeki en uygun akaryakit fiyatini gosteren Flutter mobil uygulama.

---

## Adim 1: Flutter Proje Kurulumu ✓ TAMAMLANDI
**Branch:** `feature/flutter-init`

- [x] Flutter projesi olusturma (`flutter create`)
- [x] Temel klasor yapisini duzenleme (lib/screens, lib/widgets, lib/models, lib/services vb.)
- [x] Gereksiz boilerplate temizligi
- [x] `.gitignore` guncelleme

---

## Adim 2: Python Backend API Olusturma (FastAPI) ✓ TAMAMLANDI
**Branch:** `feature/backend-api`

- [x] FastAPI kurulumu ve temel yapilandirma
- [x] Mevcut scraperlari REST API arkasina alma
- [x] Endpoint'ler: `GET /api/prices?city=istanbul&fuel_type=lpg`
- [x] Il, ilce, yakit turu bazinda fiyat sorgulama
- [x] Basit cache mekanizmasi (ayni sehir icin kisa sureli cache)
- [x] `requirements.txt` guncelleme
- [x] CORS ayarlari (Flutter uygulamasindan erisim icin)

---

## Adim 3: Flutter Veri Modelleri ve Servis Katmani ✓ TAMAMLANDI
**Branch:** `feature/data-models`

- [x] Dart data modelleri (`FuelPrice`, `City`, `PricesResult` vb.)
- [x] API servis sinifi (HTTP client - `http` paketi)
- [x] Backend ile haberlesme altyapisi
- [x] Hata yonetimi (network error, timeout vb.)

---

## Adim 4: Konum Servisi Entegrasyonu ✓ TAMAMLANDI
**Branch:** `feature/location-service`

- [x] `geolocator` + `geocoding` paketi ile kullanicinin anlik konumunu alma
- [x] Konum izni yonetimi (Android & iOS)
- [x] Mesafe hesaplama fonksiyonlari (Geolocator.distanceBetween + Haversine)
- [x] Konum alinamadiginda fallback davranisi (LocationStatus enum)

---

## Adim 5: Ana Ekran UI ✓ TAMAMLANDI
**Branch:** `feature/home-screen`

- [x] Yakit turu secimi (Motorin, Benzin 95, LPG vb. — ChoiceChip)
- [x] Yaricap secimi (5 km, 10 km, 25 km, 50 km — ChoiceChip)
- [x] Arama/filtre butonu (FilledButton)
- [x] Temel tema ve tasarim (Material 3, kirmizi tema)
- [x] Konum karti (GPS varsa otomatik, yoksa manuel sehir girisi)
- [x] ResultsScreen placeholder ile navigasyon altyapisi

---

## Adim 6: Sonuc Listesi Ekrani ✓ TAMAMLANDI
**Branch:** `feature/results-screen`

- [x] Fiyat siralamasiyla istasyon listesi (ListView, loading/error/empty state)
- [x] Her istasyonda: marka, ilce, fiyat, tarih bilgisi
- [x] Siralama secenekleri (En Ucuz, İlçeye Göre — SegmentedButton)
- [x] Bos sonuc durumu icin bilgilendirme (_EmptyView)
- [x] Hata durumu icin retry butonu (_ErrorView)
- [x] En ucuz 1-2-3 icin altin/gumus/bronz rozet

---

## Adim 7: Harita Entegrasyonu ✓ TAMAMLANDI
**Branch:** `feature/map-integration`

- [x] `flutter_map` (OpenStreetMap) ile harita gorunumu — API key gerektirmez
- [x] İlce bazinda pin gosterimi (en ucuz fiyat balonu + konum ikonu)
- [x] Navigasyon baslatma: Google Maps HTTPS deep link (url_launcher)
- [x] Liste ↔ harita toggling (IndexedStack, AppBar IconButton)
- [x] Pin'e tiklaninca ilce detay bottom sheet (tum istasyonlar + Yol Tarifi)
- [x] Geocoding sirasinda yükleniyor göstergesi
- [x] Android: INTERNET izni + url_launcher queries blogu eklendi

---

## Adim 8: Istasyon Detay Ekrani ✓ TAMAMLANDI
**Branch:** `feature/station-detail`

- [x] Tum yakit turlerinin fiyatlari (API'den tum fiyatlar cekilir, istasyona filtre)
- [x] Adres: ilce + sehir bilgisi, guncelleme tarihi
- [x] Navigasyona yonlendirme butonu (Google Maps deep link, url_launcher)
- [x] Marka logosu: marka renginde dolu daire + kisaltma (OP/BP/SH/PO/TE/AY/TP)
- [x] Arama yapilan yakit turu fiyat satirinda vurgulanir
- [x] ResultsScreen karti tiklayinca StationDetailScreen'e navigate

---

## Adim 9: Favoriler ve Ayarlar
**Branch:** `feature/favorites-settings`

- [ ] Favori istasyonlari kaydetme (local storage - `shared_preferences` veya `hive`)
- [ ] Varsayilan yakit turu ve yaricap ayarlari
- [ ] Tema tercihi (acik/koyu)

---

## Adim 10: Son Duzenlemeler ve Yayina Hazirlik
**Branch:** `feature/polish-and-release`

- [ ] Hata yonetimi ve edge case'ler
- [ ] Loading/error state'leri
- [ ] Uygulama ikonu ve splash screen
- [ ] Android ve iOS build ayarlari

---

## Notlar
- Her adim ayri bir branch'te gelistirilecek
- Her adim tamamlandiginda GitHub'a pushlanacak
- Her adim bir oncekinin uzerine insa edilecek
