# BAB IV
# DESIGN SISTEM

Bab ini menjelaskan tahap perancangan sistem secara menyeluruh, meliputi arsitektur sistem, perancangan alur sistem, perancangan basis data, serta rancangan fitur sistem untuk ketiga modul.

## 4.1 Arsitektur Sistem

Arsitektur sistem dirancang menggunakan pola client-server dengan pendekatan modular. Seluruh komponen sistem dibagi menjadi tiga lapisan utama: presentasi (frontend), logika bisnis (backend), dan persistensi data (database). Sistem ini terdiri dari tiga modul utama yang saling terintegrasi, yaitu Modul Web Administrator (SvelteKit), Modul Mobile Customer (Flutter), dan Modul Mobile Kurir (Flutter).

> **_[Gambar 4.1 Arsitektur Sistem]_**
> ![Arsitektur Sistem](/buku/alaha.jpg)

Pada gambar di atas dapat dilihat bahwa sistem ini memiliki tiga aktor utama yang berinteraksi dengan sistem, yaitu Admin Toko, Pelanggan, dan Kurir. Admin mengakses sistem melalui Browser Desktop yang menjalankan aplikasi Web SvelteKit. Pelanggan dan Kurir mengakses sistem melalui Smartphone yang menjalankan aplikasi Mobile Flutter. Ketiga antarmuka klien berkomunikasi dengan satu titik pusat yaitu NestJS Server yang bertindak sebagai API Provider dan gateway ke layanan eksternal (Midtrans dan OpenRouteService).

### 4.1.2 Interaksi Antar Komponen

Komunikasi antara client dan server menggunakan protokol REST untuk operasi biasa dan WebSocket untuk komunikasi real-time. Berikut alur interaksi utama:

**a. Proses Pemesanan (Order Flow)**
1. Customer mengakses katalog produk melalui Mobile App
2. Product Module mengembalikan daftar produk dan stok
3. Customer menambahkan produk ke keranjang
4. Customer menyelesaikan checkout dengan memilih alamat dan slot waktu
5. Order Module membuat record pesanan dengan status "pending"
6. System memvalidasi stok per item
7. System mengurangi stok produk setelah pesanan dibuat
8. System melakukan auto-dispatch untuk menugaskan kurir terdekat

**b. Proses Pengiriman (Delivery Flow)**
1. Sistem auto-dispatch secara otomatis menugaskan kurir terdekat berdasarkan formula Haversine
2. Kurir menerima notifikasi dan melihat detail pesanan
3. Kurir menerima pesanan (Accept Order), status berubah menjadi "pickingUp"
4. Kurir menuju gudang dan memperbarui status menjadi "pickedUp" saat mengambil barang
5. Kurir menuju alamat pengiriman dan memperbarui status menjadi "delivering"
6. Kurir mengambil foto bukti pengiriman dan upload ke server
7. Sistem memperbarui status pesanan menjadi "delivered"

**c. Auto-dispatch Flow**
1. Pesanan baru dibuat oleh customer
2. Sistem mendeteksi pesanan baru yang belum ditugaskan kurir
3. Sistem mengambil daftar kurir yang sedang aktif dan tersedia
4. Untuk setiap kurir yang memiliki data lokasi, sistem menghitung jarak ke gudang menggunakan formula Haversine
5. Kurir dengan jarak terdekat dipilih secara otomatis untuk menangani pesanan
6. Sistem memperbarui status kurir agar tidak ditugaskan pesanan lain pada saat yang sama
7. Pesanan ditugaskan ke kurir tersebut dan notifikasi dikirim ke aplikasi kurir

**d. Live Tracking Flow (Real-time Location Update)**
1. Courier App mengirim location update secara periodik ke server via HTTP PUT
2. Backend menyimpan koordinat ke record Driver (currentLat, currentLng)
3. Admin Panel melakukan polling ke server setiap 30 detik untuk memperbarui posisi kurir di peta
4. Customer App dapat melihat posisi kurir yang sedang delivering pada halaman pelacakan pesanan

