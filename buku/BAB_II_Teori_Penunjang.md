# BAB II
# TEORI PENUNJANG

## 2.1 Framework dan Bahasa Pemrograman

Pengembangan sistem multiplatform memerlukan penggunaan beberapa framework dan bahasa pemrograman yang telah terbukti handal dalam membangun aplikasi skala enterprise. Pemilihan teknologi ini didasarkan pada kemampuan setiap tools dalam menangani kebutuhan spesifik dari masing-masing modul dalam arsitektur sistem.

### 2.1.1 NestJS

NestJS adalah framework server-side untuk Node.js yang efisien, dapat diskalakan (scalable), dan dibangun dengan dukungan penuh TypeScript. Framework ini menggabungkan elemen-elemen dari Pemrograman Berorientasi Objek (OOP), Pemrograman Fungsional (FP), dan Pemrograman Reaktif Fungsional (FRP).

Struktur modular NestJS sangat mirip dengan Angular, yang memungkinkan pengembang mengorganisir kode ke dalam modul-modul terpisah seperti Modul Auth, Modul Produk, Modul Logistik, dan lainnya. Pendekatan ini menjadikan kode lebih rapi, mudah diuji, dan mudah dipelihara dibandingkan framework Node.js konvensional.

Dalam arsitektur sistem ini, NestJS berfungsi sebagai backend utama yang menangani seluruh logika bisnis seperti perhitungan stok dengan algoritma Reorder Point, manajemen pesanan, penjadwalan pengiriman, komunikasi real-time melalui WebSocket, serta interaksi dengan layanan eksternal seperti Payment Gateway Midtrans dan OpenRouteService API.

### 2.1.2 SvelteKit

SvelteKit adalah meta-framework untuk membangun aplikasi web modern yang dibangun di atas library Svelte. Berbeda dengan framework tradisional seperti React atau Vue yang melakukan sebagian besar pekerjaan di browser menggunakan Virtual DOM, SvelteKit melakukan proses kompilasi pada tahap build time.

Pendekatan ini mengubah komponen deklaratif menjadi kode JavaScript imperatif yang sangat efisien yang secara langsung memanipulasi DOM. Hasilnya adalah performa yang sangat ringan dan cepat, memungkinkan admin toko memuat halaman laporan penjualan yang padat data dan memantau stok barang tanpa lag.

Dalam proyek ini, SvelteKit digunakan untuk membangun Dashboard Admin Web. Keunggulan utamanya adalah pengalaman pengguna yang responsif dan waktu muat halaman yang cepat, sangat penting untuk admin yang memerlukan akses real-time terhadap data operasional toko.

### 2.1.3 Flutter & Dart

Flutter adalah Software Development Kit (SDK) antarmuka pengguna (UI) open-source yang dikembangkan oleh Google untuk membangun aplikasi yang dikompilasi secara native (asli) untuk seluler (Android), web, dan desktop dari satu basis kode tunggal. Flutter menggunakan bahasa pemrograman Dart yang dioptimalkan untuk klien yang cepat dan produktif.

Konsep inti Flutter adalah widget, di mana setiap elemen tampilan adalah widget yang dapat dikustomisasi. Flutter menyediakan widget Material Design dan Cupertino yang memungkinkan pengembangan aplikasi dengan tampilan native untuk Android dan iOS secara bersamaan.

Dalam penelitian ini, Flutter digunakan untuk membangun dua aplikasi mobile: Aplikasi Customer dan Aplikasi Kurir. Kemampuan multiplatform Flutter memastikan aplikasi dapat berjalan mulus di berbagai perangkat smartphone dengan performa tinggi (60fps), yang sangat krusial untuk fitur peta interaktif menggunakan OpenStreetMap dan pemindaian QR Code yang lancar.

## 2.2 Manajemen Basis Data

Sistem informasi yang kompleks memerlukan sistem manajemen basis data yang handal untuk menyimpan dan mengelola data secara efisien. Pemilihan PostgreSQL dan Prisma ORM dalam proyek ini didasarkan pada kemampuan keduanya dalam menangani data relasional yang kompleks dengan sintaks yang type-safe dan intuitif.

### 2.2.1 PostgreSQL

