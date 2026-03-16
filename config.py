"""Sabitler, şehir kodları ve URL yapılandırmaları."""

# ---------------------------------------------------------------------------
# Opet API
# ---------------------------------------------------------------------------
OPET_PROVINCES_URL = "https://api.opet.com.tr/api/fuelprices/provinces"
OPET_PRICES_URL = "https://api.opet.com.tr/api/fuelprices/prices"
OPET_HEADERS = {
    "channel": "Web",
    "Accept": "application/json",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
}

# ---------------------------------------------------------------------------
# Petrol Ofisi / BP  (aynı altyapı, isBp parametresi değişir)
# ---------------------------------------------------------------------------
PO_FUEL_SEARCH_URL = "https://www.petrolofisi.com.tr/Fuel/Search"
PO_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "X-Requested-With": "XMLHttpRequest",
    "Accept": "*/*",
    "Referer": "https://www.petrolofisi.com.tr/akaryakit-fiyatlari",
}

# ---------------------------------------------------------------------------
# Shell  (turkiyeshell.com ASP.NET callback)
# ---------------------------------------------------------------------------
SHELL_BASE_URL = "https://www.turkiyeshell.com/pompatest/"
SHELL_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "X-Requested-With": "XMLHttpRequest",
    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
    "Referer": "https://www.turkiyeshell.com/pompatest/",
}

# ---------------------------------------------------------------------------
# TotalEnergies  (guzelenerji.com.tr JSON API — token gerektirmez)
# ---------------------------------------------------------------------------
TOTAL_CITIES_URL = "https://apimobile.guzelenerji.com.tr/exapi/fuel_price_cities"
TOTAL_PRICES_URL = "https://apimobile.guzelenerji.com.tr/exapi/fuel_prices/{city_id}"
TOTAL_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "application/json",
}

# ---------------------------------------------------------------------------
# Aytemiz  (ASP.NET WebForms POST → HTML tablo)
# ---------------------------------------------------------------------------
AYTEMIZ_URL = "https://www.aytemiz.com.tr/akaryakit-fiyatlari/arsiv-fiyat-listesi"
AYTEMIZ_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/x-www-form-urlencoded",
    "Referer": "https://www.aytemiz.com.tr/akaryakit-fiyatlari/arsiv-fiyat-listesi",
}

# ---------------------------------------------------------------------------
# TP (Türkiye Petrolleri)  (SSL expired → verify=False, GET → HTML tablo)
# ---------------------------------------------------------------------------
TP_BASE_URL = "https://www.tppd.com.tr/{city_slug}-akaryakit-fiyatlari"
TP_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "text/html",
}

# ---------------------------------------------------------------------------
# HTTP ayarları
# ---------------------------------------------------------------------------
REQUEST_TIMEOUT = 15  # saniye

# ---------------------------------------------------------------------------
# Türkiye illeri — plaka kodu → il adı eşleşmesi
# Opet kendi il kodu sistemini kullanır (API'den çekilir).
# PO/BP için plaka kodu kullanılır.
# Shell için 3 haneli kod kullanılır (plaka kodunun başına sıfır eklenir).
# ---------------------------------------------------------------------------
CITY_PLATE_CODES: dict[str, str] = {
    "adana": "01",
    "adiyaman": "02",
    "afyonkarahisar": "03",
    "agri": "04",
    "amasya": "05",
    "ankara": "06",
    "antalya": "07",
    "artvin": "08",
    "aydin": "09",
    "balikesir": "10",
    "bilecik": "11",
    "bingol": "12",
    "bitlis": "13",
    "bolu": "14",
    "burdur": "15",
    "bursa": "16",
    "canakkale": "17",
    "cankiri": "18",
    "corum": "19",
    "denizli": "20",
    "diyarbakir": "21",
    "edirne": "22",
    "elazig": "23",
    "erzincan": "24",
    "erzurum": "25",
    "eskisehir": "26",
    "gaziantep": "27",
    "giresun": "28",
    "gumushane": "29",
    "hakkari": "30",
    "hatay": "31",
    "isparta": "32",
    "mersin": "33",
    "istanbul": "34",
    "izmir": "35",
    "kars": "36",
    "kastamonu": "37",
    "kayseri": "38",
    "kirklareli": "39",
    "kirsehir": "40",
    "kocaeli": "41",
    "konya": "42",
    "kutahya": "43",
    "malatya": "44",
    "manisa": "45",
    "kahramanmaras": "46",
    "mardin": "47",
    "mugla": "48",
    "mus": "49",
    "nevsehir": "50",
    "nigde": "51",
    "ordu": "52",
    "rize": "53",
    "sakarya": "54",
    "samsun": "55",
    "siirt": "56",
    "sinop": "57",
    "sivas": "58",
    "tekirdag": "59",
    "tokat": "60",
    "trabzon": "61",
    "tunceli": "62",
    "sanliurfa": "63",
    "usak": "64",
    "van": "65",
    "yozgat": "66",
    "zonguldak": "67",
    "aksaray": "68",
    "bayburt": "69",
    "karaman": "70",
    "kirikkale": "71",
    "batman": "72",
    "sirnak": "73",
    "bartin": "74",
    "ardahan": "75",
    "igdir": "76",
    "yalova": "77",
    "karabuk": "78",
    "kilis": "79",
    "osmaniye": "80",
    "duzce": "81",
}

