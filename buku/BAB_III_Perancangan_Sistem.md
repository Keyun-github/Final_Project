# BAB III
# PERANCANGAN SISTEM

## 3.1 Arsitektur Sistem

Sistem ini dirancang dengan menerapkan arsitektur client-server modern yang memisahkan tanggung jawab antara antarmuka pengguna (frontend) dan logika bisnis pusat (backend). Selruh logika bisnis utama, termasuk perhitungan algoritma Reorder Point (ROP), manajemen transaksi, dan pengaturan jadwal logistik, dipusatkan pada sisi server yang dibangun menggunakan framework NestJS.

Di sisi klien, sistem menyediakan tiga platform antarmuka yang berbeda sesuai kebutuhan penggunanya:

**Modul Web Administrator** dikembangkan menggunakan SvelteKit yang menawarkan performa ringan dan cepat untuk pengelolaan data inventori yang padat.

**Modul Mobile Customer** dan **Modul Mobile Kurir** dikembangkan menggunakan Flutter yang dikompilasi secara native untuk perangkat Android, memungkinkan akses fitur perangkat keras seperti kamera dan GPS secara optimal.

Komunikasi data antara klien dan server difasilitasi melalui protokol HTTP menggunakan format pertukaran data JSON (JavaScript Object Notation) yang ringan. Untuk kebutuhan komunikasi real-time seperti live tracking dan notifikasi, sistem menggunakan protokol WebSocket yang menjaga koneksi tetap terbuka antara klien dan server.

### 3.1.1 Arsitektur Overall

Arsitektur sistem secara keseluruhan dapat dilihat pada Gambar 1. Di sisi kiri, terdapat tiga aktor utama yaitu Admin, Pelanggan, dan Kurir. Admin mengakses sistem melalui Browser Desktop yang menjalankan aplikasi Web SvelteKit. Pelanggan dan Kurir mengakses sistem melalui Smartphone yang menjalankan aplikasi Mobile Flutter.

Kedua antarmuka klien (Web dan Mobile) tidak saling berkomunikasi secara langsung, melainkan terhubung ke satu titik pusat yaitu NestJS Server. Ketika Pelanggan melakukan pemesanan atau Kurir memperbarui status pengiriman, aplikasi klien mengirimkan HTTP Request ke Server. Server memproses permintaan tersebut, melakukan validasi logika bisnis, dan berinteraksi dengan Database PostgreSQL untuk menyimpan atau mengambil data.

Selain itu, Server NestJS juga bertindak sebagai jembatan ke layanan eksternal. Untuk pembayaran, server terhubung dengan API Midtrans untuk mendapatkan status transaksi. Untuk keperluan logistik, server memanfaatkan layanan API OpenRouteService untuk memvalidasi koordinat lokasi dan menghitung estimasi jarak tempuh.

### 3.1.2 Arsitektur Modul

Sistem terdiri dari tiga modul utama yang saling terintegrasi:

**Modul Web Administrator** menangani seluruh operasi manajemen toko termasuk manajemen produk dan inventori, pemantauan status pesanan, manajemen kurir dan armada, serta visualisasi data melalui dashboard.

**Modul Mobile Customer** menangani proses belanja mulai dari penelusuran katalog produk, penempatan pesanan, pembayaran, pemilihan jadwal pengiriman, hingga pelacakan status pesanan secara real-time.

**Modul Mobile Kurir** menangani operasional lapangan termasuk penerimaan tugas pengiriman, navigasi ke lokasi tujuan, konfirmasi pengambilan paket, serta pengunggahan bukti pengiriman berupa foto dan tanda tangan digital.

## 3.2 Perancangan Alur Sistem

Perancangan alur sistem описывает interaksi antara aktor dengan sistem melalui Use Case Diagram dan Activity Diagram. Use case diagram menggambarkan fungsionalitas tingkat tinggi yang dapat diakses oleh masing-masing aktor, sedangkan activity diagram menggambarkan alur proses bisnis secara detail.

### 3.2.1 Use Case Diagram

Sistem ini memiliki tiga aktor utama yang berinteraksi dengan sistem, yaitu Admin Toko, Pelanggan, dan Kurir.

#### Use Case Admin Toko

Admin bertindak sebagai pengelola utama sistem yang memiliki akses penuh ke dashboard web. Fungsionalitas yang доступны bagi Admin meliputi:

| No | Use Case | Deskripsi |
|----|----------|-----------|
| 1 | Login | Admin masuk ke sistem dengan autentikasi username dan password |
| 2 | Manajemen Produk | Admin dapat menambah, mengubah, dan menghapus data produk |
| 3 | Manajemen Stok | Admin dapat memantau dan mengelola stok barang termasuk melihat notifikasi ROP |
| 4 | Manajemen Pesanan | Admin dapat melihat daftar pesanan masuk, memverifikasi detail pesanan, dan mencetak invoice |
| 5 | Manajemen Kurir | Admin dapat menambah dan mengelola data kurir termasuk status aktif/nonaktif |
| 6 | Penugasan Kurir | Admin dapat menugaskan kurir secara manual atau menggunakan auto-dispatch |
| 7 | Monitoring Armada | Admin dapat melihat lokasi kurir secara real-time di peta |
| 8 | Validasi Pengiriman | Admin dapat memvalidasi bukti foto dan tanda tangan digital dari kurir |

#### Use Case Pelanggan

Pelanggan berinteraksi melalui aplikasi mobile untuk kebutuhan belanja. Fungsionalitas yang доступны bagi Pelanggan meliputi:

| No | Use Case | Deskripsi |
|----|----------|-----------|
| 1 | Registrasi & Login | Pelanggan membuat akun dan masuk ke aplikasi |
| 2 | Browse Produk | Pelanggan menelusuri katalog produk |
| 3 | Tambah ke Keranjang | Pelanggan menambahkan produk ke keranjang belanja |
| 4 | Checkout | Pelanggan menyelesaikan pembayaran pesanan |
| 5 | Pilih Jadwal Pengiriman | Pelanggan memilih slot waktu pengiriman yang tersedia |
| 6 | Lacak Pesanan | Pelanggan memantau posisi kurir secara real-time di peta |
| 7 | Riwayat Pesanan | Pelanggan dapat melihat riwayat pesanan yang pernah dilakukan |

#### Use Case Kurir

Kurir menggunakan aplikasi khusus untuk meninjau operasional logistik harian. Fungsionalitas yang tersedia bagi Kurir meliputi:

| No | Use Case | Deskripsi |
|----|----------|-----------|
| 1 | Login | Kurir masuk ke aplikasi dengan autentikasi |
| 2 | Lihat Daftar Tugas | Kurir dapat melihat daftar tugas pengiriman harian |
| 3 | Terima Tugas | Kurir dapat menerima atau menolak pesanan yang ditugaskan |
| 4 | Update Status | Kurir memperbarui status pengiriman (picking up, picked up, delivering) |
| 5 | Live Location | Kurir menyiarkan posisi GPS-nya agar dapat dipantau oleh sistem |
| 6 | Konfirmasi Pengiriman | Kurir mengunggah foto dan tanda tangan digital sebagai bukti serah terima |
| 7 | Riwayat Pengiriman | Kurir dapat melihat riwayat tugas yang telah diselesaikan |

### 3.2.2 Activity Diagram Pemesanan (Ordering)

Activity diagram pemesanan menggambarkan alur aktivitas dimulai dari pelanggan membuka aplikasi hingga pesanan berhasil dibuat. Alur ini melibatkan interaksi antara Pelanggan, Aplikasi Customer, Server, dan Database.

Proses pemesanan dimulai ketika pelanggan membuka aplikasi mobile dan melakukan login. Setelah berhasil login, pelanggan dapat menelusuri katalog produk yang tersedia. Pelanggan memilih produk yang diinginkan dan menambahkannya ke keranjang belanja. Proses ini dapat berulang untuk menambahkan produk lainnya.

Setelah pelanggan menyelesaikan pemilihan produk, sistem akan memeriksa ketersediaan stok untuk setiap item. Jika stok tersedia, sistem menghitung total biaya transaksi yang mencakup harga barang dan biaya pengiriman. Pelanggan kemudian memilih metode pembayaran yang tersedia.

Pembayaran dilakukan melalui Payment Gateway Midtrans yang mendukung berbagai metode seperti Virtual Account, QRIS, dan E-Wallet. Sistem menunggu konfirmasi pembayaran dari Midtrans melalui webhook. Apabila pembayaran berhasil diverifikasi, pelanggan dapat memilih jadwal pengiriman sesuai slot waktu yang tersedia.

Setelah jadwal dipilih, sistem secara otomatis memotong stok produk dan menyimpan data transaksi. Pesanan baru akan muncul di dashboard admin untuk diproses lebih lanjut.

### 3.2.3 Activity Diagram Pemenuhan Pesanan (Fulfillment)

Activity diagram pemenuhan pesanan menggambarkan aktivitas manajemen pesanan yang dilakukan oleh Admin sebelum barang diserahkan kepada kurir. Aktivitas dimulai ketika admin login ke dashboard.