PostgreSQL adalah sistem manajemen basis data relasional objek (ORDBMS) yang kuat dan open-source. PostgreSQL dikenal dengan keandalan, ketahanan data, dan performanya dalam menangani kueri yang kompleks. PostgreSQL mendukung berbagai fitur lanjutan seperti JOIN kompleks, transaction, foreign key, trigger, stored procedure, dan view.

Dalam proyek ini, PostgreSQL berfungsi sebagai tempat penyimpanan utama untuk data pengguna, transaksi penjualan, data produk dan inventori, serta data logistik pengiriman. PostgreSQL dipilih karena kemampuannya dalam menangani relasi antar tabel yang kompleks seperti relasi antara tabel Pesanan dan Pengiriman yang memerlukan integritas referensial yang ketat.

Keunggulan PostgreSQL lainnya adalah dukungan penuh terhadap JSON data type yang memungkinkan penyimpanan data semi-structured, serta fitur full-text search untuk pencarian produk yang efisien. Selain itu, PostgreSQL memiliki ekosistem Extensions yang kaya seperti PostGIS untuk data geospasial yang mendukung fitur Location-Based Service dalam sistem.

### 2.2.2 Prisma ORM

Prisma adalah Object-Relational Mapper (ORM) generasi baru yang menjembatani kode TypeScript di NestJS dengan database PostgreSQL. Prisma memungkinkan pengembang melakukan operasi CRUD (Create, Read, Update, Delete) dengan sintaks yang type-safe dan intuitif tanpa perlu menulis kueri SQL mentah secara manual.

Prisma Schema adalah pusat definisi model data dalam aplikasi. Setiap model dalam schema akan secara otomatis menghasilkan struktur tabel yang sesuai di PostgreSQL serta kode TypeScript yang dapat digunakan di seluruh aplikasi. Pendekatan ini memastikan konsistensi antara struktur database dan kode aplikasi.

Dalam proyek ini, Prisma digunakan untuk mendefinisikan dan mengelola relasi antar entitas seperti User, Product, Order, Delivery, dan CourierAssignment. Prisma juga mempermudah manajemen relasi antar tabel dan migrasi database ketika struktur schema berubah, sehingga proses pengembangan dan pemeliharaan sistem menjadi lebih efisien.

## 2.3 Konsep Algoritma dan Logika Sistem

Implementasi sistem yang efisien memerlukan penerapan algoritma yang tepat untuk menyelesaikan masalah operasional yang spesifik. Dalam konteks ini, tiga algoritma utama diimplementasikan untuk meningkatkan efisiensi manajemen inventori dan pengiriman barang.

### 2.3.1 Reorder Point (ROP)

Reorder Point (ROP) adalah metode manajemen inventori yang menentukan tingkat stok minimum di mana pemesanan ulang barang harus dilakukan. Tujuan utama ROP adalah memastikan bahwa stok baru tiba tepat sebelum stok yang ada habis, sehingga mencegah terjadinya kekosongan barang (stockout) yang dapat merugikan penjualan.

Rumus dasar ROP yang diterapkan dalam sistem ini adalah:

**ROP = (Lead Time × Rata-rata Penjualan Harian) + Safety Stock**

Keterangan:
- **Lead Time**: Waktu yang diperlukan dari pemesanan hingga barang diterima (dalam hari)
- **Rata-rata Penjualan Harian**: Jumlah unit terjual per hari rata-rata
- **Safety Stock**: Jumlah stok pengaman untuk menghadapi ketidakpastian permintaan

Penerapan algoritma ROP pada backend NestJS memungkinkan sistem memberikan notifikasi otomatis kepada admin ketika stok suatu barang menyentuh angka kritis. Dengan demikian, manajemen stok menjadi lebih cerdas dan efisien karena owner dapat melakukan reorder tepat waktu sebelum stok benar-benar habis.

Dalam implementasi sistem, setiap produk memiliki parameter Lead Time dan Safety Stock yang dapat dikonfigurasi melalui dashboard admin. Sistem secara otomatis menghitung ROP untuk setiap produk berdasarkan data penjualan historis dan memperbarui status rekomendasi pemesanan ulang secara real-time.

