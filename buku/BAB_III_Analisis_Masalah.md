# BAB III
# ANALISIS MASALAH

Bab ini menjelaskan identifikasi dan analisis masalah yang dihadapi toko modern dalam mengelola operasional bisnisnya, meliputi studi kasus, gap analysis, dan perumusan kebutuhan sistem.

## 3.1 Identifikasi Masalah

Pengelolaan toko modern saat ini menghadapi berbagai tantangan yang kompleks dalam mengoperasikan bisnisnya. Meskipun teknologi telah berkembang pesat, banyak toko mandiri yang masih mengandalkan sistem manual dalam mengelola operasional sehari-hari. Hal ini menciptakan berbagai masalah yang berdampak langsung pada efisiensi kerja dan kepuasan pelanggan.

Berdasarkan pengamatan yang dilakukan, terdapat beberapa masalah utama yang dihadapi oleh toko modern dalam mengelola operasional bisnisnya:

**Pertama**, masalah terkait dengan manajemen stok barang yang tidak real-time. Pencatatan stok dilakukan secara manual menggunakan buku atau spreadsheet sederhana, sehingga pemilik toko tidak memiliki visibility terhadap tingkat stok secara akurat setiap saat. Kondisi ini sering kali menyebabkan kehabisan barang (stockout) pada saat permintaan tinggi, yang pada akhirnya mengakibatkan kehilangan penjualan dan pelanggan.

**Kedua**, masalah dalam proses pengiriman barang kepada pelanggan. Toko yang memiliki armada pengiriman sendiri seringkali menghadapi kesulitan dalam mengelola jadwal pengiriman dan penugasan kurir. Proses penugasan kurir yang dilakukan secara manual memerlukan waktu dan effort yang besar, terutama ketika volume pesanan meningkat. Selain itu, kurangnya transparansi dalam pelacakan pengiriman membuat pelanggan sering merasa tidak yakin mengenai status pesanan mereka.

**Ketiga**, masalah terkait dengan verifikasi dan dokumentasi pengiriman. Tanpa sistem yang memadai, bukti penerimaan barang berupa foto dan tanda tangan digital masih jarang diimplementasikan. Hal ini dapat menimbulkan disputes antara toko dan pelanggan ketika terjadi komplain terkait pengiriman barang.

**Keempat**, masalah dalam optimasi rute pengiriman. Kurir yang menentukan urutan pengiriman berdasarkan intuisi pribadi seringkali mengambil rute yang tidak efisien, sehingga menghasilkan waktu tempuh yang lebih lama dan biaya operasional yang lebih tinggi.

## 3.2 Studi Kasus pada Toko Modern

Untuk memahami lebih mendalam mengenai masalah yang dihadapi, dilakukan studi kasus pada toko modern yang mengelola operasional secara konvensional. Toko yang diteliti merupakan toko retail yang menjual berbagai kebutuhan pokok sehari-hari seperti beras, gula, minyak goreng, dan produk kebutuhan rumah tangga lainnya.

### 3.2.1 Kondisi Eksisting (Current State)

Toko tersebut memiliki beberapa karakteristik operasional sebagai berikut:

**Manajemen Stok:**
Stok barang tercatat dalam buku inventory yang diupdate setiap kali ada transaksi penjualan. Pemilik toko melakukan pengecekan fisik stok seminggu sekali untuk memverifikasi kesesuaian data. Tidak ada sistem peringatan otomatis ketika stok menipis, sehingga pemilik baru mengetahui kehabisan stok ketika pelanggan bertanya dan barang tidak tersedia.

**Proses Pemesanan:**
Pelanggan datang langsung ke toko untuk memilih barang atau memesan melalui telepon. Untuk pesanan dalam jumlah besar, pelanggan harus datang langsung atau menghubungi pemilik via telepon. Tidak ada katalog digital yang dapat diakses pelanggan untuk melihat produk yang tersedia.

**Proses Pembayaran:**
Pembayaran dilakukan secara tunai di kasir atau melalui transfer bank langsung ke rekening pribadi pemilik. Tidak ada integrasi dengan payment gateway untuk menerima berbagai metode pembayaran secara otomatis.

**Manajemen Pengiriman:**
Penugasan kurir dilakukan berdasarkan ketersediaan kurir dan pengalaman kurir dalam mengenali area pengiriman. Tidak ada sistem yang secara otomatis mempertimbangkan lokasi kurir saat ini dalam penugasan. Kurir menentukan rute pengiriman sendiri tanpa bantuan sistem navigasi atau optimasi rute.

**Dokumentasi Pengiriman:**
Bukti pengiriman berupa nota tulisan sederhana yang ditandatangani oleh penerima. Tidak ada foto dokumentasi atau pencatatan koordinat lokasi penerimaan secara digital.