**e. Proof of Delivery Flow**
1. Kurir mengambil foto bukti pengiriman di lokasi tujuan
2. Foto diunggah ke Supabase Storage
3. URL foto disimpan ke record pesanan
4. Admin memvalidasi foto sebelum menyelesaikan pesanan

## 4.2 Perancangan Alur Sistem

### 4.2.1 Use Case Diagram

> **_[Gambar 4.2 Use Case Diagram]_**
> ![Use Case Diagram](/buku/use_case_diagram_ta3.jpg)

Berdasarkan arsitektur di atas, dapat diidentifikasi fungsionalitas utama untuk masing-masing aktor:

**Admin Toko:**
- Manage Product: Manajemen data produk (Create, Read, Update, Delete)
- Manage Stock: Pemantauan stok dengan notifikasi ROP (Reorder Point)
- Manage Orders: Pemantauan pesanan masuk, verifikasi bukti pengiriman
- Monitor Auto-dispatch: Pemantauan proses auto-dispatch yang berjalan otomatis
- Validate Delivery: Validasi bukti foto pengiriman
- Monitor Driver Location: Pemantauan posisi kurir secara real-time via polling
- Manage Employee: Manajemen data kurir (Employee dalam sistem)
- View Reports: Melihat laporan penjualan dan statistik
- Export PDF: Ekspor laporan pesanan dengan filter tanggal

**Pelanggan:**
- Login/Register: Autentikasi pengguna
- Browse Catalog: Penjelajahan katalog produk dengan pencarian dan filter kategori
- Add to Cart: Penambahan produk ke keranjang dengan pemilihan varian satuan
- Checkout: Penyelesaian pesanan dengan pemilihan alamat dan slot waktu
- Payment: Pembayaran melalui Midtrans (QRIS, Virtual Account, E-Wallet)
- Track Order: Pelacakan status pesanan dan posisi kurir secara real-time
- View History: Riwayat transaksi

**Kurir:**
- Login: Autentikasi kurir
- View Tasks: Daftar tugas pengiriman harian
- Accept Order: Menerima/menolak pesanan yang ditugaskan
- Update Status: Memperbarui status pengiriman (pickingUp, pickedUp, delivering, delivered)
- Send Location: Mengirimkan koordinat lokasi secara periodik ke server
- Upload Photo: Mengunggah foto bukti pengambilan dan pengiriman
- View History: Riwayat pengiriman yang telah diselesaikan
- Manage Profile: Ubah informasi profil dan kendaraan

### 4.2.2 Activity Diagram

#### Activity Diagram Alur Pemesanan

> **_[Gambar 4.3 Activity Diagram Alur Pemesanan]_**
> ![Activity Diagram Alur Pemesanan](/buku/activity_diagram_alur_pemesanan.jpg)

Alur aktivitas dimulai pada Customer saat pengguna membuka aplikasi. Pengguna menelusuri katalog produk (Browse Product Catalog) dan memilih produk yang diinginkan untuk dimasukkan ke dalam keranjang (Add Product to Cart). Setelah pengguna melanjutkan ke tahap Checkout, sistem akan memeriksa ketersediaan stok barang (Check Stock).

Jika stok tersedia, sistem menghitung total biaya transaksi (Calculate Total Payment). Pengguna memilih alamat pengiriman dan metode pembayaran, kemudian mengkonfirmasi pesanan. Sistem membuat pesanan dengan status "PENDING" dan menyimpan data transaksi. Sistem kemudian mengurangi stok produk yang dipesan.

#### Activity Diagram Pengiriman

> **_[Gambar 4.4 Activity Diagram Pengiriman]_**
> ![Activity Diagram Pengiriman](/buku/activity_diagram_pengiriman.jpg)

Aktivitas pengiriman dimulai ketika sistem auto-dispatch secara otomatis menugaskan kurir terdekat ke pesanan. Sistem mencari kurir dengan jarak terdekat menggunakan formula Haversine dan menyimpannya ke field driverId pada pesanan.