### 2.3.2 Nearest Neighbor untuk Optimasi Rute

Algoritma Nearest Neighbor adalah algoritma optimasi rute yang bekerja dengan prinsip Greedy. Algoritma ini bertujuan menentukan urutan kunjungan yang paling efisien dengan cara memilih lokasi tujuan berikutnya yang memiliki jarak terdekat dari posisi saat ini.

Prosedur algoritma Nearest Neighbor adalah sebagai berikut:
1. Mulai dari lokasi awal (depot / toko)
2. Cari lokasi tujuan terdekat yang belum dikunjungi
3. Pindahkan ke lokasi tersebut dan tandai sebagai dikunjungi
4. Ulangi langkah 2-3 hingga semua lokasi tujuan telah dikunjungi
5. Kembali ke lokasi awal

Metode ini sangat efektif diterapkan pada sistem logistik untuk meminimalkan total jarak tempuh kurir dalam satu siklus pengiriman. Algoritma Nearest Neighbor memiliki waktu komputasi yang cepat sehingga tidak membebani kinerja aplikasi, menjadikannya cocok untuk aplikasi real-time yang memerlukan respons cepat.

Dalam konteks penelitian ini, algoritma Nearest Neighbor digunakan untuk menentukan urutan rute pengiriman barang berdasarkan jarak terdekat dari posisi kurir saat itu. Sistem memanfaatkan API OpenRouteService untuk menghitung jarak antar koordinat dan menghasilkan urutan kunjungan yang optimal. Dengan implementasi ini, kurir dapat menempuh jarak yang lebih pendek dan efisien dibandingkan menentukan rute secara manual atau berdasarkan intuisi.

### 2.3.3 Mekanisme Auto-dispatch

Auto-dispatch adalah mekanisme otomatisasi penugasan tugas kepada kurir tanpa intervensi manual dari admin. Sistem menentukan kurir yang paling tepat berdasarkan perhitungan skor yang menggabungkan parameter jarak dan ketersediaan armada.

Proses auto-dispatch dalam sistem ini bekerja sebagai berikut:
1. Ketika pesanan baru masuk dan siap untuk dikirim, sistem mengidentifikasi kurir yang sedang dalam status online
2. Sistem menghitung skor proximity menggunakan rumus Haversine untuk menentukan jarak antara posisi kurir saat ini dengan lokasi toko
3. Kurir dengan jarak terdekat dan status available akan secara otomatis ditugaskan untuk pesanan tersebut
4. Notifikasi penugasan dikirimkan ke aplikasi kurir secara real-time melalui WebSocket

Rumus Haversine digunakan untuk menghitung jarak bola (great-circle distance) antara dua titik di permukaan bumi berdasarkan koordinat lintang dan bujur. Dengan mekanisme ini, pesanan dapat langsung dialokasikan kepada kurir yang berada di radius terdekat dari lokasi toko untuk mempercepat proses penjemputan barang.

Implementasi auto-dispatch mengurangi beban kerja admin dalam pemilihan manual kurir dan memastikan penugasan dilakukan secara objektif berdasarkan proximity dan ketersediaan. Sistem juga mempertimbangkan beban kerja kurir saat ini untuk memastikan distribusi tugas yang merata di antara kurir yang tersedia.

## 2.4 Layanan dan Protokol Terintegrasi

Sistem informasi modern memerlukan integrasi dengan berbagai layanan eksternal dan implementasi protokol komunikasi yang tepat untuk memastikan functionality yang lengkap. Bagian ini menjelaskan layanan dan protokol yang diintegrasikan dalam sistem.

### 2.4.1 Arsitektur Client-Server

Arsitektur Client-Server adalah model komputasi terdistribusi yang membagi tugas antara penyedia sumber daya (Server) dan peminta layanan (Client). Dalam model ini, komunikasi dilakukan melalui jaringan komputer di mana klien mengirimkan permintaan (request) dan server memproses serta mengirimkan balasan (response).

