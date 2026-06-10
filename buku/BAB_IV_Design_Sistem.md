# Bab IV
# Design Sistem

Bab ini menjelaskan tahap perancangan sistem secara menyeluruh, meliputi arsitektur sistem, perancangan alur sistem, perancangan basis data, serta rancangan fitur sistem untuk ketiga modul. Perancangan dilakukan sebagai landasan sebelum tahap implementasi, guna memastikan setiap komponen sistem dirancang dengan terstruktur dan saling terintegrasi satu sama lain. Ketiga modul yang dirancang dalam bab ini mencakup Customer App, Courier App, dan Admin Panel, yang masing-masing memiliki alur dan fungsionalitas yang disesuaikan dengan kebutuhan penggunanya.

## 4.1 Arsitektur Sistem

Arsitektur sistem dirancang menggunakan pola client-server dengan pendekatan modular. Seluruh komponen sistem dibagi menjadi tiga frontend, backend, dan database. Sistem ini terdiri dari tiga modul utama yang saling terintegrasi, yaitu Modul Web Administrator (SvelteKit), Modul Mobile Customer (Flutter), dan Modul Mobile Kurir (Flutter).

> **Gambar 4.1 Arsitektur Sistem**

Pada gambar di atas dapat dilihat bahwa sistem ini memiliki tiga aktor utama yang berinteraksi dengan sistem, yaitu Admin, Customer, dan Driver. Admin mengakses sistem melalui perangkat desktop yang menjalankan aplikasi web berbasis SvelteKit, dan dapat melakukan input data produk, pengecekan stok, manajemen jadwal, serta melihat dashboard visualisasi, stock alerts, dan laporan. Customer dan Driver masing-masing mengakses sistem melalui perangkat smartphone yang menjalankan aplikasi mobile berbasis Flutter dan Dart dalam bentuk file APK, di mana Customer dapat melakukan browsing produk, checkout, dan pemilihan slot waktu pengiriman, sedangkan Driver dapat mengelola daftar tugas pengiriman, mengunggah bukti pengiriman, serta memanfaatkan navigasi peta. Seluruh antarmuka klien tersebut berkomunikasi dengan NestJS sebagai backend utama yang bertindak sebagai API provider sekaligus gateway menuju layanan eksternal, yaitu Midtrans untuk pemrosesan pembayaran dan OpenStreetMap serta OpenRouteService untuk kebutuhan peta dan perhitungan rute. NestJS juga terhubung langsung dengan database PostgreSQL untuk menyimpan dan mengambil seluruh data yang dibutuhkan sistem, sementara proses deployment keseluruhan infrastruktur dikelola melalui platform Dokploy.

### 4.1.1 Interaksi Antar Komponen

Komunikasi antara client dan server menggunakan dua metode yang berbeda sesuai dengan kebutuhan masing-masing operasi. Operasi umum seperti pengambilan data produk, proses checkout, dan manajemen pesanan dilakukan secara sinkronus, sedangkan WebSocket digunakan untuk komunikasi real-time seperti pembaruan lokasi driver dan notifikasi status pesanan. Kombinasi keduanya memastikan sistem dapat berjalan secara efisien sesuai dengan karakteristik setiap operasi yang dibutuhkan.

**A. Proses Pemesanan**

1. Customer mengakses katalog produk melalui Mobile App
2. Customer menambahkan produk ke keranjang
3. Customer menyelesaikan checkout dengan memilih alamat dan slot waktu
4. Order Module membuat record pesanan dengan status "pending"
5. Sistem memvalidasi stok per item
6. Sistem mengurangi stok produk setelah pesanan dibuat
7. Sistem melakukan auto-dispatch untuk menugaskan kurir terdekat

**B. Proses Pengiriman**

1. Sistem auto-dispatch secara otomatis menugaskan kurir terdekat berdasarkan formula Haversine
2. Kurir menerima notifikasi dan melihat detail pesanan
3. Kurir menerima pesanan (Accept Order), status berubah menjadi "PickUp"
4. Kurir menuju gudang dan memperbarui status menjadi "PickUp" saat mengambil barang
5. Kurir menuju alamat pengiriman dan memperbarui status menjadi "delivering"
6. Kurir mengambil foto bukti pengiriman dan upload ke server
7. Sistem memperbarui status pesanan menjadi "delivered"

**C. Live Tracking Flow**