Admin memeriksa daftar pesanan baru yang masuk melalui dashboard. Untuk setiap pesanan baru, admin memverifikasi rincian pesanan termasuk produk yang dipesan, jumlah, alamat pengiriman, dan metode pembayaran. Admin kemudian mencetak invoice atau label pengiriman sebagai dokumen fisik paket.

Setelah paket siap secara fisik, admin memperbarui status pesanan menjadi "Ready to Ship". Sistem akan mencatat perubahan status tersebut. Langkah selanjutnya adalah penetapan armada, dimana admin memilih dan menugaskan kurir spesifik untuk pesanan tersebut.

Penugasan kurir dapat dilakukan secara manual oleh admin atau secara otomatis melalui mekanisme auto-dispatch. Sistem menyimpan data penugasan, memperbarui status menjadi "Waiting for Pickup", dan mengirimkan notifikasi tugas baru kepada kurir melalui WebSocket.

### 3.2.4 Activity Diagram Pengiriman (Delivery)

Activity diagram pengiriman menggambarkan alur aktivitas pada sisi operasional logistik yang dilakukan oleh kurir. Aktivitas dimulai ketika kurir membuka aplikasi mobile dan login.

Kurir melihat daftar tugas pengiriman harian yang telah ditugaskan oleh sistem. Kurir memilih tugas dan menekan tombol mulai untuk memulai pengiriman. Sistem secara otomatis mengaktifkan live GPS tracking dan memperbarui status pesanan menjadi "On Delivery".

Kurir kemudian menempuh perjalanan menuju lokasi pelanggan. Sepanjang perjalanan, aplikasi kurir secara periodik mengirimkan koordinat GPS ke server untuk diperbarukan ke dashboard admin. Hal ini memungkinkan admin dan pelanggan untuk memantau posisi kurir secara real-time.

Setibanya di tujuan, kurir melakukan serah terima barang dengan pelanggan. Proses validasi melibatkan penangkapan foto lokasi dan permintaan tanda tangan digital pelanggan melalui Canvas API. Kurir kemudian mengunggah foto dan menandatangani bukti pengiriman.

Setelah data bukti terunggah, sistem secara otomatis memfinalisasi pesanan dengan memperbarui status menjadi "Completed" dan mengirimkan notifikasi kepada pelanggan bahwa paket telah diterima dengan baik.

## 3.3 Perancangan Basis Data

Perancangan basis data sistem mencakup entity-entity utama dan relasi antar tabel. Sistem menggunakan PostgreSQL sebagai sistem manajemen basis data dengan Prisma ORM sebagai jembatan ke kode aplikasi.

### 3.3.1 Entity Relationship Diagram (ERD)

Basis data sistem terdiri dari entitas-entitas utama sebagai berikut:

**Customer** merupakan entitas untuk menyimpan data pelanggan yang telah registrasi. Atribut meliputi id, name, phone, address, username, dan password. Customer memiliki relasi one-to-many dengan Order.

**Driver** merupakan entitas untuk menyimpan data kurir atau pengemudi. Atribut meliputi id, username, password, name, phone, isActive, vehicleType, vehicleBrand, vehiclePlate, dan vehicleColor. Driver memiliki relasi one-to-many dengan Order.

**Product** merupakan entitas untuk menyimpan data produk atau barang yang dijual. Atribut meliputi id, name, description, price, imageUrl, category, rating, sold, seller, sellerCity, stock, dan unit. Product memiliki relasi one-to-many dengan ProductVariant.

**ProductVariant** merupakan entitas untuk menyimpan variasi satuan produk. Atribut meliputi id, productId, unitName, dan price. ProductVariant memiliki relasi many-to-one dengan Product.

**Order** merupakan entitas untuk menyimpan data pesanan. Atribut meliputi id, customerId, customerName, customerPhone, pickupAddress, deliveryAddress, totalAmount, status, paymentMethod, driverId, deliveryPhoto, createdAt, dan updatedAt. Order memiliki relasi many-to-one dengan Customer dan Driver, serta relasi one-to-many dengan OrderItem.

**OrderItem** merupakan entitas untuk menyimpan detail item dalam pesanan. Atribut meliputi id, orderId, productName, unitName, unitPrice, quantity, dan subtotal. OrderItem memiliki relasi many-to-one dengan Order.

**TimeSlot** merupakan entitas untuk menyimpan slot waktu pengiriman yang tersedia. Atribut meliputi id, slotTime, slotDate, bookings, dan maxBookings.

### 3.3.2 Relasi Antar Tabel

Relasi antar tabel dirancang untuk memastikan integritas data dan mendukung operasi bisnis sistem:

- Customer ke Order: One-to-Many - Satu pelanggan dapat memiliki banyak pesanan
- Driver ke Order: One-to-Many - Satu kurir dapat ditugaskan pada banyak pesanan
- Product ke ProductVariant: One-to-Many - Satu produk dapat memiliki beberapa variant satuan
- Order ke OrderItem: One-to-Many - Satu pesanan dapat memiliki beberapa item produk

### 3.3.3 Desain Tabel Utama

#### Tabel Products

| Kolom | Tipe Data | Deskripsi |
|-------|-----------|-----------|
| id | INT (PK) | Primary key |
| name | VARCHAR(255) | Nama produk |
| description | TEXT | Deskripsi produk |
| price | DECIMAL(12,2) | Harga produk |
| imageUrl | VARCHAR(500) | URL gambar produk |
| category | VARCHAR(100) | Kategori produk |
| rating | DECIMAL(3,1) | Rating produk |
| sold | INT | Jumlah terjual |
| seller | VARCHAR(255) | Nama penjual |
| sellerCity | VARCHAR(100) | Kota penjual |
| stock | INT | Stok tersedia |
| unit | VARCHAR(50) | Satuan default |
| createdAt | TIMESTAMP | Waktu dibuat |
| updatedAt | TIMESTAMP | Waktu diupdate |

#### Tabel Orders

| Kolom | Tipe Data | Deskripsi |
|-------|-----------|-----------|
| id | INT (PK) | Primary key |
| customerId | INT (FK) | Foreign key ke Customer |
| customerName | VARCHAR(255) | Nama pelanggan |
| customerPhone | VARCHAR(20) | No. telepon pelanggan |
| pickupAddress | TEXT | Alamat pengambilan |
| deliveryAddress | TEXT | Alamat pengiriman |
| totalAmount | DECIMAL(12,2) | Total pembayaran |
| status | ENUM | Status pesanan |
| paymentMethod | VARCHAR(50) | Metode pembayaran |
| driverId | INT (FK) | Foreign key ke Driver |
| deliveryPhoto | VARCHAR(500) | URL foto pengiriman |
| createdAt | TIMESTAMP | Waktu dibuat |
| updatedAt | TIMESTAMP | Waktu diupdate |

## 3.4 Rancangan Fitur Sistem

Berdasarkan analisis kebutuhan dan arsitektur yang telah dirancang, pengembangan sistem dibagi menjadi tiga modul utama yang saling terintegrasi.

### 3.4.1 Modul Web Administrator

Modul Web Administrator dikembangkan menggunakan SvelteKit dan ditujukan bagi pengelola toko untuk memantau operasional bisnis dan logistik secara terpusat. Modul ini menyediakan antarmuka berbasis web yang responsif dan cepat.

#### Dashboard Monitoring

Dashboard menampilkan visualisasi data ringkas mengenai total pendapatan hari ini, jumlah pesanan aktif, dan statistik pesanan per jam serta per bulan. Dashboard menggunakan grafik batang untuk menampilkan data secara visual dan melakukan pembaruan otomatis setiap 30 detik.

#### Manajemen Inventori

Fitur manajemen inventori memungkinkan admin untuk mengelola data produk meliputi penambahan produk baru dengan gambar, pengelolaan varian satuan seperti KG, Box, Sack-25kg, Sack-50kg, dan Piece, serta pemantauan stok dengan indikator warna untuk tingkat stok rendah, sedang, dan tinggi.

Sistem menampilkan notifikasi otomatis ketika stok menyentuh angka di bawah batas yang ditentukan. Admin dapat dengan mudah mencari produk berdasarkan nama atau satuan.

#### Manajemen Pesanan

Fitur manajemen pesanan menampilkan daftar semua pesanan dengan filter berdasarkan status. Admin dapat melihat detail pesanan lengkap termasuk item yang dipesan, data pelanggan, dan status pembayaran. Fitur print invoice memungkinkan admin mencetak nota digital dalam format yang rapi.

Untuk pesanan yang telah selesai dikirim, admin dapat melihat foto bukti pengiriman yang diunggah oleh kurir.

#### Manajemen Kurir

Fitur manajemen kurir memungkinkan admin untuk menambah kurir baru dengan data username, password, nama, dan nomor telepon. Admin dapat melihat daftar semua kurir beserta status aktif atau nonaktif mereka.

Admin dapat mengaktifkan atau menonaktifkan kurir sesuai kebutuhan operasional. Sistem juga menyimpan informasi kendaraan kurir termasuk jenis, merek, plat nomor, dan warna kendaraan.

#### Pelacakan Armada