Keuntungan arsitektur Client-Server meliputi:
- **Skalabilitas**: Server dapat ditingkatkan kapasitasnya sesuai kebutuhan
- **Maintenance Terpusat**: Perubahan dan pembaruan dapat dilakukan di sisi server
- **Keamanan**: Data tersimpan terpusat dengan kontrol akses yang ketat
- **Resource Sharing**: Multiple clients dapat mengakses resource yang sama secara bersamaan

Dalam penelitian ini, arsitektur Client-Server menjadi fondasi utama topologi sistem. Aplikasi Mobile (Flutter) dan Web Dashboard (SvelteKit) bertindak sebagai sisi Client yang berada di lokasi fisik berbeda-beda (terdistribusi). Sementara itu, Server (NestJS) bertindak sebagai pusat pemrosesan logika bisnis dan basis data yang melayani permintaan dari banyak klien secara bersamaan.

Dengan arsitektur ini, sinkronisasi data logistik antara kurir di lapangan dan admin di toko dapat dilakukan secara real-time. Klien tidak saling berkomunikasi secara langsung, melainkan terhubung ke satu titik pusat yaitu NestJS Server yang mengelola seluruh logika bisnis dan interaksi dengan database.

### 2.4.2 WebSocket & Komunikasi Real-time

WebSocket adalah protokol komunikasi komputer yang menyediakan saluran komunikasi dua arah (full-duplex) melalui koneksi TCP tunggal. Berbeda dengan model HTTP tradisional yang bersifat request-response, WebSocket memungkinkan server untuk mengirim data ke client tanpa adanya request terlebih dahulu.

Keunggulan WebSocket dibandingkan HTTP polling adalah:
- **Latency Rendah**: Data dapat langsung dikirim tanpa delay
- **Efisiensi Resource**: Tidak perlu membuat koneksi baru untuk setiap komunikasi
- **Full-duplex**: Komunikasi dua arah secara bersamaan
- **Persistent Connection**: Koneksi tetap terbuka selama session

Dalam penelitian ini, protokol WebSocket digunakan untuk menangani dua kebutuhan utama secara single connection:

1. **Live Tracking**: Mengirim koordinat GPS kurir ke server secara periodik untuk dipantau posisinya oleh admin melalui dashboard
2. **In-App Notification**: Mengirim peringatan pesanan baru kepada kurir secara instan tanpa perlu refresh halaman

Implementasi WebSocket pada sisi server menggunakan library Socket.io yang terintegrasi dengan NestJS. Library ini menangani automatic reconnection dan fallback mechanism jika browser tidak mendukung WebSocket natively. Di sisi client, Flutter menggunakan library web_socket_channel untuk establish koneksi WebSocket.

Karena standar operasional kurir mewajibkan aplikasi selalu terbuka (standby) selama jam kerja, maka notifikasi yang diimplementasikan hanya bersifat In-App Notification yang bekerja saat aplikasi aktif (foreground). Fitur Push Notification untuk aplikasi yang ditutup total tidak diimplementasikan dalam sistem ini.

### 2.4.3 Payment Gateway (Midtrans)

Payment Gateway adalah layanan perantara yang mengotorisasi pemrosesan pembayaran kartu kredit atau pembayaran langsung bagi bisnis e-commerce. Payment Gateway bertindak sebagai penghubung antara merchant, bank acquirer, dan payment network untuk memastikan transaksi pembayaran berlangsung dengan aman dan efisien.

Midtrans adalah payment gateway yang populer di Indonesia dan telah terintegrasi dengan berbagai metode pembayaran seperti Virtual Account, QRIS, E-Wallet, dan transfer bank. Midtrans menyediakan API yang mudah diintegrasikan dengan sistem dan mendukung proses verifikasi otomatis melalui webhook.

Fitur utama Midtrans yang diintegrasikan dalam sistem meliputi:
- **Multiple Payment Methods**: Mendukung berbagai metode pembayaran populer di Indonesia
- **Automatic Notification**: Webhook untuk verifikasi status pembayaran secara real-time
- **Transaction Reporting**: Laporan transaksi lengkap untuk admin
- **Secure Transaction**: Standar keamanan PCI-DSS compliant

Sistem ini memanfaatkan fitur Webhook (HTTP Notification) dari Midtrans. Ketika pelanggan berhasil melakukan pembayaran, Midtrans akan mengirimkan sinyal ke backend NestJS secara real-time untuk memperbarui status pesanan menjadi "Dibayar" tanpa memerlukan verifikasi manual dari admin toko.

