# Perancangan dan Implementasi Sistem E-Commerce Multiplatform untuk Layanan Pengiriman Barang Berbasis Aplikasi

**Kelun Kaka Santoso**
*Sekolah Tinggi Teknik Surabaya*
*kelun@stts.edu*

---

## Abstrak

**Abstrak** — Sistem e-commerce multiplatform untuk layanan pengiriman barang berbasis aplikasi telah berhasil dirancang dan dikembangkan pada penelitian ini. Sistem ini terdiri dari tiga platform utama yaitu Customer App dan Courier App yang dikembangkan menggunakan Flutter, serta Admin Panel yang dikembangkan menggunakan Svelte. Ketiga platform tersebut terintegrasi melalui backend berbasis Node.js dengan framework NestJS dan database PostgreSQL. Penelitian ini mengintegrasikan berbagai API eksternal untuk mendukung fitur-fitur utama sistem. Payment gateway Midtrans diimplementasikan untuk memproses pembayaran non-tunai melalui berbagai metode seperti QRIS, Virtual Account, dan E-Wallet. Peta interaktif menggunakan OpenStreetMap dan library Leaflet ditampilkan pada Admin Panel dan Courier App. OpenRouteService digunakan untuk menghitung rute pengiriman, sementara WebSocket diimplementasikan untuk komunikasi real-time dalam update lokasi driver dan notifikasi pesanan. Fitur auto-dispatch berhasil diimplementasikan dengan menggunakan formula Haversine untuk menghitung jarak antara driver dan lokasi penjemputan secara otomatis. Fitur manajemen stok dengan perhitungan Reorder Point dan fitur time slot booking berhasil memberikan kemudahan bagi admin dalam mengelola inventori dan memberikan fleksibilitas waktu pengiriman bagi customer. Hasil User Acceptance Test (UAT) terhadap 25 responden customer dan 3 responden courier menunjukkan nilai rata-rata yang baik, sehingga aplikasi dapat dinyatakan diterima oleh pengguna dan layak digunakan.

***Kata kunci*** — E-commerce, Multiplatform, Flutter, Svelte, NestJS, Auto-dispatch, WebSocket

---

## I. PENDAHULUAN

Perkembangan teknologi di sektor ritel menuntut toko modern untuk beralih dari manajemen konvensional ke sistem digital yang terintegrasi demi meningkatkan efisiensi dan kepuasan pelanggan. Namun, terdapat kesenjangan teknologi yang signifikan antara marketplace besar dengan toko mandiri yang masih mengelola operasionalnya secara manual [5]. Akibatnya, banyak toko mandiri kesulitan bersaing dalam hal kecepatan pelayanan, akurasi ketersediaan stok, dan kepastian pengiriman barang kepada konsumen.

Kendala operasional yang krusial meliputi pencatatan stok yang tidak real-time, sehingga memicu risiko kehabisan barang tanpa adanya peringatan dini bagi pemilik toko. Di sisi logistik, pengiriman menggunakan kurir internal seringkali tidak transparan karena minimnya bukti valid seperti lokasi GPS atau foto penerimaan barang. Selain itu, pengaturan jadwal pengiriman yang dilakukan secara manual rentan menyebabkan bentrokan slot waktu antar pelanggan dan ketidakakuratan estimasi waktu sampai.

Sebagai solusi, penelitian ini mengusulkan pengembangan sistem informasi E-Commerce dan manajemen inventori berbasis multiplatform yang menyatukan proses penjualan, pemantauan stok, dan pengiriman dalam satu pintu. Keunggulan utamanya terletak pada integrasi data real-time antara aplikasi admin dan kurir, penerapan algoritma Reorder Point (ROP) untuk rekomendasi waktu pemesanan ulang barang, mekanisme auto-dispatch untuk penugasan kurir secara otomatis, dan algoritma Nearest Neighbor untuk optimasi urutan rute pengiriman berdasarkan jarak terdekat.

Penelitian ini bertujuan untuk: (1) mengembangkan sistem E-Commerce dan manajemen distribusi barang terintegrasi berbasis multiplatform; (2) mengimplementasikan sinkronisasi data stok otomatis dan fitur time slot booking; (3) menyediakan infrastruktur digital terpusat bagi pemilik toko untuk memantau seluruh alur pemenuhan pesanan; dan (4) menerapkan mekanisme auto-dispatch dan algoritma Nearest Neighbor untuk optimasi distribusi barang.