### 3.2.2 Proses Bisnis Alur Kerja Eksisting

Proses bisnis yang berjalan saat ini dapat digambarkan sebagai berikut:

1. **Penerimaan Pesanan**: Pelanggan menghubungi toko via telepon atau datang langsung untuk memesan. Pemilik atau karyawan mencatat pesanan secara manual.

2. **Verifikasi Pembayaran**: Pembayaran dilakukan melalui transfer bank atau tunai. Pemilik memverifikasi pembayaran dengan membuka aplikasi bank atau menghitung uang tunai.

3. **Persiapan Pesanan**: Karyawan menyiapkan barang di gudang berdasarkan pesanan. Stok diupdate manual setelah barang disiapkan.

4. **Penugasan Kurir**: Pemilik memilih kurir yang tersedia dan memberikan informasi alamat pengiriman. Penugasan dilakukan secara manual tanpa mempertimbangkan lokasi kurir saat itu.

5. **Proses Pengiriman**: Kurir membawa barang dan nota pengiriman ke alamat tujuan. Kurir menentukan sendiri rute yang akan diambil.

6. **Konfirmasi Penerimaan**: Pelanggan menandatangani nota sebagai bukti penerimaan. Kurir kembali ke toko dan melaporkan status pengiriman.

## 3.3 Gap Analysis

Berdasarkan studi kasus yang dilakukan, dapat diidentifikasi kesenjangan antara kondisi eksisting dengan kondisi yang diharapkan (future state). Gap analysis ini membantu dalam memahami bagian mana dari operasional yang memerlukan perbaikan atau transformasi.

### 3.3.1 Tabel Gap Analysis

| No | Area | Kondisi Eksisting | Kondisi yang Diharapkan | Gap |
|----|------|-------------------|-------------------------|-----|
| 1 | Manajemen Stok | Pencatatan manual, tidak real-time | Sistem digital dengan update real-time dan notifikasi otomatis | Sistem belum terintegrasi untuk memberikan visibility stok secara real-time |
| 2 | Pemesanan | Melalui telepon atau datang langsung | Katalog digital yang dapat diakses pelanggan kapan saja | Toko belum memiliki platform e-commerce untuk menjangkau pelanggan |
| 3 | Pembayaran | Tunai dan transfer manual | Payment gateway dengan berbagai metode pembayaran otomatis | Tidak ada integrasi dengan payment gateway untuk verifikasi otomatis |
| 4 | Penugasan Kurir | Manual berdasarkan ketersediaan | Auto-dispatch berdasarkan lokasi dan ketersediaan | Belum ada sistem yang otomatis menugaskan kurir terdekat |
| 5 | Pelacakan Pengiriman | Tidak transparan, hanya melalui telepon | Live tracking berbasis GPS yang dapat dipantau real-time | Kurir belum memiliki sistem untuk membagikan lokasi secara real-time |
| 6 | Dokumentasi Pengiriman | Nota tulisan tangan sederhana | Foto dan tanda tangan digital tersimpan di server | Bukti pengiriman belum terdigitalisasi dengan baik |
| 7 | Optimasi Rute | Berdasarkan intuisi kurir | Algoritma optimasi untuk menentukan rute terpendek | Rute pengiriman belum dioptimasi secara sistematis |
| 8 | Jadwal Pengiriman | Diatur manual, sering bentrok | Sistem slot waktu yang mencegah tumpang tindih | Belum ada sistem penjadwalan yang mengelola kapasitas pengiriman |

### 3.3.2 Analisis Akar Masalah (Root Cause Analysis)

Berdasarkan gap analysis di atas, dapat diidentifikasi akar masalah yang menyebabkan kesenjangan tersebut:

**Akar Masalah 1: Ketiadaan Sistem Informasi yang Terintegrasi**
Toko belum memiliki sistem informasi yang mengintegrasikan seluruh proses bisnis dari penerimaan pesanan hingga pengiriman barang. Setiap proses dilakukan secara terpisah dan memerlukan intervention manual, yang meningkatkan risiko error dan memakan waktu.

**Akar Masalah 2: Keterbatasan Teknologi yang Dimiliki**
Pemilik toko belum memanfaatkan teknologi modern seperti platform e-commerce, payment gateway, dan sistem manajemen inventori digital. Investment pada teknologi masih minim karena keterbatasan pengetahuan dan modal.

**Akar Masalah 3: Tidak Adanya Standarisasi Proses**
Proses operasional masih bergantung pada kebiasaan individu dan tidak memiliki standar yang jelas. Hal ini menyebabkan inkonsistensi dalam pelayanan dan kesulitan dalam melakukan evaluasi kinerja.

## 3.4 Perumusan Kebutuhan Sistem

