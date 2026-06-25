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
-- ============================================================
-- GEN LABORATUVARI - Örnek Seed Verileri
-- Her tabloya 20 satır örnek veri
-- MariaDB Uyumlu
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
USE `gen_laboratuvari`;

-- ============================================================
-- 1. PORTAL_KULLANICILARI (20 kayıt)
--    Şifre hash'leri placeholder — üretimde bcrypt kullanın
-- ============================================================
-- TRUNCATE TABLE `portal_kullanicilari`;

INSERT INTO `portal_kullanicilari`
  (`uuid`, `kullanici_adi`, `email`, `sifre_hash`, `rol`, `ad`, `soyad`, `telefon`, `aktif`, `email_dogrulandi`, `son_giris`)
VALUES
  (UUID(), 'admin',          'admin@genlaboratuvari.com',      '$2y$12$hash_admin',    'admin',    'Ahmet',    'Yılmaz',      '05321000001', 1, 1, '2025-06-01 08:30:00'),
  (UUID(), 'mudur_ayse',     'ayse.kaya@genlaboratuvari.com',  '$2y$12$hash_ayse',     'admin',    'Ayşe',     'Kaya',        '05321000002', 1, 1, '2025-06-02 09:00:00'),
  (UUID(), 'egitmen_mehmet', 'mehmet.celik@genlaboratuvari.com','$2y$12$hash_mehmet',  'egitmen',  'Mehmet',   'Çelik',       '05321000003', 1, 1, '2025-06-03 10:15:00'),
  (UUID(), 'egitmen_fatma',  'fatma.arslan@genlaboratuvari.com','$2y$12$hash_fatma',   'egitmen',  'Fatma',    'Arslan',      '05321000004', 1, 1, '2025-06-04 11:00:00'),
  (UUID(), 'egitmen_emre',   'emre.sahin@genlaboratuvari.com', '$2y$12$hash_emre',    'egitmen',  'Emre',     'Şahin',       '05321000005', 1, 1, '2025-06-05 09:30:00'),
  (UUID(), 'ogrenci_ali',    'ali.demir@email.com',            '$2y$12$hash_ali',     'ogrenci',  'Ali',      'Demir',       '05331000001', 1, 1, '2025-06-10 14:00:00'),
  (UUID(), 'ogrenci_zeynep', 'zeynep.ozturk@email.com',        '$2y$12$hash_zeynep',  'ogrenci',  'Zeynep',   'Öztürk',      '05331000002', 1, 1, '2025-06-11 15:00:00'),
  (UUID(), 'ogrenci_burak',  'burak.yildiz@email.com',         '$2y$12$hash_burak',   'ogrenci',  'Burak',    'Yıldız',      '05331000003', 1, 1, '2025-06-12 16:00:00'),
  (UUID(), 'ogrenci_elif',   'elif.kurt@email.com',            '$2y$12$hash_elif',    'ogrenci',  'Elif',     'Kurt',        '05331000004', 1, 1, '2025-06-13 10:30:00'),
  (UUID(), 'ogrenci_can',    'can.polat@email.com',            '$2y$12$hash_can',     'ogrenci',  'Can',      'Polat',       '05331000005', 1, 1, '2025-06-14 11:45:00'),
  (UUID(), 'ogrenci_selin',  'selin.aydın@email.com',          '$2y$12$hash_selin',   'ogrenci',  'Selin',    'Aydın',       '05331000006', 1, 1, '2025-06-15 13:00:00'),
  (UUID(), 'ogrenci_mert',   'mert.ozcan@email.com',           '$2y$12$hash_mert',    'ogrenci',  'Mert',     'Özcan',       '05331000007', 1, 0, NULL),
  (UUID(), 'ogrenci_nisa',   'nisa.koc@email.com',             '$2y$12$hash_nisa',    'ogrenci',  'Nisa',     'Koç',         '05331000008', 1, 1, '2025-06-16 09:00:00'),
  (UUID(), 'ogrenci_baris',  'baris.aslan@email.com',          '$2y$12$hash_baris',   'ogrenci',  'Barış',    'Aslan',       '05331000009', 1, 1, '2025-06-17 14:20:00'),
  (UUID(), 'ogrenci_irmak',  'irmak.gul@email.com',            '$2y$12$hash_irmak',   'ogrenci',  'Irmak',    'Gül',         '05331000010', 1, 1, '2025-06-18 16:30:00'),
  (UUID(), 'ogrenci_oguz',   'oguz.tas@email.com',             '$2y$12$hash_oguz',    'ogrenci',  'Oğuz',     'Taş',         '05331000011', 1, 0, NULL),
  (UUID(), 'ogrenci_pinar',  'pinar.cetin@email.com',          '$2y$12$hash_pinar',   'ogrenci',  'Pınar',    'Çetin',       '05331000012', 1, 1, '2025-06-19 10:00:00'),
  (UUID(), 'ogrenci_kerem',  'kerem.erdogan@email.com',        '$2y$12$hash_kerem',   'ogrenci',  'Kerem',    'Erdoğan',     '05331000013', 1, 1, '2025-06-20 11:00:00'),
  (UUID(), 'misafir_hakan',  'hakan.bulut@email.com',          '$2y$12$hash_hakan',   'misafir',  'Hakan',    'Bulut',       NULL,          1, 0, NULL),
  (UUID(), 'egitmen_derya',  'derya.yilmaz@genlaboratuvari.com','$2y$12$hash_derya',  'egitmen',  'Derya',    'Yılmaz',      '05321000006', 1, 1, '2025-06-20 08:00:00');


-- ============================================================
-- 2. OGRENCILER (20 kayıt)
--    kullanici_id = 6..18 arası ogrenci rolündeki kullanıcılar
-- ============================================================
-- TRUNCATE TABLE `ogrenciler`;

INSERT INTO `ogrenciler`
  (`kullanici_id`, `ad`, `soyad`, `dogum_tarihi`, `cinsiyet`, `okul_adi`, `sinif`, `bolum`,
   `veli_ad_soyad`, `veli_telefon`, `veli_email`, `ogrenci_email`, `ogrenci_telefon`, `il`, `ilce`)