# ---------------------------------------------------------------------------
# TotalEnergies şehir ID eşleşmesi  (city_id — plaka kodundan farklı)
# API'den dinamik olarak çekilir; bu harita yedek olarak kullanılır.
# ---------------------------------------------------------------------------
TOTAL_CITY_IDS: dict[str, int] = {
    "adana": 1, "adiyaman": 2, "afyonkarahisar": 3, "agri": 4, "aksaray": 5,
    "amasya": 6, "ankara": 7, "antalya": 8, "ardahan": 9, "artvin": 10,
    "aydin": 11, "balikesir": 12, "bartin": 13, "batman": 14, "bayburt": 15,
    "bilecik": 16, "bingol": 17, "bitlis": 18, "bolu": 19, "burdur": 20,
    "bursa": 21, "canakkale": 22, "cankiri": 23, "corum": 24, "denizli": 25,
    "diyarbakir": 26, "duzce": 27, "edirne": 28, "elazig": 29, "erzincan": 30,
    "erzurum": 31, "eskisehir": 32, "gaziantep": 33, "giresun": 34, "gumushane": 35,
    "hakkari": 36, "hatay": 37, "igdir": 38, "isparta": 39, "istanbul": 32,
    "izmir": 41, "kahramanmaras": 42, "karabuk": 43, "karaman": 44, "kars": 45,
    "kastamonu": 46, "kayseri": 47, "kilis": 48, "kirikkale": 49, "kirklareli": 50,
    "kirsehir": 51, "kocaeli": 52, "konya": 53, "kutahya": 54, "malatya": 55,
    "manisa": 56, "mardin": 57, "mersin": 58, "mugla": 59, "mus": 60,
    "nevsehir": 61, "nigde": 62, "ordu": 63, "osmaniye": 64, "rize": 65,
    "sakarya": 66, "samsun": 67, "sanliurfa": 68, "siirt": 69, "sinop": 70,
    "sirnak": 71, "sivas": 72, "tekirdag": 73, "tokat": 74, "trabzon": 75,
    "tunceli": 76, "usak": 77, "van": 78, "yalova": 79, "yozgat": 80, "zonguldak": 81,
}