Kurir menerima notifikasi tugas dan melihat detail pesanan (alamat gudang, item, info pelanggan). Kurir menekan tombol Accept untuk menerima pesanan. Sistem memperbarui status pesanan menjadi "PICKING_UP". Kurir kemudian menuju gudang untuk mengambil barang.

Setibanya di gudang, kurir memperbarui status menjadi "PICKED_UP" dan mengambil barang. Kurir kemudian menuju alamat pengiriman pelanggan. Sistem memperbarui status menjadi "DELIVERING".

Setibanya di tujuan, kurir mengambil foto bukti pengiriman dan mengunggahnya ke server. Sistem menyimpan URL foto dan memperbarui status pesanan menjadi "DELIVERED".

#### Activity Diagram Order Fulfillment

> **_[Gambar 4.5 Activity Diagram Order Fulfillment]_**
> ![Activity Diagram Order Fulfillment](/buku/activity_diagram_order_fulfillment.jpg)

#### Algoritma Auto-dispatch

Sistem menggunakan algoritma Nearest Neighbor yang dikombinasikan dengan formula Haversine untuk menghitung jarak antara posisi kurir saat ini dengan lokasi gudang. Formula Haversine digunakan untuk menghitung jarak lurus antara dua titik koordinat geografis di permukaan bumi.

Implementasi dalam sistem:
1. Sistem mengambil semua driver yang berstatus aktif dan tersedia
2. Driver harus memiliki data koordinat lokasi yang tersimpan di sistem
3. Jarak dihitung menggunakan fungsi haversineDistance untuk setiap driver
4. Driver dengan jarak terdekat dipilih untuk ditugaskan
5. Jika tidak ada driver yang memenuhi kriteria, pesanan akan masuk ke daftar pesanan belum ditugaskan untuk diproses manual oleh admin

Aktivitas manajemen pesanan dimulai pada Admin saat admin masuk ke dashboard dan melihat daftar pesanan masuk. Admin dapat melihat detail pesanan dan melihat status pesanan beserta driver yang telah ditugaskan oleh sistem melalui auto-dispatch.

Admin memantau proses pengiriman dan memverifikasi bukti foto pengiriman setelah kurir menyelesaikan pesanan dengan status "DELIVERED". Jika terdapat masalah, admin dapat melakukan follow up kepada kurir terkait. Admin juga dapat membatalkan pesanan jika diperlukan.

## 4.3 Perancangan Basis Data

### 4.3.1 Entity Relationship Diagram (ERD)

> **_[Gambar 4.6 Entity Relationship Diagram]_**
> [^6]: *Sisipkan gambar ERD pada bagian ini.*

### 4.3.2 Desain Tabel

Berdasarkan implementasi actual pada sistem, berikut adalah struktur tabel yang digunakan:

#### Tabel 4.1 Tabel Products

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| name | VARCHAR(255) | Nama produk | NOT NULL |
| description | TEXT | Deskripsi produk | DEFAULT '' |
| price | DECIMAL(12,2) | Harga satuan | NOT NULL |
| imageUrl | VARCHAR(500) | URL gambar produk | DEFAULT '' |
| category | VARCHAR(100) | Kategori produk | DEFAULT '' |
| rating | DECIMAL(3,1) | Rating rata-rata | DEFAULT 0 |
| sold | INTEGER | Jumlah terjual | DEFAULT 0 |
| seller | VARCHAR(255) | Nama penjual | DEFAULT '' |
| sellerCity | VARCHAR(100) | Kota penjual | DEFAULT '' |
| stock | INTEGER | Stok tersedia | DEFAULT 0 |
| unit | VARCHAR(50) | Satuan default | DEFAULT 'Piece' |
| leadTime | INTEGER | Lead time dalam hari | DEFAULT 3 |
| safetyStock | INTEGER | Stok pengaman | DEFAULT 5 |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

#### Tabel 4.2 Tabel ProductVariants

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| productId | INTEGER | FK ke products | FK |
| unitName | VARCHAR(100) | Nama satuan (KG, Sack 25KG, dll) | NOT NULL |
| price | DECIMAL(12,2) | Harga untuk satuan ini | NOT NULL |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