1. Currier App mengirim location update secara berkala ke server via websocket
2. Backend menyimpan koordinat ke record Driver
3. Admin Panel melakukan polling ke server setiap 5 detik untuk memperbarui posisi kurir di peta
4. Customer App dapat melihat posisi kurir yang sedang delivering pada halaman pelacakan pesanan

**D. Proof of Delivery Flow**

1. Kurir mengambil foto bukti pengiriman di lokasi tujuan
2. Foto disimpan ke record pesanan pada admin

## 4.2 Perancangan Alur Sistem

Perancangan alur sistem menggambarkan bagaimana setiap aktor berinteraksi dengan sistem melalui serangkaian proses yang terstruktur dan saling berkaitan. Alur sistem dirancang untuk mencakup seluruh skenario utama yang terjadi dalam sistem, mulai dari proses autentikasi, pengelolaan pesanan, pembayaran, hingga pengiriman barang kepada customer. Setiap alur dijelaskan secara terpisah berdasarkan fitur dan aktor yang terlibat, sehingga memudahkan pemahaman mengenai jalannya proses dalam sistem secara keseluruhan.

### 4.2.1 Use Case Diagram

> **Gambar 4.2 Use Case Diagram**

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

> **Gambar 4.3 Activity Diagram Alur Pemesanan**

Alur aktivitas dimulai pada Customer saat pengguna membuka aplikasi. Pengguna menelusuri katalog produk (Browse Product Catalog) dan memilih produk yang diinginkan untuk dimasukkan ke dalam keranjang (Add Product to Cart). Setelah pengguna melanjutkan ke tahap Checkout, sistem akan memeriksa ketersediaan stok barang (Check Stock). Jika stok tersedia, sistem menghitung total biaya transaksi (Calculate Total Payment). Pengguna memilih alamat pengiriman dan metode pembayaran, kemudian mengkonfirmasi pesanan. Sistem membuat pesanan dengan status "PENDING" dan menyimpan data transaksi. Sistem kemudian mengurangi stok produk yang dipesan.

> **Gambar 4.4 Activity Diagram Pengiriman**

Aktivitas pengiriman dimulai ketika sistem auto-dispatch secara otomatis menugaskan kurir terdekat ke pesanan. Sistem mencari kurir dengan jarak terdekat menggunakan formula Haversine dan menyimpannya ke field driverId pada pesanan. Kurir menerima notifikasi tugas dan melihat detail pesanan (alamat gudang, item, info pelanggan). Kurir menekan tombol Accept untuk menerima pesanan. Sistem memperbarui status pesanan menjadi "PICKING_UP". Kurir kemudian menuju gudang untuk mengambil barang.

Setibanya di gudang, kurir memperbarui status menjadi "PICKED_UP" dan mengambil barang. Kurir kemudian menuju alamat pengiriman pelanggan. Sistem memperbarui status menjadi "DELIVERING". Setibanya di tujuan, kurir mengambil foto bukti pengiriman dan mengunggahnya ke server. Sistem menyimpan URL foto dan memperbarui status pesanan menjadi "DELIVERED".

> **Gambar 4.5 Activity Diagram Order Fulfillment**

Aktivitas manajemen pesanan dimulai ketika admin membuka dashboard dan melihat daftar pesanan yang masuk. Admin dapat memantau detail setiap pesanan beserta status terkini dan driver yang telah ditugaskan secara otomatis oleh sistem melalui proses auto-dispatch. Setelah kurir menyelesaikan pengiriman dengan status "DELIVERED", admin memverifikasi bukti foto pengiriman dan dapat melakukan tindak lanjut kepada kurir apabila terdapat kendala di lapangan.

## 4.3 Perancangan Database

Perancangan database digambarkan melalui Entity Relationship Diagram (ERD) yang menunjukkan seluruh entitas yang terlibat dalam sistem beserta relasi antar entitasnya. ERD berikut mencakup tujuh entitas utama yaitu Products, ProductVariants, Customers, Drivers, Orders, OrderItems, dan TimeSlots yang saling berelasi satu sama lain.

> **Gambar 4.6 Entity Relationship Diagram (ERD)**

Diagram ERD di atas menggambarkan relasi antar entitas yang digunakan dalam sistem. Tabel Orders menjadi entitas pusat yang berelasi dengan Customers, Drivers, OrderItems, dan TimeSlots, sementara tabel OrderItems berelasi dengan Products dan ProductVariants untuk menyimpan snapshot data produk pada saat pesanan dibuat.