VALUES
  (6,  'Ali',    'Demir',    '2008-03-15', 'E', 'Kadıköy Anadolu Lisesi',         11, 'Sayısal',       'Hasan Demir',      '05301001001', 'hasan.demir@email.com',    'ali.demir@email.com',    '05331000001', 'İstanbul',  'Kadıköy'),
  (7,  'Zeynep', 'Öztürk',   '2009-07-22', 'K', 'Beşiktaş Atatürk Anadolu Lisesi','10', 'Eşit Ağırlık', 'Meral Öztürk',    '05301001002', 'meral.ozturk@email.com',   'zeynep.ozturk@email.com','05331000002', 'İstanbul',  'Beşiktaş'),
  (8,  'Burak',  'Yıldız',   '2007-11-05', 'E', 'Ankara Fen Lisesi',              12, 'Sayısal',       'Serdar Yıldız',    '05301001003', 'serdar.yildiz@email.com',  'burak.yildiz@email.com', '05331000003', 'Ankara',    'Çankaya'),
  (9,  'Elif',   'Kurt',     '2009-02-28', 'K', 'İzmir Bornova Anadolu Lisesi',   10, 'Sayısal',       'Fatma Kurt',       '05301001004', 'fatma.kurt@email.com',     'elif.kurt@email.com',    '05331000004', 'İzmir',     'Bornova'),
  (10, 'Can',    'Polat',    '2008-09-18', 'E', 'Bursa Anadolu Lisesi',           11, 'Sayısal',       'Erdal Polat',      '05301001005', 'erdal.polat@email.com',    'can.polat@email.com',    '05331000005', 'Bursa',     'Osmangazi'),
  (11, 'Selin',  'Aydın',    '2008-05-12', 'K', 'Üsküdar Anadolu Lisesi',         11, 'Eşit Ağırlık', 'Nilüfer Aydın',    '05301001006', 'nilufer.aydin@email.com',  'selin.aydın@email.com',  '05331000006', 'İstanbul',  'Üsküdar'),
  (12, 'Mert',   'Özcan',    '2009-12-01', 'E', 'Konya Anadolu Lisesi',           10, 'Sayısal',       'Yusuf Özcan',      '05301001007', 'yusuf.ozcan@email.com',    'mert.ozcan@email.com',   '05331000007', 'Konya',     'Meram'),
  (13, 'Nisa',   'Koç',      '2007-08-30', 'K', 'Galatasaray Lisesi',             12, 'Sayısal',       'Bülent Koç',       '05301001008', 'bulent.koc@email.com',     'nisa.koc@email.com',     '05331000008', 'İstanbul',  'Beyoğlu'),
  (14, 'Barış',  'Aslan',    '2008-04-17', 'E', 'Antalya Anadolu Lisesi',         11, 'Sayısal',       'Mustafa Aslan',    '05301001009', 'mustafa.aslan@email.com',  'baris.aslan@email.com',  '05331000009', 'Antalya',   'Muratpaşa'),
  (15, 'Irmak',  'Gül',      '2009-06-23', 'K', 'Eskişehir Anadolu Lisesi',       10, 'Eşit Ağırlık', 'Gülten Gül',       '05301001010', 'gulten.gul@email.com',     'irmak.gul@email.com',    '05331000010', 'Eskişehir', 'Tepebaşı'),
  (16, 'Oğuz',   'Taş',      '2008-01-09', 'E', 'Trabzon Fen Lisesi',             11, 'Sayısal',       'Ahmet Taş',        '05301001011', 'ahmet.tas@email.com',      'oguz.tas@email.com',     '05331000011', 'Trabzon',   'Ortahisar'),
  (17, 'Pınar',  'Çetin',    '2009-10-14', 'K', 'Adana Anadolu Lisesi',           10, 'Sayısal',       'Leyla Çetin',      '05301001012', 'leyla.cetin@email.com',    'pinar.cetin@email.com',  '05331000012', 'Adana',     'Seyhan'),
  (18, 'Kerem',  'Erdoğan',  '2007-07-07', 'E', 'Robert Kolej',                   12, 'Sayısal',       'Tamer Erdoğan',    '05301001013', 'tamer.erdogan@email.com',  'kerem.erdogan@email.com','05331000013', 'İstanbul',  'Sarıyer'),
  (NULL,'Deniz', 'Aktaş',    '2009-03-25', 'K', 'Samsun Anadolu Lisesi',          10, 'Eşit Ağırlık', 'Sevinç Aktaş',     '05301001014', 'sevinc.aktas@email.com',   'deniz.aktas@email.com',  '05331000014', 'Samsun',    'İlkadım'),
  (NULL,'Emre',  'Çınar',    '2008-11-19', 'E', 'Kayseri Anadolu Lisesi',         11, 'Sayısal',       'Ramazan Çınar',    '05301001015', 'ramazan.cinar@email.com',  'emre.cinar@email.com',   '05331000015', 'Kayseri',   'Melikgazi'),
  (NULL,'Aylin', 'Duman',    '2009-08-08', 'K', 'Diyarbakır Anadolu Lisesi',      10, 'Sayısal',       'Sevda Duman',      '05301001016', 'sevda.duman@email.com',    'aylin.duman@email.com',  '05331000016', 'Diyarbakır','Bağlar'),
  (NULL,'Umut',  'Karaca',   '2007-05-21', 'E', 'Gaziantep Anadolu Lisesi',       12, 'Eşit Ağırlık', 'Veli Karaca',      '05301001017', 'veli.karaca@email.com',    'umut.karaca@email.com',  '05331000017', 'Gaziantep', 'Şahinbey'),
  (NULL,'Hande', 'Şimşek',   '2008-02-14', 'K', 'Mersin Anadolu Lisesi',          11, 'Sayısal',       'Canan Şimşek',     '05301001018', 'canan.simsek@email.com',   'hande.simsek@email.com', '05331000018', 'Mersin',    'Yenişehir'),
  (NULL,'Furkan','Bozkurt',   '2009-09-03', 'E', 'Malatya Fen Lisesi',             10, 'Sayısal',       'İbrahim Bozkurt',  '05301001019', 'ibrahim.bozkurt@email.com','furkan.bozkurt@email.com','05331000019','Malatya',   'Battalgazi'),
  (NULL,'Gizem', 'Özer',     '2008-12-27', 'K', 'Balıkesir Anadolu Lisesi',       11, 'Eşit Ağırlık', 'Hüseyin Özer',     '05301001020', 'huseyin.ozer@email.com',   'gizem.ozer@email.com',   '05331000020', 'Balıkesir', 'Karesi');


-- ============================================================
-- 3. EGITIM_KATEGORILERI (20 kayıt — 6'sı zaten seed'de var, 14 ek)
-- ============================================================
-- TRUNCATE TABLE `egitim_kategorileri`;

INSERT INTO `egitim_kategorileri`
  (`ust_kategori_id`, `ad`, `slug`, `aciklama`, `renk_kodu`, `sira`, `aktif`)