Fitur pelacakan armada menampilkan lokasi semua kurir yang sedang aktif di atas peta interaktif berbasis OpenStreetMap. Admin dapat mencari kurir berdasarkan nama atau lokasi dan melihat detail posisi koordinat latitude dan longitude.

Peta diperbarui secara real-time untuk memberikan informasi lokasi yang akurat kepada admin.

### 3.4.2 Modul Mobile Customer

Modul Mobile Customer dikembangkan menggunakan Flutter untuk memberikan pengalaman belanja yang responsif bagi pengguna akhir. Modul ini dirancang dengan antarmuka yang intuitif dan mudah digunakan.

#### Katalog dan Keranjang Belanja

Fitur katalog produk menampilkan daftar produk dengan gambar, nama, harga, dan informasi stok. Pelanggan dapat mencari produk dan melihat detail produk lengkap termasuk deskripsi dan varian satuan yang tersedia.

Fitur keranjang belanja memungkinkan pelanggan menambah, mengurangi, atau menghapus produk sebelum checkout. Sistem menghitung subtotal untuk setiap item dan total keseluruhan secara otomatis.

#### Proses Pembayaran

Integrasi pembayaran digital dilakukan melalui Payment Gateway Midtrans yang mendukung berbagai metode pembayaran populer di Indonesia termasuk Transfer Bank, E-Wallet, dan QRIS.

Setelah memilih metode pembayaran, pelanggan diarahkan ke halaman pembayaran Midtrans. Sistem menunggu konfirmasi pembayaran secara real-time melalui webhook dan secara otomatis memperbarui status pesanan tanpa memerlukan verifikasi manual.

#### Pemilihan Jadwal Pengiriman

Setelah pembayaran sukses, pelanggan diberikan akses untuk memilih slot waktu pengiriman yang tersedia. Sistem menampilkan tanggal dan jam yang dapat dipilih sesuai dengan kuota yang tersedia pada setiap slot waktu.

Fitur ini mencegah bentrokan jadwal pengiriman karena setiap slot memiliki batas maksimum pemesanan.

#### Pelacakan Pesanan

Pelanggan dapat memantau posisi kurir secara real-time melalui peta digital interaktif. Informasi driver termasuk nama, nomor telepon, dan plat kendaraan ditampilkan untuk memudahkan koordinasi.

Status pesanan diperbarui secara otomatis melalui mekanisme polling setiap 5 detik untuk memberikan informasi terkini kepada pelanggan.

#### Riwayat Transaksi

Fitur riwayat transaksi menampilkan daftar lengkap riwayat belanja pengguna mulai dari pesanan yang sedang diproses, dikirim, hingga yang telah selesai atau dibatalkan. Pelanggan dapat melihat detail nota digital dan status pengiriman terakhir untuk keperluan pembelian ulang atau komplain.

### 3.4.3 Modul Mobile Kurir

Modul Mobile Kurir dikembangkan menggunakan Flutter dengan fokus pada operasional lapangan dan validasi data lokasi. Modul ini dirancang untuk memberikan kemudahan bagi kurir dalam menyelesaikan tugas pengiriman.

#### Manajemen Tugas Pengiriman

Kurir dapat melihat daftar tugas harian yang telah ditugaskan oleh sistem. Setiap tugas menampilkan detail lengkap termasuk alamat penerima, nomor telepon, dan jumlah item yang akan diantarkan.

Kurir dapat menerima tugas dan memperbarui status pengiriman sesuai dengan progress pengiriman saat itu. Status yang tersedia meliputi Menunggu, Menuju Pickup, Diambil, dan Dalam Perjalanan.

#### Navigasi dan Live Location

Aplikasi kurir menggunakan koneksi WebSocket yang persisten untuk mengirimkan lokasi terkini kurir ke server secara terus-menerus. Hal ini memungkinkan admin dan pelanggan untuk memantau posisi kurir secara real-time.

Kurir juga menerima notifikasi penugasan pesanan baru secara instan tanpa perlu refresh halaman manual.

#### Bukti Pengiriman Digital

Fitur validasi penerimaan barang memanfaatkan Canvas API untuk menangkap tanda tangan digital pelanggan. Kurir diwajibkan mengambil foto lokasi pengiriman dan meminta tanda tangan digital pelanggan langsung di layar smartphone sebagai bukti sah serah terima barang.

Foto dan tanda tangan kemudian diunggah ke server sebagai dokumentasi penyelesaian tugas.

#### Profil dan Informasi Kendaraan

Kurir dapat mengelola profil pribadi dan informasi kendaraan mereka melalui halaman pengaturan. Informasi kendaraan包括 jenis, merek, plat nomor, dan warna yang ditampilkan kepada pelanggan saat pelacakan pesanan.