# Bab VI
# Uji Coba

Pada bab ini akan dijelaskan mengenai uji coba yang dilakukan pada aplikasi e-commerce multiplatform Tugas Akhir. Uji coba yang dilakukan bertujuan untuk menemukan kekurangan, keterbatasan, maupun kesalahan dalam pembuatan aplikasi Tugas Akhir ini. Terdapat dua macam uji coba yang akan dilakukan, yaitu Functionality Test dan User Acceptance Test.

---

## 6.1 Functionality Test

Pada sub-bab ini akan menjelaskan mengenai functionality testing, dimana uji coba akan dilakukan oleh developer. Pada functionality test, semua fitur yang terdapat dalam aplikasi akan dicoba untuk memastikan semua fitur berjalan sesuai dengan yang diinginkan. Pada functionality test juga akan dilakukan uji coba perbandingan input dan output aplikasi untuk memastikan bahwa fitur sudah berfungsi dengan benar. Berikut penjelasan uji coba functionality testing yang dilakukan dalam pembuatan Tugas Akhir ini.

### 6.1.1 Integrasi API Midtrans

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur integrasi API Midtrans. Uji coba ini dilakukan untuk memastikan proses pembayaran non-tunai melalui Midtrans dapat berjalan dengan baik, termasuk generation snap token, handling notification, dan pemetaan status transaksi. Tabel skenario uji coba pada fitur integrasi API Midtrans dapat dilihat pada Tabel 6.1.

**Tabel 6.1 Skenario dan Hasil Pengujian Fitur Integrasi API Midtrans**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Inisialisasi Midtrans client | Aplikasi melakukan inisialisasi dengan serverKey dan clientKey dari environment | Client Midtrans berhasil dibuat dan siap digunakan | Sesuai harapan |
| 2 | Generate snap token | Customer memilih metode pembayaran Midtrans dan menekan tombol Bayar | Snap token berhasil dibuat dan redirect URL terbentuk | Sesuai harapan |
| 3 | Handle payment notification | Midtrans mengirimkan webhook notification ke server | Status transaksi dipetakan dengan benar (capture/settlement → paid, deny/cancel/expire → failed) | Sesuai harapan |
| 4 | Pemetaan status transaksi | Sistem menerima status "settlement" dari Midtrans | Status dipetakan ke "paid" dan order status diperbarui | Sesuai harapan |

### 6.1.2 Integrasi OpenStreetMap

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur integrasi OpenStreetMap. Uji coba dilakukan untuk memastikan peta interaktif dapat ditampilkan dengan baik menggunakan library Leaflet, termasuk inisialisasi peta, penambahan marker, dan binding popup. Tabel skenario uji coba pada fitur integrasi OpenStreetMap dapat dilihat pada Tabel 6.2.

**Tabel 6.2 Skenario dan Hasil Pengujian Fitur Integrasi OpenStreetMap**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Inisialisasi peta | Memanggil fungsi initMap dengan ID elemen, koordinat, dan level zoom | Peta berhasil diinisialisasi dan tile layer OpenStreetMap aktif | Sesuai harapan |
| 2 | Penambahan marker | Memanggil fungsi addMarker dengan koordinat dan teks popup | Marker muncul pada posisi yang ditentukan di peta dan popup menampilkan teks saat diklik | Sesuai harapan |
| 3 | Tile layer OpenStreetMap | Peta menampilkan tile layer dari OpenStreetMap | Tile layer OpenStreetMap tampil dengan benar dengan atribusi yang sesuai | Sesuai harapan |
| 4 | Popup binding | Marker diklik oleh pengguna | Popup menampilkan teks yang telah di-bind sebelumnya | Sesuai harapan |

### 6.1.3 Integrasi OpenRouteService

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur integrasi OpenRouteService. Uji coba dilakukan untuk memastikan perhitungan rute dapat berjalan dengan baik, termasuk penanganan data rute invalid dan mekanisme pengulangan. Tabel skenario uji coba pada fitur integrasi OpenRouteService dapat dilihat pada Tabel 6.3.

**Tabel 6.3 Skenario dan Hasil Pengujian Fitur Integrasi OpenRouteService**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Hitung rute dengan ORS | Driver memulai pengiriman dan sistem memanggil layanan rute dengan titik awal dan tujuan | Rute pengiriman dikembalikan dan siap ditampilkan di peta | Sesuai harapan |
| 2 | Decode polyline | Sistem menerima data rute terenkripsi dari ORS | Rute berhasil didecode menjadi koordinat yang dapat digambar di peta | Sesuai harapan |
| 3 | Navigasi ditampilkan di peta | Rute pengiriman divisualisasikan pada peta | Rute yang dibuat sudah sesuai, namun garis pada peta sedikit menyimpang dari jalan yang sebenarnya | Tidak sesuai harapan |