# ---------------------------------------------------------------------------
# Aytemiz şehir ID eşleşmesi  (1-81 sıralı, plaka koduyla aynı)
# ---------------------------------------------------------------------------
AYTEMIZ_CITY_IDS: dict[str, str] = {
    "adana": "1", "adiyaman": "2", "afyonkarahisar": "3", "agri": "4",
    "amasya": "5", "ankara": "6", "antalya": "7", "artvin": "8",
    "aydin": "9", "balikesir": "10", "bilecik": "11", "bingol": "12",
    "bitlis": "13", "bolu": "14", "burdur": "15", "bursa": "16",
    "canakkale": "17", "cankiri": "18", "corum": "19", "denizli": "20",
    "diyarbakir": "21", "edirne": "22", "elazig": "23", "erzincan": "24",
    "erzurum": "25", "eskisehir": "26", "gaziantep": "27", "giresun": "28",
    "gumushane": "29", "hakkari": "30", "hatay": "31", "isparta": "32",
    "mersin": "33", "istanbul": "34", "izmir": "35", "kars": "36",
    "kastamonu": "37", "kayseri": "38", "kirklareli": "39", "kirsehir": "40",
    "kocaeli": "41", "konya": "42", "kutahya": "43", "malatya": "44",
    "manisa": "45", "kahramanmaras": "46", "mardin": "47", "mugla": "48",
    "mus": "49", "nevsehir": "50", "nigde": "51", "ordu": "52",
    "rize": "53", "sakarya": "54", "samsun": "55", "siirt": "56",
    "sinop": "57", "sivas": "58", "tekirdag": "59", "tokat": "60",
    "trabzon": "61", "tunceli": "62", "sanliurfa": "63", "usak": "64",
    "van": "65", "yozgat": "66", "zonguldak": "67", "aksaray": "68",
    "bayburt": "69", "karaman": "70", "kirikkale": "71", "batman": "72",
    "sirnak": "73", "bartin": "74", "ardahan": "75", "igdir": "76",
    "yalova": "77", "karabuk": "78", "kilis": "79", "osmaniye": "80",
    "duzce": "81",
}

# ---------------------------------------------------------------------------
# TP şehir URL slug'ları  (URL'de kullanılan adlar)
# ---------------------------------------------------------------------------
TP_CITY_SLUGS: dict[str, str] = {
    "adana": "adana", "adiyaman": "adiyaman", "afyonkarahisar": "afyonkarahisar",
    "agri": "agri", "aksaray": "aksaray", "amasya": "amasya", "ankara": "ankara",
    "antalya": "antalya", "ardahan": "ardahan", "artvin": "artvin",
    "aydin": "aydin", "balikesir": "balikesir", "bartin": "bartin",
    "batman": "batman", "bayburt": "bayburt", "bilecik": "bilecik",
    "bingol": "bingol", "bitlis": "bitlis", "bolu": "bolu", "burdur": "burdur",
    "bursa": "bursa", "canakkale": "canakkale", "cankiri": "cankiri",
    "corum": "corum", "denizli": "denizli", "diyarbakir": "diyarbakir",
    "duzce": "duzce", "edirne": "edirne", "elazig": "elazig",
    "erzincan": "erzincan", "erzurum": "erzurum", "eskisehir": "eskisehir",
    "gaziantep": "gaziantep", "giresun": "giresun", "gumushane": "gumushane",
    "hakkari": "hakkari", "hatay": "hatay", "igdir": "igdir",
    "isparta": "isparta", "istanbul": "istanbul", "izmir": "izmir",
    "kahramanmaras": "kahramanmaras", "karabuk": "karabuk", "karaman": "karaman",
    "kars": "kars", "kastamonu": "kastamonu", "kayseri": "kayseri",
    "kilis": "kilis", "kirikkale": "kirikkale", "kirklareli": "kirklareli",
    "kirsehir": "kirsehir", "kocaeli": "kocaeli", "konya": "konya",
    "kutahya": "kutahya", "malatya": "malatya", "manisa": "manisa",
    "mardin": "mardin", "mersin": "mersin", "mugla": "mugla", "mus": "mus",
    "nevsehir": "nevsehir", "nigde": "nigde", "ordu": "ordu",
    "osmaniye": "osmaniye", "rize": "rize", "sakarya": "sakarya",
    "samsun": "samsun", "sanliurfa": "sanliurfa", "siirt": "siirt",
    "sinop": "sinop", "sirnak": "sirnak", "sivas": "sivas",
    "tekirdag": "tekirdag", "tokat": "tokat", "trabzon": "trabzon",
    "tunceli": "tunceli", "usak": "usak", "van": "van",
    "yalova": "yalova", "yozgat": "yozgat", "zonguldak": "zonguldak",
}