### 4.3.1 Desain Tabel

Berdasarkan implementasi actual pada sistem, berikut adalah struktur tabel yang digunakan:

**Tabel 4.1 Tabel Products**

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

**Tabel 4.2 Tabel ProductVariants**

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| productId | INTEGER | FK ke products | FK |
| unitName | VARCHAR(100) | Nama satuan (KG, Sack 25KG, dll) | NOT NULL |
| price | DECIMAL(12,2) | Harga untuk satuan ini | NOT NULL |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

**Tabel 4.3 Tabel Customers**

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

**Tabel 4.4 Tabel Drivers**

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

**Tabel 4.5 Tabel Orders**

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

**Tabel 4.6 Tabel OrderItems**

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

**Tabel 4.7 Tabel TimeSlots**

| Kolom | Tipe Data | Deskripsi | Constraint |
|-------|-----------|-----------|------------|
| id | SERIAL | Primary key | PK |
| slotTime | VARCHAR(10) | Waktu slot (08:00, 10:00, dll) | NOT NULL |
| slotDate | VARCHAR(20) | Tanggal slot | NOT NULL |
| bookings | INTEGER | Jumlah pemesanan slot ini | DEFAULT 0 |
| maxBookings | INTEGER | Kapasitas maksimum | DEFAULT 3 |
| createdAt | TIMESTAMP | Waktu pembuatan | DEFAULT NOW() |
| updatedAt | TIMESTAMP | Waktu update | DEFAULT NOW() |

## 4.4 Rancangan Modul Sistem

Sub-bab ini menjelaskan rancangan modul-modul yang terdapat dalam sistem secara keseluruhan. Sistem dibagi menjadi tiga modul utama yaitu Admin Panel, Customer App, dan Courier App, yang masing-masing dirancang dengan fungsionalitas yang disesuaikan dengan kebutuhan dan peran penggunanya. Rancangan setiap modul mencakup fitur-fitur utama yang akan diimplementasikan dan menjadi acuan dalam tahap pengembangan sistem pada bab selanjutnya.

### 4.4.1 OpenStreetMap

Modul OpenStreetMap menyediakan layanan pemetaan dan navigasi berbasis peta open-source. Modul ini menggunakan library Leaflet untuk visualisasi peta pada sisi klien. Komponen:

- Leaflet Library: Library JavaScript untuk visualisasi peta interaktif
- OpenStreetMap Tile Server: Sumber gambar peta (tiles)
- OpenRouteService API: Layanan untuk menghitung rute dan jarak (planned)

Penggunaan:

- Admin Panel: Menampilkan lokasi driver yang sedang bertugas
- Courier App: Menampilkan peta navigasi untuk lokasi penjemputan dan pengiriman

## 4.5 Rancangan Fitur Aplikasi

Sub-bab ini menjelaskan rancangan fitur-fitur utama yang terdapat pada masing-masing modul sistem. Setiap modul dirancang dengan fitur yang disesuaikan berdasarkan kebutuhan dan peran penggunanya, yaitu Admin Panel sebagai pengelola toko, Customer App sebagai antarmuka belanja pelanggan, dan Courier App sebagai pendukung operasional kurir di lapangan. Rancangan fitur ini menjadi acuan dalam proses implementasi sistem yang dijelaskan pada bab selanjutnya.

### 4.5.1 Admin Panel (Web Admin - SvelteKit)

Admin Panel dirancang sebagai dashboard pengelolaan toko. Fitur utama meliputi:

a. **Dashboard Monitoring:** Halaman utama yang menampilkan statistik penting meliputi total karyawan, total revenue, dan jumlah order. Dashboard menyajikan visualisasi data ringkas mengenai operasional toko.

b. **Manajemen Produk:** Fitur untuk mengelola data produk (tambah, ubah, hapus) dengan informasi lengkap termasuk gambar, harga, kategori, dan stok. Admin dapat memantau stok dan menerima peringatan dini ketika stok menipis.

c. **Manajemen Stok:** Pemantauan stok secara real-time dengan sistem notifikasi Reorder Point (ROP). Sistem menampilkan daftar produk dengan stok rendah berdasarkan perhitungan yang mempertimbangkan waktu tunggu pengiriman dan stok pengaman.