### 6.1.4 WebSocket Gateway

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur WebSocket Gateway. Uji coba dilakukan untuk memastikan komunikasi real-time antara server dan klien dapat berjalan dengan baik untuk update lokasi driver dan notifikasi pesanan. Tabel skenario uji coba pada fitur WebSocket Gateway dapat dilihat pada Tabel 6.4.

**Tabel 6.4 Skenario dan Hasil Pengujian Fitur WebSocket Gateway**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Koneksi driver ke WebSocket | Driver membuka halaman pengiriman dan aplikasi melakukan koneksi WebSocket | Koneksi WebSocket tersambung | Sesuai harapan |
| 2 | Pengiriman lokasi driver | Driver mengirim update lokasi melalui WebSocket | Lokasi driver diperbarui di database dan admin menerima notifikasi | Sesuai harapan |
| 3 | Broadcast ke admin dan Customer | Driver mengirim lokasi update | Admin menerima update lokasi driver secara real-time | Sesuai harapan |

### 6.1.5 Authentication Customer

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Authentication Customer. Uji coba dilakukan untuk memastikan proses login dan registrasi customer dapat berjalan dengan baik dan aman. Tabel skenario uji coba pada fitur Authentication Customer dapat dilihat pada Tabel 6.5.

**Tabel 6.5 Skenario dan Hasil Pengujian Fitur Authentication Customer**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Login customer dengan data valid | Customer memasukkan username dan password yang benar lalu login | Login berhasil dan data customer (id, name, username, phone) dikembalikan | Sesuai harapan |
| 2 | Login customer dengan data invalid | Customer memasukkan username atau password yang salah | Login gagal dan error message "Username atau password salah" ditampilkan | Sesuai harapan |
| 3 | Login dengan field kosong | Customer menekan tombol login tanpa mengisi username atau password | Validasi menunjukkan pesan error bahwa field harus diisi | Sesuai harapan |
| 4 | Registrasi customer baru | Customer mengisi form registrasi dengan data lengkap dan valid | Customer baru tersimpan di database dan dapat login | Sesuai harapan |

### 6.1.6 Authentication Courier

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Authentication Courier. Uji coba dilakukan untuk memastikan proses login courier (driver) dapat berjalan dengan baik, termasuk pemeriksaan isActive driver. Tabel skenario uji coba pada fitur Authentication Courier dapat dilihat pada Tabel 6.6.

**Tabel 6.6 Skenario dan Hasil Pengujian Fitur Authentication Courier**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Login driver dengan data valid | Driver memasukkan username dan password yang benar lalu login | Login berhasil dan data driver (id, name, username) dikembalikan | Sesuai harapan |
| 2 | Login driver dengan data invalid | Driver memasukkan username atau password yang salah | Login gagal dan error message ditampilkan | Sesuai harapan |
| 3 | Login driver nonaktif | Driver yang sudah dinonaktifkan mencoba login | Login gagal karena driver tidak aktif | Sesuai harapan |
| 4 | Login dengan field kosong | Driver menekan tombol login tanpa mengisi field | Validasi menunjukkan pesan error | Sesuai harapan |

### 6.1.7 Katalog Produk

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Katalog Produk. Uji coba dilakukan untuk memastikan tampilan daftar produk, pencarian, dan filter berdasarkan kategori dapat berjalan dengan baik. Tabel skenario uji coba pada fitur Katalog Produk dapat dilihat pada Tabel 6.7.

**Tabel 6.7 Skenario dan Hasil Pengujian Fitur Katalog Produk**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan daftar produk | Customer membuka halaman katalog produk | Daftar produk tampil dalam bentuk grid dengan gambar, nama, harga, dan info stok | Sesuai harapan |
| 2 | Pencarian produk | Customer mengetikkan kata kunci pada search box | Produk yang sesuai dengan kata kunci ditampilkan | Sesuai harapan |

### 6.1.8 Detail Produk dan Add to Cart

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Detail Produk dan Add to Cart. Uji coba dilakukan untuk memastikan pemilihan variant, quantity selector, dan penambahan produk ke keranjang dapat berjalan dengan baik. Tabel skenario uji coba pada fitur Detail Produk dan Add to Cart dapat dilihat pada Tabel 6.8.