# Okunabilir Türkçe il adları
CITY_DISPLAY_NAMES: dict[str, str] = {
    "adana": "Adana",
    "adiyaman": "Adıyaman",
    "afyonkarahisar": "Afyonkarahisar",
    "agri": "Ağrı",
    "amasya": "Amasya",
    "ankara": "Ankara",
    "antalya": "Antalya",
    "artvin": "Artvin",
    "aydin": "Aydın",
    "balikesir": "Balıkesir",
    "bilecik": "Bilecik",
    "bingol": "Bingöl",
    "bitlis": "Bitlis",
    "bolu": "Bolu",
    "burdur": "Burdur",
    "bursa": "Bursa",
    "canakkale": "Çanakkale",
    "cankiri": "Çankırı",
    "corum": "Çorum",
    "denizli": "Denizli",
    "diyarbakir": "Diyarbakır",
    "edirne": "Edirne",
    "elazig": "Elazığ",
    "erzincan": "Erzincan",
    "erzurum": "Erzurum",
    "eskisehir": "Eskişehir",
    "gaziantep": "Gaziantep",
    "giresun": "Giresun",
    "gumushane": "Gümüşhane",
    "hakkari": "Hakkari",
    "hatay": "Hatay",
    "isparta": "Isparta",
    "mersin": "Mersin",
    "istanbul": "İstanbul",
    "izmir": "İzmir",
    "kars": "Kars",
    "kastamonu": "Kastamonu",
    "kayseri": "Kayseri",
    "kirklareli": "Kırklareli",
    "kirsehir": "Kırşehir",
    "kocaeli": "Kocaeli",
    "konya": "Konya",
    "kutahya": "Kütahya",
    "malatya": "Malatya",
    "manisa": "Manisa",
    "kahramanmaras": "Kahramanmaraş",
    "mardin": "Mardin",
    "mugla": "Muğla",
    "mus": "Muş",
    "nevsehir": "Nevşehir",
    "nigde": "Niğde",
    "ordu": "Ordu",
    "rize": "Rize",
    "sakarya": "Sakarya",
    "samsun": "Samsun",
    "siirt": "Siirt",
    "sinop": "Sinop",
    "sivas": "Sivas",
    "tekirdag": "Tekirdağ",
    "tokat": "Tokat",
    "trabzon": "Trabzon",
    "tunceli": "Tunceli",
    "sanliurfa": "Şanlıurfa",
    "usak": "Uşak",
    "van": "Van",
    "yozgat": "Yozgat",
    "zonguldak": "Zonguldak",
    "aksaray": "Aksaray",
    "bayburt": "Bayburt",
    "karaman": "Karaman",
    "kirikkale": "Kırıkkale",
    "batman": "Batman",
    "sirnak": "Şırnak",
    "bartin": "Bartın",
    "ardahan": "Ardahan",
    "igdir": "Iğdır",
    "yalova": "Yalova",
    "karabuk": "Karabük",
    "kilis": "Kilis",
    "osmaniye": "Osmaniye",
    "duzce": "Düzce",
}


def normalize_city(city: str) -> str:
    """Kullanıcı girdisini normalize eder (küçük harf, Türkçe karakter düzeltme).

    Unicode NFKD decomposition ile combining character'ları da temizler.
    Opet API'sinin döndürdüğü 'İ' → 'i̇' (i + combining dot) gibi durumları ele alır.
    """
    import unicodedata

    # Önce NFKD decomposition uygula (combining char'ları ayır)
    city = unicodedata.normalize("NFKD", city)
    # Combining character'ları kaldır (accent, dot above, vs.)
    city = "".join(c for c in city if not unicodedata.combining(c))

    replacements = {
        "ı": "i", "İ": "i", "ğ": "g", "Ğ": "g",
        "ü": "u", "Ü": "u", "ş": "s", "Ş": "s",
        "ö": "o", "Ö": "o", "ç": "c", "Ç": "c",
    }
    city = city.strip().lower()
    for tr_char, en_char in replacements.items():
        city = city.replace(tr_char, en_char)
    # Boşlukları kaldır
    city = city.replace(" ", "")
    return city


def get_plate_code(city: str) -> str | None:
    """Şehir adından plaka kodunu döndürür."""
    return CITY_PLATE_CODES.get(normalize_city(city))


def get_shell_code(city: str) -> str | None:
    """Şehir adından Shell 3 haneli kodunu döndürür (ör: '006' → Ankara)."""
    plate = get_plate_code(city)
    if plate:
        return plate.zfill(3)
    return None


def get_display_name(city: str) -> str:
    """Şehir adının okunabilir Türkçe halini döndürür."""
    return CITY_DISPLAY_NAMES.get(normalize_city(city), city.title())