d. **Manajemen Pesanan:** Fitur untuk melihat daftar pesanan masuk dengan filter berdasarkan tanggal. Admin dapat melihat detail pesanan, memverifikasi bukti foto pengiriman, mengekspor laporan ke PDF, dan memantau status pesanan serta driver yang ditugaskan oleh auto-dispatch.

e. **Lacak Driver:** Fitur untuk melihat lokasi driver yang sedang bertugas secara real-time. Posisi driver diperbarui di peta menggunakan library Leaflet untuk visualisasi peta OpenStreetMap.

f. **Manajemen Employee:** Fitur untuk mendaftarkan dan mengelola data driver termasuk informasi kendaraan (jenis, merek, plat nomor, warna) dan status aktif/nonaktif.

### 4.5.2 Customer App (Mobile - Flutter)

Customer App dirancang untuk pengalaman belanja pelanggan menggunakan Flutter. Fitur utama meliputi:

a. **Login/Register:** Fitur autentikasi untuk masuk atau mendaftarkan akun baru.

b. **Katalog dan Pencarian:** Halaman utama yang menampilkan daftar produk dengan gambar, nama, harga, dan stok. Pelanggan dapat mencari dan memfilter produk berdasarkan kategori.

c. **Detail Produk:** Halaman detail produk yang menampilkan informasi lengkap termasuk deskripsi, harga, dan varian satuan yang tersedia (contoh: KG, Sack 25KG, Sack 50KG). Pelanggan dapat memilih varian dan menambahkan ke keranjang.

d. **Keranjang Belanja:** Fitur untuk mengelola produk dalam keranjang dengan kemampuan mengubah jumlah item atau menghapus produk sebelum checkout.

e. **Checkout:** Fitur untuk menyelesaikan pesanan meliputi pemilihan alamat pengiriman dan pemilihan slot waktu pengiriman yang tersedia. Sistem menghitung total pembayaran.

f. **Pembayaran:** Integrasi dengan Midtrans untuk berbagai metode pembayaran (QRIS, Virtual Account, E-Wallet).

g. **Pelacakan Pesanan (Live Tracking):** Fitur untuk melacak status pesanan yang sedang diproses atau dikirim. Menampilkan timeline status dan informasi kurir yang ditugaskan.

h. **Riwayat Transaksi:** Fitur untuk melihat daftar transaksi sebelumnya beserta detail dan status masing-masing pesanan.

### 4.5.3 Courier App (Mobile - Flutter)

Courier App dirancang untuk mendukung operasional kurir di lapangan menggunakan Flutter. Fitur utama meliputi:

a. **Login:** Fitur autentikasi kurir untuk masuk ke aplikasi.

b. **Daftar Tugas:** Halaman utama yang menampilkan daftar tugas pengiriman yang ditugaskan. Tugas dibagi menjadi dua kategori: assigned (ditugaskan) dan pending (tersedia untuk diambil).

c. **Detail Pesanan:** Halaman detail pesanan yang menampilkan informasi lengkap meliputi data pelanggan, alamat pengiriman, dan item yang akan diantar. Kurir dapat menerima atau menolak pesanan.

d. **Update Status:** Fitur untuk memperbarui status pengiriman. Kurir dapat mengubah status menjadi pickingUp (menuju gudang), pickedUp (barang diambil), delivering (sedang dikirim), atau delivered (sudah diterima).

e. **Peta Navigasi:** Halaman peta interaktif yang menampilkan lokasi penjemputan (gudang) dan lokasi pengiriman (pelanggan). Membantu kurir menavigasi rute menggunakan OpenStreetMap.

f. **Konfirmasi Pengiriman:** Fitur untuk mengunggah foto bukti pengiriman. Kurir mengambil foto di lokasi tujuan sebagai bukti serah terima. Foto disimpan ke Supabase Storage dan URL-nya disimpan ke record pesanan.

g. **Riwayat Pengiriman:** Fitur untuk melihat riwayat pengiriman yang telah diselesaikan sebelumnya.

h. **Informasi Profil:** Fitur untuk melihat dan memperbarui informasi profil kurir termasuk data kendaraan (jenis, merek, plat nomor, warna).

## 4.6 Rancangan Antarmuka Pengguna (UI Design)

Sub-bab ini menampilkan rancangan antarmuka pengguna (User Interface) untuk masing-masing modul sistem dalam bentuk screenshot implementasi. Rancangan antarmuka dirancang dengan mempertimbangkan kemudahan penggunaan dan kenyamanan masing-masing pengguna, baik Admin, Customer, maupun Courier. Setiap tampilan yang ditunjukkan merupakan hasil implementasi aktual dari sistem yang telah dibangun, mencakup seluruh halaman utama dari ketiga modul.