**Tabel 6.8 Skenario dan Hasil Pengujian Fitur Detail Produk dan Add to Cart**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan detail produk | Customer memilih salah satu produk dari katalog | Halaman detail produk tampil dengan info lengkap, gambar, dan variant | Sesuai harapan |
| 2 | Pemilihan variant | Customer memilih salah satu variant dari daftar (jika produk memiliki variant) | Variant yang dipilih ditandai dan harga sesuai variant yang dipilih | Sesuai harapan |
| 3 | Increment quantity | Customer menekan tombol + pada quantity selector | Jumlah quantity bertambah sesuai | Sesuai harapan |
| 4 | Decrement quantity | Customer menekan tombol - pada quantity selector | Jumlah quantity berkurang (minimum 1) | Sesuai harapan |
| 5 | Tambah ke keranjang | Customer mengisi quantity dan menekan tombol "Tambah ke Keranjang" | Item ditambahkan ke keranjang dan modal tertutup | Sesuai harapan |
| 6 | Tambah ke keranjang melebihi stok | Customer memasukkan quantity melebihi stok yang tersedia | Quantity dibatasi sesuai stok maksimum | Sesuai harapan |

### 6.1.9 Keranjang Belanja

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Keranjang Belanja. Uji coba dilakukan untuk memastikan proses CRUD item keranjang, update quantity, dan perhitungan subtotal dapat berjalan dengan baik. Tabel skenario uji coba pada fitur Keranjang Belanja dapat dilihat pada Tabel 6.9.

**Tabel 6.9 Skenario dan Hasil Pengujian Fitur Keranjang Belanja**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan item keranjang | Customer membuka halaman keranjang belanja | Semua item di keranjang tampil dengan info produk, jumlah, dan subtotal | Sesuai harapan |
| 2 | Update jumlah item | Customer mengubah jumlah item pada salah satu produk | Jumlah dan subtotal diperbarui sesuai perubahan | Sesuai harapan |
| 3 | Hapus item dari keranjang | Customer menekan tombol hapus pada salah satu item | Item dihapus dari keranjang dan daftar diperbarui | Sesuai harapan |
| 4 | Kosongkan keranjang | Customer memilih opsi kosongkan keranjang | Semua item di keranjang dihapus | Sesuai harapan |
| 5 | Perhitungan subtotal | Customer menambahkan atau mengubah jumlah item | Total harga diperbarui secara real-time sesuai perubahan | Sesuai harapan |
| 6 | Lanjut ke checkout | Customer menekan tombol "Checkout" | Navigasi ke halaman checkout dengan data keranjang dan total | Sesuai harapan |

### 6.1.10 Checkout dan Pembayaran

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Checkout dan Pembayaran. Uji coba dilakukan untuk memastikan pencarian alamat dengan Nominatim, pemilihan time slot, pembuatan order, dan pembayaran dengan Midtrans dapat berjalan dengan baik. Tabel skenario uji coba pada fitur Checkout dan Pembayaran dapat dilihat pada Tabel 6.10.

**Tabel 6.10 Skenario dan Hasil Pengujian Fitur Checkout dan Pembayaran**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Pencarian alamat | Customer mengetikkan alamat pada search box | Saran alamat dari Nominatim muncul | Sesuai harapan |
| 2 | Pemilihan saran alamat | Customer memilih salah satu saran alamat | Alamat terisi otomatis dan koordinat tersimpan | Sesuai harapan |
| 3 | Pemilihan time slot | Customer memilih jadwal pengiriman yang tersedia | Time slot yang dipilih tersimpan | Sesuai harapan |
| 4 | Time slot penuh | Customer memilih time slot yang sudah mencapai batas maksimal (3 order) | Time slot tidak dapat dipilih atau dinonaktifkan | Sesuai harapan |
| 5 | Membuat order | Customer mengisi semua data required dan menekan tombol "Buat Pesanan" | Order berhasil dibuat dengan status sesuai metode pembayaran | Sesuai harapan |
| 6 | Pembayaran dengan Midtrans | Customer memilih metode pembayaran Midtrans | Midtrans Snap terbuka dan customer dapat menyelesaikan pembayaran | Sesuai harapan |
| 7 | Validasi field kosong | Customer mencoba checkout tanpa mengisi salah satu field wajib | Sistem menampilkan pesan error dan tidak memproses checkout | Sesuai harapan |

### 6.1.11 Manajemen Alamat

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Manajemen Alamat. Uji coba dilakukan untuk memastikan customer dapat melihat dan memperbarui alamat pengiriman mereka. Tabel skenario uji coba pada fitur Manajemen Alamat dapat dilihat pada Tabel 6.11.

