# Anında Çeviri

Flutter ile geliştirilmiş, ses ile anında çeviri yapabilen mobil uygulama projesi. Bu proje, pratik bir ihtiyacı karşılamanın yanı sıra Flutter'daki modüler mimari, servis kullanımı ve donanım entegrasyonları gibi konuları öğrenmek amacıyla geliştirilmiştir.

## ✨ Özellikler

- **Çoklu Giriş Yöntemi:**
  - 🎤 **Sesle Çeviri:** Konuşulanları anında dinleyip metne çevirir.
  - ✍️ **Metinle Çeviri:** Klavyeden yazılan metinleri çevirir.
- **Dinamik Dil Seçimi:** Kaynak ve hedef diller, kullanıcı tarafından kolayca değiştirilebilir.
- **Sesli Geri Bildirim:** Yapılan çeviriyi hedef dilde sesli olarak okur.
- **Çeviri Geçmişi:** Yapılan son çeviriler cihaz hafızasına kaydedilir ve uygulama içinden tekrar görüntülenebilir.
- **Kullanıcı Dostu Arayüz:** Panoya kopyalama, metni temizleme ve dilleri takas etme gibi kullanışlı kısayollar içerir.

## 🛠️ Kullanılan Teknolojiler ve Paketler

- **Çatı (Framework):** Flutter
- **Dil:** Dart
- **Mimari:** Modüler yapı (Servis katmanı, Model katmanı, Ekran katmanı)

### Ana Paketler:

- `speech_to_text`: Ses tanıma (Konuşmayı metne çevirme).
- `flutter_tts`: Metin seslendirme (Text-to-Speech).
- `translator`: Metin çeviri servisi.
- `google_ml_kit_text_recognition`: Kamera ve resimlerden metin tanıma (OCR).
- `image_picker`: Cihazın galerisinden veya kamerasından resim seçme.
- `shared_preferences`: Çeviri geçmişini cihaz hafızasında saklama.

## 🚀 Projeyi Çalıştırma

Bu projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyin.

### Ön Koşullar

- [Flutter SDK](https://flutter.dev/docs/get-started/install) kurulu olmalı.
- Bir Android/iOS emülatörü veya fiziksel bir cihaz bağlı olmalı.

### Kurulum

1.  **Projeyi Klonlayın:**
    ```sh
    git clone https://github.com/irtengunica/aninda_ceviri_pro.git
    ```

2.  **Proje Klasörüne Gidin:**
    ```sh
    cd aninda_ceviri_pro
    ```

3.  **Paketleri Yükleyin:**
    ```sh
    flutter pub get
    ```

4.  **Uygulamayı Çalıştırın:**
    ```sh
    flutter run
    ```

## 📝 Notlar

- Uygulama ilk kez çalıştırıldığında Mikrofon, Konuşma Tanıma, Kamera ve Galeri erişimi için izinler isteyecektir. Uygulamanın tam fonksiyonel çalışabilmesi için bu izinlerin verilmesi gerekmektedir.
- `release` modunda bir APK oluştururken, ML Kit kütüphanesinin doğru çalışması için `proguard-rules.pro` dosyasına gerekli kurallar eklenmiştir.