VALUES
  -- Ana kategoriler
  (NULL, 'DNA ve Genetik',         'dna-ve-genetik',         'DNA yapısı, gen ifadesi, kalıtım mekanizmaları',             '#2563EB', 1,  1),
  (NULL, 'Hücre Biyolojisi',       'hucre-biyolojisi',       'Hücre organelleri, bölünme ve membran olayları',              '#16A34A', 2,  1),
  (NULL, 'Mikrobiyoloji',           'mikrobiyoloji',           'Bakteri, virüs, mantar ve protist dünyası',                   '#9333EA', 3,  1),
  (NULL, 'Biyoteknoloji',           'biyoteknoloji',           'PCR, CRISPR, GDO ve uygulama alanları',                      '#DC2626', 4,  1),
  (NULL, 'Evrim ve Ekoloji',        'evrim-ve-ekoloji',        'Evrim teorisi, ekosistemler, biyoçeşitlilik',                 '#EA580C', 5,  1),
  (NULL, 'Laboratuvar Becerileri',  'laboratuvar-becerileri',  'Mikroskop kullanımı, preparasyon, güvenlik',                  '#0891B2', 6,  1),
  -- Alt kategoriler — DNA ve Genetik (id=1)
  (1,   'Mendelyen Genetik',        'mendelyen-genetik',       'Dominantlık, resesiflik, Mendel deneyleri',                   '#3B82F6', 7,  1),
  (1,   'Moleküler Genetik',        'moleküler-genetik',       'DNA replikasyonu, transkripsiyon, translasyon',               '#60A5FA', 8,  1),
  (1,   'Popülasyon Genetiği',      'populasyon-genetigi',     'Hardy-Weinberg dengesi, genetik sürüklenme',                  '#93C5FD', 9,  1),
  -- Alt kategoriler — Hücre Biyolojisi (id=2)
  (2,   'Hücre Bölünmesi',          'hucre-bolunmesi',         'Mitoz, mayoz ve hücre döngüsü kontrolü',                     '#22C55E', 10, 1),
  (2,   'Hücre Zarı Olayları',      'hucre-zari-olaylari',     'Difüzyon, osmoz, aktif taşıma',                              '#4ADE80', 11, 1),
  -- Alt kategoriler — Biyoteknoloji (id=4)
  (4,   'PCR Teknikleri',            'pcr-teknikleri',          'Polimeraz zincir reaksiyonu uygulama ve analizi',             '#EF4444', 12, 1),
  (4,   'CRISPR-Cas9',               'crispr-cas9',             'Gen düzenleme teknolojisinin temelleri',                      '#F87171', 13, 1),
  (4,   'Biyoinformatik',            'biyoinformatik',          'Genomik veri analizi, BLAST, sekans hizalama',               '#FCA5A5', 14, 1),
  -- Alt kategoriler — Laboratuvar Becerileri (id=6)
  (6,   'Mikroskopi',                'mikroskopi',              'Işık ve elektron mikroskobu kullanımı',                      '#06B6D4', 15, 1),
  (6,   'Elektroforez',              'elektroforez',            'Jel elektroforezi ile DNA ve protein analizi',               '#67E8F9', 16, 1),
  (6,   'Steril Teknik',             'steril-teknik',           'Aseptik çalışma yöntemleri ve laboratuvar güvenliği',        '#A5F3FC', 17, 1),
  -- Arşivlenmiş / pasif kategoriler
  (NULL, 'Biyofizik (Arşiv)',        'biyofizik-arsiv',         'Eski müfredat — artık aktif değil',                           '#9CA3AF', 18, 0),
  (NULL, 'Botanik',                  'botanik',                 'Bitki anatomisi ve fizyolojisi',                              '#65A30D', 19, 1),
  (NULL, 'Zooloji',                  'zooloji',                 'Hayvan sistemleri ve karşılaştırmalı anatomi',               '#A16207', 20, 1);


-- ============================================================
-- 4. EGITIMLER (20 kayıt)
--    egitmen_id: 3=Mehmet Çelik, 4=Fatma Arslan, 5=Emre Şahin, 20=Derya Yılmaz
-- ============================================================
-- TRUNCATE TABLE `egitimler`;

INSERT INTO `egitimler`
  (`kategori_id`, `egitmen_id`, `baslik`, `slug`, `kisa_aciklama`, `seviye`,
   `sure_saat`, `kontenjan`, `ucret`, `ucretsiz_mi`, `on_kosul`, `kazanimlar`,
   `durum`, `sertifika_var_mi`, `onculuk_sirasi`)
