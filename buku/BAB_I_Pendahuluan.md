# BAB I
# PENDAHULUAN

## 1.1 Latar Belakang

Perkembangan teknologi di sektor ritel menuntut toko modern untuk beralih dari manajemen konvensional ke sistem digital yang terintegrasi demi meningkatkan efisiensi dan kepuasan pelanggan. Namun, terdapat kesenjangan teknologi yang signifikan antara marketplace besar dengan toko mandiri yang masih mengelola operasionalnya secara manual. Akibatnya, banyak toko mandiri kesulitan bersaing dalam hal kecepatan pelayanan, akurasi ketersediaan stok, dan kepastian pengiriman barang kepada konsumen.

Kendala operasional yang krusial meliputi pencatatan stok yang tidak real-time, sehingga memicu risiko kehabisan barang tanpa adanya peringatan dini bagi pemilik toko. Di sisi logistik, pengiriman menggunakan kurir internal seringkali tidak transparan karena minimnya bukti valid seperti lokasi GPS atau foto penerimaan barang. Selain itu, pengaturan jadwal pengiriman yang dilakukan secara manual rentan menyebabkan bentrokan slot waktu antar pelanggan dan ketidakakuratan estimasi waktu sampai.

Sebagai solusi, penelitian ini mengusulkan pengembangan sistem informasi E-Commerce dan manajemen inventori berbasis multiplatform. Sistem ini menyatukan proses penjualan, pemantauan stok, dan pengiriman dalam satu pintu. Keunggulan utamanya terletak pada integrasi data real-time antara aplikasi admin dan kurir, serta penerapan algoritma Reorder Point (ROP) untuk memberikan rekomendasi waktu pemesanan ulang barang secara akurat.

Selain masalah jadwal, kendala operasional lainnya adalah ketidakefisienan rute pengiriman. Saat ini, penentuan urutan pengiriman paket sepenuhnya bergantung pada intuisi kurir tanpa adanya sistem yang mengelompokkan area tujuan secara otomatis. Hal ini seringkali menyebabkan kurir menempuh jarak yang lebih jauh dari yang seharusnya (rute zigzag), yang berdampak pada pemborosan bahan bakar dan keterlambatan waktu sampai ke pelanggan. Oleh karena itu, diperlukan implementasi algoritma optimasi rute untuk membantu kurir menentukan urutan pengiriman yang paling efisien.

Berdasarkan uraian tersebut, penulis tertarik untuk mengembangkan sebuah sistem informasi E-Commerce dan manajemen distribusi barang terintegrasi berbasis multiplatform menggunakan framework NestJS, SvelteKit, dan Flutter. Sistem ini diharapkan dapat mengatasi berbagai permasalahan tersebut dan memberikan solusi nyata bagi toko modern dalam mengelola operasional bisnisnya secara lebih efisien.

## 1.2 Perumusan Masalah

Berdasarkan latar belakang yang telah diuraikan, maka perumusan masalah dalam penelitian ini adalah sebagai berikut:

1. Bagaimana mengembangkan sistem informasi E-Commerce dan manajemen inventori berbasis multiplatform yang dapat mengintegrasikan proses penjualan, pemantauan stok, dan pengiriman dalam satu sistem?

2. Bagaimana menerapkan mekanisme sinkronisasi data stok otomatis dan fitur manajemen slot waktu pengiriman (delivery scheduling) yang dapat mencegah pemilihan jam ganda oleh pelanggan serta memberikan estimasi waktu tiba yang akurat?

3. Bagaimana menyediakan infrastruktur digital terpusat bagi pemilik toko mandiri untuk memantau seluruh alur pemenuhan pesanan (order fulfillment), mulai dari verifikasi pembayaran otomatis hingga validasi status pengiriman?

4. Bagaimana menerapkan mekanisme Auto-dispatch untuk penugasan kurir secara otomatis dan algoritma Nearest Neighbor untuk mengoptimalkan urutan rute pengiriman berdasarkan jarak terdekat guna meningkatkan efisiensi distribusi barang?

## 1.3 Tujuan

Berdasarkan perumusan masalah yang telah diuraikan, tujuan dari penelitian ini adalah sebagai berikut:

1. Mengembangkan sebuah sistem informasi E-Commerce dan manajemen distribusi barang terintegrasi berbasis multiplatform (Web Admin dan Aplikasi Mobile), yang mencakup tiga modul utama yaitu manajemen transaksi penjualan, pengelolaan inventori, dan layanan logistik pengiriman mandiri.

2. Mengimplementasikan mekanisme sinkronisasi data stok otomatis dan fitur manajemen slot waktu pengiriman (delivery scheduling), yang berfungsi mencegah pemilihan jam ganda oleh pelanggan serta memberikan informasi estimasi waktu tiba (Estimated Time of Arrival) yang transparan dan akurat.

3. Menyediakan infrastruktur digital yang terpusat bagi pemilik toko mandiri untuk memantau seluruh alur pemenuhan pesanan (order fulfillment), mulai dari verifikasi pembayaran otomatis, pengelolaan stok toko, hingga validasi status pengiriman, guna meningkatkan efisiensi operasional toko dan kepercayaan pelanggan.

4. Menerapkan mekanisme Auto-dispatch untuk penugasan kurir secara otomatis dan algoritma Nearest Neighbor untuk mengoptimalkan urutan rute pengiriman berdasarkan jarak terdekat guna meningkatkan efisiensi distribusi barang.

## 1.4 Ruang Lingkup dan Batasan Sistem

### 1.4.1 Ruang Lingkup Sistem

Sistem yang dikembangkan dalam penelitian ini dirancang dengan menerapkan arsitektur client-server modern yang memisahkan tanggung jawab antara antarmuka pengguna (frontend) dan logika bisnis pusat (backend). Sistem ini terdiri dari tiga modul utama yang saling terintegrasi, yaitu:

**a. Modul Web Administrator**

Modul ini dikembangkan menggunakan SvelteKit dan ditujukan bagi pengelola toko untuk memantau operasional bisnis dan logistik secara terpusat. Fitur-fitur utama meliputi dashboard monitoring, manajemen inventori, manajemen pemenuhan pesanan, validasi pengiriman, dan manajemen multi-satuan.

**b. Modul Mobile Customer**

Modul ini dikembangkan menggunakan Flutter untuk memberikan pengalaman belanja yang responsif bagi pengguna akhir. Fitur-fitur utama meliputi katalog dan keranjang belanja, integrasi pembayaran digital, pemilihan jadwal pengiriman, pelacakan pesanan, dan riwayat transaksi.

**c. Modul Mobile Kurir**

Modul ini dikembangkan menggunakan Flutter dengan fokus pada operasional lapangan dan validasi data lokasi. Fitur-fitur utama meliputi manajemen tugas pengiriman, navigasi dan live location, serta bukti pengiriman digital.

Seluruh logika bisnis utama, termasuk perhitungan algoritma Reorder Point (ROP), manajemen transaksi, dan pengaturan jadwal logistik, dipusatkan pada sisi server yang dibangun menggunakan framework NestJS. Komunikasi data antara klien dan server difasilitasi melalui protokol HTTP menggunakan format pertukaran data JSON serta protokol WebSocket untuk komunikasi real-time.

### 1.4.2 Batasan Sistem

Untuk memastikan pengembangan sistem tetap terarah dan sesuai dengan rancangan arsitektur yang telah ditetapkan, penulis menetapkan batasan-batasan sebagai berikut:

1. **Ruang Lingkup Operasional**: Sistem difokuskan pada layanan pengiriman dalam kota (intracity) yang dikelola oleh armada internal toko. Sistem ini berdiri sendiri dan tidak terintegrasi dengan API ekspedisi pihak ketiga (seperti JNE atau J&T).

2. **Integrasi Pembayaran**: Sistem menerapkan metode pembayaran non-tunai (cashless) secara penuh melalui integrasi Payment Gateway Midtrans. Sistem tidak melayani pembayaran tunai di tempat (Cash on Delivery), dan seluruh status transaksi diverifikasi otomatis oleh sistem.

3. **Layanan Peta**: Sistem memanfaatkan peta berbasis OpenStreetMap (OSM) dan layanan OpenRouteService untuk fitur navigasi dan pelacakan. Fitur Live Tracking tersedia untuk memantau posisi kurir secara real-time saat status pengiriman aktif.

4. **Manajemen Penugasan**: Sistem menangani penugasan kurir secara otomatis (Auto-dispatch) berdasarkan lokasi dan ketersediaan armada. Penentuan urutan rute pengiriman dilakukan menggunakan algoritma Nearest Neighbor yang bersifat sekuensial.

5. **Protokol Komunikasi dan Notifikasi**: Sistem menggunakan protokol WebSocket untuk fitur real-time. Notifikasi yang diimplementasikan hanya bersifat In-App Notification dan tidak mencakup Push Notification saat aplikasi ditutup total.

6. **Skala Pengujian**: Pengujian fungsionalitas dan User Acceptance Test (UAT) akan dilakukan dengan skala simulasi operasional terbatas dengan minimal 25 pengguna sebagai Customer dan 3 pengguna sebagai Kurir.

## 1.5 Sistematika Pembahasan

Sistematika pembahasan dalam buku tugas akhir ini disusun agar pembaca dapat memahami alur penelitian dan implementasi sistem secara sistematis. Berikut adalah struktur penulisan yang digunakan:

**BAB I PENDAHULUAN**  
Bab ini berisi uraian mengenai latar belakang pemilihan judul, perumusan masalah, tujuan penelitian, ruang lingkup dan batasan sistem, serta sistematika pembahasan.

**BAB II TEORI PENUNJANG**  
Bab ini membahas teori-teori yang mendasari penelitian, meliputi penjelasan mengenai aplikasi pembanding (Lalamove), framework dan bahasa pemrograman (NestJS, SvelteKit, Flutter & Dart), manajemen basis data (PostgreSQL dan Prisma ORM), konsep algoritma dan logika sistem (Reorder Point, Nearest Neighbor, Auto-dispatch), layanan dan protokol terintegrasi (Arsitektur Client-Server, WebSocket, Payment Gateway, LBS, Digital Signature), serta pengujian perangkat lunak (UAT).

**BAB III PERANCANGAN SISTEM**  
Bab ini menjelaskan tahap perancangan sistem secara menyeluruh, meliputi arsitektur sistem, perancangan alur sistem (Use Case Diagram dan Activity Diagram), perancangan basis data, serta rancangan fitur sistem untuk ketiga modul (Web Admin, Mobile Customer, dan Mobile Kurir).

**BAB IV IMPLEMENTASI SISTEM**  
Bab ini memuat detail implementasi sistem, meliputi lingkungan implementasi, implementasi antarmuka dan fungsionalitas untuk masing-masing modul, serta implementasi algoritma dan komunikasi jaringan.

**BAB V PENGUJIAN DAN EVALUASI SISTEM**  
Bab ini mencakup skenario uji coba, pengujian fungsionalitas (Functionality Testing), pengujian penerimaan pengguna (User Acceptance Testing), serta evaluasi dan analisis sistem.

**BAB VI KESIMPULAN DAN SARAN**  
Bab ini berisi kesimpulan dari seluruh proses penelitian dan implementasi sistem, serta saran-saran untuk pengembangan lebih lanjut.