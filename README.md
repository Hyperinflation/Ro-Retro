# Ro-Retro Game Hub (Flutter Edition)

Ro-Retro, **Ro-ASD OS** ve tüm **Fedora** sürümleri için tasarlanmış, Epic Games Store arayüzünden esinlenen premium bir retro oyun merkezi masaüstü uygulamasıdır. Bu sürüm tamamen **Flutter** framework'ü kullanılarak yazılmıştır.

Uygulama, mimariden bağımsız (`noarch`) bir RPM paketi olarak derlenip çalışacak şekilde tasarlanmıştır.

---

## Proje Mimarisi

1. **Ön Yüz (Flutter Web):**
   Arayüz ve tüm sayfa geçişleri, arama, filtreleme, ROM ekleme işlemleri Flutter (Dart) ile yazılmıştır. Flutter Web olarak derlenerek optimize edilmiş HTML/JS/CSS statik dosyaları haline getirilir.
2. **Çevrimdışı Depolama (IndexedDB & JS Interop):**
   Kullanıcıların içe aktardığı ROM dosyaları ve kapak resimleri tarayıcının yerel **IndexedDB** veritabanında ikili (Binary Blob) biçiminde saklanır. Flutter ile Javascript interop (`dart:js` ve `dart:js_util`) kullanılarak bu verilere erişim sağlanır.
3. **Emülasyon (EmulatorJS):**
   Oyunlar, web tabanlı WebAssembly emülasyon motoru olan **EmulatorJS** ile izole edilmiş bir iframe içinde çalıştırılır. Nintendo (NES), Super Nintendo (SNES), Game Boy (GB), Game Boy Advance (GBA) ve Sega Genesis gibi popüler retro konsolları destekler.
4. **Taşınabilir Sunucu Başlatıcı (Python):**
   Kayıtlı oyunların ve yerel depolama özelliklerinin tarayıcıda tam yetkiyle çalışabilmesi için yerel bir web sunucusu gereklidir. `launcher.py` başlatıcısı, Python'ın yerleşik HTTP sunucusunu rastgele boştaki bir yerel portta başlatır, tarayıcıda arayüzü açar ve tarayıcı sekmesi kapatıldığında otomatik olarak arka planda kendi sürecini sonlandırır.

---

## Gereksinimler

- **Geliştirme / Derleme İçin:**
  - [Flutter SDK](https://flutter.dev/docs/get-started)
- **Çalıştırmak İçin:**
  - Python 3 (Fedora'da varsayılan olarak kuruludur)
  - Herhangi bir modern Web Tarayıcı (Firefox, Chromium vb.)

---

## Yerel Geliştirme ve Çalıştırma

### 1. Flutter Kodunu Derleme

Öncelikle Flutter kodunu web platformuna derleyip statik çıktıları oluşturun:

```bash
# Makefile kullanarak derleme:
make compile

# Veya doğrudan Flutter komutuyla derleme:
flutter build web --release
```

### 2. Uygulamayı Başlatma

Yerel Python sunucusunu çalıştırarak uygulamayı başlatın:

```bash
python launcher.py
```
Bu komut boştaki bir portu bulacak, sunucuyu kuracak ve otomatik olarak varsayılan tarayıcınızda uygulamayı açacaktır.

---

## Fedora Copr için RPM Yapılandırması ve Build Alma

Uygulamayı tüm Fedoralarda çalışacak şekilde `noarch` RPM olarak paketlemek ve Fedora Copr'a yüklemek için şu adımları izleyin:

### 1. Kaynak Tarball Paketini Oluşturma

Projeyi derleyin ve dağıtıma hazır hale getirmek için bir tarball arşivi oluşturun:

```bash
make dist
```
Bu komut `ro-retro-1.0.0.tar.gz` dosyasını oluşturacaktır.

### 2. Mock ile Yerel RPM Testi (İsteğe Başlı)

Yerel makinenizde Fedora RPM paketleme araçları yüklüyse:

```bash
# Bağımlılıkları kurun
sudo dnf install fedora-packager mock

# RPM paketini mock ile yerel olarak derleyin
mock -r fedora-rawhide-x86_64 --buildsrpm --spec ro-retro.spec --sources .
```

### 3. Fedora Copr Üzerinde Build Alma

1. [Fedora Copr](https://copr.fedorainfracloud.org/) web sitesinde bir hesap oluşturun.
2. Yeni bir proje oluşturun (Örn: `ro-retro`).
3. Proje ayarlarında mimari (Active Chroots) olarak Fedora sürümlerini seçin. `noarch` olarak derleneceğinden herhangi bir standart build root chroot'u işinizi görecektir.
4. **Build Source** olarak oluşturduğunuz `ro-retro-1.0.0.tar.gz` dosyasını ve `ro-retro.spec` dosyasını yükleyin veya GitHub deponuzu entegre ederek doğrudan deponuzdan build tetikleyin.
5. Copr, spec dosyasındaki `BuildArch: noarch` tanımını okuyarak paketi derleyecek ve kullanıcılara sunacaktır.

Kullanıcılar projenizi şu komutlarla yükleyebilir:

```bash
sudo dnf copr enable <kullanici_adiniz>/ro-retro
sudo dnf install ro-retro
```
Kurulum tamamlandığında uygulama menüsünde `Ro-Retro` simgesine tıklayarak uygulamayı başlatabilirler.