### 4.6.1 Admin Panel (Web Administrator)

Sub-bab ini menampilkan rancangan antarmuka pengguna untuk modul Admin Panel yang diakses melalui browser desktop berbasis SvelteKit. Halaman-halaman yang dirancang mencakup dashboard statistik, manajemen employee, manajemen stok, lacak driver, dan manajemen time slot yang masing-masing dirancang untuk memudahkan admin dalam memantau dan mengelola seluruh operasional toko secara terpusat.

#### 4.6.1.1 Halaman Login Admin

Halaman login Admin Panel merupakan halaman pertama yang ditampilkan ketika admin mengakses sistem melalui browser. Halaman ini menampilkan form input username dan password yang digunakan untuk memverifikasi identitas admin sebelum dapat mengakses fitur-fitur yang tersedia di dalam sistem. Apabila kredensial yang dimasukkan tidak valid, sistem akan menampilkan pesan error yang informatif untuk memandu admin dalam melakukan login ulang.

> **Gambar 4.7 Screenshot Halaman Login Admin**

Gambar 4.7 menampilkan rancangan halaman login Admin Panel yang terdiri dari form input username dan password di bagian tengah halaman, serta tombol login di bawah form input yang digunakan admin untuk masuk ke dalam sistem setelah mengisi kredensial yang benar.

#### 4.6.1.2 Halaman Dashboard

Halaman dashboard merupakan halaman utama yang ditampilkan setelah admin berhasil login ke dalam sistem. Halaman ini menampilkan ringkasan statistik operasional toko secara real-time yang mencakup Total Employee, Revenue Today, Total Orders Today, dan Total Orders This Month dalam bentuk kartu informasi. Selain kartu statistik, halaman ini juga menampilkan dua grafik yaitu grafik pesanan per jam untuk hari ini dan grafik pesanan per hari untuk bulan ini, sehingga admin dapat memantau tren penjualan secara visual dengan mudah.

> **Gambar 4.8 Screenshot Halaman Dashboard Admin**

Gambar 4.8 menampilkan rancangan halaman dashboard Admin Panel dengan sidebar navigasi di sisi kiri yang berisi menu Dashboard, Add Employee, Locate Employee, Orders, dan Stock, serta area konten utama di sisi kanan yang menampilkan kartu statistik dan grafik pesanan secara bersamaan.

#### 4.6.1.3 Halaman Manajemen Stok

Halaman manajemen stok digunakan oleh admin untuk memantau dan mengelola seluruh produk yang tersedia di toko. Halaman ini menampilkan daftar produk dalam bentuk tabel yang berisi informasi nama produk, harga, jumlah stok, satuan, dan status stok, di mana status akan menampilkan badge "OK" berwarna hijau jika stok aman dan badge "Need Reorder" berwarna kuning jika stok telah mencapai batas reorder point. Tersedia juga fitur pencarian produk berdasarkan nama atau satuan, tombol Refresh untuk memperbarui data, serta tombol Add Item untuk menambahkan produk baru ke dalam sistem.

> **Gambar 4.9 Screenshot Halaman Manajemen Stok**

Gambar 4.9 menampilkan rancangan halaman manajemen stok yang menampilkan tujuh produk dengan berbagai satuan seperti KG dan Piece, di mana produk Sepatu Running Ultralight terlihat memiliki status "Need Reorder" yang menandakan stok produk tersebut telah mencapai batas reorder point dan perlu segera diisi ulang.

#### 4.6.1.4 Halaman Manajemen Pesanan

Halaman manajemen pesanan digunakan oleh admin untuk memantau seluruh pesanan yang masuk dalam rentang waktu tertentu. Halaman ini menampilkan daftar pesanan dalam bentuk tabel yang berisi informasi Order ID, nama customer, tanggal pesanan, total harga, dan status pesanan, di mana status ditampilkan dengan warna berbeda seperti kuning untuk Pending, biru untuk Processing, dan hijau untuk Completed. Tersedia juga fitur filter berdasarkan rentang tanggal, tombol Refresh untuk memperbarui data, serta tombol Export PDF untuk mengunduh laporan pesanan dalam rentang tanggal yang dipilih.