VALUES
  (1,  3, 'DNA Yapısı ve Replikasyon',       'dna-yapisi-replikasyon',       'Watson-Crick modeli, baz eşleşmesi ve DNA kopyalanma mekanizması',            'baslangic', 8.00,  16, 0.00,    1, NULL,               'DNA yapısını modelleyebilir, replikasyon basamaklarını sıralayabilir',       'yayin', 1, 10),
  (1,  3, 'Gen İfadesi: Transkripsiyon',     'gen-ifadesi-transkripsiyon',   'mRNA sentezi, RNA polimeraz ve promotör bölgesi',                             'orta',      6.00,  16, 0.00,    1, 'DNA Yapısı eğitimi', 'Transkripsiyon basamaklarını açıklar ve simüle eder',                        'yayin', 1, 8),
  (1,  4, 'Mendelyen Kalıtım',               'mendelyen-kalitim',            'Bezelye deneyleri, monohibrit ve dihibrit çaprazlamalar',                     'baslangic', 10.00, 20, 0.00,    1, NULL,               'Punnett karesi hazırlayabilir, fenotip-genotip oranı hesaplayabilir',        'yayin', 1, 9),
  (4,  3, 'PCR Uygulamaları',                'pcr-uygulamalari',             'Polimeraz zincir reaksiyonu: teori ve laboratuvar pratiği',                   'orta',      12.00, 12, 500.00,  0, 'Temel biyoloji bilgisi', 'PCR deneyi tasarlayabilir ve sonuçları yorumlayabilir',                    'yayin', 1, 7),
  (4,  5, 'CRISPR-Cas9 Temelleri',           'crispr-cas9-temelleri',        'Gen düzenleme teknolojisi: tarihçe, mekanizma ve etik',                       'ileri',     8.00,  10, 750.00,  0, 'Moleküler genetik bilgisi', 'CRISPR mekanizmasını açıklar, güncel uygulamaları değerlendirir',       'yayin', 1, 6),
  (2,  4, 'Hücre Zarı ve Taşıma',            'hucre-zari-tasima',            'Lipid çift katman, kanallar ve taşıyıcı proteinler',                          'baslangic', 6.00,  20, 0.00,    1, NULL,               'Pasif ve aktif taşımayı karşılaştırabilir, osmoz deneyi yapabilir',          'yayin', 1, 8),
  (2,  5, 'Mitoz ve Mayoz',                  'mitoz-ve-mayoz',               'Hücre döngüsü, kromozom hareketleri ve genetik çeşitlilik',                   'orta',      8.00,  18, 0.00,    1, 'Hücre biyolojisi giriş', 'Mitoz ve mayozu karşılaştırabilir, hücre döngüsü kontrolünü açıklar',   'yayin', 1, 7),
  (3,  20, 'Bakteriyel Genetik',             'bakteriyel-genetik',           'Bakteri genomu, plazmid, konjugasyon ve antibiyotik direnci',                 'orta',      10.00, 14, 300.00,  0, 'Temel mikrobiyoloji',  'Bakteri genetiği deneylerini tasarlayabilir',                                'yayin', 1, 5),
  (3,  20, 'Virüs Biyolojisi',               'virus-biyolojisi',             'Virüs yapısı, replikasyon döngüleri ve konakçı etkileşimi',                   'baslangic', 6.00,  20, 0.00,    1, NULL,               'Lityik ve lizojenik döngüyü karşılaştırabilir',                             'yayin', 0, 6),
  (6,  5, 'Mikroskopi Teknikleri',           'mikroskopi-teknikleri',         'Işık mikroskobu ayarları, preparat hazırlama ve boyama',                      'baslangic', 8.00,  12, 200.00,  0, NULL,               'Işık mikroskobu ile hücre preparatı hazırlayabilir',                        'yayin', 1, 9),
  (6,  3, 'Jel Elektroforezi',               'jel-elektroforezi',            'DNA fragmentlerinin agaroz jel elektroforeziyle ayrılması',                   'orta',      6.00,  12, 400.00,  0, 'PCR bilgisi önerilir', 'DNA bantlarını analiz edebilir, moleküler ağırlık hesaplayabilir',        'yayin', 1, 7),
  (4,  4, 'Biyoinformatiğe Giriş',           'biyoinformatik-giris',         'BLAST, NCBI veritabanları ve sekans hizalama algoritmalarına giriş',          'orta',      10.00, 15, 250.00,  0, 'Temel bilgisayar kullanımı', 'BLAST analizi yapabilir, genomik veritabanlarını kullanabilir',       'yayin', 0, 5),
  (1,  5, 'Epigenetik',                      'epigenetik',                   'DNA metilasyonu, histon modifikasyonu ve gen ifadesi düzenlemesi',             'ileri',     8.00,  10, 600.00,  0, 'Gen ifadesi eğitimi', 'Epigenetik mekanizmaları açıklar, güncel araştırmaları değerlendirir',    'yayin', 1, 4),
  (5,  20, 'Evrim Teorisi',                  'evrim-teorisi',                'Doğal seçilim, adaptasyon ve türleşme mekanizmaları',                         'baslangic', 8.00,  25, 0.00,    1, NULL,               'Doğal seçilimi örneklerle açıklayabilir, fosil kanıtlarını değerlendirir', 'yayin', 0, 6),
  (5,  20, 'Ekosistem Ekolojisi',            'ekosistem-ekolojisi',           'Enerji akışı, madde döngüleri ve biyoçeşitlilik',                             'baslangic', 6.00,  25, 0.00,    1, NULL,               'Besin zinciri ve enerji piramidi çizebilir',                                'yayin', 0, 5),
  (19, 4,  'Bitki Fizyolojisi',              'bitki-fizyolojisi',            'Fotosentez, solunum ve bitki hormonları',                                     'orta',      10.00, 16, 200.00,  0, 'Hücre biyolojisi',    'Fotosentez hız deneyi yapabilir, ışık ve karanlık reaksiyonları açıklar', 'yayin', 1, 3),
  (2,  5,  'Kök Hücre Biyolojisi',           'kok-hucre-biyolojisi',         'Embriyonik ve yetişkin kök hücreler, farklılaşma ve terapötik kullanım',     'ileri',     10.00, 8,  800.00,  0, 'Hücre biyolojisi + genetik', 'Kök hücre türlerini karşılaştırabilir, etik boyutları tartışabilir', 'yayin', 1, 3),
  (4,  3,  'Sentetik Biyoloji',              'sentetik-biyoloji',             'Biyolojik devrelerin tasarımı, iGEM projeleri ve uygulama örnekleri',         'ileri',     12.00, 8,  900.00,  0, 'Biyoteknoloji + programlama', 'Basit genetik devre tasarlayabilir, iGEM yarışmasını değerlendirir', 'taslak', 0, 2),
  (3,  20, 'Parazitoloji',                   'parazitoloji',                  'Parazitik organizmalar, yaşam döngüleri ve hastalık mekanizmaları',            'orta',      8.00,  14, 0.00,    1, 'Mikrobiyoloji giriş', 'Önemli insan parazitlerini sınıflandırabilir',                             'yayin', 0, 2),
  (6,  4,  'Steril Çalışma Teknikleri',      'steril-calisma-teknikleri',     'Aseptik teknik, otoklavlama, laminar hava akışlı kabin kullanımı',            'baslangic', 6.00,  12, 150.00,  0, NULL,               'Steril ortam hazırlayabilir, kontaminasyonu önleyebilir',                   'yayin', 1, 8);


-- ============================================================
-- 5. EGITIM_OTURUMLARI (20 kayıt)
-- ============================================================
-- TRUNCATE TABLE `egitim_oturumlari`;

INSERT INTO `egitim_oturumlari`
  (`egitim_id`, `egitmen_id`, `oturum_kodu`, `baslangic_tarihi`, `bitis_tarihi`,
   `baslangic_saati`, `bitis_saati`, `gun_paterni`, `format`, `lokasyon`,
   `kontenjan`, `kayit_bitis_tarihi`, `durum`)