---

## II. TINJAUAN PUSTAKA

### A. Framework dan Bahasa Pemrograman

**NestJS** adalah framework server-side untuk Node.js yang efisien dan dibangun dengan dukungan penuh TypeScript [7]. Struktur modularnya memungkinkan pengembang mengorganisir kode ke dalam modul-modul terpisah. Dalam penelitian ini, NestJS berfungsi sebagai backend utama yang menangani logika bisnis, komunikasi real-time melalui WebSocket, serta interaksi dengan layanan eksternal.

**SvelteKit** adalah framework untuk membangun aplikasi web modern yang melakukan proses kompilasi pada tahap build time [8]. Pendekatan ini menghasilkan performa yang sangat ringan dan cepat. Dalam proyek ini, SvelteKit digunakan untuk membangun Dashboard Admin Web.

**Flutter** adalah SDK UI open-source dari Google untuk membangun aplikasi yang dikompilasi secara native dari satu basis kode tunggal [9]. Dalam penelitian ini, Flutter digunakan untuk membangun Customer App dan Courier App.

### B. Manajemen Basis Data

**PostgreSQL** digunakan sebagai sistem manajemen basis data relasional yang mendukung fitur lanjutan seperti JOIN kompleks, transaction, dan trigger [11]. **Prisma ORM** menjembatani kode TypeScript dengan database PostgreSQL, memungkinkan operasi CRUD dengan sintaks yang type-safe [10].

### C. Algoritma dan Logika Sistem

**Reorder Point (ROP)** menentukan tingkat stok minimum di mana pemesanan ulang harus dilakukan [3]. Rumus yang diterapkan:

*ROP = (Lead Time × Rata-rata Penjualan Harian) + Safety Stock*

**Nearest Neighbor** adalah algoritma optimasi rute yang bekerja dengan prinsip Greedy, memilih lokasi tujuan berikutnya yang memiliki jarak terdekat dari posisi saat ini. Algoritma ini efektif untuk meminimalkan total jarak tempuh kurir dalam satu siklus pengiriman.

**Auto-dispatch** merupakan mekanisme otomatisasi penugasan kurir menggunakan formula Haversine untuk menghitung jarak bola antara dua titik di permukaan bumi berdasarkan koordinat lintang dan bujur.

### D. Layanan dan Protokol Terintegrasi

Arsitektur **Client-Server** menjadi fondasi utama topologi sistem [1]. **WebSocket** menggunakan Socket.IO untuk komunikasi real-time seperti live tracking dan in-app notification [16]. **Payment Gateway Midtrans** memproses pembayaran non-tunai dengan verifikasi otomatis melalui webhook [14]. **OpenStreetMap** dan **OpenRouteService** menyediakan layanan peta dan routing secara open-source [12][13].

### E. Aplikasi Pembanding

Perbandingan dengan Lalamove menunjukkan bahwa sistem memiliki standar fitur operasional setara dalam hal pelacakan real-time, optimasi rute multi-stop, dan bukti pengiriman digital. Keunggulan kompetitif sistem terletak pada fitur Integrasi Otomatis dengan Stok yang tidak dimiliki Lalamove.

---

## III. ANALISIS MASALAH DAN DESAIN SISTEM

### A. Analisis Masalah

Berdasarkan studi kasus pada toko modern yang mengelola operasional secara konvensional, diidentifikasi beberapa permasalahan utama: (1) manajemen stok barang tidak real-time menggunakan pencatatan manual; (2) proses penugasan kurir secara manual tanpa mempertimbangkan lokasi kurir; (3) kurangnya transparansi dalam pelacakan pengiriman; dan (4) optimasi rute pengiriman berdasarkan intuisi kurir yang tidak efisien.

Tabel I menyajikan ringkasan gap analysis antara kondisi eksisting dan kondisi yang diharapkan.

**Tabel I. Gap Analysis Kondisi Eksisting dan Kondisi yang Diharapkan**

