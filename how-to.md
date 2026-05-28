# Experimental OpenSSL

Panduan ini menjelaskan alur penggunaan script otomatis:

- generate-ca.sh
- generate-cert.sh

## 1) Buat Root CA

Jalankan sekali untuk membuat CA lokal:

```bash
chmod +x generate-ca.sh
./generate-ca.sh
```

Output:

- ca-key.pem
- ca.pem

Input yang diminta:

- CA Common Name (default: Local Root CA)
- Masa berlaku CA dalam hari (default: 3650)
- Pass phrase baru untuk CA key
- Konfirmasi pass phrase
- Simpan pass phrase ke password.txt (opsional)

Catatan:

- Jika ca-key.pem atau ca.pem sudah ada, script minta konfirmasi overwrite.
- Jika CA dibuat ulang, ca.srl lama dihapus otomatis.

## 2) Install CA ke Sistem

Setelah CA dibuat, install `ca.pem` ke sistem agar browser percaya pada cert lokal yang ditandatangani CA ini.

### macOS

1. Buka Keychain Access.
2. Pilih System.
3. Import file `ca.pem`.
4. Buka info sertifikat lalu set Trust menjadi Always Trust.
5. Simpan perubahan (masukkan password admin jika diminta).

### Windows

1. Buka Manage User Certificates.
2. Pilih Trusted Root Certification Authorities > Certificates.
3. Import `ca.pem`.
4. Pastikan sertifikat masuk ke Trusted Root Certification Authorities.

### Linux

1. Salin `ca.pem` ke direktori CA lokal distro Anda (umumnya `/usr/local/share/ca-certificates/`).
2. Jalankan:

```bash
sudo update-ca-certificates
```

## 3) Buat Sertifikat Domain

Jalankan kapan saja untuk domain baru:

```bash
chmod +x generate-cert.sh
./generate-cert.sh
```

Input yang diminta:

- Domain name (contoh: cuydev.local)
- DNS tambahan (opsional, pisahkan koma)
- IP (opsional, default 127.0.0.1)
- Nama sertifikat berdasarkan domain (y/N)

Tentang pass phrase:

- Jika `password.txt` ada dan tidak kosong, script otomatis pakai pass phrase dari file itu.
- Jika `password.txt` tidak ada, script minta input pass phrase manual.

SAN default:

- DNS:domain
- DNS:*.domain
- IP:127.0.0.1 (atau IP input)

## 4) Lokasi dan Nama Output

Output disimpan di:

```text
$PWD/generated/<domain>
```

Jika pilih `Nama sertifikat berdasarkan domain = y`, contoh domain `cuydev.local`:

- cuydev-key.pem
- cuydev-pub.pem
- cuydev.pem (fullchain)
- cert.csr
- extfile.cnf

Jika pilih `N` (default):

- cert-key.pem
- cert.pem
- fullchain.pem
- cert.csr
- extfile.cnf

## 5) Contoh Nginx

Jika menggunakan mode default (`N`):

```nginx
server {
  listen 443 ssl;
  server_name *.cuydev.local;

  ssl_certificate /path/to/generated/cuydev.local/fullchain.pem;
  ssl_certificate_key /path/to/generated/cuydev.local/cert-key.pem;
}
```

Jika menggunakan mode nama domain (`y`), sesuaikan file:

- ssl_certificate: `/path/to/generated/cuydev.local/cuydev.pem`
- ssl_certificate_key: `/path/to/generated/cuydev.local/cuydev-key.pem`