**Tabel 6.11 Skenario dan Hasil Pengujian Fitur Manajemen Alamat**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan alamat saat ini | Customer membuka halaman edit alamat | Alamat saat ini tampil pada form | Sesuai harapan |
| 2 | Memperbarui alamat | Customer mengubah alamat dan menyimpan | Alamat diperbarui di database | Sesuai harapan |
| 3 | Simpan dengan field kosong | Customer mengosongkan field alamat dan menyimpan | Sistem menampilkan pesan error bahwa alamat tidak boleh kosong | Sesuai harapan |
| 4 | Alamat otomatis terisi di checkout | Customer telah menyimpan alamat default | Pada halaman checkout, field alamat terisi otomatis | Sesuai harapan |

### 6.1.12 Riwayat Pesanan Customer

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Riwayat Pesanan Customer. Uji coba dilakukan untuk memastikan customer dapat melihat daftar pesanan dan detail setiap pesanan dengan lengkap. Tabel skenario uji coba pada fitur Riwayat Pesanan Customer dapat dilihat pada Tabel 6.12.

**Tabel 6.12 Skenario dan Hasil Pengujian Fitur Riwayat Pesanan Customer**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan daftar pesanan | Customer membuka halaman riwayat pesanan | Daftar pesanan tampil dengan urutan terbaru terlebih dahulu | Sesuai harapan |
| 2 | Menampilkan detail pesanan | Customer memilih salah satu pesanan dari daftar | Halaman detail pesanan tampil dengan info lengkap (items, driver, alamat, status) | Sesuai harapan |
| 3 | Format status pesanan | Daftar pesanan menampilkan status dengan label yang mudah dipahami | Status seperti "pending" ditampilkan sebagai "Menunggu", "delivered" sebagai "Selesai" | Sesuai harapan |
| 4 | Format tanggal pesanan | Pesanan menampilkan tanggal dengan format dd/mm/yyyy | Tanggal pesanan tampil dengan format yang benar | Sesuai harapan |

### 6.1.13 Auto-dispatch

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Auto-dispatch. Uji coba dilakukan untuk memastikan sistem dapat menugaskan driver terdekat secara otomatis menggunakan formula Haversine. Tabel skenario uji coba pada fitur Auto-dispatch dapat dilihat pada Tabel 6.13.

**Tabel 6.13 Skenario dan Hasil Pengujian Fitur Auto-dispatch**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Perhitungan jarak Haversine | Sistem menghitung jarak antara dua titik koordinat | Jarak dalam kilometer dikembalikan dengan benar | Sesuai harapan |
| 2 | Cari driver terdekat | Order baru masuk dan pembayaran berhasil, sistem mencari driver terdekat | Driver dengan jarak terdekat dari lokasi penjemputan dipilih | Sesuai harapan |
| 3 | Driver tanpa koordinat | Driver yang dipilih belum memiliki koordinat | Driver tersebut langsung dipilih tanpa perhitungan jarak | Sesuai harapan |
| 4 | Tidak ada driver tersedia | Semua driver sedang sibuk atau tidak ada driver aktif | Sistem tidak menugaskan driver dan order menunggu | Sesuai harapan |
| 5 | Update status driver | Driver ditugaskan ke order | Driver yang dipilih ditandai sebagai tidak tersedia sampai order selesai | Sesuai harapan |

### 6.1.14 Manajemen Pengiriman Courier

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Manajemen Pengiriman Courier. Uji coba dilakukan untuk memastikan courier dapat menerima order, memperbarui status pengiriman, dan mengirim update lokasi secara real-time. Tabel skenario uji coba pada fitur Manajemen Pengiriman Courier dapat dilihat pada Tabel 6.14.

**Tabel 6.14 Skenario dan Hasil Pengujian Fitur Manajemen Pengiriman Courier**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan daftar pesanan | Courier membuka halaman utama | Pesanan yang tersedia dan pesanan yang diterima tampil dengan jelas | Sesuai harapan |
| 2 | Update status: Mulai Pickup | Courier menekan tombol "Mulai Pickup" pada status pending | Status berubah menjadi pickingUp dan timestamp diperbarui | Sesuai harapan |
| 3 | Update status: Barang Diambil | Courier menekan tombol "Barang Diambil" pada status pickingUp | Status berubah menjadi pickedUp | Sesuai harapan |
| 4 | Update status: Mulai Antar | Courier menekan tombol "Mulai Antar" pada status pickedUp | Status berubah menjadi delivering | Sesuai harapan |
| 5 | Update status: Selesai | Courier menekan tombol "Selesai" pada status delivering | Status berubah menjadi delivered dan driver kembali available | Sesuai harapan |
| 6 | Inisialisasi location tracking | Courier membuka halaman pengiriman | Aplikasi meminta permission lokasi dan memulai tracking | Sesuai harapan |
| 7 | Pengiriman lokasi via WebSocket | Location update dikirim melalui WebSocket | Lokasi driver diperbarui di server dan broadcast ke admin | Sesuai harapan |

