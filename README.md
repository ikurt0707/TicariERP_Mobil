# TicariERP Mobil

Tüp & Su Satış Mobil Uygulaması - Delphi 13 FMX

## Proje Yapısı

```
TicariERP_Mobil/
├── TicariERP_Mobil.dpr          # Ana proje dosyası
├── TicariERP_Mobil.dproj        # Proje konfigürasyonu
├── src/
│   ├── Models/                  # Veri modelleri
│   │   ├── uCustomer.pas       # Müşteri modeli
│   │   ├── uOrder.pas          # Sipariş modeli
│   │   ├── uProduct.pas        # Ürün modeli
│   │   ├── uCourier.pas        # Kurye modeli
│   │   └── uDailySummary.pas   # Günlük özet modeli
│   ├── Services/                # Servis katmanı
│   │   ├── uApiService.pas     # HTTP API istemcisi
│   │   ├── uAuthService.pas    # Kimlik doğrulama servisi
│   │   ├── uOrderService.pas   # Sipariş servisi
│   │   └── uCustomerService.pas# Müşteri servisi
│   ├── Forms/                   # FMX Formları
│   │   ├── uFrmMain.pas        # Ana sayfa / Dashboard
│   │   ├── uFrmGelenArama.pas  # Gelen arama ekranı
│   │   ├── uFrmYeniSiparis.pas # Yeni sipariş ekranı
│   │   ├── uFrmKuryeTakip.pas  # Kurye takip ekranı
│   │   └── uFrmSiparisler.pas  # Siparişler listesi
│   └── Utils/                   # Yardımcı araçlar
│       ├── uConstants.pas       # Sabitler
│       └── uHelpers.pas         # Yardımcı fonksiyonlar
└── tests/                       # DUnitX Unit Testleri
    ├── TicariERP_Tests.dpr      # Test projesi
    ├── TestCustomer.pas         # Müşteri model testleri
    ├── TestProduct.pas          # Ürün model testleri
    ├── TestOrder.pas            # Sipariş model testleri
    ├── TestCourier.pas          # Kurye model testleri
    ├── TestDailySummary.pas     # Günlük özet testleri
    ├── TestHelpers.pas          # Helper fonksiyon testleri
    └── TestOrderService.pas     # Sipariş servis testleri
```

## Ekranlar

1. **Ana Sayfa (Dashboard)** - Günlük özet, son siparişler, hızlı işlemler
2. **Gelen Arama** - Arayan müşteri bilgisi, hızlı sipariş açma
3. **Yeni Sipariş** - Ürün seçimi, miktar belirleme, sipariş kaydetme
4. **Kurye Takip** - Harita üzerinde kurye konumları, teslimat durumu
5. **Siparişler** - Sipariş listesi, filtreleme, arama

## Gereksinimler

- RAD Studio / Delphi 13 (Athens)
- FireMonkey (FMX) framework
- DUnitX (test framework)
- Hedef platform: Android 64-bit, iOS

## API Bağlantısı

Uygulama VDS sunucudaki REST API'ye bağlanır. API base URL `src/Utils/uConstants.pas` dosyasında tanımlıdır.

## Testleri Çalıştırma

1. `tests/TicariERP_Tests.dpr` projesini RAD Studio'da açın
2. Build & Run yapın
3. DUnitX konsol runner test sonuçlarını gösterecektir

## Mimari

- **Model-Service-Form** katmanlı mimari
- **Models**: İş mantığı ve veri yapıları (JSON serialization dahil)
- **Services**: API iletişimi ve veri yönetimi
- **Forms**: Kullanıcı arayüzü (FMX)
- **Utils**: Yardımcı fonksiyonlar ve sabitler