| No | Area | Kondisi Eksisting | Kondisi yang Diharapkan |
|----|------|-------------------|-------------------------|
| 1 | Manajemen Stok | Pencatatan manual, tidak real-time | Sistem digital dengan update real-time dan notifikasi otomatis |
| 2 | Penugasan Kurir | Manual berdasarkan ketersediaan | Auto-dispatch berdasarkan lokasi dan ketersediaan |
| 3 | Pelacakan Pengiriman | Tidak transparan | Live tracking berbasis GPS real-time |
| 4 | Optimasi Rute | Berdasarkan intuisi kurir | Algoritma optimasi rute terpendek |
| 5 | Jadwal Pengiriman | Diatur manual, sering bentrok | Sistem slot waktu mencegah tumpang tindih |

### B. Arsitektur Sistem

Arsitektur sistem dirancang menggunakan pola client-server dengan pendekatan modular. Sistem terdiri dari tiga modul utama yang saling terintegrasi: (1) Modul Web Administrator (SvelteKit) untuk pengelola toko; (2) Modul Mobile Customer (Flutter) untuk pelanggan; dan (3) Modul Mobile Kurir (Flutter) untuk operasional lapangan.

Seluruh antarmuka klien berkomunikasi dengan NestJS sebagai backend utama yang bertindak sebagai API provider sekaligus gateway menuju layanan eksternal Midtrans, OpenStreetMap, dan OpenRouteService. NestJS terhubung langsung dengan database PostgreSQL untuk penyimpanan data. Komunikasi menggunakan dua metode: REST API untuk operasi sinkronus dan WebSocket untuk komunikasi real-time.

### C. Perancangan Database

Database terdiri dari tujuh entitas utama: Products, ProductVariants, Customers, Drivers, Orders, OrderItems, dan TimeSlots. Tabel Orders menjadi entitas pusat yang berelasi dengan Customers, Drivers, OrderItems, dan TimeSlots.

### D. Rancangan Fitur Utama

**Admin Panel** mencakup: dashboard monitoring, manajemen produk dan stok dengan notifikasi ROP, manajemen pesanan dengan export PDF, lacak driver secara real-time, dan manajemen employee.

**Customer App** mencakup: katalog produk dengan pencarian, keranjang belanja, checkout dengan peta interaktif dan pemilihan slot waktu, integrasi pembayaran Midtrans, pelacakan pesanan real-time, dan riwayat transaksi.

**Courier App** mencakup: daftar tugas pengiriman, update status pengiriman bertahap, navigasi peta dengan OpenStreetMap, unggah bukti pengiriman (foto), dan riwayat pengiriman.

---

## IV. IMPLEMENTASI SISTEM

### A. Integrasi API Eksternal

**Midtrans Payment.** Integrasi Midtrans menggunakan library `midtrans-client` pada backend NestJS. Sistem membuat Snap token untuk setiap transaksi dan menerima webhook notification untuk verifikasi pembayaran otomatis. Status transaksi dari Midtrans dipetakan ke status internal: `capture`/`settlement` → `paid`, `deny`/`cancel`/`expire` → `failed`.

**OpenStreetMap.** Peta interaktif diimplementasikan menggunakan library Leaflet dengan tile layer dari OpenStreetMap. Fungsi `initMap()` menginisialisasi peta dengan koordinat dan zoom level, sedangkan `addMarker()` menambahkan marker pada posisi tertentu.

**OpenRouteService.** Perhitungan rute menggunakan OSRM sebagai layanan utama dengan mekanisme retry. Hasil berupa encoded polyline yang divisualisasikan di atas peta sebagai garis rute pengiriman.

**WebSocket.** Implementasi menggunakan Socket.IO dengan namespace `/driver-location`. Gateway menangani tiga event utama: `register_driver` untuk registrasi driver ke room, `driver_location_update` untuk menyimpan koordinat dan broadcast ke admin, dan `admin_subscribe` untuk admin memantau lokasi driver.

### B. Fitur Auto-dispatch

Auto-dispatch diimplementasikan menggunakan formula Haversine untuk menghitung jarak antara posisi kurir dan lokasi penjemputan. Rumus Haversine:

*d = 2R × arctan2(√a, √(1-a))*

di mana *a = sin²(Δlat/2) + cos(lat₁) × cos(lat₂) × sin²(Δlng/2)* dan *R = 6371 km* (radius bumi).