### 6.1.15 Riwayat Pengiriman Courier

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Riwayat Pengiriman Courier. Uji coba dilakukan untuk memastikan courier dapat melihat daftar pesanan yang telah diselesaikan. Tabel skenario uji coba pada fitur Riwayat Pengiriman Courier dapat dilihat pada Tabel 6.15.

**Tabel 6.15 Skenario dan Hasil Pengujian Fitur Riwayat Pengiriman Courier**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan pesanan selesai | Courier membuka halaman riwayat pengiriman | Daftar pesanan dengan status delivered ditampilkan | Sesuai harapan |
| 2 | Filter pesanan selesai | Sistem memanggil data pesanan dengan status selesai | Hanya pesanan yang sudah selesai yang dikembalikan | Sesuai harapan |
| 3 | Menampilkan info pesanan | Setiap item pada daftar menampilkan ID, alamat tujuan, dan tanggal selesai | Info pesanan tampil dengan lengkap dan terformat | Sesuai harapan |
| 4 | Urutan terbaru | Daftar pesanan diurutkan berdasarkan updatedAt descending | Pesanan terbaru muncul pertama | Sesuai harapan |

### 6.1.16 Manajemen Employee

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Manajemen Employee. Uji coba dilakukan untuk memastikan admin dapat menambah, melihat, memperbarui, dan menonaktifkan data driver/employee. Tabel skenario uji coba pada fitur Manajemen Employee dapat dilihat pada Tabel 6.16.

**Tabel 6.16 Skenario dan Hasil Pengujian Fitur Manajemen Employee**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menambah employee baru | Admin mengisi form data driver lengkap dan menyimpan | Driver baru tersimpan di database | Sesuai harapan |
| 2 | Melihat daftar employee | Admin membuka halaman manajemen employee | Daftar semua driver tampil dengan info nama, username, kendaraan | Sesuai harapan |
| 3 | Menonaktifkan employee | Admin menekan tombol hapus pada salah satu driver | Driver dinonaktifkan | Sesuai harapan |
| 4 | Validasi input kosong | Admin menyimpan form dengan field wajib kosong | Sistem menampilkan pesan error | Sesuai harapan |

### 6.1.17 Lacak Driver (Admin)

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Lacak Driver. Uji coba dilakukan untuk memastikan admin dapat melihat lokasi real-time semua driver yang sedang bertugas di atas peta. Tabel skenario uji coba pada fitur Lacak Driver dapat dilihat pada Tabel 6.17.

**Tabel 6.17 Skenario dan Hasil Pengujian Fitur Lacak Driver**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan peta dengan driver | Admin membuka halaman lacak driver | Peta OpenStreetMap tampil dengan marker untuk setiap driver aktif | Sesuai harapan |
| 2 | Menampilkan info driver di marker | Admin mengklik marker driver | Popup menampilkan nama driver dan status (Tersedia/Sedang Mengirim) | Sesuai harapan |
| 3 | Update lokasi driver secara real-time | Driver mengirim update lokasi baru | Posisi marker driver di peta bergeser sesuai koordinat baru | Sesuai harapan |
| 4 | Filter driver aktif saja | Sistem memanggil data lokasi semua driver | Hanya driver yang aktif yang ditampilkan | Sesuai harapan |

### 6.1.18 Pelacakan Pesanan (Customer)

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Pelacakan Pesanan. Uji coba dilakukan untuk memastikan customer dapat memantau status pesanan secara real-time termasuk lokasi driver di peta. Tabel skenario uji coba pada fitur Pelacakan Pesanan dapat dilihat pada Tabel 6.18.

**Tabel 6.18 Skenario dan Hasil Pengujian Fitur Pelacakan Pesanan Customer**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan status pesanan | Customer membuka halaman tracking pesanan | Status pesanan dan timeline tampil dengan benar | Sesuai harapan |
| 2 | Update status real-time | Status pesanan berubah (misal dari pickingUp ke pickedUp) | UI secara otomatis memperbarui status tanpa refresh | Sesuai harapan |
| 3 | Lokasi driver di peta | Driver mengirim update lokasi | Marker driver bergerak di peta sesuai lokasi terbaru | Sesuai harapan |
| 4 | Label status yang mudah dipahami | Status pesanan "delivering" | Ditampilkan sebagai "Driver dalam perjalanan ke lokasi Anda" | Sesuai harapan |

### 6.1.19 Dashboard Admin

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Dashboard Admin. Uji coba dilakukan untuk memastikan admin dapat melihat statistik pesanan, revenue, dan aktivitas driver secara real-time. Tabel skenario uji coba pada fitur Dashboard Admin dapat dilihat pada Tabel 6.19.