**Contoh Data:**
| unitName | Price |
|---------|-------|
| KG | 15000 |
| Sack 25KG | 360000 |
| Sack 50KG | 710000 |

#### Tabel 4.3 Tabel Customers

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| name | VARCHAR(255) | Nama lengkap | NOT NULL |
| username | VARCHAR(100) | Username login | UNIQUE |
| phone | VARCHAR(50) | Nomor telepon | DEFAULT '' |
| password | VARCHAR(255) | Password terenkripsi | NOT NULL |
| address | TEXT | Alamat default | DEFAULT '' |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

#### Tabel 4.4 Tabel Drivers

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| username | VARCHAR(100) | Username login | UNIQUE, NOT NULL |
| password | VARCHAR(255) | Password terenkripsi | NOT NULL |
| name | VARCHAR(255) | Nama lengkap | NOT NULL |
| phone | VARCHAR(50) | Nomor telepon | DEFAULT '' |
| isActive | BOOLEAN | Status aktif | DEFAULT true |
| isAvailable | BOOLEAN | Status ketersediaan untuk auto-dispatch | DEFAULT true |
| vehicleType | VARCHAR(50) | Jenis kendaraan | DEFAULT 'motorcycle' |
| vehicleBrand | VARCHAR(100) | Merek kendaraan | DEFAULT '' |
| vehiclePlate | VARCHAR(20) | Plat nomor | DEFAULT '' |
| vehicleColor | VARCHAR(50) | Warna kendaraan | DEFAULT '' |
| currentLat | DECIMAL(10,8) | Latitude lokasi saat ini | NULLABLE |
| currentLng | DECIMAL(11,8) | Longitude lokasi saat ini | NULLABLE |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

**Fitur Auto-dispatch:**
Sistem menggunakan formula Haversine untuk menghitung jarak antara posisi kurir saat ini dengan gudang. Kurir dengan jarak terdekat dan status isAvailable = true akan ditugaskan secara otomatis. Location tracking menggunakan update berkala dari Courier App yang dikirim via HTTP PUT ke endpoint `/drivers/:id/location`. Admin Panel melakukan polling setiap 30 detik untuk memperbarui posisi di peta.

#### Tabel 4.5 Tabel Orders

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| customerId | INTEGER | FK ke customers | NULLABLE |
| customerName | VARCHAR(255) | Nama pelanggan | NOT NULL |
| customerPhone | VARCHAR(50) | Telepon pelanggan | DEFAULT '' |
| pickupAddress | TEXT | Alamat penjemputan | DEFAULT 'Gudang Utama...' |
| deliveryAddress | TEXT | Alamat pengiriman | NOT NULL |
| totalAmount | DECIMAL(12,2) | Total pembayaran | NOT NULL |
| paymentMethod | VARCHAR(50) | Metode pembayaran | DEFAULT 'COD' |
| status | VARCHAR(50) | Status pesanan | DEFAULT 'pending' |
| driverId | INTEGER | FK ke drivers | NULLABLE |
| deliveryPhoto | VARCHAR | URL foto bukti pengiriman | NULLABLE |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

**Status Pesanan:**
- `pending` - Menunggu konfirmasi
- `pickingUp` - Kurir menuju gudang
- `pickedUp` - Barang sudah diambil
- `delivering` - Sedang dikirim
- `delivered` - Sudah diterima
- `cancelled` - Dibatalkan

#### Tabel 4.6 Tabel OrderItems

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| orderId | INTEGER | FK ke orders | FK |
| productId | INTEGER | FK ke products | FK |
| productName | VARCHAR(255) | Nama produk (snapshot) | NOT NULL |
| quantity | INTEGER | Jumlah item | NOT NULL, DEFAULT 1 |
| unitPrice | DECIMAL(12,2) | Harga saat pesan | NOT NULL |
| unitName | VARCHAR(100) | Satuan (snapshot) | DEFAULT '' |
| subtotal | DECIMAL(12,2) | Subtotal | NOT NULL |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