Ketika pesanan baru masuk dan pembayaran dikonfirmasi, sistem: (1) mengidentifikasi semua kurir yang berstatus online dan available; (2) menghitung jarak setiap kurir ke lokasi penjemputan; (3) menugaskan kurir dengan jarak terdekat secara otomatis; dan (4) mengirimkan notifikasi via WebSocket ke aplikasi kurir.

### C. Fitur Manajemen Stok dengan ROP

Sistem menghitung ROP untuk setiap produk berdasarkan parameter Lead Time, Safety Stock, dan rata-rata penjualan harian 7 hari terakhir. Produk ditandai "Need Reorder" jika: stok ≤ safety stock (jika sold = 0), stok ≤ safety stock + lead time (jika sold < 7), atau stok ≤ ROP (jika sold ≥ 7).

### D. Fitur Time Slot Booking

Sistem time slot membatasi maksimal 3 pesanan per slot waktu untuk mengoptimalkan kapasitas driver. Customer memilih slot waktu pada halaman checkout, dan sistem secara otomatis menonaktifkan slot yang sudah penuh.

### E. Fitur Pelacakan Pesanan Real-time

Live tracking diimplementasikan dengan mengirim koordinat GPS kurir ke server setiap 5 detik melalui WebSocket. Posisi kurir ditampilkan pada peta di Admin Panel dan Customer App secara real-time tanpa refresh halaman.

---

## V. UJI COBA DAN HASIL

### A. Functionality Testing

Pengujian fungsionalitas dilakukan terhadap 21 fitur utama sistem. Tabel II menampilkan ringkasan hasil functionality testing.

**Tabel II. Ringkasan Hasil Functionality Testing**

| No | Fitur yang Diuji | Jumlah Skenario | Hasil |
|----|-------------------|-----------------|-------|
| 1 | Integrasi API Midtrans | 4 | Sesuai harapan |
| 2 | Integrasi OpenStreetMap | 4 | Sesuai harapan |
| 3 | Integrasi OpenRouteService | 3 | 2 sesuai, 1 tidak sesuai* |
| 4 | WebSocket Gateway | 3 | Sesuai harapan |
| 5 | Authentication Customer | 4 | Sesuai harapan |
| 6 | Authentication Courier | 4 | Sesuai harapan |
| 7 | Katalog Produk | 2 | Sesuai harapan |
| 8 | Detail Produk & Add to Cart | 6 | Sesuai harapan |
| 9 | Keranjang Belanja | 6 | Sesuai harapan |
| 10 | Checkout & Pembayaran | 7 | Sesuai harapan |
| 11 | Manajemen Alamat | 4 | Sesuai harapan |
| 12 | Riwayat Pesanan Customer | 4 | Sesuai harapan |
| 13 | Auto-dispatch | 5 | Sesuai harapan |
| 14 | Manajemen Pengiriman Courier | 7 | Sesuai harapan |
| 15 | Riwayat Pengiriman Courier | 4 | Sesuai harapan |
| 16 | Manajemen Employee | 4 | Sesuai harapan |
| 17 | Lacak Driver (Admin) | 4 | Sesuai harapan |
| 18 | Pelacakan Pesanan Customer | 4 | Sesuai harapan |
| 19 | Dashboard Admin | 5 | Sesuai harapan |
| 20 | Manajemen Stok | 7 | Sesuai harapan |
| 21 | Time Slot Booking | 4 | Sesuai harapan |

*Catatan: Pada pengujian navigasi di peta, garis rute sedikit menyimpang dari jalan yang sebenarnya.

Dari total 89 skenario pengujian, 88 skenario menghasilkan output sesuai harapan (98,9%) dan 1 skenario tidak sesuai harapan pada visualisasi rute di peta.

### B. User Acceptance Testing

UAT dilakukan dengan 25 responden customer dan 3 responden courier menggunakan skala Likert 1-5. Interpretasi skala: 1.00–1.99 (Sangat Buruk), 2.00–2.99 (Buruk), 3.00–3.49 (Cukup), 3.50–4.19 (Baik), 4.20–5.00 (Sangat Baik).

**Tabel III. Rata-Rata UAT Customer App (25 Responden)**

