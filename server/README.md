# TicariERP REST API Server

Delphi DataSnap REST API - TicariERP Mobil uygulaması için backend servis.

## Mimari

```
server/
├── TicariERP_API.dpr          # Ana program (console app)
├── TicariERP_API.dproj        # Proje dosyası
└── src/
    ├── uDM.pas                # FireDAC veritabanı bağlantısı
    ├── uServerContainer.pas   # DataSnap server container
    ├── uWebModule.pas         # HTTP Web dispatcher
    ├── uSmCari.pas            # Müşteri (Cari) servisleri
    ├── uSmSiparis.pas         # Sipariş servisleri
    ├── uSmStok.pas            # Ürün/Stok servisleri
    ├── uSmCallerID.pas        # Gelen arama (CallerID) servisleri
    ├── uSmKurye.pas           # Kurye/Dağıtım servisleri
    └── uSmAuth.pas            # Kimlik doğrulama servisleri
```

## Veritabanı Bağlantısı

Ortam değişkenleri ile yapılandırılır:

| Değişken | Açıklama | Varsayılan |
|----------|----------|------------|
| `MSSQL_SERVER_HOST` | MSSQL sunucu adresi | 127.0.0.1 |
| `MSSQL_SERVER_PORT` | MSSQL port | 1433 |
| `MSSQL_DATABASE_NAME` | Veritabanı adı | TicariERP |
| `MSSQL_USERNAME` | Kullanıcı adı | SA |
| `MSSQL_PASSWORD` | Şifre | - |

## API Endpoints

DataSnap REST formatı: `http://server:8080/datasnap/rest/TSmXxx/MethodName/params`

### Auth (`TSmAuth`)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/rest/TSmAuth/Ping` | Health check |
| GET | `/rest/TSmAuth/Login/{user}/{pass}` | Giriş |
| GET | `/rest/TSmAuth/GetRoller` | Roller listesi |
| GET | `/rest/TSmAuth/GetRolYetkiler/{rolId}` | Rol yetkileri |
| GET | `/rest/TSmAuth/GetSirketBilgi` | Şirket bilgisi |

### Müşteri (`TSmCari`)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/rest/TSmCari/GetCariList/{page}/{pageSize}` | Müşteri listesi |
| GET | `/rest/TSmCari/GetCariById/{id}` | Müşteri detay |
| GET | `/rest/TSmCari/GetCariByTelefon/{tel}` | Telefon ile ara |
| GET | `/rest/TSmCari/SearchCari/{arama}/{page}/{pageSize}` | Müşteri ara |
| POST | `/rest/TSmCari/CreateCari` | Yeni müşteri |
| POST | `/rest/TSmCari/UpdateCari/{id}` | Müşteri güncelle |
| GET | `/rest/TSmCari/GetCariAdresler/{id}` | Adresler |
| GET | `/rest/TSmCari/GetCariTelefonlar/{id}` | Telefonlar |
| GET | `/rest/TSmCari/GetCariBakiye/{id}` | Bakiye |
| GET | `/rest/TSmCari/GetCariHareketler/{id}/{page}/{pageSize}` | Hareketler |

### Sipariş (`TSmSiparis`)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/rest/TSmSiparis/GetSiparisler/{durum}/{page}/{pageSize}` | Sipariş listesi |
| GET | `/rest/TSmSiparis/GetSiparisById/{id}` | Sipariş detay |
| POST | `/rest/TSmSiparis/CreateSiparis` | Yeni sipariş |
| GET | `/rest/TSmSiparis/UpdateSiparisDurum/{id}/{durum}` | Durum güncelle |
| GET | `/rest/TSmSiparis/CancelSiparis/{id}/{neden}` | İptal |
| GET | `/rest/TSmSiparis/GetGunlukOzet/{tarih}` | Günlük özet |
| GET | `/rest/TSmSiparis/GetCariSiparisleri/{cariId}/{page}/{pageSize}` | Müşteri siparişleri |
| GET | `/rest/TSmSiparis/GetSonSiparisler/{limit}` | Son siparişler |

### Stok (`TSmStok`)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/rest/TSmStok/GetStokList/{page}/{pageSize}` | Stok listesi |
| GET | `/rest/TSmStok/GetHizliSiparisUrunler` | Hızlı sipariş ürünleri |
| GET | `/rest/TSmStok/GetStokById/{id}` | Stok detay |
| GET | `/rest/TSmStok/SearchStok/{arama}` | Stok ara |
| GET | `/rest/TSmStok/GetKategoriler` | Kategoriler |
| GET | `/rest/TSmStok/GetStokByKategori/{katId}` | Kategoriye göre |

### CallerID (`TSmCallerID`)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/rest/TSmCallerID/LogCallerIdEvent/{tel}/{callerId}/{tip}` | Arama logu |
| GET | `/rest/TSmCallerID/GetCallerInfo/{tel}` | Arayan bilgisi |
| POST | `/rest/TSmCallerID/CreateAramaLog` | Arama log kaydet |
| GET | `/rest/TSmCallerID/GetAramaLoglar/{page}/{pageSize}` | Log listesi |
| GET | `/rest/TSmCallerID/GetSonAramalar/{limit}` | Son aramalar |

### Kurye (`TSmKurye`)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/rest/TSmKurye/GetDagitimBekleyenler` | Bekleyen siparişler |
| GET | `/rest/TSmKurye/AtaSiparis/{siparisId}/{kulId}` | Sipariş ata |
| GET | `/rest/TSmKurye/YolaCikis/{siparisId}/{enlem}/{boylam}` | Yola çıkış |
| GET | `/rest/TSmKurye/TeslimEt/{siparisId}/{notu}/{tahsilat}` | Teslim et |
| GET | `/rest/TSmKurye/TeslimEdilemedi/{siparisId}/{nedenId}/{neden}` | Teslim edilemedi |
| GET | `/rest/TSmKurye/KonumGuncelle/{siparisId}/{enlem}/{boylam}` | Konum güncelle |
| GET | `/rest/TSmKurye/GetDagitimOzeti/{kulId}/{tarih}` | Dağıtım özeti |
| GET | `/rest/TSmKurye/GetTeslimEdilemediNedenleri` | Neden listesi |
| POST | `/rest/TSmKurye/RegisterPushDevice/{kulId}/{token}/{deviceId}/{platform}` | Push kayıt |

## Çalıştırma

```bash
# Ortam değişkenlerini ayarlayın
set MSSQL_SERVER_HOST=2.56.152.155
set MSSQL_SERVER_PORT=1433
set MSSQL_DATABASE_NAME=TicariERP
set MSSQL_USERNAME=SA
set MSSQL_PASSWORD=****

# Sunucuyu başlatın (varsayılan port 8080)
TicariERP_API.exe

# Özel port ile
TicariERP_API.exe 9090
```

## Derleme

RAD Studio / Delphi 13 ile `TicariERP_API.dproj` dosyasını açın ve derleyin.

Gerekli bileşenler:
- FireDAC (MSSQL driver)
- DataSnap Server
- Indy (HTTP server)