> **Gambar 4.10 Screenshot Halaman Manajemen Pesanan**

Gambar 4.10 menampilkan rancangan halaman manajemen pesanan dengan filter rentang tanggal 20/05/2026 hingga 27/05/2026 yang menampilkan 7 hari data pesanan, di mana terlihat beberapa pesanan dengan status Pending, satu pesanan berstatus Processing, dan satu pesanan berstatus Completed yang dapat diekspor menjadi laporan PDF.

#### 4.6.1.5 Halaman Lacak Employee

Halaman lacak employee digunakan oleh admin untuk memantau daftar driver yang sedang aktif bertugas beserta informasi kontaknya. Halaman ini menampilkan daftar driver yang sedang On Duty dalam bentuk tabel berisi nama driver dan nomor telepon, serta tombol "Lacak Lokasi" pada setiap baris yang dapat diklik admin untuk melihat posisi driver tersebut secara real-time di peta. Tersedia juga fitur pencarian driver berdasarkan nama atau nomor telepon, serta tombol Refresh untuk memperbarui data driver yang sedang aktif.

> **Gambar 4.11 Screenshot Halaman Lacak Employee**

Gambar 4.11 menampilkan rancangan halaman lacak employee yang menunjukkan terdapat 3 driver sedang On Duty, di mana admin dapat menekan tombol "Lacak Lokasi" pada masing-masing driver untuk melihat posisinya di peta secara real-time.

### 4.6.2 Customer App (Mobile)

Sub-bab ini menampilkan rancangan antarmuka pengguna untuk modul Customer App yang diakses melalui perangkat smartphone berbasis Flutter. Halaman-halaman yang dirancang mencakup login, katalog produk, detail produk, keranjang belanja, checkout, pelacakan pesanan, dan riwayat pesanan yang masing-masing dirancang untuk memberikan pengalaman belanja yang mudah dan nyaman bagi customer.

#### 4.6.2.1 Halaman Login

Halaman login Customer App merupakan halaman pertama yang ditampilkan saat customer membuka aplikasi. Halaman ini menampilkan form input username atau nomor telepon dan password yang digunakan untuk memverifikasi identitas customer sebelum dapat mengakses fitur aplikasi. Tersedia juga tautan "Daftar" di bagian bawah halaman bagi customer yang belum memiliki akun.

> **Gambar 4.12 Screenshot Halaman Login Customer**

Gambar 4.12 menampilkan rancangan halaman login Customer App dengan logo aplikasi di bagian atas, diikuti teks sambutan "Selamat Datang!", form input username atau nomor telepon dan password, tombol "Masuk" berwarna ungu, serta tautan "Daftar" di bagian bawah untuk customer yang belum memiliki akun.

#### 4.6.2.2 Halaman Katalog Produk

Halaman katalog produk merupakan halaman utama yang ditampilkan setelah customer berhasil login ke dalam aplikasi. Halaman ini menampilkan daftar produk dalam bentuk grid dua kolom yang dilengkapi dengan informasi nama produk, harga, rating, jumlah terjual, stok, dan lokasi toko pada setiap kartu produk. Tersedia juga fitur pencarian produk di bagian atas halaman untuk memudahkan customer menemukan produk yang diinginkan.

> **Gambar 4.13 Screenshot Halaman Katalog Produk**

Gambar 4.13 menampilkan rancangan halaman katalog produk dengan grid dua kolom yang menampilkan produk beserta informasi lengkapnya, serta ikon profil dan keranjang belanja tersedia di pojok kanan atas halaman.

#### 4.6.2.3 Halaman Detail Produk

Halaman detail produk menampilkan informasi lengkap mengenai produk yang dipilih oleh customer. Halaman ini memuat gambar produk berukuran besar di bagian atas, diikuti informasi harga, nama produk, jumlah terjual, stok tersedia, nama toko beserta lokasinya, dan deskripsi produk di bagian bawah. Terdapat tombol "Tambah ke Keranjang" di bagian bawah halaman yang digunakan customer untuk menambahkan produk ke keranjang belanja.

> **Gambar 4.14 Screenshot Halaman Detail Produk**

Gambar 4.14 menampilkan rancangan halaman detail produk yang menampilkan informasi produk secara lengkap, dengan tombol "Tambah ke Keranjang" berwarna ungu yang selalu terlihat di bagian bawah halaman sehingga customer dapat dengan mudah menambahkan produk ke keranjang kapan saja.