| No | Aspek Pengujian | Rata-Rata |
|----|-----------------|-----------|
| 1 | Waktu loading login ke katalog | 4.16 |
| 2 | Pesan error saat login gagal | 4.08 |
| 3 | Proses registrasi akun baru | 3.72 |
| 4 | Tampilan halaman login dan registrasi | 4.00 |
| 5 | Tampilan produk | 3.92 |
| 6 | Fitur pencarian produk | 3.92 |
| 7 | Kecepatan memuat daftar produk | 3.96 |
| 8 | Informasi stok produk | 4.04 |
| 9 | Informasi halaman detail produk | 3.96 |
| 10 | Update total harga di keranjang | 3.96 |
| 11 | Proses hapus item dari keranjang | 4.00 |
| 12 | Peta di halaman checkout | 3.96 |
| 13 | Pemilihan slot waktu pengiriman | 3.88 |
| 14 | Keseluruhan alur checkout | 4.00 |
| 15 | Redirect ke pelacakan setelah pembayaran | 4.16 |
| 16 | Status pesanan di halaman pelacakan | 3.84 |
| 17 | Posisi driver di peta saat delivering | 3.84 |
| 18 | Timeline status pesanan | 4.20 |
| 19 | Daftar riwayat pesanan | 3.80 |
| 20 | Detail pesanan dari riwayat | 4.04 |
| | **Rata-rata keseluruhan** | **3.97** |

Rata-rata keseluruhan UAT Customer App adalah **3.97** yang termasuk kategori **"Baik"**.

**Tabel IV. Rata-Rata UAT Courier App (3 Responden)**

| No | Aspek Pengujian | Rata-Rata |
|----|-----------------|-----------|
| 1 | Waktu loading login ke dashboard | 3.33 |
| 2 | Pesan error saat login gagal | 3.00 |
| 3 | Waktu respon tombol terima pesanan | 3.67 |
| 4 | Akurasi peta navigasi ke toko | 3.00 |
| 5 | Informasi detail item pesanan | 4.00 |
| 6 | Update status "Pesanan Telah Diambil" | 4.00 |
| 7 | Akurasi peta navigasi ke pelanggan | 3.33 |
| 8 | Tracking posisi driver di peta | 3.33 |
| 9 | Kejelasan tampilan pengiriman | 3.67 |
| 10 | Update status "Pesanan Tiba" | 4.00 |
| 11 | Proses konfirmasi penyelesaian | 4.00 |
| 12 | Fitur unggah bukti pengiriman | 3.00 |
| 13 | Daftar riwayat pesanan selesai | 4.00 |
| 14 | Proses logout dari aplikasi | 3.67 |
| 15 | Keseluruhan pengalaman | 3.67 |
| | **Rata-rata keseluruhan** | **3.58** |

Rata-rata keseluruhan UAT Courier App adalah **3.58** yang termasuk kategori **"Baik"**.

---

## VI. KESIMPULAN

Berdasarkan penelitian yang telah dilakukan, dapat disimpulkan:

1. Sistem e-commerce multiplatform yang terdiri dari Customer App, Courier App, dan Admin Panel berhasil diimplementasikan dengan baik. Hasil UAT menunjukkan rata-rata Customer App 3.97 (Baik) dan Courier App 3.58 (Baik).

2. Integrasi payment gateway Midtrans berhasil memproses pembayaran non-tunai dengan metode QRIS, Virtual Account, dan E-Wallet dengan verifikasi otomatis melalui webhook.

3. Fitur auto-dispatch menggunakan formula Haversine berhasil menugaskan driver terdekat secara otomatis, menghilangkan kebutuhan intervensi manual admin.

4. Pelacakan pesanan real-time menggunakan WebSocket memungkinkan customer memantau posisi driver dan status pesanan tanpa refresh halaman.

5. Manajemen stok dengan algoritma ROP berhasil memberikan peringatan otomatis ketika stok mencapai batas reorder point.

6. Time slot booking dengan batas 3 pesanan per slot berhasil mengoptimalkan kapasitas driver dan mencegah bentrokan jadwal.

Saran untuk pengembangan di masa mendatang: (1) optimalisasi visualisasi garis navigasi rute agar lebih sesuai dengan jalan sebenarnya; (2) penambahan fitur push notification untuk informasi status pesanan saat aplikasi tidak aktif; dan (3) pengembangan fitur export laporan dalam format PDF atau Excel.

---

## UCAPAN TERIMA KASIH

