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

## Adim 6: Sonuc Listesi Ekrani
**Branch:** `feature/results-screen`

- [ ] Yakinlik + fiyat siralamasiyla istasyon listesi
- [ ] Her istasyonda: marka, ilce, fiyat, mesafe bilgisi
- [ ] Siralama secenekleri (en ucuz, en yakin)
- [ ] Bos sonuc durumu icin bilgilendirme

---

## Adim 7: Harita Entegrasyonu
**Branch:** `feature/map-integration`

- [ ] `google_maps_flutter` veya `flutter_map` ile harita gorunumu
- [ ] Istasyonlarin harita uzerinde pin olarak gosterimi
- [ ] Secilen istasyona navigasyon baslatma (Google Maps / Apple Maps deep link)
- [ ] Liste ve harita gorunumu arasi gecis

---

## Adim 8: Istasyon Detay Ekrani
**Branch:** `feature/station-detail`

- [ ] Tum yakit turlerinin fiyatlari
- [ ] Adres, mesafe bilgisi
- [ ] Navigasyona yonlendirme butonu
- [ ] Marka logosu gosterimi

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
