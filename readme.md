## Generate Local SSL Certificate

Project ini punya 2 script:

- `generate-ca.sh`: membuat Root CA lokal (`ca-key.pem` dan `ca.pem`).
- `generate-cert.sh`: membuat sertifikat domain yang ditandatangani Root CA.

Alur penggunaan:

1. Jalankan `generate-ca.sh` sekali untuk membuat CA.
2. Jalankan `generate-cert.sh` setiap kali ingin membuat cert domain baru.

## Prasyarat

- `openssl` sudah terpasang.
- Untuk membuat cert domain, file CA harus tersedia:
	- `ca.pem`
	- `ca-key.pem`
- Opsional: `password.txt` untuk pass phrase CA key.

## Buat Root CA (Sekali Saja)

```bash
chmod +x generate-ca.sh
./generate-ca.sh
```

Input pada `generate-ca.sh`:

1. `Input CA Common Name` (default: `Local Root CA`)
2. `Masa berlaku CA dalam hari` (default: `3650`)
3. `Masukan pass phrase baru untuk CA key`
4. `Ulangi pass phrase`
5. `Simpan pass phrase ke password.txt (y/N)`

Catatan:

- Jika `ca-key.pem` atau `ca.pem` sudah ada, script akan minta konfirmasi overwrite.
- Jika CA dibuat ulang, file `ca.srl` lama akan dihapus otomatis agar serial cert baru konsisten.

## Buat Sertifikat Domain

```bash
chmod +x generate-cert.sh
./generate-cert.sh
```

## Input Interaktif

Saat menjalankan script, Anda akan diminta:

1. `Input domain name`
	- Contoh: `cuydev.local`
2. `Input DNS tambahan` (optional)
	- Isi beberapa DNS dipisahkan koma.
	- Contoh: `api.cuydev.local,admin.cuydev.local`
3. `Input IP` (optional, default `127.0.0.1`)
4. `Nama sertifikat berdasarkan domain (y/N)`
	- `y`: nama file cert menyesuaikan domain
	- `N`/kosong: nama file default

### Pass Phrase Behavior

- Jika file `password.txt` ada dan tidak kosong, script otomatis pakai file tersebut (tanpa prompt pass phrase).
- Jika `password.txt` tidak ada, script akan meminta input pass phrase CA key secara manual.

## SAN (Subject Alternative Name)

Default SAN selalu berisi:

- `DNS:<domain>`
- `DNS:*.<domain>`
- `IP:<ip>` (default `127.0.0.1` jika input IP kosong)

Jika mengisi DNS tambahan, nilainya akan ditambahkan ke SAN.

## Lokasi Output

Output selalu dibuat di direktori kerja saat script dijalankan:

```text
$PWD/generated/<domain>
```

Contoh jika domain `cuydev.local`:

```text
generated/cuydev.local/
```

## File Output

File yang selalu dibuat:

- private key
- CSR (`cert.csr`)
- SAN config (`extfile.cnf`)
- public cert
- fullchain

### Mode 1: `Nama sertifikat berdasarkan domain = y`

Nama file memakai bagian sebelum titik pertama domain.

Contoh domain `cuydev.local` menjadi base `cuydev`:

- `cuydev-key.pem` (private key)
- `cert.csr`
- `extfile.cnf`
- `cuydev-pub.pem` (public cert)
- `cuydev.pem` (fullchain)

### Mode 2: `Nama sertifikat berdasarkan domain = N` (default)

- `cert-key.pem` (private key)
- `cert.csr`
- `extfile.cnf`
- `cert.pem` (public cert)
- `fullchain.pem` (fullchain)

## Git Ignore

File `.gitignore` sudah mengabaikan file sensitif/hasil generate seperti:

- `generated/`
- `password.txt`
- file CA tertentu