Penulis mengucapkan terima kasih kepada Sekolah Tinggi Teknik Surabaya yang telah memberikan dukungan dalam penyelesaian penelitian ini.

---

## DAFTAR PUSTAKA

[1] A. S. Tanenbaum and M. van Steen, *Distributed Systems: Principles and Paradigms*, 3rd ed. CreateSpace Independent Publishing Platform, 2017.

[2] R. S. Pressman and B. R. Maxim, *Software Engineering: A Practitioner's Approach*, 9th ed. New York: McGraw-Hill Education, 2019.

[3] J. Heizer, B. Render, and C. Munson, *Operations Management: Sustainability and Supply Chain Management*, 12th ed. Boston: Pearson, 2017.

[4] R. T. Fielding, "Architectural Styles and the Design of Network-based Software Architectures," Ph.D. dissertation, Dept. Info. & Comp. Sci., Univ. of California, Irvine, CA, 2000.

[5] K. C. Laudon and C. G. Traver, *E-Commerce 2021-2022: Business, Technology, Society*, 16th ed. Pearson, 2021.

[6] J. Schiller and A. Voisard, *Location-Based Services*. Morgan Kaufmann, 2004.

[7] NestJS, "NestJS - A progressive Node.js framework," NestJS Documentation. [Online]. Available: https://docs.nestjs.com/. [Accessed: Jan. 25, 2025].

[8] Svelte, "SvelteKit • Web development, streamlined," SvelteKit Documentation. [Online]. Available: https://kit.svelte.dev/. [Accessed: Jan. 25, 2025].

[9] Google Developers, "Flutter - Build apps for any screen," Flutter Documentation. [Online]. Available: https://flutter.dev/. [Accessed: Jan. 25, 2025].

[10] Prisma, "Prisma | Next-generation ORM for Node.js & TypeScript," Prisma Documentation. [Online]. Available: https://www.prisma.io/. [Accessed: Jan. 25, 2025].

[11] PostgreSQL Global Development Group, "PostgreSQL: The World's Most Advanced Open Source Relational Database," PostgreSQL Documentation. [Online]. Available: https://www.postgresql.org/. [Accessed: Jan. 25, 2025].

[12] OpenStreetMap Foundation, "OpenStreetMap," OpenStreetMap Documentation. [Online]. Available: https://www.openstreetmap.org. [Accessed: Feb. 10, 2026].

[13] Heidelberg Institute for Geoinformation Technology, "OpenRouteService API Documentation," OpenRouteService Documentation. [Online]. Available: https://openrouteservice.org. [Accessed: Feb. 10, 2026].

[14] Midtrans, "Technical Documentation Midtrans," Midtrans Documentation. [Online]. Available: https://docs.midtrans.com/. [Accessed: Jan. 25, 2025].

[15] V. Agoston, "Leaflet.js - An Open-Source JavaScript Library for Mobile-Friendly Interactive Maps," Leaflet Documentation. [Online]. Available: https://leafletjs.com/. [Accessed: Feb. 10, 2026].

[16] Socket.IO, "Socket.IO," Socket.IO Documentation. [Online]. Available: https://socket.io/docs/v4/. [Accessed: Feb. 10, 2026].

[17] Midtrans, "Snap JS - Payment Gateway Integration," Midtrans Documentation. [Online]. Available: https://snap.midtrans.com/. [Accessed: Feb. 10, 2026].

[18] Nominatim, "Nominatim - OpenStreetMap Nominatim API," OpenStreetMap Nominatim Documentation. [Online]. Available: https://nominatim.openstreetmap.org/. [Accessed: Feb. 10, 2026].

[19] Postman, "Postman API Platform," Postman Documentation. [Online]. Available: https://www.postman.com/. [Accessed: Feb. 10, 2026].

[20] GitHub, Inc., "GitHub: Let's build from here," GitHub Documentation. [Online]. Available: https://docs.github.com/. [Accessed: Feb. 10, 2026].

[21] Docker, Inc., "Docker - Build, Share, Run," Docker Documentation. [Online]. Available: https://docs.docker.com/. [Accessed: Feb. 10, 2026].

[22] Mozilla Developer Network, "Canvas API," MDN Web Docs. [Online]. Available: https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API. [Accessed: Jan. 25, 2025].