VALUES
  (1,  3,  'DNA-2025-YAZ-01', '2025-07-07', '2025-07-11', '10:00:00', '13:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Oda 101', 16, '2025-07-01', 'tamamlandi'),
  (1,  3,  'DNA-2025-YAZ-02', '2025-08-04', '2025-08-08', '14:00:00', '17:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Oda 101', 16, '2025-07-28', 'tamamlandi'),
  (2,  3,  'TRN-2025-YAZ-01', '2025-07-14', '2025-07-18', '10:00:00', '13:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Oda 102', 16, '2025-07-07', 'tamamlandi'),
  (3,  4,  'MEN-2025-YAZ-01', '2025-07-21', '2025-08-01', '09:00:00', '12:00:00', 'Pazartesi-Çarşamba-Cuma', 'yuz_yuze', 'Kadıköy Lab. - Oda 103', 20, '2025-07-14', 'tamamlandi'),
  (4,  3,  'PCR-2025-GUZ-01', '2025-09-15', '2025-09-26', '13:00:00', '17:00:00', 'Pazartesi-Çarşamba', 'yuz_yuze', 'Kadıköy Lab. - Lab 201',  12, '2025-09-05', 'aktif'),
  (5,  5,  'CRS-2025-GUZ-01', '2025-10-06', '2025-10-17', '14:00:00', '17:00:00', 'Salı-Perşembe',      'yuz_yuze', 'Kadıköy Lab. - Lab 201',  10, '2025-09-26', 'planlandi'),
  (6,  4,  'ZAR-2025-YAZ-01', '2025-07-07', '2025-07-11', '14:00:00', '17:00:00', 'Pazartesi-Cuma',     'online',   NULL,                       20, '2025-07-01', 'tamamlandi'),
  (7,  5,  'MIT-2025-YAZ-01', '2025-07-28', '2025-08-08', '10:00:00', '13:00:00', 'Pazartesi-Çarşamba-Cuma', 'yuz_yuze', 'Kadıköy Lab. - Oda 102', 18, '2025-07-21', 'tamamlandi'),
  (8,  20, 'BAK-2025-GUZ-01', '2025-09-22', '2025-10-03', '10:00:00', '14:00:00', 'Pazartesi-Çarşamba', 'yuz_yuze', 'Kadıköy Lab. - Lab 202',  14, '2025-09-12', 'planlandi'),
  (9,  20, 'VIR-2025-YAZ-01', '2025-08-11', '2025-08-15', '10:00:00', '13:00:00', 'Pazartesi-Cuma',     'online',   NULL,                       20, '2025-08-04', 'tamamlandi'),
  (10, 5,  'MKR-2025-YAZ-01', '2025-07-07', '2025-07-11', '09:00:00', '13:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Lab 201',  12, '2025-07-01', 'tamamlandi'),
  (10, 5,  'MKR-2025-GUZ-01', '2025-10-13', '2025-10-17', '09:00:00', '13:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Lab 201',  12, '2025-10-06', 'planlandi'),
  (11, 3,  'ELK-2025-YAZ-01', '2025-08-18', '2025-08-22', '13:00:00', '17:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Lab 201',  12, '2025-08-11', 'tamamlandi'),
  (12, 4,  'BIO-2025-GUZ-01', '2025-09-29', '2025-10-10', '14:00:00', '17:00:00', 'Salı-Perşembe',      'online',   NULL,                       15, '2025-09-19', 'planlandi'),
  (13, 5,  'EPI-2025-GUZ-01', '2025-10-20', '2025-10-31', '14:00:00', '17:00:00', 'Pazartesi-Çarşamba', 'yuz_yuze', 'Kadıköy Lab. - Oda 101',  10, '2025-10-10', 'planlandi'),
  (14, 20, 'EVR-2025-YAZ-01', '2025-07-14', '2025-07-25', '10:00:00', '13:00:00', 'Pazartesi-Çarşamba-Cuma', 'online', NULL,                   25, '2025-07-07', 'tamamlandi'),
  (15, 20, 'EKO-2025-YAZ-01', '2025-08-04', '2025-08-08', '14:00:00', '17:00:00', 'Pazartesi-Cuma',     'online',   NULL,                       25, '2025-07-28', 'tamamlandi'),
  (16, 4,  'BIT-2025-GUZ-01', '2025-10-06', '2025-10-17', '10:00:00', '14:00:00', 'Salı-Perşembe',      'yuz_yuze', 'Kadıköy Lab. - Lab 202',  16, '2025-09-26', 'planlandi'),
  (19, 20, 'PAR-2025-GUZ-01', '2025-11-03', '2025-11-14', '13:00:00', '17:00:00', 'Pazartesi-Çarşamba', 'online',   NULL,                       14, '2025-10-24', 'planlandi'),
  (20, 4,  'STR-2025-YAZ-01', '2025-07-07', '2025-07-11', '09:00:00', '12:00:00', 'Pazartesi-Cuma',     'yuz_yuze', 'Kadıköy Lab. - Lab 202',  12, '2025-07-01', 'tamamlandi');


-- ============================================================
-- 6. BASVURULAR (20 kayıt)
-- ============================================================
-- TRUNCATE TABLE `basvurular`;

INSERT INTO `basvurular`
  (`ogrenci_id`, `oturum_id`, `basvuru_no`, `basvuru_tarihi`, `durum`,
   `onay_tarihi`, `onaylayan_id`, `odeme_durumu`, `odeme_tutari`, `odeme_tarihi`,
   `katilim_durumu`, `sertifika_no`, `sertifika_tarihi`, `veli_onayi`, `veli_onay_tarihi`)
