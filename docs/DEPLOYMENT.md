# Deployment Guide - Heft Workout Tracker

Panduan lengkap untuk deploy aplikasi Heft ke Docker dan berbagai platform cloud.

## Daftar Isi

1. [Build Docker Image](#1-build-docker-image)
2. [Test Lokal dengan Docker](#2-test-lokal-dengan-docker)
3. [Deploy ke Google Cloud Run](#3-deploy-ke-google-cloud-run)
4. [Deploy ke DigitalOcean / VPS](#4-deploy-ke-digitalocean--vps)
5. [Deploy ke Railway / Render](#5-deploy-ke-railway--render)
6. [Setup Custom Domain & SSL](#6-setup-custom-domain--ssl)
7. [Update Firebase Authorized Origins](#7-update-firebase-authorized-origins)
8. [Troubleshooting](#troubleshooting)

---

## 1. Build Docker Image

### Prasyarat

- Docker Desktop terinstall: https://www.docker.com/products/docker-desktop
- File konfigurasi sudah lengkap:
  - `lib/firebase_options.dart` (sudah ada API key)
  - `web/index.html` (sudah ada Web Client ID)

### Build

```bash
# Build image
docker build -t heft-web:latest .

# Cek image
docker images | grep heft-web
```

Build pertama kali akan lama (5-10 menit) karena download Flutter SDK image. Build berikutnya cepat karena cache.

---

## 2. Test Lokal dengan Docker

### Cara A: Docker Compose (Recommended)

```bash
# Start container
docker-compose up -d

# Cek status
docker-compose ps

# Lihat logs
docker-compose logs -f heft-web

# Stop
docker-compose down
```

App akan jalan di **http://localhost:8080**

### Cara B: Docker Run

```bash
docker run -d -p 8080:80 --name heft-web heft-web:latest
```

### Update Authorized Origin

Tambahkan `http://localhost:8080` ke Google Cloud Console OAuth client (lihat section [Update Firebase](#7-update-firebase-authorized-origins)).

---

## 3. Deploy ke Google Cloud Run

Cara paling mudah dan murah (free tier 2M requests/bulan).

### Setup

```bash
# Install gcloud CLI
brew install google-cloud-sdk

# Login
gcloud auth login

# Set project
gcloud config set project workout-tracker-ead9b

# Enable APIs
gcloud services enable run.googleapis.com cloudbuild.googleapis.com
```

### Deploy

```bash
# Build dan push ke Google Container Registry, lalu deploy
gcloud run deploy heft-web \
  --source . \
  --region asia-southeast2 \
  --platform managed \
  --allow-unauthenticated \
  --port 80 \
  --memory 256Mi \
  --max-instances 10
```

Setelah selesai, akan muncul URL seperti `https://heft-web-xxxxx-uc.a.run.app`.

### Update Authorized Origin

Tambahkan URL Cloud Run ke Authorized JavaScript origins di Google Cloud Console.

---

## 4. Deploy ke DigitalOcean / VPS

Untuk VPS umum (Ubuntu/Debian).

### Setup Server

```bash
# SSH ke server
ssh root@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com | sh
apt install docker-compose -y

# Clone repo
git clone <your-repo-url> heft
cd heft
```

### Upload Firebase Config

`lib/firebase_options.dart` di-gitignore. Upload manual:

```bash
# Dari mesin lokal
scp lib/firebase_options.dart root@your-server-ip:/root/heft/lib/
```

### Deploy

```bash
# Build dan run
docker-compose up -d --build

# Cek
curl http://localhost:8080/health
```

### Setup Reverse Proxy (Nginx + SSL)

Install Nginx dan Certbot di host:

```bash
apt install nginx certbot python3-certbot-nginx -y
```

Buat config `/etc/nginx/sites-available/heft`:

```nginx
server {
    listen 80;
    server_name heft.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable dan get SSL:

```bash
ln -s /etc/nginx/sites-available/heft /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
certbot --nginx -d heft.yourdomain.com
```

---

## 5. Deploy ke Railway / Render

Platform PaaS termudah, tinggal connect Git.

### Railway

1. Buka https://railway.app
2. **New Project** → **Deploy from GitHub repo**
3. Pilih repo Heft
4. Railway auto-detect Dockerfile dan deploy
5. Generate domain di **Settings** → **Networking**

### Render

1. Buka https://render.com
2. **New** → **Web Service** → connect GitHub
3. Pilih repo Heft
4. Pilih:
   - **Environment**: Docker
   - **Region**: Singapore (terdekat dari Indonesia)
   - **Plan**: Free
5. Click **Create Web Service**

Render auto-build dari Dockerfile dan kasih domain `xxx.onrender.com`.

---

## 6. Setup Custom Domain & SSL

### Untuk Cloud Run

```bash
gcloud run domain-mappings create \
  --service heft-web \
  --domain heft.yourdomain.com \
  --region asia-southeast2
```

Tambahkan DNS record sesuai instruksi yang muncul.

### Untuk VPS

Sudah dijelaskan di section 4 (Certbot otomatis).

### Untuk Railway/Render

Settings → Domains → Add Custom Domain → ikuti instruksi DNS.

---

## 7. Update Firebase Authorized Origins

**WAJIB** setiap kali deploy ke domain baru, jika tidak Google Sign-In akan error `origin_mismatch`.

### Langkah

1. Buka https://console.cloud.google.com/apis/credentials?project=workout-tracker-ead9b
2. Klik OAuth 2.0 Client ID: **Web client (auto created by Google Service)**
3. Di **Authorized JavaScript origins**, tambahkan SEMUA domain yang akan dipakai:
   ```
   http://localhost:8080
   https://heft-web-xxxxx-uc.a.run.app
   https://heft.yourdomain.com
   ```
4. **Save**
5. Tunggu 5-15 menit untuk propagasi

### Update Authorized Domains di Firebase

1. Buka https://console.firebase.google.com/project/workout-tracker-ead9b/authentication/settings
2. Tab **Authorized domains** → Add domain
3. Tambahkan domain produksi (tanpa `https://`)

---

## Troubleshooting

### Error: `Cannot connect to Docker daemon`

Docker Desktop belum jalan. Buka Docker Desktop dari Applications.

### Error: `firebase_options.dart` not found saat build

File di-gitignore. Pastikan ada di working directory sebelum `docker build`.

```bash
ls lib/firebase_options.dart
```

### Error: `origin_mismatch` di production

Domain belum ditambah ke Authorized JavaScript origins. Lihat section 7.

### Build Docker lambat

Build pertama kali memang lama (download Flutter SDK ~2GB). Gunakan BuildKit cache:

```bash
DOCKER_BUILDKIT=1 docker build -t heft-web:latest .
```

### Container exit langsung

Cek logs:

```bash
docker logs heft-web
```

Biasanya karena nginx config error.

### App loading tapi blank

1. Buka DevTools (F12) → Console untuk lihat error
2. Cek Network tab — apakah `main.dart.js` ter-load?
3. Hard refresh: Cmd+Shift+R

### Image size terlalu besar

Image final ~50MB (nginx:alpine + build/web). Jika lebih, cek `.dockerignore` apakah exclude `build/`, `.dart_tool/`, dll.

---

## Estimasi Biaya

| Platform | Free Tier | Setelah Free Tier |
|----------|-----------|-------------------|
| Google Cloud Run | 2M requests/bulan | ~$0.40/M requests |
| Railway | $5 kredit/bulan | $5/bulan minimum |
| Render | 750 jam/bulan (with sleep) | $7/bulan untuk always-on |
| DigitalOcean Droplet | - | $4-6/bulan |
| Firebase Hosting | 10GB transfer/bulan | $0.15/GB |

Untuk traffic kecil-menengah, **Cloud Run** atau **Firebase Hosting** paling murah.

---

## Alternatif: Firebase Hosting (Tanpa Docker)

Jika tidak butuh Docker, deploy langsung ke Firebase Hosting (gratis):

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Init hosting (sekali saja)
firebase init hosting
# Pilih: build/web sebagai public directory
# Configure as SPA: Yes
# Set up automatic builds: No

# Deploy
flutter build web --release
firebase deploy --only hosting
```

Akan dapat URL `https://workout-tracker-ead9b.web.app` gratis dengan SSL.

---

## Quick Reference

```bash
# Local Docker
docker-compose up -d
# → http://localhost:8080

# Cloud Run (paling cepat)
gcloud run deploy heft-web --source . --region asia-southeast2 --allow-unauthenticated

# Firebase Hosting (paling murah)
flutter build web --release && firebase deploy --only hosting

# VPS dengan SSL
docker-compose up -d --build
certbot --nginx -d heft.yourdomain.com
```
