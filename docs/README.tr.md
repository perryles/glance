<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">Mac'inizin kilidini yüzünüzle açın</h3>

<p align="center">
  <a href="../README.md" lang="en">English</a> ·
  <a href="README.zh-CN.md" lang="zh-CN">简体中文</a> ·
  <a href="README.ja.md" lang="ja">日本語</a> ·
  <a href="README.es.md" lang="es">Español</a> ·
  <a href="README.fr.md" lang="fr">Français</a> ·
  <a href="README.de.md" lang="de">Deutsch</a> ·
  <a href="README.pt-BR.md" lang="pt-BR">Português (Brasil)</a> ·
  <a href="README.tr.md" lang="tr">Türkçe</a>
</p>

<p align="center">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT Lisansı"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

Glance, iPhone'daki Face ID'ye benzer bir deneyimi Mac'inize getirir. Parola yazmadan veya Touch ID tuşuna uzanmadan, bir bakışla Mac'inizin kilidini açın. Tüm işlemler Apple'ın Vision ve Core ML çerçeveleriyle cihaz üzerinde gerçekleştirilir. Yüz verileriniz ve Mac parolanız hiçbir zaman internete gönderilmez. Arayüz, Dynamic Island benzeri akıcı animasyonlarla MacBook'unuzun çentiğine entegre olur.

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## İndirmeden önce okuyun
> ## Glance, Apple'ın Face ID veya Touch ID teknolojileri kadar güvenli değildir
>
> MacBook'larda, iPhone'daki Face ID'yi güvenilir ve güvenli kılan derinlik sensörleri bulunmaz. iPhone yüzünüzün üç boyutlu haritasını oluştururken MacBook kamerası düz, iki boyutlu bir görüntü görür. Bunun getirdiği sınırlamalar aşağıda açıklanmıştır.
>
> - Glance, basılı bir fotoğrafla veya telefon ekranındaki bir fotoğrafla yapılan aldatma girişimlerini makul bir güven düzeyiyle engelleyebilir (yüksek düzeyde canlılık algılama açık olmalıdır).
> - Glance, videonuz kullanılarak yapılan aldatma girişimlerini güvenilir biçimde engelleyemez.
> - macOS, üçüncü taraf bir uygulamanın oturum açmayı yetkilendirmesine olanak tanıyan bir API sunmaz. Bu nedenle Glance, kayıtlı parolanızı kilit ekranına yazarak kilidi açar.
>
> Glance kolaylık sağlayan bir özelliktir, güvenliği artırmaz. Yalnızca bu ödünleşimi kabul ediyorsanız devam edin.

## Kurulum

**Gereksinimler**

- macOS 15 Sequoia veya üzeri
- Apple Silicon veya Intel işlemcili Mac

<a href="https://github.com/jonnyoo/glance/releases/latest/download/Glance.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Mac için indir" /></a>

`.dmg` dosyasını açın, Glance'i `/Applications` klasörüne sürükleyin ve uygulamayı başlatın.

## İzinler

| İzin | Amacı |
|---|---|
| **Kamera** | Yüzünüzü algılamak için kullanılır. Kareler bellekte işlenir ve hiçbir zaman diske yazılmaz. |
| **Erişilebilirlik** | Parolanızı kilit ekranına yazmak için kullanılır. |
| **Touch ID** | Yüz verilerinizi ve parolanızı şifreleyen anahtara erişimi korur. |

## Nasıl çalışır?

1. Uygulamayı başlatın ve yüzünüzü kaydetmek için ilk kurulum adımlarını izleyin. Glance, başınızı dokuz yöne çevirerek yüzünüzü kaydetmeniz için size yol gösterir. Her kare, matematiksel bir parmak izi olan 512 sayılık bir *özellik vektörüne* dönüştürülür ve görüntü atılır.
2. Mac parolanızı bir kez girin. Parola şifrelenir ve Touch ID ile korunur.
3. Mac'iniz kilitlendiğinde veya uykudan uyandığında çentikte animasyon belirir ve yüz aranmaya başlanır.
4. Yüzünüz eşleşirse ve canlılık kontrolleri gerçek bir kişi olduğunuzu doğrularsa Glance parolayı yazar ve kilidi açar.

## Özellikler

| Özellik | Açıklama |
|---|---|
| **Yüzle kilit açma** | Uyanma sırasında, kilitlendiğinde veya kilit ekranında boşluk tuşuna basıldığında tetiklenir. Bu seçenekleri dilediğiniz gibi birleştirebilirsiniz. |
| **Birden fazla kimlik** | Birden fazla kişiyi veya gözlüklü, sakallı ya da farklı ışık koşullarındaki hâllerinizi kaydedin. Her kimliği silmeden ayrı ayrı devre dışı bırakabilirsiniz. |
| **Canlılık kontrolleri** | Gerçek bir yüzü fotoğraftan ayıran hareketleri ve yansımaları inceler. Düşük veya yüksek düzeyi seçebilir ya da kontrolleri kapatabilirsiniz. |
| **Çentik arayüzü** | Kapalı bir kapsül, başarı ve başarısızlık durumlarını gösteren bir tarama animasyonuna genişler. Yeniden denemek için imleci üzerine getirin veya Glance'in görünmez kalması için animasyonları tamamen kapatın. |
| **Kamera ve ekran** | Kullanılacak kamerayı seçin. Yerleşik ekran ve harici monitör için farklı kameralar da belirleyebilirsiniz. |
| **Oturumların otomatik kilitlenmesi** | Touch ID oturumu, seçtiğiniz hareketsizlik süresinden sonra yeniden kilitlenir. Böylece gözetimsiz kalan bir Mac süresiz olarak yetkilendirilmiş durumda kalmaz. |
| **İzleme dörtgeninde dokunsal geri bildirim** | İmleci çentiğin üzerine getirmek dokunsal geri bildirimi tetikler. |
| **Çentiksiz Mac desteği** | Çentiği olmayan Mac'lerde Dynamic Island tarzında kapsül biçimli bir arayüz gösterilir. |
| **Verilerinizin kontrolü sizde** | Yüz kayıtlarınızı veya saklanan parolanızı istediğiniz zaman düzenleyin ya da silin. İlgili şifrelenmiş dosyalar hemen kaldırılır. |