**Tabel 6.19 Skenario dan Hasil Pengujian Fitur Dashboard Admin**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan statistik utama | Admin membuka halaman dashboard | Kartu statistik menampilkan Total Employee, Revenue Today, Orders Today, Orders This Month | Sesuai harapan |
| 2 | Load data revenue | Dashboard memuat data dari API | Revenue today tampil dengan format mata uang Indonesia (Rp) | Sesuai harapan |
| 3 | Data grafik orders per jam | Dashboard memuat data orders per hour | Data untuk 24 jam terakhir tampil pada grafik | Sesuai harapan |
| 4 | Data grafik orders per bulan | Dashboard memuat data orders per day | Data untuk 30 hari terakhir tampil pada grafik | Sesuai harapan |
| 5 | Handle error saat load stats | API mengembalikan error | Error ditangani dengan log dan tidak crash aplikasi | Sesuai harapan |

### 6.1.20 Manajemen Stok

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Manajemen Stok. Uji coba dilakukan untuk memastikan admin dapat mengelola inventori produk dan sistem memberikan alert reorder point dengan benar. Tabel skenario uji coba pada fitur Manajemen Stok dapat dilihat pada Tabel 6.20.

**Tabel 6.20 Skenario dan Hasil Pengujian Fitur Manajemen Stok**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Perhitungan ROP | Sistem menghitung ROP dengan formula (leadTime × avgDailySales) + safetyStock | Nilai ROP dihitung dengan benar | Sesuai harapan |
| 2 | Alert reorder: sold = 0 | Produk terjual 0 unit dan stock ≤ safetyStock | Produk ditandai perlu reorder | Sesuai harapan |
| 3 | Alert reorder: sold < 7 | Produk terjual kurang dari 7 unit dan stock ≤ (safetyStock + leadTime) | Produk ditandai perlu reorder | Sesuai harapan |
| 4 | Alert reorder: sold ≥ 7 | Produk terjual 7 atau lebih dan stock ≤ ROP | Produk ditandai perlu reorder | Sesuai harapan |
| 5 | Menambah produk baru | Admin mengisi form produk lengkap dan menyimpan | Produk baru tersimpan di database | Sesuai harapan |
| 6 | Validasi input produk | Admin mengisi harga atau stock dengan nilai invalid | Sistem menampilkan pesan error dan tidak menyimpan | Sesuai harapan |
| 7 | Hitung avgDailySales | Sistem menghitung rata-rata penjualan harian dalam 7 hari terakhir | AvgDailySales dihitung dari total sold / 7 | Sesuai harapan |

### 6.1.21 Time Slot Booking

Pada sub-bab ini akan dijelaskan mengenai uji coba pada fitur Time Slot Booking. Uji coba dilakukan untuk memastikan admin dapat membuat dan mengelola time slot, dan customer dapat memilih slot waktu pengiriman. Tabel skenario uji coba pada fitur Time Slot Booking dapat dilihat pada Tabel 6.21.

**Tabel 6.21 Skenario dan Hasil Pengujian Fitur Time Slot Booking**

| No | Skenario Pengujian | Test Case | Hasil yang Diharapkan | Hasil Pengujian |
|----|-------------------|-----------|----------------------|-----------------|
| 1 | Menampilkan daftar time slot | Sistem memanggil semua time slot aktif | Semua time slot aktif tampil dengan urutan berdasarkan tanggal dan jam mulai | Sesuai harapan |
| 2 | Calendar view time slot | Halaman time slot menampilkan calendar view | Time slot dikelompokkan berdasarkan tanggal | Sesuai harapan |
| 3 | Validasi input time slot | Admin menyimpan form dengan field kosong | Sistem menampilkan pesan error | Sesuai harapan |
| 4 | Batas maksimal 3 order per slot | Terdapat 3 pesanan pada slot waktu yang sama | Slot tersebut tidak dapat dipilih oleh customer lain | Sesuai harapan |

---

## 6.2 User Acceptance Testing

Pada sub-bab ini dijelaskan proses pelaksanaan User Acceptance Test (UAT) terhadap aplikasi e-commerce multiplatform. UAT dilakukan untuk memastikan bahwa aplikasi telah memenuhi kebutuhan operasional pengguna akhir serta dapat digunakan dengan nyaman, mudah dipahami, dan memberikan manfaat nyata pada proses kerja.

Uji coba dilakukan oleh beberapa aktor sesuai perannya, yaitu customer dan courier. Setiap pengguna memperoleh arahan mengenai langkah pengujian, kemudian mencoba aplikasi sesuai fitur yang relevan dengan perannya. Setelah itu, pengguna mengisi kuesioner evaluasi menggunakan skala Likert 1–5.