### 2.4.4 Location-Based Service (LBS) dan Layanan Peta

Location-Based Service (LBS) adalah layanan informasi yang dapat diakses melalui perangkat seluler dengan memanfaatkan kemampuan jaringan untuk menentukan posisi geografis pengguna. LBS menggabungkan teknologi navigasi, sistem informasi geografis, dan telekomunikasi untuk memberikan layanan yang kontekstual terhadap lokasi.

Dalam konteks penelitian ini, sistem tidak menggunakan layanan berbayar Google Maps Platform. Sebagai penggantinya, sistem memanfaatkan:

1. **OpenStreetMap (OSM)**: Sebagai peta dasar (basemap) untuk visualisasi lokasi. OSM adalah proyek open source yang menyediakan data peta dunia yang dapat digunakan secara gratis.

2. **OpenRouteService (ORS) API**: Untuk fitur perhitungan rute (routing) dan matriks jarak (Distance Matrix) yang diperlukan dalam algoritma optimasi pengiriman.

Teori LBS menjadi landasan ilmiah bagi fitur pelacakan armada (fleet tracking) dalam aplikasi. Sistem tidak hanya sekadar menampilkan peta, tetapi melakukan pengolahan data spasial secara terdistribusi. Posisi kurir (Latitude/Longitude) dikirimkan secara periodik melalui jaringan data seluler ke server, yang kemudian didistribusikan kembali ke dashboard admin untuk memberikan visualisasi pergerakan armada secara akurat.

Fitur live tracking dalam sistem memungkinkan admin memantau posisi kurir secara real-time saat status pengiriman aktif. Data koordinat kurir dikirimkan setiap 5 detik melalui koneksi WebSocket yang persisten, sehingga admin memiliki visibilitas penuh terhadap lokasi armada pengiriman.

### 2.4.5 Digital Signature (Canvas API)

Digital Signature dalam konteks aplikasi ini merujuk pada mekanisme penangkapan input sentuhan (touch input) pengguna pada layar perangkat seluler yang dikonversi menjadi format citra digital. Fitur ini merupakan komponen kunci dari fitur Proof of Delivery (PoD).

Tanda tangan digital diimplementasikan menggunakan pustaka berbasis HTML5 Canvas yang di-wrap untuk digunakan dalam Flutter. Proses capture tanda tangan adalah sebagai berikut:

1. Pengguna (pelanggan) menggoreskan tanda tangan langsung di area canvas pada layar perangkat kurir
2. Koordinat titik-titik goresan ditangkap secara real-time dan disimpan dalam array
3. Data array tersebut kemudian di-render menjadi gambar PNG menggunakan Canvas API
4. Gambar tanda tangan diunggah ke server sebagai bukti serah terima

Teknologi ini memastikan non-repudiation atau tidak dapat disangkal dalam serah terima barang. Dengan adanya bukti tanda tangan digital yang tersimpan di server, tidak ada pihak yang dapat menyangkal telah menerima atau menyerahkan barang.

Canvas API menyediakan kemampuan untuk menggambar grafik dan gambar secara programatik. Dalam implementasi ini, API ini digunakan untuk merekonstruksi goresan tanda tangan dari data koordinat dan mengkonversinya menjadi format gambar yang dapat disimpan dan diverifikasi.

### 2.4.6 Aplikasi Pembanding (Lalamove)

Lalamove adalah platform pengiriman on-demand yang menjadi pemimpin pasar dalam layanan logistik urbain. Platform ini menghubungkan bisnis dengan pengemudi pengantaran terdekat secara real-time. Untuk mengevaluasi keunggulan dan kelemahan sistem yang dikembangkan, dilakukan perbandingan fitur seperti terlihat pada Tabel 1.

**Tabel 1. Tabel Perbandingan Fitur Sistem dengan Lalamove**