VALUES
  (1,  1,  'BAS-20250001', '2025-06-25 10:00:00', 'tamamlandi', '2025-06-26 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0001', '2025-07-12', 1, '2025-06-25 14:00:00'),
  (2,  1,  'BAS-20250002', '2025-06-25 11:00:00', 'tamamlandi', '2025-06-26 09:05:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0002', '2025-07-12', 1, '2025-06-25 15:00:00'),
  (3,  2,  'BAS-20250003', '2025-07-10 09:30:00', 'tamamlandi', '2025-07-11 10:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0003', '2025-08-09', 1, '2025-07-10 13:00:00'),
  (4,  3,  'BAS-20250004', '2025-07-01 14:00:00', 'tamamlandi', '2025-07-02 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0004', '2025-07-19', 1, '2025-07-01 18:00:00'),
  (5,  4,  'BAS-20250005', '2025-07-05 10:00:00', 'tamamlandi', '2025-07-07 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0005', '2025-08-02', 1, '2025-07-05 12:00:00'),
  (6,  5,  'BAS-20250006', '2025-09-01 09:00:00', 'onaylandi',  '2025-09-02 10:00:00', 2, 'odendi',  500.00, '2025-09-02', 'belirsiz',   NULL,             NULL,         1, '2025-09-01 11:00:00'),
  (7,  5,  'BAS-20250007', '2025-09-01 10:00:00', 'onaylandi',  '2025-09-02 10:05:00', 2, 'odendi',  500.00, '2025-09-02', 'belirsiz',   NULL,             NULL,         1, '2025-09-01 12:00:00'),
  (8,  6,  'BAS-20250008', '2025-09-10 11:00:00', 'onaylandi',  '2025-09-11 09:00:00', 2, 'odendi',  750.00, '2025-09-11', 'belirsiz',   NULL,             NULL,         1, '2025-09-10 15:00:00'),
  (9,  7,  'BAS-20250009', '2025-06-28 14:00:00', 'tamamlandi', '2025-06-29 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0006', '2025-07-12', 1, '2025-06-28 16:00:00'),
  (10, 8,  'BAS-20250010', '2025-07-15 09:00:00', 'tamamlandi', '2025-07-16 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0007', '2025-08-09', 1, '2025-07-15 11:00:00'),
  (11, 10, 'BAS-20250011', '2025-06-20 10:00:00', 'tamamlandi', '2025-06-21 09:00:00', 2, 'odendi',  200.00, '2025-06-21', 'katildi',    'SERT-2025-0008', '2025-07-12', 1, '2025-06-20 13:00:00'),
  (12, 11, 'BAS-20250012', '2025-08-01 11:00:00', 'tamamlandi', '2025-08-02 10:00:00', 2, 'odendi',  400.00, '2025-08-02', 'katildi',    'SERT-2025-0009', '2025-08-23', 1, '2025-08-01 14:00:00'),
  (13, 13, 'BAS-20250013', '2025-08-05 09:00:00', 'tamamlandi', '2025-08-06 09:00:00', 2, 'odendi',  400.00, '2025-08-06', 'katilmadi',  NULL,             NULL,         1, '2025-08-05 10:00:00'),
  (14, 16, 'BAS-20250014', '2025-07-01 14:00:00', 'tamamlandi', '2025-07-02 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0010', '2025-07-26', 1, '2025-07-01 16:00:00'),
  (15, 17, 'BAS-20250015', '2025-07-20 10:00:00', 'tamamlandi', '2025-07-21 09:00:00', 2, 'muaf',    0.00,   NULL,         'katildi',    'SERT-2025-0011', '2025-08-09', 1, '2025-07-20 12:00:00'),
  (16, 9,  'BAS-20250016', '2025-09-05 09:00:00', 'beklemede',  NULL,                  NULL,'odenmedi', NULL, NULL,         'belirsiz',   NULL,             NULL,         0, NULL),
  (17, 14, 'BAS-20250017', '2025-09-12 11:00:00', 'onaylandi',  '2025-09-13 10:00:00', 2, 'odendi',  250.00, '2025-09-13', 'belirsiz',   NULL,             NULL,         1, '2025-09-12 15:00:00'),
  (18, 15, 'BAS-20250018', '2025-09-10 14:00:00', 'onaylandi',  '2025-09-11 09:00:00', 2, 'odendi',  600.00, '2025-09-11', 'belirsiz',   NULL,             NULL,         1, '2025-09-10 17:00:00'),
  (19, 18, 'BAS-20250019', '2025-09-15 10:00:00', 'beklemede',  NULL,                  NULL,'odenmedi', NULL, NULL,         'belirsiz',   NULL,             NULL,         0, NULL),
  (20, 20, 'BAS-20250020', '2025-06-22 09:00:00', 'tamamlandi', '2025-06-23 09:00:00', 2, 'odendi',  150.00, '2025-06-23', 'katildi',    'SERT-2025-0012', '2025-07-12', 1, '2025-06-22 12:00:00');


-- ============================================================
-- 7. DUYURULAR (20 kayıt)
-- ============================================================
-- TRUNCATE TABLE `duyurular`;

INSERT INTO `duyurular`
  (`yazar_id`, `baslik`, `ozet`, `tip`, `oncelik`, `hedef_kitle`,
   `yayinlanma_tarihi`, `bitis_tarihi`, `durum`, `sabit_mi`, `goruntuleme_sayisi`, `ilgili_egitim_id`)
VALUES
  (2, '2025 Yaz Dönemi Kayıtları Açıldı',          'Yaz dönemi eğitimlerimize başvurular başlamıştır.',                                         'egitim',  'yuksek',  'herkese',      '2025-05-15 09:00:00', '2025-08-31 23:59:00', 'yayin', 1, 1520, NULL),
  (2, 'Güz Dönemi Programı Yayınlandı',             'Eylül-Kasım 2025 eğitim takvimi ve kontenjanlar açıklandı.',                               'egitim',  'yuksek',  'herkese',      '2025-08-01 09:00:00', '2025-11-30 23:59:00', 'yayin', 1, 843,  NULL),
  (1, 'Sistem Bakımı: 22 Haziran 02:00-04:00',      'Portal planlı bakım nedeniyle geçici olarak kapalı olacaktır.',                             'acil',    'kritik',  'herkese',      '2025-06-20 14:00:00', '2025-06-22 06:00:00', 'arsiv', 0, 312,  NULL),
  (3, 'PCR Eğitimi Kontenjanı Doldu',               'GÜZ-01 oturumunun tüm kontenjanları dolmuştur. Bekleme listesi aktiftir.',                  'egitim',  'yuksek',  'herkese',      '2025-09-03 10:00:00', NULL,                  'yayin', 0, 567,  4),
  (4, 'CRISPR Eğitimi Yeni Oturum Duyurusu',        'CRISPR-Cas9 eğitiminin ikinci oturumu Ekim ayında başlayacak.',                            'egitim',  'normal',  'herkese',      '2025-09-05 09:00:00', NULL,                  'yayin', 0, 423,  5),
  (2, 'TÜBİTAK 2204-A Proje Başvuruları',          'Lise öğrencileri için ulusal proje yarışması başvuruları açıldı. Danışmanlık veriyoruz.',    'etkinlik','yuksek',  'ogrencilere',  '2025-09-10 09:00:00', '2025-10-31 23:59:00', 'yayin', 0, 789,  NULL),
  (20, 'Mikrobiyoloji Semineri: Antibiyotik Direnci','Ücretsiz online seminer — 5 Ekim 2025, saat 15:00',                                        'etkinlik','normal',  'herkese',      '2025-09-15 09:00:00', '2025-10-05 18:00:00', 'yayin', 0, 634,  8),
  (5,  'Biyoinformatik Kursuna Ön Kayıt Başladı',   'BLAST ve genomik analiz eğitimimize ön kayıtlar açılmıştır.',                              'egitim',  'normal',  'herkese',      '2025-09-01 09:00:00', NULL,                  'yayin', 0, 298,  12),
  (3,  'Jel Elektroforezi Eğitimi Sonuçları',        'Temmuz 2025 oturumunu tamamlayan öğrencilerimizi tebrik ediyoruz!',                       'duyuru',  'normal',  'ogrencilere',  '2025-08-25 10:00:00', NULL,                  'yayin', 0, 412,  11),
  (2,  'Veli Bilgilendirme Toplantısı',              '10 Ekim 2025 Cuma, saat 14:00 — Kadıköy Laboratuvarı Konferans Salonu',                   'etkinlik','yuksek',  'herkese',      '2025-09-20 09:00:00', '2025-10-10 16:00:00', 'yayin', 0, 521,  NULL),
  (1,  'Gizlilik Politikası Güncellendi',            'KVKK kapsamında gizlilik politikamız güncellenmiştir. Lütfen inceleyiniz.',                 'genel',   'normal',  'herkese',      '2025-06-01 09:00:00', NULL,                  'yayin', 0, 234,  NULL),
  (4,  'Evrim Eğitimi Online Oturumu Tamamlandı',   'Katılan tüm öğrencilerimize teşekkürler. Sertifikalar e-posta ile gönderildi.',             'egitim',  'normal',  'ogrencilere',  '2025-07-26 10:00:00', NULL,                  'yayin', 0, 198,  14),
  (20, 'Yeni Eğitmen: Dr. Derya Yılmaz',            'Mikrobiyoloji ve parazitoloji alanında uzman Dr. Yılmaz ekibimize katıldı.',               'duyuru',  'normal',  'herkese',      '2025-06-10 09:00:00', NULL,                  'yayin', 0, 876,  NULL),
  (2,  'Burs Başvuruları — Son Gün: 30 Eylül',      'Maddi imkânı kısıtlı öğrencilerimiz için ücretli eğitimlerde burs desteği sunuyoruz.',    'duyuru',  'yuksek',  'ogrencilere',  '2025-09-01 09:00:00', '2025-09-30 23:59:00', 'yayin', 1, 1102, NULL),
  (5,  'Kök Hücre Eğitimi — Erken Kayıt İndirimi', 'Kasım başlamadan kayıt yaptıranlara %20 indirim uygulanacaktır.',                          'egitim',  'normal',  'herkese',      '2025-09-25 09:00:00', '2025-10-15 23:59:00', 'yayin', 0, 345,  17),
  (3,  'DNA Eğitimi 2. Oturum: Müfredat Güncellendi','Ağustos oturumunda CRISPR uygulamalarına yer verilecek.',                                 'egitim',  'normal',  'egitim',       '2025-07-20 09:00:00', '2025-08-08 23:59:00', 'arsiv', 0, 267,  1),
  (2,  'Laboratuvar Güvenlik Prosedürleri Güncellendi','Yeni güvenlik kuralları ve acil durum planı tüm katılımcılara bildirildi.',              'acil',    'kritik',  'egitimlilere', '2025-07-01 09:00:00', NULL,                  'yayin', 0, 445,  NULL),
  (4,  'Bitki Fizyolojisi Eğitimi — Materyal Listesi','Eğitim öncesi hazırlanması gereken materyal listesi yayınlandı.',                       'egitim',  'normal',  'egitimlilere', '2025-09-28 09:00:00', NULL,                  'yayin', 0, 189,  16),
  (1,  '2026 Kış Dönemi Planlaması Başlıyor',       'Kış dönemi eğitim programı için görüş ve öneri formunu doldurunuz.',                       'genel',   'normal',  'herkese',      '2025-10-01 09:00:00', '2025-10-31 23:59:00', 'yayin', 0, 156,  NULL),
  (20, 'Parazitoloji Eğitimi İçin Ön Kayıt',        'Kasım 2025 oturumuna ön kayıt yaptırarak yerinizi garantileyin.',                         'egitim',  'normal',  'herkese',      '2025-10-01 09:00:00', '2025-10-24 23:59:00', 'yayin', 0, 213,  19);


