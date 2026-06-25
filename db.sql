-- ============================================================
-- GEN LABORATUVARI - Biyoloji Eğitim ve Araştırma Merkezi
-- Veritabanı Modeli
-- MariaDB Uyumlu SQL Script
-- Oluşturulma: 2026
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

CREATE DATABASE IF NOT EXISTS `gen_laboratuvari`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_turkish_ci;

USE `gen_laboratuvari`;

-- ============================================================
-- 1. PORTAL KULLANICI TABLOSU
--    Sisteme giriş yapabilen tüm kullanıcılar (admin, eğitmen, öğrenci)
-- ============================================================
CREATE TABLE `portal_kullanicilari` (
  `id`               INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `uuid`             CHAR(36)        NOT NULL COMMENT 'Benzersiz kullanıcı kimliği (UUID v4)',
  `kullanici_adi`    VARCHAR(60)     NOT NULL,
  `email`            VARCHAR(180)    NOT NULL,
  `sifre_hash`       VARCHAR(255)    NOT NULL COMMENT 'bcrypt/argon2 hash',
  `rol`              ENUM('admin','egitmen','ogrenci','misafir') NOT NULL DEFAULT 'misafir',
  `ad`               VARCHAR(80)     NOT NULL,
  `soyad`            VARCHAR(80)     NOT NULL,
  `telefon`          VARCHAR(20)         NULL,
  `avatar_url`       VARCHAR(500)        NULL,
  `aktif`            TINYINT(1)      NOT NULL DEFAULT 1,
  `email_dogrulandi` TINYINT(1)      NOT NULL DEFAULT 0,
  `son_giris`        DATETIME            NULL,
  `sifre_sifir_token`   VARCHAR(100)     NULL,
  `sifre_sifir_son`     DATETIME         NULL,
  `olusturulma_tarihi`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_uuid`           (`uuid`),
  UNIQUE KEY `uq_kullanici_adi`  (`kullanici_adi`),
  UNIQUE KEY `uq_email`          (`email`),
  KEY `idx_rol`                  (`rol`),
  KEY `idx_aktif`                (`aktif`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Portal''a erişim yetkisi olan tüm kullanıcılar';


-- ============================================================
-- 2. ÖĞRENCİ TABLOSU
--    Eğitim almak isteyen lise öğrencilerinin profil bilgileri
-- ============================================================
CREATE TABLE `ogrenciler` (
  `id`                   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `kullanici_id`         INT UNSIGNED      NULL COMMENT 'Portal hesabı varsa bağlı kullanıcı',
  `ad`                   VARCHAR(80)   NOT NULL,
  `soyad`                VARCHAR(80)   NOT NULL,
  `tc_kimlik`            CHAR(11)          NULL COMMENT 'Opsiyonel, şifreli tutulmalı',
  `dogum_tarihi`         DATE              NULL,
  `cinsiyet`             ENUM('E','K','Belirtmek istemiyorum') NULL,
  `okul_adi`             VARCHAR(200)  NOT NULL,
  `sinif`                TINYINT UNSIGNED  NULL COMMENT '9,10,11,12',
  `bolum`                VARCHAR(100)      NULL COMMENT 'Sayısal, Eşit Ağırlık vb.',
  `veli_ad_soyad`        VARCHAR(160)      NULL,
  `veli_telefon`         VARCHAR(20)       NULL,
  `veli_email`           VARCHAR(180)      NULL,
  `ogrenci_email`        VARCHAR(180)      NULL,
  `ogrenci_telefon`      VARCHAR(20)       NULL,
  `adres`                TEXT              NULL,
  `ilce`                 VARCHAR(80)       NULL,
  `il`                   VARCHAR(80)       NULL,
  `kayit_tarihi`         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `notlar`               TEXT              NULL COMMENT 'İç notlar',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_kullanici_id` (`kullanici_id`),
  KEY `idx_okul`    (`okul_adi`(50)),
  KEY `idx_il`      (`il`),
  KEY `idx_sinif`   (`sinif`),

  CONSTRAINT `fk_ogrenci_kullanici`
    FOREIGN KEY (`kullanici_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Eğitim almak isteyen lise öğrencileri';


-- ============================================================
-- 3. EĞİTİM KATEGORİ TABLOSU
--    Eğitimlerin gruplandığı hiyerarşik kategoriler
-- ============================================================
CREATE TABLE `egitim_kategorileri` (
  `id`                   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `ust_kategori_id`      INT UNSIGNED      NULL COMMENT 'Hiyerarşi için üst kategori',
  `ad`                   VARCHAR(120)  NOT NULL,
  `slug`                 VARCHAR(130)  NOT NULL COMMENT 'URL dostu isim',
  `aciklama`             TEXT              NULL,
  `ikon`                 VARCHAR(100)      NULL COMMENT 'CSS ikon sınıfı veya URL',
  `renk_kodu`            CHAR(7)           NULL COMMENT 'Hex renk kodu: #RRGGBB',
  `sira`                 SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `aktif`                TINYINT(1)    NOT NULL DEFAULT 1,
  `olusturulma_tarihi`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slug` (`slug`),
  KEY `idx_ust_kategori` (`ust_kategori_id`),
  KEY `idx_aktif_sira`   (`aktif`, `sira`),

  CONSTRAINT `fk_kategori_ust`
    FOREIGN KEY (`ust_kategori_id`)
    REFERENCES `egitim_kategorileri` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Eğitimlerin sınıflandırıldığı kategoriler (hiyerarşik)';


-- ============================================================
-- 4. EĞİTİM İÇERİK TABLOSU
--    Mevcut tüm eğitim programlarının tanım ve detayları
-- ============================================================
CREATE TABLE `egitimler` (
  `id`                   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `kategori_id`          INT UNSIGNED    NOT NULL,
  `egitmen_id`           INT UNSIGNED        NULL COMMENT 'Sorumlu eğitmen (portal_kullanicilari)',
  `baslik`               VARCHAR(250)    NOT NULL,
  `slug`                 VARCHAR(260)    NOT NULL,
  `kisa_aciklama`        VARCHAR(500)        NULL,
  `icerik`               LONGTEXT            NULL COMMENT 'HTML/Markdown detaylı içerik',
  `seviye`               ENUM('baslangic','orta','ileri') NOT NULL DEFAULT 'baslangic',
  `sure_saat`            DECIMAL(5,2)        NULL COMMENT 'Toplam eğitim süresi (saat)',
  `kontenjan`            SMALLINT UNSIGNED   NULL COMMENT 'NULL = sınırsız',
  `ucret`                DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
  `para_birimi`          CHAR(3)         NOT NULL DEFAULT 'TRY',
  `ucretsiz_mi`          TINYINT(1)      NOT NULL DEFAULT 1,
  `on_kosul`             TEXT                NULL,
  `hedef_kitle`          TEXT                NULL,
  `kazanimlar`           TEXT                NULL COMMENT 'Öğrenim çıktıları',
  `materyal_listesi`     TEXT                NULL,
  `kapak_gorsel`         VARCHAR(500)        NULL,
  `durum`                ENUM('taslak','yayin','arsiv','iptal') NOT NULL DEFAULT 'taslak',
  `onculuk_sirasi`       SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
  `sertifika_var_mi`     TINYINT(1)      NOT NULL DEFAULT 0,
  `olusturulma_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slug`        (`slug`),
  KEY `idx_kategori`          (`kategori_id`),
  KEY `idx_egitmen`           (`egitmen_id`),
  KEY `idx_durum`             (`durum`),
  KEY `idx_seviye`            (`seviye`),
  KEY `idx_ucretsiz`          (`ucretsiz_mi`),

  CONSTRAINT `fk_egitim_kategori`
    FOREIGN KEY (`kategori_id`)
    REFERENCES `egitim_kategorileri` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT `fk_egitim_egitmen`
    FOREIGN KEY (`egitmen_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Eğitim programlarının içerik ve meta bilgileri';


-- ============================================================
-- 5. EĞİTİM TARİH / OTURUM TABLOSU
--    Eğitimlerin belirli tarihlerdeki oturumları (şubeler)
-- ============================================================
CREATE TABLE `egitim_oturumlari` (
  `id`                   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `egitim_id`            INT UNSIGNED    NOT NULL,
  `egitmen_id`           INT UNSIGNED        NULL COMMENT 'Oturuma özgü eğitmen (farklıysa)',
  `oturum_kodu`          VARCHAR(30)         NULL COMMENT 'Örn: GEN-2025-01-A',
  `baslangic_tarihi`     DATE            NOT NULL,
  `bitis_tarihi`         DATE            NOT NULL,
  `baslangic_saati`      TIME                NULL,
  `bitis_saati`          TIME                NULL,
  `gun_paterni`          VARCHAR(100)        NULL COMMENT 'Örn: Pazartesi-Çarşamba',
  `format`               ENUM('yuz_yuze','online','hibrit') NOT NULL DEFAULT 'yuz_yuze',
  `lokasyon`             VARCHAR(300)        NULL,
  `online_link`          VARCHAR(500)        NULL,
  `kontenjan`            SMALLINT UNSIGNED   NULL,
  `min_katilimci`        SMALLINT UNSIGNED   NULL DEFAULT 5,
  `kayit_bitis_tarihi`   DATE                NULL,
  `durum`                ENUM('planlandi','aktif','tamamlandi','iptal','dolu') NOT NULL DEFAULT 'planlandi',
  `notlar`               TEXT                NULL,
  `olusturulma_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_egitim_id`         (`egitim_id`),
  KEY `idx_egitmen_id`        (`egitmen_id`),
  KEY `idx_baslangic`         (`baslangic_tarihi`),
  KEY `idx_durum`             (`durum`),
  KEY `idx_format`            (`format`),
  KEY `idx_kayit_bitis`       (`kayit_bitis_tarihi`),

  CONSTRAINT `fk_oturum_egitim`
    FOREIGN KEY (`egitim_id`)
    REFERENCES `egitimler` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT `fk_oturum_egitmen`
    FOREIGN KEY (`egitmen_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Eğitimlerin tarih bazlı oturumları / şubeleri';


-- ============================================================
-- 6. BAŞVURU / KAYIT TABLOSU
--    Öğrencilerin eğitim oturumlarına başvuruları
-- ============================================================
CREATE TABLE `basvurular` (
  `id`                   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `ogrenci_id`           INT UNSIGNED    NOT NULL,
  `oturum_id`            INT UNSIGNED    NOT NULL,
  `basvuru_no`           VARCHAR(20)     NOT NULL COMMENT 'Benzersiz başvuru numarası: BAŞ-20250001',
  `basvuru_tarihi`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `durum`                ENUM(
                           'beklemede',
                           'onaylandi',
                           'red_edildi',
                           'bekleme_listesi',
                           'iptal_ogrenci',
                           'iptal_merkez',
                           'tamamlandi'
                         ) NOT NULL DEFAULT 'beklemede',
  `onay_tarihi`          DATETIME            NULL,
  `onaylayan_id`         INT UNSIGNED        NULL COMMENT 'Onaylayan portal kullanıcısı',
  `odeme_durumu`         ENUM('odenmedi','odendi','iade','muaf') NOT NULL DEFAULT 'muaf',
  `odeme_tutari`         DECIMAL(10,2)       NULL,
  `odeme_tarihi`         DATETIME            NULL,
  `odeme_referans`       VARCHAR(100)        NULL,
  `katilim_durumu`       ENUM('katildi','katilmadi','kismi','belirsiz') NULL DEFAULT 'belirsiz',
  `devamsizlik_saati`    DECIMAL(4,1)        NULL,
  `sertifika_no`         VARCHAR(60)         NULL,
  `sertifika_tarihi`     DATE                NULL,
  `veli_onayi`           TINYINT(1)      NOT NULL DEFAULT 0,
  `veli_onay_tarihi`     DATETIME            NULL,
  `notlar`               TEXT                NULL,
  `guncellenme_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_basvuru_no`       (`basvuru_no`),
  UNIQUE KEY `uq_ogrenci_oturum`   (`ogrenci_id`, `oturum_id`) COMMENT 'Aynı oturuma çift başvuru engeli',
  KEY `idx_oturum_id`              (`oturum_id`),
  KEY `idx_durum`                  (`durum`),
  KEY `idx_odeme_durumu`           (`odeme_durumu`),
  KEY `idx_basvuru_tarihi`         (`basvuru_tarihi`),
  KEY `idx_onaylayan`              (`onaylayan_id`),

  CONSTRAINT `fk_basvuru_ogrenci`
    FOREIGN KEY (`ogrenci_id`)
    REFERENCES `ogrenciler` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT `fk_basvuru_oturum`
    FOREIGN KEY (`oturum_id`)
    REFERENCES `egitim_oturumlari` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT `fk_basvuru_onaylayan`
    FOREIGN KEY (`onaylayan_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Öğrencilerin eğitim oturumlarına başvuru ve kayıt kayıtları';


-- ============================================================
-- 7. DUYURULAR TABLOSU
-- ============================================================
CREATE TABLE `duyurular` (
  `id`                   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `yazar_id`             INT UNSIGNED        NULL COMMENT 'Duyuruyu oluşturan kullanıcı',
  `baslik`               VARCHAR(300)    NOT NULL,
  `ozet`                 VARCHAR(600)        NULL,
  `icerik`               LONGTEXT            NULL COMMENT 'HTML/Markdown içerik',
  `tip`                  ENUM('genel','egitim','acil','etkinlik','duyuru') NOT NULL DEFAULT 'genel',
  `oncelik`              ENUM('normal','yuksek','kritik') NOT NULL DEFAULT 'normal',
  `hedef_kitle`          ENUM('herkese','ogrencilere','egitimlilere','adminlere') NOT NULL DEFAULT 'herkese',
  `yayinlanma_tarihi`    DATETIME            NULL,
  `bitis_tarihi`         DATETIME            NULL COMMENT 'Bu tarihten sonra gösterilmez',
  `durum`                ENUM('taslak','yayin','arsiv') NOT NULL DEFAULT 'taslak',
  `sabit_mi`             TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Üstte sabit gösterim',
  `gorsel_url`           VARCHAR(500)        NULL,
  `goruntuleme_sayisi`   INT UNSIGNED    NOT NULL DEFAULT 0,
  `ilgili_egitim_id`     INT UNSIGNED        NULL,
  `olusturulma_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_durum_yayin`      (`durum`, `yayinlanma_tarihi`),
  KEY `idx_tip`              (`tip`),
  KEY `idx_oncelik`          (`oncelik`),
  KEY `idx_sabit`            (`sabit_mi`),
  KEY `idx_yazar`            (`yazar_id`),
  KEY `idx_ilgili_egitim`    (`ilgili_egitim_id`),

  CONSTRAINT `fk_duyuru_yazar`
    FOREIGN KEY (`yazar_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT `fk_duyuru_egitim`
    FOREIGN KEY (`ilgili_egitim_id`)
    REFERENCES `egitimler` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='Site geneli duyurular ve haberler';


-- ============================================================
-- 8. İLETİŞİM FORMU TABLOSU
--    Ziyaretçi ve kullanıcı iletişim mesajları
-- ============================================================
CREATE TABLE `iletisim_mesajlari` (
  `id`                   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `kullanici_id`         INT UNSIGNED        NULL COMMENT 'Giriş yapmış kullanıcıysa bağlı',
  `gonderen_ad`          VARCHAR(80)     NOT NULL,
  `gonderen_soyad`       VARCHAR(80)         NULL,
  `gonderen_email`       VARCHAR(180)    NOT NULL,
  `gonderen_telefon`     VARCHAR(20)         NULL,
  `konu`                 VARCHAR(250)    NOT NULL,
  `mesaj`                TEXT            NOT NULL,
  `kategori`             ENUM(
                           'genel_bilgi',
                           'egitim_basvuru',
                           'teknik_destek',
                           'isbirligi',
                           'sikayet',
                           'oneri',
                           'diger'
                         ) NOT NULL DEFAULT 'genel_bilgi',
  `durum`                ENUM('okunmadi','okundu','yanit_bekleniyor','yanitlandi','kapali') NOT NULL DEFAULT 'okunmadi',
  `atanan_kullanici_id`  INT UNSIGNED        NULL COMMENT 'Yanıt verecek personel',
  `yanit`                TEXT                NULL,
  `yanit_tarihi`         DATETIME            NULL,
  `yanit_veren_id`       INT UNSIGNED        NULL,
  `ip_adresi`            VARCHAR(45)         NULL COMMENT 'IPv4/IPv6',
  `user_agent`           VARCHAR(500)        NULL,
  `gonderim_tarihi`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `guncellenme_tarihi`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  KEY `idx_durum`            (`durum`),
  KEY `idx_kategori`         (`kategori`),
  KEY `idx_kullanici`        (`kullanici_id`),
  KEY `idx_atanan`           (`atanan_kullanici_id`),
  KEY `idx_yanit_veren`      (`yanit_veren_id`),
  KEY `idx_email`            (`gonderen_email`),
  KEY `idx_gonderim`         (`gonderim_tarihi`),

  CONSTRAINT `fk_mesaj_kullanici`
    FOREIGN KEY (`kullanici_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT `fk_mesaj_atanan`
    FOREIGN KEY (`atanan_kullanici_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT `fk_mesaj_yanit_veren`
    FOREIGN KEY (`yanit_veren_id`)
    REFERENCES `portal_kullanicilari` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_turkish_ci
  COMMENT='İletişim formundan gelen mesajlar ve yanıtlar';


-- ============================================================
-- ÖRNEK / SEED VERİLER
-- ============================================================

-- Kategoriler
INSERT INTO `egitim_kategorileri` (`ad`, `slug`, `aciklama`, `renk_kodu`, `sira`, `aktif`) VALUES
('DNA ve Genetik',       'dna-ve-genetik',       'DNA yapısı, gen ifadesi, kalıtım mekanizmaları',    '#2563EB', 1, 1),
('Hücre Biyolojisi',    'hucre-biyolojisi',     'Hücre organelleri, bölünme, membran olayları',       '#16A34A', 2, 1),
('Mikrobiyoloji',        'mikrobiyoloji',         'Bakteri, virüs, mantar ve protist dünyası',          '#9333EA', 3, 1),
('Biyoteknoloji',        'biyoteknoloji',         'PCR, CRISPR, GDO ve uygulama alanları',              '#DC2626', 4, 1),
('Evrim ve Ekoloji',     'evrim-ve-ekoloji',     'Evrim teorisi, ekosistemler, biyoçeşitlilik',        '#EA580C', 5, 1),
('Laboratuvar Becerileri','laboratuvar-becerileri','Mikroskop kullanımı, preparasyon, güvenlik',        '#0891B2', 6, 1);

-- Admin kullanıcı (şifre: changeme123 — üretimde değiştirilmeli)
INSERT INTO `portal_kullanicilari` (`uuid`, `kullanici_adi`, `email`, `sifre_hash`, `rol`, `ad`, `soyad`, `aktif`, `email_dogrulandi`) VALUES
(UUID(), 'admin', 'admin@genlaboratuvari.com', '$2y$12$placeholder_hash_degistiriniz', 'admin', 'Sistem', 'Yöneticisi', 1, 1);

-- Örnek duyuru
INSERT INTO `duyurular` (`baslik`, `ozet`, `tip`, `oncelik`, `durum`, `sabit_mi`, `yayinlanma_tarihi`) VALUES
('2025 Yaz Dönemi Kayıtları Açıldı',
 'Yaz dönemi eğitim programlarımıza başvurular başlamıştır. Kontenjanlar sınırlıdır.',
 'egitim', 'yuksek', 'yayin', 1, NOW());

-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;
-- ============================================================
-- GEN LABORATUVARI VERİTABANI KURULUMU TAMAMLANDI
-- Toplam: 8 tablo
--   1. portal_kullanicilari  - Kullanıcı yönetimi
--   2. ogrenciler            - Öğrenci profilleri
--   3. egitim_kategorileri   - Kategori hiyerarşisi
--   4. egitimler             - Eğitim içerikleri
--   5. egitim_oturumlari     - Tarih/oturum planlaması
--   6. basvurular            - Başvuru ve kayıt takibi
--   7. duyurular             - Duyuru yönetimi
--   8. iletisim_mesajlari    - İletişim formu
-- ============================================================