### 6.2.1 Skala Likert

Skala Likert digunakan sebagai acuan dalam menginterpretasikan hasil kuesioner User Acceptance Testing yang telah diisi oleh responden. Setiap jawaban responden diberikan bobot nilai dari 1 hingga 5, kemudian dirata-ratakan untuk menentukan kategori penilaian terhadap masing-masing aspek yang diuji. Tabel 6.22 berikut menampilkan rentang skor beserta interpretasinya yang digunakan sebagai dasar penilaian hasil UAT.

**Tabel 6.22 Interpretasi Skala Likert**

| Rentang Skor | Interpretasi |
|-------------|-------------|
| 1.00–1.99 | Sangat Buruk |
| 2.00–2.99 | Buruk |
| 3.00–3.49 | Cukup |
| 3.50–4.19 | Baik |
| 4.20–5.00 | Sangat Baik |

### 6.2.2 Kuesioner untuk Customer

UAT untuk Customer App melibatkan 25 responden yang berperan sebagai customer dalam proses pengujian. Kuesioner yang digunakan terdiri dari 21 pertanyaan yang mencakup seluruh fitur utama Customer App, mulai dari proses login dan registrasi, katalog produk, keranjang belanja, checkout, pembayaran, hingga pelacakan pesanan. Tabel 6.23 berikut menampilkan daftar pertanyaan kuesioner yang digunakan dalam pengujian UAT Customer App.

**Tabel 6.23 Kuesioner User Acceptance Testing untuk Customer**

| No | Pertanyaan |
|----|-----------|
| 1 | Waktu Loading dari tekan login sampai masuk ke katalog |
| 2 | Pesan error saat Login gagal |
| 3 | Proses Registrasi Akun Baru |
| 4 | Tampilan Halaman Login dan Registrasi Secara Visual |
| 5 | Tampilan Produk |
| 6 | Fitur Pencarian Produk |
| 7 | Kecepatan Memuat Daftar Produk saat Pertama Kali Membuka Katalog |
| 8 | Informasi Stock Produk yang di Tampilkan |
| 9 | Informasi pada Halaman Detial Produk |
| 10 | Perubahan Jumlah item di Keranjang Mengupdate total Harga |
| 11 | Proses Hapus Item Dari Keranjang |
| 12 | Peta di halaman Checkout Menunjukkan Lokasi Alamat yang dipilih |
| 13 | Pemilihan Slot Waktu Pengiriman |
| 14 | Keseluruhan Alur dari Pilih Produk sampai Selesai Checkout |
| 15 | Setelah Pembayaran Suskses, Redirect ke Halaman Pelacakan |
| 16 | Status pesanan terbaru di Tampilkan di Halaman Pelacakan |
| 17 | Posisi Driver Terlihat di Peta Saat Status Delivering |
| 18 | Timeline Status Pesanan (Menunggu - Pickup - diantar - tiba) terlihat |
| 19 | Daftar Riwayat Pesanan |
| 20 | Detail Pesanan Dari Riwayat |

### 6.2.3 Kuesioner untuk Courier

UAT untuk Courier App melibatkan 3 responden yang berperan sebagai kurir dalam proses pengujian. Kuesioner yang digunakan terdiri dari 16 pertanyaan yang mencakup seluruh fitur utama Courier App, mulai dari proses login, daftar tugas pengiriman, detail pesanan, navigasi peta, hingga konfirmasi pengiriman. Tabel 6.24 berikut menampilkan daftar pertanyaan kuesioner yang digunakan dalam pengujian UAT Courier App.

**Tabel 6.24 Kuesioner User Acceptance Testing untuk Courier**

| No | Pertanyaan |
|----|-----------|
| 1 | Waktu Loading dari Tekan Login Sampai Masuk ke DashBoard Utama Driver |
| 2 | Pesan Error Saat Login Gagal |
| 3 | Waktu Sistem Saat Menekan Tombol Terima Pesanan |
| 4 | Akurasi Peta dan Navigasi Menuju Lokasi Toko |
| 5 | Informasi Detail Item Pesanan yang Harus di Ambil di Toko |
| 6 | Fitur Update Status "Pesanan Telah Diambil" Bekerja |
| 7 | Akurasi Peta dan Navigasi Rute dari Toko ke Alamat Pelanggan |
| 8 | Fitur Tracking Posisi Driver di Peta Saat Proses Pengiriman |
| 9 | Kejelasan Tampilan Pengiriman |
| 10 | Fitur Update Status "Pesanan Tiba di Tujuan" Bekerja |
| 11 | Proses Konfirmasi Penyelesaian Pesanan |
| 12 | Fitur Ungah Bukti Pengiriman |
| 13 | Daftar Riwayat Pesanan Yang Telah di Selesaikan |
| 14 | Proses Logout Dari Aplikasi |
| 15 | Keseluruhan Pengalaman dari Menerima Order Hingga Selesai |