| Fitur                                           | Lalamove | Sistem Yang Dikembangkan |
|-------------------------------------------------|:--------:|:------------------------:|
| Pelacakan Lokasi Real-time                      |     ✓    |            ✓             |
| Optimasi Rute Multi-stop                        |     ✓    |            ✓             |
| Bukti Pengiriman (Foto & Tanda Tangan)          |     ✓    |            ✓             |
| Jangkauan Area Layanan Nasional                 |     ✓    |            ✗             |
| Ketersediaan Driver 24 Jam                      |     ✓    |            ✗             |
| Integrasi Otomatis dengan Stok                  |     ✗    |            ✓             |

Berdasarkan Tabel 1, sistem yang dibangun memiliki standar fitur operasional yang setara dengan Lalamove dalam hal pelacakan lokasi real-time, optimasi rute multi-stop, serta validasi bukti pengiriman digital. Hal ini menunjukkan bahwa secara teknis, sistem mampu menangani kebutuhan pengiriman barang dengan standar industri logistik modern.

Namun, sistem memiliki batasan pada aspek jangkauan area nasional dan ketersediaan pengemudi 24 jam. Hal ini wajar karena sistem dirancang khusus untuk manajemen armada internal toko yang memiliki jam kerja tetap, bukan untuk layanan crowdsourcing umum seperti Lalamove.

Keunggulan kompetitif utama sistem terletak pada fitur Integrasi Otomatis dengan Stok. Lalamove beroperasi sebagai entitas terpisah tanpa akses ke database gudang pengirim, sedangkan sistem ini menghubungkan proses pengiriman langsung dengan database inventori, sehingga stok barang terpotong secara otomatis dan real-time begitu status pengiriman terkonfirmasi selesai.

## 2.5 Pengujian Perangkat Lunak (UAT)

User Acceptance Testing (UAT) atau pengujian penerimaan pengguna adalah tahap akhir dalam siklus pengembangan perangkat lunak di mana sistem diuji oleh target pengguna sebenarnya sebelum diluncurkan secara resmi. UAT merupakan verifikasi terakhir yang memastikan bahwa sistem sesuai dengan kebutuhan bisnis dan dapat dioperasikan dengan nyaman dalam skenario operasional nyata.

Tujuan utama UAT adalah memvalidasi apakah alur sistem sudah sesuai dengan kebutuhan bisnis dan apakah pengguna dapat menyelesaikan tugas-tugas mereka menggunakan sistem dengan efektif. UAT berbeda dengan pengujian fungsi (functional testing) karena fokusnya pada kegunaan dari sudut pandang pengguna akhir, bukan pada deteksi bug teknis.

Metodologi UAT dalam penelitian ini mencakup:

1. **Persiapan**: Menetapkan skenario uji coba yang mencakup alur lengkap dari pemesanan hingga penyelesaian pengiriman. Skenario ini dirancang berdasarkan use case diagram dan activity diagram yang telah dirancang sebelumnya.

2. **Pelaksanaan**: Pengujian melibatkan partisipan yang mencakup Admin Toko, Kurir armada internal, dan Pelanggan sukarelawan. Target responden adalah minimal 1 orang Admin, 3 orang Kurir, dan 25 orang Pelanggan.

3. **Evaluasi**: Partisipan diminta untuk menyelesaikan skenario operasional nyata dan memberikan penilaian melalui kuesioner skala Likert yang disebarkan menggunakan Google Form. Data yang diperoleh kemudian dianalisis untuk mengukur efektivitas sistem.

Aspek yang diukur dalam UAT meliputi:
- **Kegunaan Antarmuka**: Seberapa mudah pengguna dapat menavigasi dan menggunakan fitur-fitur sistem
- **Fungsionalitas**: Apakah semua fitur bekerja sesuai dengan harapan
- **Performa**: Kecepatan respons sistem dalam kondisi operasional normal
- **Kepuasan Pengguna**: Tingkat kepuasan keseluruhan terhadap sistem

Hasil pengujian UAT dievaluasi untuk memastikan bahwa fitur-fitur kompleks seperti pelacakan lokasi real-time dan tanda tangan digital dapat diterima dan dioperasikan dengan baik oleh pengguna target. Temuan dari UAT akan digunakan untuk memperbaiki aspek-aspek yang dianggap kurang intuitif atau problematic sebelum sistem diluncurkan secara resmi.