-- ============================================================
-- 8. ILETISIM_MESAJLARI (20 kayıt)
-- ============================================================
-- TRUNCATE TABLE `iletisim_mesajlari`;

INSERT INTO `iletisim_mesajlari`
  (`kullanici_id`, `gonderen_ad`, `gonderen_soyad`, `gonderen_email`, `gonderen_telefon`,
   `konu`, `mesaj`, `kategori`, `durum`,
   `atanan_kullanici_id`, `yanit`, `yanit_tarihi`, `yanit_veren_id`, `ip_adresi`)
VALUES
  (NULL, 'Seda',    'Güneş',   'seda.gunes@email.com',    '05301110001', 'DNA Eğitimi Hakkında Bilgi',        'Merhaba, 10. sınıf öğrencisiyim. DNA eğitimine kayıt olmak istiyorum, hangi ön koşullar var?',                              'egitim_basvuru',  'yanitlandi',        2, 'Merhaba Seda Hanım, DNA Yapısı eğitimimize ön koşul bulunmamaktadır. Dilediğiniz zaman kayıt olabilirsiniz.', '2025-06-10 09:00:00', 2, '95.70.100.1'),
  (NULL, 'Murat',   'Erdem',   'murat.erdem@email.com',   '05301110002', 'PCR Eğitimi Burs Talebi',           'Burs programına nasıl başvurabilirim? PCR eğitimine katılmak istiyorum ama ücret konusunda yardıma ihtiyacım var.',         'egitim_basvuru',  'yanitlandi',        2, 'Bursa başvuru formunu web sitemizin İletişim sayfasından ulaşabilirsiniz. Başvurunuzu aldık.', '2025-09-02 10:00:00', 2, '85.34.112.5'),
  (6,  'Ali',       'Demir',   'ali.demir@email.com',     '05331000001', 'Sertifika Teslim Tarihi',           'DNA eğitimini tamamladım. Sertifikam ne zaman gelecek?',                                                                   'genel_bilgi',     'yanitlandi',        4, 'Sertifikanız e-posta adresinize 5 iş günü içinde gönderilecektir.', '2025-07-13 10:00:00', 4, '78.162.50.3'),
  (NULL, 'Arzu',   'Şen',      'arzu.sen@email.com',      '05301110003', 'Kurumsal İşbirliği Teklifi',        'Lisemiz için grup eğitimi düzenlenebilir mi? 30 öğrencimiz var.',                                                          'isbirligi',       'yanitlandi',        1, 'Kurumsal teklifiniz için teşekkürler. Detaylı görüşmek üzere sizi arayacağız.', '2025-06-15 11:00:00', 1, '213.14.200.7'),
  (NULL, 'Tuncay', 'Avcı',     'tuncay.avci@email.com',   '05301110004', 'Online Eğitimlerde Teknik Sorun',   'Virüs Biyolojisi online eğitimine bağlanamıyorum. Zoom linki çalışmıyor.',                                                 'teknik_destek',   'yanitlandi',        5, 'Yedek Zoom linkini e-posta adresinize ilettik. Sorun yaşamaya devam ederseniz lütfen tekrar yazın.', '2025-08-11 14:30:00', 5, '188.119.45.20'),
  (NULL, 'Lale',   'Doğan',    'lale.dogan@email.com',    '05301110005', 'CRISPR Eğitimi Yaş Sınırı',         'Oğlum 9. sınıf, CRISPR eğitimine kayıt olabilir mi?',                                                                     'egitim_basvuru',  'yanitlandi',        2, 'CRISPR eğitimimiz ileri seviye olup 11-12. sınıf öğrencilerine önerilmektedir. Önce DNA ve Genetik eğitimlerimizden başlamasını öneririz.', '2025-09-08 10:00:00', 2, '78.162.51.10'),
  (8,  'Burak',    'Yıldız',   'burak.yildiz@email.com',  '05331000003', 'CRISPR Ödev Kaynakları',            'Eğitimde bahsedilen Jennifer Doudna makalelerine nasıl ulaşabilirim?',                                                    'genel_bilgi',     'yanitlandi',        3, 'PubMed üzerinden erişebilirsiniz. Okul kütüphanenizden de yardım alabilirsiniz.', '2025-10-08 15:00:00', 3, '95.70.100.5'),
  (NULL, 'Hüseyin','Kara',      'huseyin.kara@email.com',  '05301110006', 'Toplu Kayıt Faturası',              'Şirketimiz 5 öğrenci için kayıt yaptıracak. Fatura kesilir mi?',                                                          'genel_bilgi',     'yanitlandi',        1, 'Fatura düzenleyebiliyoruz. Vergi bilgilerinizi muhasebe@genlaboratuvari.com adresine iletiniz.', '2025-09-18 11:00:00', 1, '31.142.80.2'),
  (NULL, 'Dilek',  'Polat',     'dilek.polat@email.com',   '05301110007', 'Eğitim İçerik Önerisi',             'Genetik hastalıklar konusunda bir eğitim açılabilir mi? Çok talep var.',                                                  'oneri',           'okundu',            2, NULL, NULL, NULL, '46.2.130.14'),
  (11, 'Selin',    'Aydın',    'selin.aydın@email.com',   '05331000006', 'Ödeme Makbuzu',                     'Mikroskopi eğitimi ödememi yaptım ama makbuz alamadım.',                                                                  'teknik_destek',   'yanitlandi',        5, 'Makbuzunuzu e-posta adresinize yeniden gönderdik. Spam klasörünüzü de kontrol ediniz.', '2025-06-22 09:00:00', 5, '78.162.52.8'),
  (NULL, 'Serkan', 'Uçar',      'serkan.ucar@email.com',   '05301110008', 'Eğitmenler Hakkında Bilgi',         'Eğitmenlerin akademik özgeçmişlerini nereden inceleyebilirim?',                                                           'genel_bilgi',     'yanitlandi',        2, 'Web sitemizin Ekibimiz sayfasında tüm eğitmenlerimizin profilleri yer almaktadır.', '2025-07-05 13:00:00', 2, '95.1.210.33'),
  (NULL, 'Berna',  'Çelik',     'berna.celik@email.com',   '05301110009', 'Evrim Eğitimi Sertifikası',         'Online evrim eğitimini tamamladım. Sertifika veriliyor mu?',                                                             'egitim_basvuru',  'yanitlandi',        4, 'Evrim eğitimimizde sertifika verilmemektedir. Sertifikalı eğitimlerimizi web sitemizden inceleyebilirsiniz.', '2025-07-28 14:00:00', 4, '188.119.46.5'),
  (NULL, 'Okan',   'Demirci',   'okan.demirci@email.com',  '05301110010', 'Şikayet: Eğitim İptali',           'Kayıtlandığım eğitim iptal edildi ama ücret iadesi yapılmadı.',                                                          'sikayet',         'yanitlandi',        1, 'Özür dileriz. İade işleminiz 3 iş günü içinde tamamlanacak. Referans: IAD-2025-042', '2025-09-22 10:00:00', 1, '213.14.201.9'),
  (13, 'Nisa',     'Koç',      'nisa.koc@email.com',      '05331000008', 'Jel Elektroforezi Devamsızlık',     'Hastalık nedeniyle bir gün katılamadım. Telafi imkânı var mı?',                                                          'egitim_basvuru',  'yanitlandi',        3, 'Hastalık durumunda bir sonraki oturumda telafi hakkınız bulunmaktadır. Randevu için lütfen arayın.', '2025-08-20 11:00:00', 3, '78.162.53.2'),
  (NULL, 'Gülsüm', 'Arslan',    'gülsüm.arslan@email.com', '05301110011', 'Eğitim Takvimi Sorusu',            'Güz döneminde hafta sonu eğitim seçeneği var mı?',                                                                        'genel_bilgi',     'okunmadi',          NULL, NULL, NULL, NULL, '31.142.81.5'),
  (NULL, 'Tarkan', 'Özkan',     'tarkan.ozkan@email.com',  '05301110012', 'Medyaya Yönelik Bilgi Talebi',     'Eğitim merkeziniz hakkında röportaj yapmak istiyoruz. Nasıl iletişime geçebiliriz?',                                    'isbirligi',       'yanitlandi',        1, 'Basın talepleriniz için basin@genlaboratuvari.com adresimize başvurabilirsiniz.', '2025-09-25 09:00:00', 1, '85.34.113.8'),
  (17, 'Pınar',    'Çetin',    'pinar.cetin@email.com',   '05331000012', 'Biyoinformatik Eğitimi Zorluk',    'Eğitim materyalleri çok teknik geliyor. Ek kaynak önerebilir misiniz?',                                                  'genel_bilgi',     'yanitlandi',        4, 'Eğitmenimiz size ek kaynak listesi gönderecektir. Ayrıca öğrenci portalındaki kaynaklara göz atabilirsiniz.', '2025-10-01 14:00:00', 4, '95.70.101.3'),
  (NULL, 'Ece',    'Kaplan',    'ece.kaplan@email.com',    '05301110013', 'İkiz Kardeş İndirimi',             'İkiz kardeşimle birlikte kayıt olacağız, indirim imkânı var mı?',                                                        'egitim_basvuru',  'yanitlandi',        2, 'Aynı anda kayıt olan aile bireylerinde %10 indirim uygulanmaktadır.', '2025-09-28 10:00:00', 2, '46.2.131.7'),
  (NULL, 'Volkan', 'Saraç',     'volkan.sarac@email.com',  '05301110014', 'Staj ve Gönüllülük Fırsatları',    'Üniversite öğrencisiyim, laboratuvarınızda staj veya gönüllü çalışabilir miyim?',                                        'isbirligi',       'yanit_bekleniyor',  1, NULL, NULL, NULL, '188.119.47.1'),
  (NULL, 'Melis',  'Tunç',      'melis.tunc@email.com',    '05301110015', 'Eğitim Kiti Teslimatı',            'PCR eğitimi için gönderilen deney kiti henüz ulaşmadı. Kargo takip numarası alabilir miyim?',                           'teknik_destek',   'yanitlandi',        5, 'Kargo takip numaranız: TR-2025-PCR-00421. Tahmini teslimat 2-3 iş günüdür.', '2025-09-12 15:00:00', 5, '95.70.102.6');

-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;
-- Seed verisi yükleme tamamlandı.
-- Her tabloda 20 örnek kayıt oluşturuldu.
-- ============================================================

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