### 6.2.4 Hasil User Acceptance Testing

Berdasarkan data yang dikumpulkan dari responden, dilakukan perhitungan rata-rata untuk setiap pertanyaan. Hasil rekapitulasi User Acceptance Testing akan disajikan pada tabel berikut.

**Tabel 6.25 Rata-Rata User Acceptance Testing Customer**

| No | Pertanyaan | Rata-Rata |
|----|-----------|-----------|
| 1 | Waktu Loading dari tekan login sampai masuk ke katalog | 4.16 |
| 2 | Pesan error saat Login gagal | 4.08 |
| 3 | Proses Registrasi Akun Baru | 3.72 |
| 4 | Tampilan Halaman Login dan Registrasi Secara Visual | 4.00 |
| 5 | Tampilan Produk | 3.92 |
| 6 | Fitur Pencarian Produk | 3.92 |
| 7 | Kecepatan Memuat Daftar Produk saat Pertama Kali Membuka Katalog | 3.96 |
| 8 | Informasi Stock Produk yang di Tampilkan | 4.04 |
| 9 | Informasi pada Halaman Detial Produk | 3.96 |
| 10 | Perubahan Jumlah item di Keranjang Mengupdate total Harga | 3.96 |
| 11 | Proses Hapus Item Dari Keranjang | 4.00 |
| 12 | Peta di halaman Checkout Menunjukkan Lokasi Alamat yang dipilih | 3.96 |
| 13 | Pemilihan Slot Waktu Pengiriman | 3.88 |
| 14 | Keseluruhan Alur dari Pilih Produk sampai Selesai Checkout | 4.00 |
| 15 | Setelah Pembayaran Suskses, Redirect ke Halaman Pelacakan | 4.16 |
| 16 | Status pesanan terbaru di Tampilkan di Halaman Pelacakan | 3.84 |
| 17 | Posisi Driver Terlihat di Peta Saat Status Delivering | 3.84 |
| 18 | Timeline Status Pesanan (Menunggu - Pickup - diantar - tiba) terlihat | 4.20 |
| 19 | Daftar Riwayat Pesanan | 3.80 |
| 20 | Detail Pesanan Dari Riwayat | 4.04 |

**Tabel 6.26 Rata-Rata User Acceptance Testing Courier**

| No | Pertanyaan | Rata-Rata |
|----|-----------|-----------|
| 1 | Waktu Loading dari Tekan Login Sampai Masuk ke DashBoard Utama Driver | 3.33 |
| 2 | Pesan Error Saat Login Gagal | 3.00 |
| 3 | Waktu Sistem Saat Menekan Tombol Terima Pesanan | 3.67 |
| 4 | Akurasi Peta dan Navigasi Menuju Lokasi Toko | 3.00 |
| 5 | Informasi Detail Item Pesanan yang Harus di Ambil di Toko | 4.00 |
| 6 | Fitur Update Status "Pesanan Telah Diambil" Bekerja | 4.00 |
| 7 | Akurasi Peta dan Navigasi Rute dari Toko ke Alamat Pelanggan | 3.33 |
| 8 | Fitur Tracking Posisi Driver di Peta Saat Proses Pengiriman | 3.33 |
| 9 | Kejelasan Tampilan Pengiriman | 3.67 |
| 10 | Fitur Update Status "Pesanan Tiba di Tujuan" Bekerja | 4.00 |
| 11 | Proses Konfirmasi Penyelesaian Pesanan | 4.00 |
| 12 | Fitur Ungah Bukti Pengiriman | 3.00 |
| 13 | Daftar Riwayat Pesanan Yang Telah di Selesaikan | 4.00 |
| 14 | Proses Logout Dari Aplikasi | 3.67 |
| 15 | Keseluruhan Pengalaman dari Menerima Order Hingga Selesai | 3.67 |

### 6.2.5 Kesimpulan User Acceptance Testing

Berdasarkan hasil pengujian yang telah dilakukan, pengguna aplikasi e-commerce multiplatform merasa puas terhadap kualitas aplikasi yang dikembangkan. Aplikasi telah berhasil memenuhi kebutuhan pengguna dalam hal kemudahan penggunaan, kenyamanan tampilan, serta efisiensi dalam proses kerja. Dengan demikian, aplikasi dapat dinyatakan diterima oleh pengguna dan layak digunakan sebagai sistem e-commerce multiplatform.