#### Tabel 4.7 Tabel TimeSlots

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| slotTime | VARCHAR(10) | Waktu slot (08:00, 10:00, dll) | NOT NULL |
| slotDate | VARCHAR(20) | Tanggal slot | NOT NULL |
| bookings | INTEGER | Jumlah pemesanan slot ini | DEFAULT 0 |
| maxBookings | INTEGER | Kapasitas maksimum | DEFAULT 3 |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

**Constraint:** UNIQUE(slotTime, slotDate)

## 4.4 Rancangan Fitur Sistem

### 4.4.1 Modul Web Administrator

Modul Web Administrator dirancang sebagai dashboard pengelolaan toko menggunakan SvelteKit. Fitur utama meliputi:

**a. Dashboard Monitoring**
Halaman utama yang menampilkan statistik penting meliputi total karyawan, total revenue, dan jumlah order. Dashboard menyajikan visualisasi data ringkas mengenai operasional toko.

**b. Manajemen Produk**
Fitur untuk mengelola data produk (tambah, ubah, hapus) dengan informasi lengkap termasuk gambar, harga, kategori, dan stok. Admin dapat memantau stok dan menerima peringatan dini ketika stok menipis.

**c. Manajemen Stok**
Pemantauan stok secara real-time dengan sistem notifikasi Reorder Point (ROP). Sistem menampilkan daftar produk dengan stok rendah berdasarkan perhitungan yang mempertimbangkan waktu tunggu pengiriman dan stok pengaman.

**d. Manajemen Pesanan**
Fitur untuk melihat daftar pesanan masuk dengan filter berdasarkan tanggal. Admin dapat melihat detail pesanan, memverifikasi bukti foto pengiriman, mengekspor laporan ke PDF, dan memantau status pesanan serta driver yang ditugaskan oleh auto-dispatch.

**e. Auto-dispatch Monitoring**
Fitur untuk memantau proses auto-dispatch yang berjalan otomatis. Sistem menampilkan daftar driver yang tersedia dan jaraknya dari gudang berdasarkan perhitungan Haversine.

**f. Lacak Driver**
Fitur untuk melihat lokasi driver yang sedang bertugas secara real-time. Posisi driver diperbarui di peta setiap 30 detik melalui polling ke server. Menggunakan library Leaflet untuk visualisasi peta OpenStreetMap.

**g. Manajemen Employee**
Fitur untuk mendaftarkan dan mengelola data driver termasuk informasi kendaraan (jenis, merek, plat nomor, warna) dan status aktif/nonaktif.

### 4.4.2 Modul Mobile Customer

Modul Mobile Customer dirancang untuk pengalaman belanja pelanggan menggunakan Flutter. Fitur utama meliputi:

**a. Katalog dan Pencarian**
Halaman utama yang menampilkan daftar produk dengan gambar, nama, harga, dan stok. Pelanggan dapat mencari dan memfilter produk berdasarkan kategori.

**b. Detail Produk**
Halaman detail produk yang menampilkan informasi lengkap termasuk deskripsi, harga, dan varian satuan yang tersedia (contoh: KG, Sack 25KG, Sack 50KG). Pelanggan dapat memilih varian dan menambahkan ke keranjang.

**c. Keranjang Belanja**
Fitur untuk mengelola produk dalam keranjang dengan kemampuan mengubah jumlah item atau menghapus produk sebelum checkout.

**d. Checkout**
Fitur untuk menyelesaikan pesanan meliputi pemilihan alamat pengiriman dan pemilihan slot waktu pengiriman yang tersedia. Sistem menghitung total pembayaran termasuk ongkir. Sistem memvalidasi ketersediaan slot untuk menghindari bentrokan jadwal.

**e. Pembayaran**
Integrasi dengan Midtrans untuk berbagai metode pembayaran (QRIS, Virtual Account, E-Wallet). Pelanggan dapat memilih metode pembayaran dan menyelesaikan transaksi. Webhook Midtrans mengkonfirmasi pembayaran secara real-time ke backend.

**f. Pelacakan Pesanan (Live Tracking)**
Fitur untuk melacak status pesanan yang sedang diproses atau dikirim. Menampilkan timeline status dan informasi kurir yang ditugaskan. Posisi kurir diperbarui secara real-time di peta OpenStreetMap saat status adalah "delivering".