---

# Gizlilik ve güvenlik

Glance, biyometrik verileri ve kimlik bilgilerini cihaz üzerinde tutmak üzere tasarlanmıştır.

### Yüz verileri

Glance kamera görüntülerini hiçbir zaman saklamaz. Kayıt sırasında yakalanan her yüz, ArcFace tabanlı bir Core ML modeliyle **512 boyutlu bir özellik vektörüne** dönüştürülür. Ardından orijinal kare atılır.

Vektörler yerel olarak saklanır ve **AES-GCM** ile şifrelenir.

### Kimlik bilgileri

Mac parolanız şifrelenmiş veri olarak saklanır ve hiçbir zaman diske düz metin olarak yazılmaz. Şifreleme anahtarı, **macOS Anahtar Zinciri'nde saklanan 256 bitlik bir AES anahtarıdır**. Anahtar, Touch ID veya cihaz parolası gerektiren `userPresence` ile korunur.

Anahtar yalnızca yetkilendirilmiş bir Glance oturumu etkinken bellekte tutulur.

### Kilit açma süreci

Glance'in parolanızı yazabilmesi için aşağıdaki koşulların tamamı karşılanmalıdır.

1. Geçerli bir Glance oturumu yetkilendirilmiş olmalıdır.
2. Mac gerçekten kilit ekranında olmalıdır.
3. Etkin bir kimlikle eşleşme, yapılandırılmış benzerlik eşiğini aşmalıdır.
4. Algılanan yüz canlılık kontrollerinden geçmelidir.
5. Parolayı girmek için erişilebilirlik izni verilmiş olmalıdır.

Yüz tanıma ve canlılık algılama birbirinden bağımsız çalışır. Parola girilmeden önce ikisinin de başarılı olması gerekir.

### Yerel işleme

Yüz tanıma, yüz kaydı ve canlılık algılama, Vision ve Core ML kullanılarak tamamen cihaz üzerinde gerçekleştirilir. Glance yüz verilerini, kamera karelerini veya kimlik bilgilerini bir sunucuya göndermez.

### Yüzü fotoğraftan nasıl ayırır?

Yaklaşık 2 saniyelik kayan bir zaman aralığında beş bağımsız ipucu, iki farklı amaçla değerlendirilir.

- **Reddetme ipuçları**, ekran yansıması veya yüzü çevreleyen cihaz biçiminde bir dikdörtgen gibi aldatma belirtileridir. Bunlardan herhangi biri taramayı doğrudan başarısız kılar ve diğer tüm sonuçların önüne geçer.
- **Doğrulama ipuçları**, yüz işaret noktalarının düz veya üç boyutlu geometrisi, baş çevrildiğinde burunda oluşan paralaks ve göz kırpma gibi gerçek bir yüze işaret eden belirtilerdir. Herhangi biri yeterlidir. Gerçek bir kişi kıpırdamadan ve göz kırpmadan oturabileceği için bu ipuçlarının yokluğu tek başına hiçbir zaman başarısızlık sayılmaz.

Düşük düzeyde algılama yalnızca reddetme ipuçlarını kullanır. Yüksek düzeyde algılama hem reddetme hem de doğrulama ipuçlarını kullanır.

### Face Lab

Face Lab, yüz tanıma ve canlılık algılamayı gerçek ölçüm değerleriyle test etmeye yarayan gizli bir hata ayıklama konsoludur.

Açmak için Ayarlar → Hakkında bölümüne gidin ve uygulama simgesine 5 kez tıklayın. Kenar çubuğunda bir hata ayıklama bölümü görünür.

---

## Kaynak koddan derleme

### Ön koşullar

- macOS 15+
- Xcode 26+

### Adımlar

1. Depoyu klonlayın.

   ```bash
   git clone https://github.com/jonnyoo/glance.git
   cd glance
   ```

2. Xcode ile açın.

   ```bash
   open glance.xcodeproj
   ```

3. Çalıştır düğmesine tıklayın veya `Cmd + R` tuşlarına basın.

## Katkıda bulunma

Şu anda PR kabul edilmiyor. Bu projeyi çatallayabilirsiniz.

Uygulamayla ilgili geri bildirimlerinizi [tryglance.app/feedback](https://tryglance.app/feedback) adresine iletebilirsiniz.

## Teşekkürler

- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — çentik penceresinin fizik tabanlı hareketleri için.
- **[InsightFace](https://github.com/deepinsight/insightface)** — yüz tanımayı gerçekleştiren ArcFace modeli için.
- **[Alcove](https://tryalcove.com)** — tasarıma büyük ilham verdiği için.

## Lisans

[MIT](../LICENSE) © Jonathan Zhou