Berdasarkan identifikasi masalah dan gap analysis yang telah dilakukan, dapat dirumuskan kebutuhan sistem yang diperlukan untuk mengatasi masalah yang ada. Kebutuhan sistem ini menjadi dasar dalam perancangan dan pengembangan sistem informasi E-Commerce dan manajemen distribusi barang berbasis multiplatform.

### 3.4.1 Kebutuhan Fungsional

Kebutuhan fungsional sistem mencakup fitur-fitur yang harus tersedia untuk mendukung operasional toko modern:

**Manajemen Produk dan Inventori:**
- Sistem harus mampu menyimpan dan mengelola data produk lengkap dengan informasi harga, satuan, dan stok
- Sistem harus dapat mengatur multi-satuan untuk produk yang dijual dalam berbagai ukuran kemasan
- Sistem harus memberikan notifikasi otomatis ketika stok mencapai titik reorder (ROP)
- Sistem harus dapat mengurangi stok secara otomatis setiap kali terjadi transaksi penjualan

**Manajemen Pemesanan:**
- Sistem harus menyediakan katalog produk digital yang dapat diakses pelanggan melalui aplikasi mobile
- Sistem harus memungkinkan pelanggan menambahkan produk ke keranjang dan menyelesaikan checkout
- Sistem harus mengintegrasikan Payment Gateway untuk menerima berbagai metode pembayaran
- Sistem harus mengelola slot waktu pengiriman untuk menghindari bentrokan jadwal

**Manajemen Pengiriman:**
- Sistem harus memiliki mekanisme auto-dispatch untuk menugaskan kurir secara otomatis berdasarkan proximity
- Sistem harus menampilkan posisi kurir secara real-time di atas peta untuk pelacakan pengiriman
- Sistem harus mengoptimasi rute pengiriman menggunakan algoritma Nearest Neighbor
- Sistem harus menyediakan fitur dokumentasi pengiriman berupa foto dan tanda tangan digital

**Manajemen Kurir:**
- Sistem harus dapat mengelola data kurir termasuk informasi kendaraan dan status ketersediaan
- Sistem harus memungkinkan kurir menerima dan memperbarui status tugas pengiriman
- Sistem harus menyimpan riwayat pengiriman untuk setiap kurir

**Dashboard Admin:**
- Sistem harus menyediakan dashboard yang menampilkan statistik penjualan dan pendapatan
- Sistem harus memungkinkan admin memonitor seluruh aktivitas operasional secara terpusat
- Sistem harus menyediakan fitur untuk mengelola produk, pesanan, dan kurir

### 3.4.2 Kebutuhan Non-Fungsional

Kebutuhan non-fungsional sistem mencakup aspek-aspek yang mendukung kualitas dan keandalan sistem:

**Performa:**
- Sistem harus dapat menangani banyak request secara bersamaan tanpa mengalami degradasi signifikan
- Response time untuk operasi biasa tidak boleh melebihi 2 detik
- Live tracking harus dapat diperbarui setiap 5 detik tanpa delay yang berarti

**Skalabilitas:**
- Sistem harus dirancang dengan arsitektur yang mendukung peningkatan kapasitas di masa depan
- Basis data harus dapat menangani pertumbuhan data seiring dengan bertambahnya transaksi

**Keamanan:**
- Data sensitif seperti password harus dienkripsi sebelum disimpan
- Akses ke sistem harus melalui proses autentikasi yang aman
- Data transaksi dan pembayaran harus dilindungi dari akses unauthorized

**Reliabilitas:**
- Sistem harus dapat beroperasi secara konsisten tanpa downtime yang tidak terduga
- Sistem harus memiliki mekanisme backup data secara berkala
- Error handling harus dilakukan dengan baik untuk memberikan pengalaman pengguna yang baik

**Kompatibilitas:**
- Aplikasi mobile harus dapat berjalan pada berbagai perangkat Android
- Dashboard web harus dapat diakses melalui browser modern tanpa hambatan
- Sistem harus kompatibel dengan berbagai ukuran layar dan resolusi

### 3.4.3 Kebutuhan Integrasi

Kebutuhan integrasi sistem mencakup koneksi dengan layanan eksternal:

**Integrasi Payment Gateway:**
- Sistem harus terintegrasi dengan Midtrans untuk menerima pembayaran melalui berbagai metode
- Sistem harus dapat menerima webhook notification untuk verifikasi pembayaran secara real-time

**Integrasi Layanan Peta:**
- Sistem harus terintegrasi dengan OpenStreetMap untuk tampilan peta
- Sistem harus terintegrasi dengan OpenRouteService untuk perhitungan rute dan jarak

**Integrasi Penyimpanan:**
- Sistem harus memiliki kemampuan untuk menyimpan foto bukti pengiriman secara cloud