**g. Riwayat Transaksi**
Fitur untuk melihat daftar transaksi sebelumnya beserta detail dan status masing-masing pesanan.

### 4.4.3 Modul Mobile Kurir

Modul Mobile Kurir dirancang untuk mendukung operasional kurir di lapangan menggunakan Flutter. Fitur utama meliputi:

**a. Daftar Tugas**
Halaman utama yang menampilkan daftar tugas pengiriman yang ditugaskan. Tugas dibagi menjadi dua kategori: assigned (ditugaskan) dan pending (tersedia untuk diambil).

**b. Detail Pesanan**
Halaman detail pesanan yang menampilkan informasi lengkap meliputi data pelanggan, alamat pengiriman, dan item yang akan diantar. Kurir dapat menerima atau menolak pesanan.

**c. Update Status**
Fitur untuk memperbarui status pengiriman. Kurir dapat mengubah status menjadi pickingUp (menuju gudang), pickedUp (barang diambil), delivering (sedang dikirim), atau delivered (sudah diterima).

**d. Live Location Sharing**
Fitur untuk mengirim dan memperbarui lokasi saat ini ke server secara periodik. Lokasi dikirim via HTTP PUT ke endpoint `/drivers/:id/location` dengan payload berisi latitude dan longitude. Ini memungkinkan Admin dan Customer untuk melacak posisi kurir secara real-time.

**e. Peta Pengiriman**
Halaman peta interaktif yang menampilkan lokasi penjemputan (gudang) dan lokasi pengiriman (pelanggan). Membantu kurir menavigasi rute menggunakan OpenStreetMap.

**f. Konfirmasi Pengiriman**
Fitur untuk mengunggah foto bukti pengiriman. Kurir mengambil foto di lokasi tujuan sebagai bukti serah terima. Foto disimpan ke Supabase Storage dan URL-nya disimpan ke record pesanan.

**g. Riwayat Pengiriman**
Fitur untuk melihat riwayat pengiriman yang telah diselesaikan sebelumnya.

**h. Informasi Profil**
Fitur untuk melihat dan memperbarui informasi profil kurir termasuk data kendaraan (jenis, merek, plat nomor, warna).

**i. Ubah Password**
Fitur untuk mengubah password login kurir.

## 4.5 Rancangan Antarmuka Pengguna (UI Design)

Bab ini menampilkan rancangan antarmuka pengguna (User Interface) untuk masing-masing modul sistem dalam bentuk screenshot implementasi.

### 4.5.1 Modul Web Administrator

#### a. Halaman Login Admin

> **_[Gambar 4.7 Screenshot Halaman Login Admin]_**[^7]
> [^7]: *Sisipkan screenshot halaman login admin pada bagian ini.*

#### b. Halaman Dashboard

> **_[Gambar 4.8 Screenshot Halaman Dashboard Admin]_**[^8]
> [^8]: *Sisipkan screenshot halaman dashboard admin pada bagian ini.*

#### c. Halaman Manajemen Stok

> **_[Gambar 4.9 Screenshot Halaman Manajemen Stok]_**[^9]
> [^9]: *Sisipkan screenshot halaman manajemen stok pada bagian ini.*

#### d. Halaman Manajemen Pesanan

> **_[Gambar 4.10 Screenshot Halaman Manajemen Pesanan]_**[^10]
> [^10]: *Sisipkan screenshot halaman manajemen pesanan pada bagian ini.*

#### e. Halaman Lacak Employee

> **_[Gambar 4.11 Screenshot Halaman Lacak Employee]_**[^11]
> [^11]: *Sisipkan screenshot halaman lacak employee pada bagian ini.*

### 4.5.2 Modul Mobile Customer

#### a. Halaman Login

> **_[Gambar 4.12 Screenshot Halaman Login Customer]_**[^12]
> [^12]: *Sisipkan screenshot halaman login customer pada bagian ini.*

#### b. Halaman Katalog Produk

