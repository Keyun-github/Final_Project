# Bab VII
# Penutup

Setelah melalui tahapan analisis, perancangan, implementasi, serta pengujian terhadap aplikasi yang dikembangkan, bab ini menyajikan kesimpulan dan saran dari Tugas Akhir ini. Kesimpulan berisi rangkuman inti yang diperoleh dari seluruh proses dan hasil analisis selama pengerjaan. Sementara itu, saran memuat berbagai usulan yang dapat diterapkan untuk pengembangan lebih lanjut di masa mendatang. Usulan tersebut disusun berdasarkan temuan selama proses analisis serta hasil kuesioner yang telah diisi oleh pengguna pada tahap pengujian.

---

## 7.1 Kesimpulan

Pada sub-bab ini disajikan kesimpulan yang diperoleh dari keseluruhan proses penyusunan Tugas Akhir. Adapun kesimpulan yang dapat diambil dari Tugas Akhir ini adalah sebagai berikut.

- Sistem e-commerce multiplatform yang terdiri dari Customer App, Courier App, dan Admin Panel berhasil diimplementasikan dengan baik. Hal ini dibuktikan melalui hasil User Acceptance Test, di mana mayoritas aspek pengujian memperoleh nilai rata-rata yang baik, sehingga aplikasi diterima oleh pengguna dan layak digunakan.

- Integrasi payment gateway Midtrans berhasil memproses pembayaran non-tunai dengan berbagai metode seperti QRIS, Virtual Account, dan E-Wallet. Sistem secara otomatis memperbarui status pesanan setelah pembayaran berhasil dikonfirmasi.

- Fitur auto-dispatch yang mengimplementasikan formula Haversine untuk menghitung jarak antara driver dan lokasi penjemputan berhasil beroperasi dengan baik. Sistem secara otomatis menugaskan driver terdekat kepada pesanan baru, sehingga menghilangkan kebutuhan intervensi manual dari admin dalam menugaskan kurir.

- Fitur pelacakan pesanan real-time yang memanfaatkan WebSocket berhasil memberikan pengalaman yang baik bagi customer. Customer dapat memantau posisi driver di peta dan status pesanan mereka tanpa perlu melakukan refresh halaman secara manual.

- Fitur manajemen stok dengan perhitungan Reorder Point (ROP) berhasil membantu admin dalam memantau dan mengendalikan inventori produk. Sistem secara otomatis memberikan peringatan ketika stok suatu produk mencapai atau melewati batas reorder point.

- Fitur time slot booking yang membatasi maksimal tiga pesanan per slot waktu berhasil mengoptimalkan kapasitas driver dan memberikan fleksibilitas waktu pengiriman bagi customer.

- Secara umum, aplikasi memberikan kemudahan penggunaan, tampilan yang jelas, serta meningkatkan efisiensi kegiatan operasional bagi seluruh pengguna.

---

## 7.2 Saran

Pada sub-bab ini akan dibahas mengenai saran untuk pengembangan Tugas Akhir ini di masa yang akan datang. Saran-saran ini didapatkan dari beberapa hal yang dialami dalam proses pengerjaan Tugas Akhir ini. Selain itu, saran-saran ini juga didapatkan dari masukan user yang menggunakan aplikasi tugas akhir ini. Berikut adalah beberapa saran yang mendapatkan dari Tugas Akhir ini.

- Perlu dilakukan optimalisasi pada tampilan garis navigasi rute pengiriman di peta agar lebih sesuai dengan jalan yang sebenarnya.

- Dapat ditambahkan fitur notifikasi push untuk memberikan informasi kepada pengguna tentang status pesanan secara langsung.

- Pengembangan lebih lanjut dapat dilakukan untuk menambahkan fitur export laporan dalam format PDF atau Excel untuk memudahkan admin dalam membuat laporan operasional.