#### 4.6.2.4 Halaman Keranjang Belanja

Halaman keranjang belanja menampilkan daftar produk yang telah ditambahkan oleh customer sebelum melanjutkan ke proses checkout. Setiap item dalam keranjang menampilkan gambar produk, nama produk, satuan, harga, serta tombol tambah dan kurang untuk mengubah jumlah item, dan ikon tempat sampah untuk menghapus item dari keranjang. Di bagian bawah halaman terdapat total harga yang diperbarui secara otomatis dan tombol "Checkout" untuk melanjutkan ke proses pembelian.

> **Gambar 4.15 Screenshot Halaman Keranjang Belanja**

Gambar 4.15 menampilkan rancangan halaman keranjang belanja yang menunjukkan satu item produk dengan satuan KG, tombol pengatur jumlah item di bagian tengah, total harga di pojok kiri bawah, serta tombol "Checkout" berwarna hijau di bagian bawah halaman.

#### 4.6.2.5 Halaman Checkout

Halaman checkout digunakan oleh customer untuk menyelesaikan proses pembelian sebelum melanjutkan ke pembayaran. Halaman ini menampilkan peta interaktif berbasis OpenStreetMap dengan fitur pencarian alamat pengiriman, pilihan waktu pengiriman, serta ringkasan pesanan yang berisi daftar produk, subtotal, dan ongkos kirim. Setelah seluruh informasi diisi dengan lengkap, customer dapat menekan tombol "Lanjut ke Pembayaran" di bagian bawah halaman untuk melanjutkan ke tahap pembayaran.

> **Gambar 4.16 Screenshot Halaman Checkout**

Gambar 4.16 menampilkan rancangan halaman checkout yang terdiri dari peta dengan marker lokasi pengiriman di bagian atas, diikuti bagian pemilihan waktu pengiriman yang menampilkan peringatan apabila waktu belum dipilih, serta ringkasan pesanan yang menampilkan detail produk, subtotal, dan ongkos kirim sebelum customer melanjutkan ke pembayaran.

#### 4.6.2.6 Halaman Pelacakan Pesanan

Halaman pelacakan pesanan digunakan oleh customer untuk memantau status dan posisi driver secara real-time setelah pesanan dikonfirmasi. Halaman ini menampilkan informasi driver yang bertugas, peta interaktif yang menunjukkan posisi driver dan lokasi customer secara bersamaan, serta timeline status pengiriman yang terdiri dari Pesanan Dikonfirmasi, Driver Menuju Pickup, Dalam Perjalanan, dan Pesanan Tiba. Seluruh data pada halaman ini diperbarui secara otomatis melalui koneksi WebSocket tanpa perlu melakukan refresh halaman secara manual.

> **Gambar 4.17 Screenshot Halaman Pelacakan Pesanan**

Gambar 4.17 menampilkan rancangan halaman pelacakan pesanan dengan status "pickingUp" yang menunjukkan driver sedang dalam perjalanan menuju lokasi pickup, di mana posisi driver dan customer sama-sama terlihat di peta beserta koordinatnya, serta timeline status pengiriman yang menampilkan progres pesanan secara visual.

### 4.6.3 Courier App (Mobile)

Sub-bab ini menampilkan rancangan antarmuka pengguna untuk modul Courier App yang diakses melalui perangkat smartphone berbasis Flutter. Halaman-halaman yang dirancang mencakup login, daftar pesanan aktif, detail pesanan, navigasi peta, dan riwayat pengiriman yang masing-masing dirancang untuk memudahkan kurir dalam mengelola dan menyelesaikan tugas pengiriman secara efisien.

#### 4.6.3.1 Halaman Login Kurir

Halaman login Courier App merupakan halaman pertama yang ditampilkan saat kurir membuka aplikasi. Halaman ini menampilkan form input username dan password dengan latar belakang berwarna biru yang digunakan untuk memverifikasi identitas kurir sebelum dapat mengakses fitur aplikasi. Berbeda dengan Customer App, halaman login Courier App tidak memiliki fitur registrasi karena akun kurir hanya dapat dibuat oleh admin melalui Admin Panel.

> **Gambar 4.18 Screenshot Halaman Login Kurir**

Gambar 4.18 menampilkan rancangan halaman login Courier App dengan logo truk dan nama aplikasi "Mobile Courier" di bagian atas, diikuti form input username dan password dalam card berwarna putih, serta tombol "Masuk" berwarna biru untuk masuk ke dalam aplikasi.