> **_[Gambar 4.13 Screenshot Halaman Katalog Produk]_**[^13]
> [^13]: *Sisipkan screenshot halaman katalog produk pada bagian ini.*

#### c. Halaman Detail Produk

> **_[Gambar 4.14 Screenshot Halaman Detail Produk]_**[^14]
> [^14]: *Sisipkan screenshot halaman detail produk pada bagian ini.*

#### d. Halaman Keranjang Belanja

> **_[Gambar 4.15 Screenshot Halaman Keranjang Belanja]_**[^15]
> [^15]: *Sisipkan screenshot halaman keranjang belanja pada bagian ini.*

#### e. Halaman Checkout

> **_[Gambar 4.16 Screenshot Halaman Checkout]_**[^16]
> [^16]: *Sisipkan screenshot halaman checkout pada bagian ini.*

#### f. Halaman Pelacakan Pesanan

> **_[Gambar 4.17 Screenshot Halaman Pelacakan Pesanan]_**[^17]
> [^17]: *Sisipkan screenshot halaman pelacakan pesanan pada bagian ini.*

### 4.5.3 Modul Mobile Kurir

#### a. Halaman Login Kurir

> **_[Gambar 4.18 Screenshot Halaman Login Kurir]_**[^18]
> [^18]: *Sisipkan screenshot halaman login kurir pada bagian ini.*

#### b. Halaman Daftar Tugas

> **_[Gambar 4.19 Screenshot Halaman Daftar Tugas Kurir]_**[^19]
> [^19]: *Sisipkan screenshot halaman daftar tugas kurir pada bagian ini.*

#### c. Halaman Detail Pesanan

> **_[Gambar 4.20 Screenshot Halaman Detail Pesanan Kurir]_**[^20]
> [^20]: *Sisipkan screenshot halaman detail pesanan kurir pada bagian ini.*

#### d. Halaman Peta Pengiriman

> **_[Gambar 4.21 Screenshot Halaman Peta Pengiriman]_**[^21]
> [^21]: *Sisipkan screenshot halaman peta pengiriman pada bagian ini.*

#### e. Halaman Konfirmasi Pengiriman

> **_[Gambar 4.22 Screenshot Halaman Konfirmasi Pengiriman]_**[^22]
> [^22]: *Sisipkan screenshot halaman konfirmasi pengiriman pada bagian ini.*

## 4.6 Ringkasan Diagram dan Tabel

| No | Keterangan | Tipe |
|----|------------|------|
| 4.1 | Arsitektur Sistem Overall | Diagram |
| 4.2 | Use Case Diagram Overview | Diagram |
| 4.3 | Activity Diagram Alur Pemesanan | Diagram |
| 4.4 | Activity Diagram Pengiriman | Diagram |
| 4.5 | Activity Diagram Order Fulfillment | Diagram |
| 4.6 | Entity Relationship Diagram | Diagram |
| 4.1-4.7 | Struktur Tabel (Products, ProductVariants, Customers, Drivers, Orders, OrderItems, TimeSlots) | Tabel |
| 4.7 | Screenshot Login Admin | UI |
| 4.8 | Screenshot Dashboard Admin | UI |
| 4.9 | Screenshot Manajemen Stok | UI |
| 4.10 | Screenshot Manajemen Pesanan | UI |
| 4.11 | Screenshot Lacak Employee | UI |
| 4.12 | Screenshot Login Customer | UI |
| 4.13 | Screenshot Katalog Produk | UI |
| 4.14 | Screenshot Detail Produk | UI |
| 4.15 | Screenshot Keranjang Belanja | UI |
| 4.16 | Screenshot Checkout | UI |
| 4.17 | Screenshot Pelacakan Pesanan | UI |
| 4.18 | Screenshot Login Kurir | UI |
| 4.19 | Screenshot Daftar Tugas Kurir | UI |
| 4.20 | Screenshot Detail Pesanan Kurir | UI |
| 4.21 | Screenshot Peta Pengiriman | UI |
| 4.22 | Screenshot Konfirmasi Pengiriman | UI |