#### 4.6.3.2 Halaman Daftar Tugas

Halaman daftar tugas merupakan halaman utama Courier App yang ditampilkan setelah kurir berhasil login ke dalam aplikasi. Bagian atas halaman menampilkan sapaan kepada kurir beserta ringkasan statistik pesanan yang terdiri dari jumlah pesanan Menunggu, Aktif, dan Selesai, serta indikator status Online di pojok kanan atas. Di bawahnya terdapat daftar pesanan aktif dalam bentuk kartu yang masing-masing menampilkan ID pesanan, nama customer, alamat pickup, alamat pengiriman, jumlah item, total harga, dan status pesanan.

> **Gambar 4.19 Screenshot Halaman Daftar Tugas Kurir**

Gambar 4.19 menampilkan rancangan halaman daftar tugas yang menunjukkan kurir memiliki 19 pesanan aktif, di mana terdapat pesanan dengan status "Menuju Pickup" dan beberapa pesanan berstatus "Menunggu", serta terdapat tombol navigasi peta di pojok kanan bawah dan navigasi bawah yang terdiri dari menu Pesanan dan Profil.

#### 4.6.3.3 Halaman Detail Pesanan

Halaman detail pesanan menampilkan informasi lengkap mengenai pesanan yang akan dikerjakan oleh kurir. Halaman ini terbagi menjadi empat bagian yaitu informasi pelanggan yang berisi nama dan nomor telepon, alamat yang menampilkan lokasi pickup dan lokasi pengiriman secara berurutan, detail barang yang berisi nama produk, jumlah item, dan total harga, serta status pengiriman yang menampilkan progres pesanan secara bertahap. Terdapat tombol aksi di bagian bawah halaman yang berubah sesuai dengan status pesanan, diawali dengan tombol "Mulai Pickup" untuk memulai proses pengambilan barang.

> **Gambar 4.20 Screenshot Halaman Detail Pesanan Kurir**

Gambar 4.20 menampilkan rancangan halaman detail pesanan yang menunjukkan informasi pelanggan, alamat pickup dan pengiriman secara lengkap, detail barang yang dipesan, serta status pengiriman "Pesanan Diterima" dengan tombol "Mulai Pickup" berwarna biru di bagian bawah halaman.

#### 4.6.3.4 Halaman Peta Pengiriman

Halaman peta pengiriman digunakan oleh kurir sebagai panduan navigasi selama proses pengiriman berlangsung. Halaman ini menampilkan peta interaktif berbasis OpenStreetMap yang memperlihatkan posisi kurir, lokasi tujuan, serta rute pengiriman dalam bentuk garis biru. Di bagian bawah halaman terdapat informasi lokasi pickup, data customer beserta tombol telepon dan pesan, serta ringkasan barang yang akan diantarkan.

> **Gambar 4.21 Screenshot Halaman Peta Pengiriman**

Gambar 4.21 menampilkan rancangan halaman peta pengiriman dengan status "Menuju Pickup" yang menunjukkan posisi kurir dan lokasi tujuan pada peta beserta rute yang harus dilalui, serta informasi lokasi pickup, data customer, dan detail barang ditampilkan di bagian bawah halaman.

#### 4.6.3.5 Halaman Konfirmasi Pengiriman

Halaman konfirmasi pengiriman digunakan oleh kurir untuk menyelesaikan proses pengiriman dengan melengkapi bukti serah terima barang kepada customer. Halaman ini terdiri dari dua bagian yaitu foto barang yang diambil langsung menggunakan kamera perangkat sebagai bukti barang telah diterima, dan tanda tangan digital customer yang diambil langsung di layar sebagai bukti penerimaan. Setelah kedua bukti tersebut dilengkapi, kurir dapat menekan tombol "Konfirmasi Selesai" untuk menandai pesanan sebagai selesai.

> **Gambar 4.22 Screenshot Halaman Konfirmasi Pengiriman**

Gambar 4.22 menampilkan rancangan halaman konfirmasi pengiriman yang terdiri dari area pengambilan foto barang dan area tanda tangan digital customer, di mana masing-masing area menampilkan instruksi untuk diketuk sebelum kurir mengisi bukti pengiriman, serta tombol "Konfirmasi Selesai" berwarna biru di bagian bawah halaman.