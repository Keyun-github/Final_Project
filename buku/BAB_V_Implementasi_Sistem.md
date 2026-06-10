# Bab V
# Implementasi Sistem

Bab ini menjelaskan implementasi dari rancangan sistem yang telah dijelaskan pada bab sebelumnya. Implementasi mencakup integrasi API eksternal dan implementasi fitur-fitur utama sistem e-commerce multiplatform yang terdiri dari Customer App, Courier App, dan Admin Panel. Setiap fitur diimplementasikan berdasarkan kebutuhan fungsional yang telah didefinisikan sebelumnya, dengan tujuan menghasilkan sistem yang dapat berjalan secara terintegrasi dan optimal.

---

## 5.1 Integrasi API Eksternal

Subbab ini menjelaskan implementasi integrasi API eksternal yang digunakan dalam aplikasi untuk mendukung berbagai fitur. Integrasi ini meliputi Midtrans untuk pembayaran, OpenStreetMap untuk peta, OpenRouteService untuk routing, dan WebSocket untuk komunikasi real-time.

### 5.1.1 Midtrans Payment

Integrasi Midtrans digunakan untuk memproses pembayaran non-tunai melalui berbagai metode pembayaran seperti QRIS, Virtual Account, dan E-Wallet. Integrasi terdiri dari layanan backend yang berkomunikasi dengan Midtrans API dalam mode sandbox, yang memungkinkan simulasi proses pembayaran secara lengkap tanpa melibatkan transaksi keuangan nyata. Setelah pembayaran berhasil dikonfirmasi melalui webhook sandbox, sistem secara otomatis memperbarui status pesanan dan memicu proses auto-dispatch untuk menugaskan kurir kepada pesanan tersebut.

**Segmen 5.1 — Inisialisasi Midtrans Client**

```
01: import { Injectable } from '@nestjs/common';
02: import { ConfigService } from '@nestjs/config';
03: import * as midtransClient from 'midtrans-client';
04:
05: @Injectable()
06: export class PaymentService {
07:   private snap: midtransClient.Snap;
08:   private core: midtransClient.CoreApi;
09:
10:   constructor(private configService: ConfigService) {
11:     const isProduction = this.configService.get('MIDTRANS_IS_PRODUCTION') === 'true';
12:
13:     const midtransConfig = {
14:       isProduction,
15:       serverKey: this.configService.get('MIDTRANS_SERVER_KEY'),
16:       clientKey: this.configService.get('MIDTRANS_CLIENT_KEY'),
17:     };
18:
19:     this.snap = new midtransClient.Snap(midtransConfig);
20:     this.core = new midtransClient.CoreApi(midtransConfig);
21:   }
22:
23:   async createSnapToken(orderId: string, amount: number, customerDetails: {
24:     name: string;
25:     email: string;
26:     phone: string;
27:   }): Promise<{ token: string; redirectUrl: string; transactionId: string }> {
28:     const orderIdStr = `ORDER-${orderId}-${Date.now()}`;
29:
30:     const grossAmount = Number(amount);
31:
32:     const parameter = {
33:       transaction_details: {
34:         order_id: orderIdStr,
35:         gross_amount: grossAmount,
36:       },
37:       customer_details: {
38:         customer_name: customerDetails.name,
39:         customer_email: customerDetails.email,
40:         customer_phone: customerDetails.phone,
41:       },
42:     };
43:
44:     const token = await this.snap.createTransactionToken(parameter);
45:     const redirectUrl = await this.snap.createTransactionRedirectUrl(parameter);
46:
47:     return {
48:       token,
49:       redirectUrl,
50:       transactionId: orderIdStr,
51:     };
52:   }
53: }
```

Segmen Program 5.1 merupakan implementasi layanan backend untuk integrasi payment gateway Midtrans. Pada baris 1 sampai dengan baris 3 dilakukan import modul-modul yang diperlukan, yaitu decorator Injectable dari NestJS, ConfigService untuk membaca konfigurasi environment, dan library midtrans-client untuk berkomunikasi dengan Midtrans API. Baris 5 sampai dengan baris 21 mendefinisikan kelas PaymentService yang di-inject sebagai service NestJS. Pada constructor di baris 10, dilakukan inisialisasi konfigurasi Midtrans dengan membaca environment variable MIDTRANS_IS_PRODUCTION, MIDTRANS_SERVER_KEY, dan MIDTRANS_CLIENT_KEY (baris 11-17), kemudian dibuat instance Snap dan CoreApi (baris 19-20). Baris 23 sampai dengan baris 52 mendefinisikan fungsi createSnapToken yang menerima orderId, jumlah pembayaran amount, dan detail customer. Fungsi ini membuat parameter transaksi (baris 32-42) yang berisi order_id dengan format yang telah disusun (baris 28), gross_amount sebagai jumlah pembayaran, serta customer_details yang berisi nama, email, dan telepon customer. Pada baris 44-45 dilakukan pemanggilan API Midtrans untuk membuat snap token dan redirect URL, kemudian dikembalikan sebagai return value fungsi (baris 47-51).

**Segmen 5.2 — Handler Notifikasi Pembayaran**

```
01: async handleNotification(payload: {
02:   order_id: string;
03:   transaction_id: string;
04:   transaction_status: string;
05:   status_code: string;
06:   gross_amount: string;
07:   signature_key?: string;
08: }): Promise<{
09:   orderId: string;
10:   status: string;
11:   transactionId: string;
12:   amount: number;
13: }> {
14:   const status = this.mapTransactionStatus(payload.transaction_status);
15:
16:   return {
17:     orderId: payload.order_id,
18:     status,
19:     transactionId: payload.transaction_id,
20:     amount: parseFloat(payload.gross_amount),
21:   };
22: }
23:
24: private mapTransactionStatus(status: string): string {
25:   const statusMap: Record<string, string> = {
26:     'capture': 'paid',
27:     'settlement': 'paid',
28:     'pending': 'pending',
29:     'deny': 'failed',
30:     'cancel': 'failed',
31:     'expire': 'failed',
32:     'refund': 'refunded',
33:     'partial_refund': 'refunded',
34:     'challenge': 'challenge',
35:   };
36:
37:   return statusMap[status] || status;
38: }
```

Segmen Program 5.2 merupakan implementasi handler notifikasi pembayaran dari Midtrans. Baris 1 sampai dengan baris 22 mendefinisikan fungsi handleNotification yang menerima payload notifikasi dari Midtrans berisi order_id, transaction_id, transaction_status, status_code, gross_amount, dan signature_key. Fungsi ini memetakan status transaksi dari Midtrans ke status internal sistem menggunakan fungsi mapTransactionStatus (baris 14), kemudian mengembalikan objek berisi orderId, status, transactionId, dan amount. Baris 24 sampai dengan baris 38 mendefinisikan fungsi mapTransactionStatus yang melakukan pemetaan status transaksi dari Midtrans ke status internal. Status capture dan settlement dipetakan ke 'paid' (pembayaran berhasil), pending tetap 'pending' (menunggu pembayaran), deny, cancel, dan expire dipetakan ke 'failed' (pembayaran gagal), refund dan partial_refund dipetakan ke 'refunded' (dana dikembalikan), dan challenge tetap 'challenge' (perlu verifikasi lanjutan). Jika status tidak ditemukan dalam mapping, maka status asli dikembalikan (baris 37).

### 5.1.2 OpenStreetMap

OpenStreetMap digunakan untuk menampilkan peta interaktif pada Admin Panel dan Courier App sebagai dasar visualisasi lokasi dan rute pengiriman. Integrasi menggunakan library Leaflet yang memungkinkan penambahan marker, polyline rute, serta fitur zoom dan pan secara interaktif di atas layer peta OpenStreetMap. Pemilihan OpenStreetMap sebagai penyedia peta didasarkan pada sifatnya yang open-source dan tidak memerlukan biaya penggunaan, sehingga cocok digunakan dalam pengembangan sistem ini.

**Segmen 5.3 — Konfigurasi Leaflet Map**

```
01: import L from 'leaflet';
02:
03: export function initMap(elementId, lat, lng, zoom = 13) {
04:   const map = L.map(elementId).setView([lat, lng], zoom);
05:
06:   L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
07:     attribution: '&copy; OpenStreetMap contributors'
08:   }).addTo(map);
09:
10:   return map;
11: }
12:
13: export function addMarker(map, lat, lng, popupText) {
14:   return L.marker([lat, lng]).addTo(map).bindPopup(popupText);
15: }
```

Segmen Program 5.3 merupakan implementasi fungsi-fungsi helper untuk inisialisasi dan konfigurasi peta menggunakan library Leaflet dengan OpenStreetMap sebagai tile provider. Baris 1 melakukan import library Leaflet. Baris 3 sampai dengan baris 11 mendefinisikan fungsi initMap yang menerima parameter elementId (ID elemen HTML untuk menempatkan peta), lat dan lng (koordinat center peta), serta zoom level (default 13). Pada baris 4 dilakukan inisialisasi objek peta dengan koordinat center dan zoom level. Baris 6 sampai dengan baris 8 menambahkan tile layer dari OpenStreetMap dengan format URL standard dan atribusi yang sesuai. Fungsi mengembalikan objek map yang telah dikonfigurasi. Baris 13 sampai dengan baris 15 mendefinisikan fungsi addMarker yang menerima objek map, koordinat lat dan lng, serta teks popup. Fungsi ini membuat marker pada posisi yang menentukan dan mengikat popup text yang akan ditampilkan saat marker diklik.

### 5.1.3 OpenRouteService

OpenRouteService digunakan untuk menghitung rute dan jarak antara lokasi toko dan tujuan pengiriman. API ini dipanggil secara otomatis setiap kali driver memulai proses pengiriman, menghasilkan data berupa polyline rute yang kemudian divisualisasikan di atas peta pada Driver App. Selain rute, OpenRouteService juga mengembalikan estimasi waktu tempuh yang ditampilkan kepada driver sebagai acuan dalam menyelesaikan pengiriman.

**Segmen 5.4 — Hitung Rute**

```
01: import { getRouteOSRM } from './osrm.util.js';
02:
03: export interface RouteResult {
04:   routeToStore: string | null;
05:   routeToDestination: string | null;
06: }
07:
08: export async function getRoute(
09:   source: [number, number],
10:   destination: [number, number],
11: ): Promise<string | null> {
12:   return getRouteOSRM(source, destination);
13: }
14:
15: export async function getRouteWithORSAndFallback(
16:   source: [number, number],
17:   destination: [number, number],
18: ): Promise<string | null> {
19:   const MIN_POLYLINE_LENGTH = 10;
20:
21:   let result = await getRouteOSRM(source, destination);
22:
23:   if (!result || result.length < MIN_POLYLINE_LENGTH) {
24:     console.log(
25:       `[Routing] OSRM returned invalid/short polyline (length: ${result?.length ?? 0}), retrying...`,
26:     );
27:     result = await getRouteOSRM(source, destination);
28:     if (result && result.length >= MIN_POLYLINE_LENGTH) {
29:       console.log('[Routing] OSRM retry succeeded, length:', result.length);
30:     } else {
31:       console.error('[Routing] OSRM failed after retry. source:', source, 'dest:', destination);
32:       result = null;
33:     }
34:   } else {
35:     console.log('[Routing] OSRM succeeded, polyline length:', result.length);
36:   }
37:
38:   return result;
39: }
```

Segmen Program 5.4 merupakan implementasi layanan routing untuk menghitung rute antara dua titik koordinat. Baris 1 melakukan import fungsi getRouteOSRM dari modul utilitas OSRM. Baris 3 sampai dengan baris 6 mendefinisikan interface RouteResult yang menyimpan encoded polyline untuk rute ke toko dan ke tujuan. Baris 8 sampai dengan baris 13 mendefinisikan fungsi getRoute sebagai wrapper yang memanggil fungsi getRouteOSRM secara langsung. Baris 15 sampai dengan baris 39 mendefinisikan fungsi getRouteWithORSAndFallback yang merupakan implementasi utama dengan mekanisme retry. Fungsi ini menerima source dan destination sebagai array koordinat [latitude, longitude]. Pada baris 19 didefinisikan MIN_POLYLINE_LENGTH = 10 sebagai threshold minimum panjang polyline yang valid. Baris 21 melakukan pemanggilan getRouteOSRM pertama. Jika hasil null atau panjang polyline kurang dari minimum (baris 23), maka dilakukan retry satu kali (baris 27). Jika retry berhasil dan polyline valid, log sukses dicetak (baris 28-29). Jika tetap gagal, result di-set null dan error dicetak (baris 30-32). Jika hasil pertama sudah valid, log sukses dicetak (baris 34-36). Fungsi mengembalikan encoded polyline rute atau null jika gagal.

### 5.1.4 WebSocket

WebSocket digunakan untuk komunikasi real-time antara server dan klien untuk driver location updates dan order notifications. Koneksi WebSocket diinisialisasi secara otomatis ketika driver maupun customer membuka aplikasi, memastikan setiap perubahan data dapat langsung diterima tanpa perlu melakukan request berulang ke server. Dengan memanfaatkan mekanisme room berbasis ID pesanan, setiap event yang dipancarkan server hanya diterima oleh pengguna yang terkait dengan pesanan tersebut.

**Segmen 5.5 — Driver Location Gateway**

```
01: import {
02:   WebSocketGateway,
03:   WebSocketServer,
04:   SubscribeMessage,
05:   OnGatewayConnection,
06:   OnGatewayDisconnect,
07:   MessageBody,
08:   ConnectedSocket,
09: } from '@nestjs/websockets';
10: import { Server, Socket } from 'socket.io';
11: import { DriversService } from '../drivers/drivers.service.js';
12:
13: @WebSocketGateway({
14:   cors: {
15:     origin: '*',
16:     methods: ['GET', 'POST'],
17:   },
18:   namespace: '/driver-location',
19: })
20: export class DriverLocationGateway implements OnGatewayConnection, OnGatewayDisconnect {
21:   @WebSocketServer()
22:   server: Server;
23:
24:   constructor(private readonly driversService: DriversService) {}
25:
26:   handleConnection(client: Socket) {
27:     console.log(`[WebSocket] Client connected: ${client.id}`);
28:   }
29:
30:   handleDisconnect(client: Socket) {
31:     console.log(`[WebSocket] Client disconnected: ${client.id}`);
32:   }
33:
34:   @SubscribeMessage('register_driver')
35:   handleRegisterDriver(
36:     @ConnectedSocket() client: Socket,
37:     @MessageBody() data: { driverId: number },
38:   ) {
39:     client.join(`driver_${data.driverId}`);
40:     console.log(`[WebSocket] Driver ${data.driverId} registered for location updates`);
41:     return { event: 'registered', driverId: data.driverId };
42:   }
43:
44:   @SubscribeMessage('driver_location_update')
45:   async handleLocationUpdate(
46:     @ConnectedSocket() client: Socket,
47:     @MessageBody() data: { driverId: number; lat: number; lng: number; orderId?: number },
48:   ) {
49:     try {
50:       await this.driversService.updateLocation(data.driverId, data.lat, data.lng);
51:
52:       this.server.to('admin_room').emit('driver_location_changed', {
53:         driverId: data.driverId,
54:         lat: data.lat,
55:         lng: data.lng,
56:         timestamp: new Date().toISOString(),
57:       });
58:
59:       return { success: true };
60:     } catch (error) {
61:       console.error('[WebSocket] handleLocationUpdate error:', error);
62:       return { success: false, error: error.message };
63:     }
64:   }
65:
66:   @SubscribeMessage('admin_subscribe')
67:   handleAdminSubscribe(@ConnectedSocket() client: Socket) {
68:     client.join('admin_room');
69:     console.log('[WebSocket] Admin subscribed to driver location updates');
70:     return { event: 'subscribed', room: 'admin_room' };
71:   }
```

Segmen Program 5.5 merupakan implementasi WebSocket Gateway untuk komunikasi real-time menggunakan Socket.IO dengan namespace '/driver-location'. Baris 1 sampai dengan baris 11 melakukan import decorator dari @nestjs/websockets, Server dan Socket dari socket.io, serta DriversService. Baris 13 sampai dengan baris 19 mendefinisikan decorator @WebSocketGateway dengan konfigurasi CORS yang mengizinkan semua origin dan namespace '/driver-location'. Baris 20 mendefinisikan kelas DriverLocationGateway yang implements OnGatewayConnection dan OnGatewayDisconnect untuk menangani event koneksi dan disconnect. Baris 26 sampai dengan baris 32 merupakan implementasi handler koneksi dan disconnect yang hanya melakukan logging. Baris 35 sampai dengan baris 43 mendefinisikan handler register_driver yang menerima driverId dan menambahkan client ke room driver_${driverId}. Baris 45 sampai dengan baris 64 mendefinisikan handler driver_location_update yang menerima update lokasi dari driver, menyimpan ke database via driversService.updateLocation (baris 50), kemudian emit event driver_location_changed ke admin_room (baris 52-57) untuk memberikan notifikasi ke semua admin yang subscribe. Baris 66 sampai dengan baris 70 mendefinisikan handler admin_subscribe yang memungkinkan admin panel untuk subscribe ke room admin_room agar menerima update lokasi driver.

---

## 5.2 Fitur Authentication

Fitur authentication digunakan oleh customer dan courier untuk login ke dalam aplikasi masing-masing. Sistem menggunakan autentikasi berbasis username dan password yang diverifikasi melalui backend API, di mana setelah verifikasi berhasil server akan mengembalikan token yang digunakan untuk mengotorisasi setiap request selanjutnya. Token tersebut disimpan secara lokal pada perangkat pengguna dan disertakan pada setiap permintaan ke server, sehingga pengguna tidak perlu melakukan login ulang selama sesi masih berlaku.

**Segmen 5.6 — Driver Login Service**

```
01: async login(username: string, password: string): Promise<Driver | null> {
02:   return this.driverRepo.findOne({
03:     where: { username, password, isActive: true },
04:   });
05: }
```

Segmen Program 5.6 merupakan implementasi fungsi login untuk driver yang terdapat pada DriversService. Baris 1 mendefinisikan fungsi login yang menerima parameter username dan password. Baris 2 sampai dengan baris 4 melakukan query ke database menggunakan driverRepo.findOne dengan kondisi where yang mencocokkan username dan password yang diberikan serta kondisi isActive = true untuk memastikan driver dalam keadaan aktif. Fungsi mengembalikan objek Driver jika ditemukan atau null jika tidak ada yang cocok.

**Segmen 5.7 — Driver Login Endpoint**

```
01: @Post('login')
02: async login(@Body() dto: LoginDriverDto) {
03:   const driver = await this.driversService.login(dto.username, dto.password);
04:   if (!driver) {
05:     throw new UnauthorizedException('Username atau password salah');
06:   }
07:   return { id: driver.id, name: driver.name, username: driver.username };
08: }
```

Segmen Program 5.7 merupakan implementasi endpoint login pada DriversController. Baris 1 mendefinisikan decorator @Post('login') yang menandai fungsi ini sebagai endpoint POST /drivers/login. Baris 2 mendefinisikan fungsi login yang menerima DTO (Data Transfer Object) LoginDriverDto dari body request. Baris 3 memanggil driversService.login dengan username dan password dari DTO. Baris 4 sampai dengan baris 6 menangani kasus jika login gagal dengan melempar UnauthorizedException yang berisi pesan error. Baris 7 mengembalikan response sukses berisi id, name, dan username driver tanpa menyertakan password.

**Segmen 5.8 — Customer Login Service**

```
01: async login(dto: LoginCustomerDto): Promise<Customer> {
02:   return this.customerRepo.findOne({
03:     where: { username: dto.username, password: dto.password },
04:   });
05: }
```

Segmen Program 5.8 merupakan implementasi fungsi login untuk customer yang terdapat pada CustomersService. Baris 1 mendefinisikan fungsi login yang menerima parameter LoginCustomerDto. Baris 2 sampai dengan baris 4 melakukan query ke database menggunakan customerRepo.findOne dengan kondisi where yang mencocokkan username dan password yang diberikan. Fungsi mengembalikan objek Customer jika ditemukan.

**Segmen 5.9 — Customer Login Endpoint**

```
01: @Post('login')
02: async login(@Body() dto: LoginCustomerDto) {
03:   const customer = await this.customersService.login(dto);
04:   return {
05:     id: customer.id,
06:     name: customer.name,
07:     username: customer.username,
08:     phone: customer.phone,
09:   };
10: }
```

Segmen Program 5.9 merupakan implementasi endpoint login pada CustomersController. Baris 1 mendefinisikan decorator @Post('login') untuk endpoint POST /customers/login. Baris 2-3 memanggil customersService.login dengan DTO dari body request. Baris 4-9 mengembalikan response berisi id, name, username, dan phone customer tanpa password.

**Segmen 5.10 — Customer App Login**

```
01: Future<void> _login() async {
02:   final usernameOrPhone = _usernameOrPhoneController.text.trim();
03:   final password = _passwordController.text.trim();
04:
05:   if (usernameOrPhone.isEmpty || password.isEmpty) {
06:     setState(
07:       () => _error = 'Username/nomor telepon dan password harus diisi',
08:     );
09:     return;
10:   }
11:
12:   setState(() {
13:     _isLoading = true;
14:     _error = null;
15:   });
16:
17:   try {
18:     final customer = await ApiService.loginCustomer(
19:       usernameOrPhone: usernameOrPhone,
20:       password: password,
21:     );
22:     widget.onLogin(customer);
23:   } catch (e) {
24:     setState(() => _error = e.toString().replaceAll('Exception: ', ''));
25:   } finally {
26:     if (mounted) setState(() => _isLoading = false);
27:   }
28: }
```

Segmen Program 5.10 merupakan implementasi halaman login pada Customer App. Baris 1 sampai dengan baris 28 mendefinisikan fungsi _login yang dipanggil saat tombol login ditekan. Baris 2-3 melakukan trim pada input username dan password untuk menghapus whitespace berlebih. Baris 5-10 melakukan validasi bahwa kedua field tidak kosong, jika kosong maka menampilkan pesan error. Baris 12-15 meng-set state loading dan membersihkan error sebelumnya. Baris 17-22 memanggil ApiService.loginCustomer dengan parameter yang dimasukkan user, jika berhasil maka callback onLogin dipanggil dengan data customer. Baris 23-24 menangani error dengan menangkap exception dan menampilkan pesan error yang sudah dibersihkan. Baris 26 memastikan state di-reset saat widget masih ter-mount.

**Segmen 5.11 — Courier App Login**

```
01: Future<void> _login() async {
02:   final user = _usernameController.text.trim();
03:   final pass = _passwordController.text.trim();
04:
05:   if (user.isEmpty || pass.isEmpty) {
06:     setState(() => _error = 'Username dan password harus diisi');
07:     return;
08:   }
09:
10:   setState(() {
11:     _loading = true;
12:     _error = null;
13:   });
14:
15:   try {
16:     final response = await http
17:       .post(
18:         Uri.parse('$_baseUrl/drivers/login'),
19:         headers: {'Content-Type': 'application/json'},
20:         body: json.encode({'username': user, 'password': pass}),
21:       )
22:       .timeout(const Duration(seconds: 10));
23:
24:     if (response.statusCode == 201) {
25:       final data = json.decode(response.body);
26:       widget.onLogin(data['name'], data['id']);
27:     } else {
28:       final errorData = json.decode(response.body);
29:       setState(() => _error = errorData['message'] ?? 'Login gagal');
30:     }
31:   } catch (e) {
32:     setState(
33:       () => _error = 'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
34:     );
35:   } finally {
36:     if (mounted) {
37:       setState(() => _loading = false);
38:     }
39:   }
40: }
```

Segmen Program 5.11 merupakan implementasi halaman login pada Courier App. Baris 1 sampai dengan baris 40 mendefinisikan fungsi _login yang dipanggil saat tombol login ditekan. Baris 2-3 mengambil nilai dari text controller dan melakukan trim. Baris 5-8 validasi input kosong. Baris 10-13 meng-set state loading. Baris 24-26 jika response status 201 (sukses), data customer di-decode dan callback onLogin dipanggil. Baris 27-29 jika gagal, error message dari response ditampilkan. Baris 31-34 menangkap exception network dan menampilkan pesan bahwa server tidak dapat dijangkau.

> **Gambar 5.1** — Tampilan Fitur Login

---

## 5.3 Fitur Katalog Produk

Fitur katalog produk digunakan oleh customer untuk melihat dan mencari produk yang tersedia di toko. Produk ditampilkan dalam bentuk grid dengan dilengkapi fitur pencarian untuk memudahkan customer menemukan produk yang diinginkan. Setiap kartu produk menampilkan informasi utama seperti gambar, nama, harga, dan status stok sehingga customer dapat membuat keputusan pembelian dengan cepat.

**Segmen 5.12 — Create Product**

```
01: async create(dto: CreateProductDto): Promise<Product> {
02:   const existing = await this.productRepo.findOne({ where: { name: dto.name }, relations: ['variants'] });
03:   if (existing) {
04:     const existingVariant = existing.variants?.find((v) => v.unitName.toLowerCase() === (dto.unit ?? 'Piece').toLowerCase());
05:     if (existingVariant) {
06:       existingVariant.price = dto.price;
07:       await this.variantRepo.save(existingVariant);
08:       existing.stock = (existing.stock ?? 0) + (dto.stock ?? 0);
09:       return this.productRepo.save(existing);
10:     } else {
11:       const newVariant = this.variantRepo.create({ unitName: dto.unit ?? 'Piece', price: dto.price, product: existing });
12:       await this.variantRepo.save(newVariant);
13:       existing.stock = (existing.stock ?? 0) + (dto.stock ?? 0);
14:       existing.variants.push(newVariant);
15:       return this.productRepo.save(existing);
16:     }
17:   } else {
18:     const product = this.productRepo.create({
19:       name: dto.name, description: dto.description ?? '', price: dto.price, imageUrl: dto.imageUrl ?? '',
20:       category: dto.category ?? '', rating: dto.rating ?? 0, sold: dto.sold ?? 0, seller: dto.seller ?? '',
21:       sellerCity: dto.sellerCity ?? '', stock: dto.stock ?? 0, unit: dto.unit ?? 'Piece',
22:       variants: [this.variantRepo.create({ unitName: dto.unit ?? 'Piece', price: dto.price })],
23:     });
24:     return this.productRepo.save(product);
25:   }
26: }
```

Segmen Program 5.12 merupakan implementasi fungsi create pada ProductsService untuk menambah produk baru atau menambahkan variant ke produk yang sudah ada. Baris 2 melakukan pencarian produk dengan nama yang sama. Baris 3-16 menangani kasus produk sudah ada. Baris 4 mencari variant dengan unitName yang sama, jika ditemukan maka harga diupdate dan stok ditambahkan (baris 5-9). Jika variant baru, maka variant baru ditambahkan ke produk (baris 10-16). Baris 17-25 menangani kasus produk baru dengan membuat objek produk lengkap beserta variant initial-nya.

**Segmen 5.13 — Catalog Home Page**

```
01: List<Product> get filteredProducts {
02:   var products = _products;
03:
04:   if (_selectedCategory != 'All') {
05:     products = products
06:       .where((p) => p.category == _selectedCategory)
07:       .toList();
08:   }
09:
10:   if (_searchQuery.isNotEmpty) {
11:     products = products
12:       .where(
13:         (p) =>
14:             p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
15:             p.category.toLowerCase().contains(_searchQuery.toLowerCase()),
16:       )
17:       .toList();
18:   }
19:
20:   return products;
21: }
```

Segmen Program 5.13 merupakan implementasi getter filteredProducts pada CatalogHomePage yang digunakan untuk memfilter daftar produk berdasarkan kategori dan kata kunci pencarian. Baris 1 mendefinisikan getter yang mengembalikan List. Baris 2 menyimpan reference ke list produk original. Baris 4-8 memfilter produk berdasarkan kategori yang dipilih, jika bukan 'All' maka hanya produk dengan category yang cocok yang dikembalikan. Baris 10-18 memfilter berdasarkan search query dengan mencari kecocokan pada nama produk atau kategori (case-insensitive menggunakan toLowerCase). Baris 20 mengembalikan list produk yang sudah difilter.

**Segmen 5.14 — Load Products**

```
01: Future<void> _loadProducts() async {
02:   try {
03:     final data = await ApiService.fetchProducts();
04:     if (mounted) {
05:       setState(() {
06:         _products = data.map((json) => Product.fromJson(json)).toList();
07:         _isLoading = false;
08:         _isUsingDemoData = false;
09:       });
10:       if (_customer != null) {
11:         await _cart.loadCart(_customer!['id'], _products);
12:       }
13:     }
14:   } catch (e) {
15:     print('[CatalogHomePage] Failed to load products from API: $e');
16:     print('[CatalogHomePage] Falling back to demo data');
17:     if (mounted) {
18:       setState(() {
19:         _products = demoProducts;
20:         _isLoading = false;
21:         _isUsingDemoData = true;
22:       });
23:     }
24:   }
25: }
```

Segmen Program 5.14 merupakan implementasi fungsi _loadProducts yang memuat daftar produk dari API backend. Baris 2-3 melakukan fetch produk dari ApiService.fetchProducts(). Baris 4-13 jika mounted, update state dengan data produk yang sudah di-parse dari JSON, set loading flag ke false, dan jika customer sudah login maka load juga data cart. Baris 14-24 menangani kasus error dengan fallback ke demo data lokal sehingga aplikasi tetap bisa digunakan meskipun backend tidak tersedia.

**Segmen 5.15 — Detail Produk**

```
01: class ProductVariant {
02:   final String unitName;
03:   final double price;
04:
05:   const ProductVariant({required this.unitName, required this.price});
06:
07:   factory ProductVariant.fromJson(Map<String, dynamic> json) {
08:     return ProductVariant(
09:       unitName: json['unitName'] ?? '',
10:       price: (json['price'] is num)
11:           ? json['price'].toDouble()
12:           : double.tryParse(json['price'].toString()) ?? 0,
13:     );
14:   }
15: }
16:
17: class Product {
18:   final List<ProductVariant>? variants;
19:   bool get hasVariants => variants != null && variants!.isNotEmpty;
20: }
```

Segmen Program 5.15 merupakan implementasi model data untuk produk dan variant. Baris 1-15 mendefinisikan kelas ProductVariant yang menyimpan unitName (satuan seperti KG, Sack 25KG, Sack 50KG) dan price untuk setiap variant. Baris 17-20 mendefinisikan kelas Product yang memiliki array variants dan getter hasVariants untuk cek apakah produk memiliki variant.

**Segmen 5.16 — Add to Cart**

```
01: void _showQuantitySelector(BuildContext context) {
02:   int quantity = 1;
03:   ProductVariant? selectedVariant = product.hasVariants
04:       ? product.variants!.first
05:       : null;
06:
07:   showModalBottomSheet(
08:     context: context,
09:     builder: (ctx) {
10:       return StatefulBuilder(
11:         builder: (context, setModalState) {
12:           return Container(
13:             padding: const EdgeInsets.all(24),
14:             // Variant Selection
15:             if (product.hasVariants) ...[
16:               Align(
17:                 alignment: Alignment.centerLeft,
18:                 child: Text('Pilih Ukuran/Satuan:', ...),
19:               ),
20:               Wrap(
21:                 spacing: 8,
22:                 children: product.variants!.map((variant) {
23:                   final isSelected = selectedVariant == variant;
24:                   return ChoiceChip(
25:                     label: Text('${variant.unitName} - ${variant.formattedPrice}'),
26:                     selected: isSelected,
27:                     onSelected: (selected) {
28:                       if (selected) {
29:                         setModalState(() { selectedVariant = variant; });
30:                       }
31:                     },
32:                   );
33:                 }).toList(),
34:               ),
35:             ],
36:             // Quantity Selector
37:             Row(
38:               children: [
39:                 Text('Jumlah:'),
40:                 IconButton(
41:                   onPressed: () {
42:                     if (quantity > 1) setModalState(() { quantity--; });
43:                   },
44:                 ),
45:                 Text('$quantity'),
46:                 IconButton(
47:                   onPressed: () {
48:                     if (quantity < product.stock) setModalState(() { quantity++; });
49:                   },
50:                 ),
51:              ],
52:            ),
53:            // Add to Cart Button
54:            ElevatedButton.icon(
55:              onPressed: product.stock <= 0 ? null : () {
56:                for (int i = 0; i < quantity; i++) {
57:                  cart.addToCart(product, selectedUnit: selectedVariant?.unitName, unitPrice: selectedVariant?.price);
58:                }
59:                Navigator.pop(ctx);
60:              },
61:            ),
62:          );
63:        },
64:      );
65:    },
66:   );
67: }
```

Segmen Program 5.16 merupakan implementasi fungsi _showQuantitySelector pada halaman detail produk. Baris 3-5 inisialisasi variant pertama yang terpilih. Baris 7-66 membuat modal bottom sheet untuk memilih variant dan jumlah. Baris 15-35 menampilkan daftar variant menggunakan ChoiceChip, setiap variant menampilkan nama satuan dan harga formatted. Baris 36-52 menampilkan quantity selector dengan tombol tambah dan kurang. Baris 54-61 tombol "Tambah ke Keranjang" yang memanggil cart.addToCart dengan parameter selectedUnit dan unitPrice dari variant yang dipilih. Setiap iteration pada baris 56-58 menambahkan satu item ke keranjang sesuai quantity yang dipilih.

> **Gambar 5.2** — Tampilan Fitur Katalog Produk

> **Gambar 5.3** — Tampilan Fitur Detail Produk

---

## 5.4 Fitur Keranjang Belanja

Fitur keranjang belanja digunakan oleh customer untuk mengelola produk yang akan dibeli sebelum melanjutkan ke proses checkout. Customer dapat menambahkan produk dari halaman katalog, mengubah jumlah item, atau menghapus item yang tidak diinginkan langsung dari halaman keranjang. Sistem secara otomatis menghitung dan memperbarui subtotal setiap kali terjadi perubahan jumlah atau penghapusan item, sehingga customer selalu mendapatkan informasi total harga yang akurat secara real-time.

**Segmen 5.17 — Cart Entity**

```
01: @Entity('carts')
02: export class Cart {
03:   @PrimaryGeneratedColumn()
04:   id: number;
05:
06:   @Column({ name: 'customer_id' })
07:   customerId: number;
08:
09:   @Column({ name: 'product_id' })
10:   productId: number;
11:
12:   @Column({ name: 'product_name' })
13:   productName: string;
14:
15:   @Column()
16:   quantity: number;
17:
18:   @Column({ name: 'unit_name' })
19:   unitName: string;
20:
21:   @Column({ name: 'unit_price', type: 'decimal' })
22:   unitPrice: number;
23:
24:   @Column({ type: 'decimal' })
25:   subtotal: number;
26:
27:   @CreateDateColumn()
28:   createdAt: Date;
29:
30:   @UpdateDateColumn()
31:   updatedAt: Date;
32: }
```

Segmen Program 5.17 merupakan definisi entity Cart untuk database. Baris 1 mendefinisikan decorator Entity dengan nama tabel carts. Baris 3-4 kolom id sebagai primary key dengan auto increment. Baris 6-7 kolom customerId untuk relasi dengan customer. Baris 9-13 kolom productId dan productName untuk menyimpan info produk. Baris 15-25 kolom quantity, unitName, unitPrice, dan subtotal untuk menghitung total per item. Baris 27-31 kolom timestamps untuk tracking kapan cart dibuat dan diupdate.

**Segmen 5.18 — Add to Cart**

```
01: async addToCart(dto: AddToCartDto): Promise<Cart> {
02:   const cartItem = this.cartRepo.create({
03:     customerId: dto.customerId,
04:     productId: dto.productId,
05:     productName: dto.productName,
06:     quantity: dto.quantity,
07:     unitName: dto.unitName,
08:     unitPrice: dto.unitPrice,
09:     subtotal: dto.quantity * dto.unitPrice,
10:   });
11:   return this.cartRepo.save(cartItem);
12: }
```

Segmen Program 5.18 merupakan implementasi fungsi addToCart pada service untuk menambahkan item ke keranjang. Baris 2-10 membuat objek cartItem dengan data dari DTO yang berisi customerId, productId, productName, quantity, unitName, dan unitPrice. Baris 9 menghitung subtotal dengan mengalikan quantity dan unitPrice. Baris 11 menyimpan ke database dan mengembalikan objek cart yang baru dibuat.

**Segmen 5.19 — Get Cart**

```
01: async getCart(customerId: number): Promise<Cart[]> {
02:   return this.cartRepo.find({
03:     where: { customerId },
04:     order: { createdAt: 'DESC' },
05:   });
06: }
```

Segmen Program 5.19 merupakan implementasi fungsi getCart untuk mendapatkan semua item di keranjang customer. Baris 2-5 query database dengan filter customerId dan diurutkan berdasarkan createdAt descending sehingga item terbaru muncul pertama.

**Segmen 5.20 — Update Cart Item**

```
01: async updateCartItem(id: number, quantity: number): Promise<Cart | null> {
02:   const cartItem = await this.cartRepo.findOne({ where: { id } });
03:   if (!cartItem) return null;
04:   cartItem.quantity = quantity;
05:   cartItem.subtotal = quantity * cartItem.unitPrice;
06:   return this.cartRepo.save(cartItem);
07: }
```

Segmen Program 5.20 merupakan implementasi fungsi updateCartItem untuk mengubah jumlah item di keranjang. Baris 2 mencari cart item berdasarkan id. Baris 3-4 jika tidak ditemukan return null, jika ditemukan update quantity dan recalculate subtotal. Baris 6 menyimpan perubahan dan mengembalikan item yang sudah diupdate.

**Segmen 5.21 — Remove Cart Item**

```
01: async removeCartItem(id: number): Promise<boolean> {
02:   const result = await this.cartRepo.delete(id);
03:   return (result.affected ?? 0) > 0;
04: }
```

Segmen Program 5.21 merupakan implementasi fungsi removeCartItem untuk menghapus item dari keranjang. Baris 2-3 melakukan delete berdasarkan id dan mengembalikan true jika ada row yang terpengaruh.

**Segmen 5.22 — Clear Cart**

```
01: async clearCart(customerId: number): Promise<void> {
02:   await this.cartRepo.delete({ customerId });
03: }
```

Segmen Program 5.22 merupakan implementasi fungsi clearCart untuk mengosongkan seluruh keranjang customer. Baris 2 menghapus semua cart item yang memiliki customerId tertentu.

**Segmen 5.23 — Cart Page**

```
01: class CartPage extends StatefulWidget {
02:   @override
03:   State<CartPage> createState() => _CartPageState();
04: }
05:
06: class _CartPageState extends State<CartPage> {
07:   List<CartItem> _items = [];
08:   bool _isLoading = true;
09:
10:   Future<void> _loadCart() async {
11:     final items = await ApiService.getCart(widget.customerId);
12:     if (mounted) {
13:       setState(() {
14:         _items = items;
15:         _isLoading = false;
16:       });
17:     }
18:   }
19:
20:   double get _totalPrice =>
21:       _items.fold(0, (sum, item) => sum + item.subtotal);
22:
23:   Future<void> _updateQuantity(int index, int newQty) async {
24:     if (newQty <= 0) {
25:       await ApiService.removeCartItem(_items[index].id);
26:     } else {
27:       await ApiService.updateCartItem(_items[index].id, newQty);
28:     }
29:     await _loadCart();
30:   }
31:
32:   Future<void> _removeItem(int index) async {
33:     await ApiService.removeCartItem(_items[index].id);
34:     await _loadCart();
35:   }
36:
37:   void _proceedToCheckout() {
38:     Navigator.push(
39:       context,
40:       MaterialPageRoute(
41:         builder: (_) => CheckoutPage(
42:           cart: _items,
43:           total: _totalPrice,
44:         ),
45:      ),
46:    );
47:  }
48: }
```

Segmen Program 5.23 merupakan implementasi halaman keranjang belanja pada Customer App. Baris 1-6 mendefinisikan StatefulWidget untuk cart page. Baris 10-18 fungsi _loadCart yang memanggil ApiService.getCart dan update state dengan data yang diterima. Baris 20-21 getter _totalPrice menggunakan fold untuk menghitung total harga dari semua item. Baris 23-30 fungsi _updateQuantity untuk mengupdate jumlah item, jika newQty <= 0 maka hapus item, jika tidak maka update via API. Baris 32-35 fungsi _removeItem untuk menghapus item dari keranjang. Baris 37-47 fungsi _proceedToCheckout untuk navigasi ke halaman checkout dengan membawa data cart dan total harga.

> **Gambar 5.4** — Tampilan Fitur Keranjang Belanja

---

## 5.5 Fitur Checkout

Fitur checkout digunakan oleh customer untuk menyelesaikan pembelian setelah memilih produk yang diinginkan. Customer dapat menentukan alamat pengiriman menggunakan fitur pencarian alamat berbasis Nominatim, memilih slot waktu pengiriman yang tersedia, serta meninjau ringkasan pesanan sebelum melanjutkan ke tahap pembayaran. Setelah semua informasi dikonfirmasi, customer diarahkan ke halaman pembayaran untuk menyelesaikan transaksi melalui metode yang tersedia.

**Segmen 5.24 — Create Order**

```
01: async create(dto: CreateOrderDto): Promise<Order> {
02:   const isMidtrans = dto.paymentMethod === 'Midtrans' || dto.paymentMethod === 'midtrans';
03:   const initialStatus = isMidtrans ? OrderStatus.PENDING_PAYMENT : OrderStatus.PENDING;
04:
05:   if (!isMidtrans) {
06:     for (const item of dto.items) {
07:       const product = await this.productRepo.findOne({ where: { name: item.productName } });
08:       if (!product) {
09:         throw new Error(`Produk "${item.productName}" tidak ditemukan`);
10:       }
11:       const requestedQty = item.quantity ?? 1;
12:       if (product.stock < requestedQty) {
13:         throw new Error(`Stok tidak cukup untuk "${item.productName}". Tersedia: ${product.stock}, diminta: ${requestedQty}`);
14:       }
15:     }
16:   }
17:
18:   const order = this.orderRepo.create({
19:     customerId: dto.customerId ?? null,
20:     customerName: dto.customerName,
21:     customerPhone: dto.customerPhone ?? '',
22:     pickupAddress: dto.pickupAddress ?? 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
23:     deliveryAddress: dto.deliveryAddress ?? '',
24:     totalAmount: dto.totalAmount,
25:     paymentMethod: dto.paymentMethod ?? '',
26:     status: initialStatus,
27:     items: dto.items.map((i) => {
28:       const quantity = i.quantity ?? 1;
29:       const subtotal = i.unitPrice * quantity;
30:       return this.itemRepo.create({ productName: i.productName, unitName: i.unitName ?? '', unitPrice: i.unitPrice, quantity, subtotal });
31:     }),
32:   });
33:   const savedOrder = await this.orderRepo.save(order);
34: }
```

Segmen Program 5.24 merupakan implementasi fungsi create order pada OrdersService. Baris 2-3 menentukan apakah metode pembayaran menggunakan Midtrans, yang akan menentukan status awal pesanan. Baris 5-16 validasi stok untuk semua item untuk memastikan produk ada dan stok mencukupi. Baris 18-33 membuat objek order dengan data dari DTO termasuk customer info, alamat pickup dan delivery, total amount, payment method, dan daftar item pesanan. Setiap item di-map menjadi objek order item dengan perhitungan subtotal.

**Segmen 5.25 — Address Search with Nominatim**

```
01: Future<void> _searchAddress(String query) async {
02:   if (query.trim().isEmpty) {
03:     setState(() => _suggestions = []);
04:     return;
05:   }
06:
07:   setState(() => _isSearching = true);
08:
09:   final results = await _nominatimService.searchAddress(query);
10:
11:   if (mounted) {
12:     setState(() {
13:       _suggestions = results;
14:       _isSearching = false;
15:     });
16:   }
17: }
18:
19: void _onSuggestionSelected(NominatimPlace place) {
20:   _searchController.text = place.displayName;
21:   _addressController.text = place.displayName;
22:   setState(() {
23:     _selectedLat = place.lat;
24:     _selectedLng = place.lon;
25:     _suggestions = [];
26:   });
27:   _mapController.move(LatLng(place.lat, place.lon), 16);
28: }
```

Segmen Program 5.25 merupakan implementasi pencarian alamat menggunakan Nominatim API dan penanganan pemilihan saran alamat. Baris 1-6 fungsi _searchAddress membersihkan suggestions jika query kosong. Baris 7 set state searching. Baris 9 memanggil Nominatim service untuk mencari alamat. Baris 11-16 update state dengan hasil pencarian. Baris 19-28 fungsi _onSuggestionSelected menangani ketika user memilih salah satu saran alamat, mengisi text field dengan alamat lengkap, menyimpan koordinat lat/lng yang dipilih, membersihkan daftar saran, dan memindahkan posisi peta ke lokasi yang dipilih dengan zoom level 16.

> **Gambar 5.5** — Tampilan Fitur Checkout

---

## 5.6 Fitur Manajemen Alamat

Fitur manajemen alamat digunakan oleh customer untuk mengelola alamat pengiriman mereka agar proses checkout dapat berlangsung lebih cepat. Customer dapat melihat dan memperbarui alamat default yang akan digunakan setiap kali checkout, dengan bantuan fitur pencarian alamat berbasis Nominatim yang memberikan saran alamat secara otomatis. Alamat yang telah disimpan akan otomatis terisi pada halaman checkout, sehingga customer tidak perlu memasukkan ulang informasi alamat di setiap transaksi.

**Segmen 5.26 — Update Address**

```
01: @Put('customers/:id/address')
02: async updateAddress(@Param('id') id: number, @Body() body: { address: string }) {
03:   const customer = await this.customerRepo.findOne({ where: { id } });
04:   if (!customer) {
05:     throw new NotFoundException('Customer not found');
06:   }
07:   customer.address = body.address;
08:   return this.customerRepo.save(customer);
09: }
```

Segmen Program 5.26 merupakan implementasi endpoint untuk memperbarui alamat customer. Baris 1 mendefinisikan decorator @Put untuk endpoint PUT /customers/:id/address. Baris 2-8 fungsi updateAddress yang menerima parameter id dari URL dan address dari body request. Baris 3-6 mencari customer berdasarkan id, jika tidak ditemukan lempar exception NotFoundException. Baris 7-8 update field address customer dan simpan ke database.

**Segmen 5.27 — Get Customer Address**

```
01: @Get('customers/:id')
02: async getCustomer(@Param('id') id: number) {
03:   const customer = await this.customerRepo.findOne({ where: { id } });
04:   if (!customer) {
05:     throw new NotFoundException('Customer not found');
06:   }
07:   return {
08:     id: customer.id,
09:     name: customer.name,
10:     address: customer.address,
11:     phone: customer.phone,
12:   };
13: }
```

Segmen Program 5.27 merupakan implementasi endpoint untuk mendapatkan data customer termasuk alamat. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /customers/:id. Baris 3-6 mencari customer berdasarkan id, jika tidak ditemukan lempar exception. Baris 7-13 mengembalikan objek yang hanya berisi field yang diperlukan (id, name, address, phone) tanpa password.

**Segmen 5.28 — Address Edit Page**

```
01: class AddressEditPage extends StatefulWidget {
02:   @override
03:   State<AddressEditPage> createState() => _AddressEditPageState();
04: }
05:
06: class _AddressEditPageState extends State<AddressEditPage> {
07:   final _addressController = TextEditingController();
08:   bool _isLoading = false;
09:   String? _error;
10:
11:   @override
12:   void initState() {
13:     super.initState();
14:     _addressController.text = widget.currentAddress;
15:   }
16:
17:   Future<void> _saveAddress() async {
18:     if (_addressController.text.trim().isEmpty) {
19:       setState(() => _error = 'Alamat tidak boleh kosong');
20:       return;
21:     }
22:
23:     setState(() {
24:       _isLoading = true;
25:       _error = null;
26:     });
27:
28:     try {
29:       await ApiService.updateCustomerAddress(
30:         customerId: widget.customerId,
31:         address: _addressController.text.trim(),
32:       );
33:
34:       if (mounted) {
35:         ScaffoldMessenger.of(context).showSnackBar(
36:           const SnackBar(content: Text('Alamat berhasil diperbarui')),
37:         );
38:         Navigator.pop(context, _addressController.text.trim());
39:       }
40:     } catch (e) {
41:       setState(() => _error = e.toString());
42:     } finally {
43:       if (mounted) {
44:         setState(() => _isLoading = false);
45:       }
46:     }
47:   }
48: }
```

Segmen Program 5.28 merupakan implementasi halaman edit alamat pada Customer App. Baris 1-4 mendefinisikan StatefulWidget untuk address edit page. Baris 7-9 deklarasi controller dan state untuk loading dan error. Baris 11-15 inisialisasi state dengan mengisi controller menggunakan alamat saat ini dari widget. Baris 17-47 fungsi _saveAddress yang memvalidasi input, memanggil ApiService.updateCustomerAddress, menampilkan SnackBar sukses, dan kembali ke halaman sebelumnya dengan data alamat baru. Baris 40-41 menangkap error dan menampilkan pesan error.

> **Gambar 5.6** — Tampilan Fitur Manajemen Alamat

---

## 5.7 Fitur Riwayat Pesanan

Fitur riwayat pesanan digunakan oleh customer untuk melihat daftar transaksi yang sudah pernah dilakukan sebelumnya. Setiap pesanan menampilkan informasi lengkap meliputi status, total amount, dan tanggal pemesanan, sehingga customer dapat dengan mudah memantau seluruh aktivitas transaksi mereka. Customer juga dapat membuka detail setiap pesanan untuk melihat informasi lebih lengkap seperti daftar item yang dibeli, alamat pengiriman, serta data kurir yang menangani pesanan tersebut.

**Segmen 5.29 — Get Orders By Customer**

```
01: @Get('orders/customer/:customerId')
02: async getOrdersByCustomer(@Param('customerId') customerId: number) {
03:   return this.orderRepo.find({
04:     where: { customerId },
05:     relations: ['items'],
06:     order: { createdAt: 'DESC' },
07:   });
08: }
```

Segmen Program 5.29 merupakan implementasi endpoint untuk mendapatkan semua pesanan customer. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /orders/customer/:customerId dengan parameter customerId dari URL. Baris 3-7 query database menggunakan orderRepo.find dengan filter customerId, include relasi items, dan diurutkan berdasarkan createdAt descending sehingga pesanan terbaru muncul pertama.

**Segmen 5.30 — Get Order Detail**

```
01: @Get('orders/:id')
02: async getOrderDetail(@Param('id') id: number) {
03:   const order = await this.orderRepo.findOne({
04:     where: { id },
05:     relations: ['items', 'driver'],
06:   });
07:   if (!order) {
08:     throw new NotFoundException('Order not found');
09:   }
10:   return order;
11: }
```

Segmen Program 5.30 merupakan implementasi endpoint untuk mendapatkan detail satu pesanan. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /orders/:id. Baris 3-6 query database dengan include relasi items dan driver. Baris 7-9 jika tidak ditemukan lempar exception NotFoundException. Baris 10 mengembalikan objek order lengkap dengan relasi.

**Segmen 5.31 — Order History Page**

```
01: class OrderHistoryPage extends StatefulWidget {
02:   @override
03:   State<OrderHistoryPage> createState() => _OrderHistoryPageState();
04: }
05:
06: class _OrderHistoryPageState extends State<OrderHistoryPage> {
07:   List<Order> _orders = [];
08:   bool _isLoading = true;
09:
10:   Future<void> _loadOrders() async {
11:     try {
12:       final orders = await ApiService.getCustomerOrders(widget.customerId);
13:       if (mounted) {
14:         setState(() {
15:           _orders = orders;
16:           _isLoading = false;
17:         });
18:       }
19:     } catch (e) {
20:       if (mounted) {
21:         setState(() {
22:           _isLoading = false;
23:         });
24:       }
25:     }
26:   }
27:
28:   @override
29:   void initState() {
30:     super.initState();
31:     _loadOrders();
32:   }
33:
34:   String _formatStatus(String status) {
35:     switch (status) {
36:       case 'pending':
37:         return 'Menunggu';
38:       case 'pickingUp':
39:         return 'Menjemput';
40:       case 'pickedUp':
41:         return 'Diambil';
42:       case 'delivering':
43:         return 'Mengirim';
44:       case 'delivered':
45:         return 'Selesai';
46:       default:
47:         return status;
48:     }
49:   }
50:
51:   String _formatDate(DateTime date) {
52:     return '${date.day}/${date.month}/${date.year}';
53:   }
54: }
```

Segmen Program 5.31 merupakan implementasi halaman riwayat pesanan pada Customer App. Baris 1-6 mendefinisikan StatefulWidget untuk order history page. Baris 10-26 fungsi _loadOrders yang memanggil ApiService.getCustomerOrders dan update state dengan data yang diterima. Baris 34-49 fungsi _formatStatus untuk mengkonversi kode status menjadi label teks yang mudah dipahami. Baris 51-53 fungsi _formatDate untuk memformat tanggal menjadi format dd/mm/yyyy.

**Segmen 5.32 — Order History List**

```
01: ListView.builder(
02:   itemCount: _orders.length,
03:   itemBuilder: (context, index) {
04:     final order = _orders[index];
05:     return Card(
06:       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
07:       child: InkWell(
08:         onTap: () {
09:           Navigator.push(
10:             context,
11:             MaterialPageRoute(
12:               builder: (_) => OrderDetailPage(orderId: order.id),
13:            ),
14:          );
15:        },
16:        child: Padding(
17:          padding: const EdgeInsets.all(16),
18:          child: Column(
19:            crossAxisAlignment: CrossAxisAlignment.start,
20:            children: [
21:              Row(
22:                mainAxisAlignment: MainAxisAlignment.spaceBetween,
23:                children: [
24:                  Text(
25:                    'Order #${order.id}',
26:                    style: const TextStyle(fontWeight: FontWeight.bold),
27:                  ),
28:                  Container(
29:                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
30:                    decoration: BoxDecoration(
31:                      color: _getStatusColor(order.status),
32:                      borderRadius: BorderRadius.circular(4),
33:                    ),
34:                    child: Text(
35:                      _formatStatus(order.status),
36:                      style: const TextStyle(color: Colors.white, fontSize: 12),
37:                    ),
38:                  ),
39:                ],
40:              ),
41:              const SizedBox(height: 8),
42:              Text(
43:                _formatDate(order.createdAt),
44:                style: TextStyle(color: Colors.grey[600]),
45:              ),
46:              const SizedBox(height: 4),
47:              Text(
48:                'Rp ${order.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
49:                style: const TextStyle(fontWeight: FontWeight.w600),
50:              ),
51:              const SizedBox(height: 8),
52:              Text(
53:                '${order.items.length} item',
54:                style: TextStyle(color: Colors.grey[600]),
55:              ),
56:            ],
57:          ),
58:        ),
59:      ),
60:    );
61:   },
62: );
```

Segmen Program 5.32 merupakan implementasi widget tampilan daftar riwayat pesanan. Baris 1 membuat ListView dengan jumlah item sesuai panjang _orders. Baris 4-60 membangun tampilan setiap card pesanan. Baris 8-14 navigasi ke halaman detail pesanan saat card diklik. Baris 21-40 menampilkan ID pesanan dan status dengan badge berwarna. Baris 42-44 menampilkan tanggal pesanan. Baris 46-49 menampilkan total amount dengan format mata uang Indonesia. Baris 51-54 menampilkan jumlah item dalam pesanan.

> **Gambar 5.7** — Tampilan Fitur Riwayat Pesanan

---

## 5.8 Fitur Auto-dispatch

Fitur auto-dispatch digunakan untuk secara otomatis menugaskan kurir terdekat kepada pesanan baru berdasarkan formula Haversine untuk menghitung jarak. Ketika pesanan baru masuk dan pembayaran telah dikonfirmasi, sistem akan mencari seluruh kurir yang sedang aktif dan menghitung jarak masing-masing kurir terhadap lokasi penjemputan pesanan secara real-time. Kurir dengan jarak terdekat kemudian secara otomatis ditugaskan untuk menangani pesanan tersebut, sehingga proses penugasan berlangsung efisien tanpa memerlukan intervensi manual dari admin.

**Segmen 5.33 — Haversine Distance Calculation**

```
01: export function toRadians(degrees: number): number {
02:   return degrees * (Math.PI / 180);
03: }
04:
05: export function haversineDistance(
06:   lat1: number,
07:   lng1: number,
08:   lat2: number,
09:   lng2: number,
10: ): number {
11:   const R = 6371;
12:   const dLat = toRadians(lat2 - lat1);
13:   const dLng = toRadians(lng2 - lng1);
14:
15:   const a =
16:     Math.sin(dLat / 2) * Math.sin(dLat / 2) +
17:     Math.cos(toRadians(lat1)) *
18:       Math.cos(toRadians(lat2)) *
19:       Math.sin(dLng / 2) *
20:       Math.sin(dLng / 2);
21:
22:   const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
23:
24:   return R * c;
25: }
```

Segmen Program 5.33 merupakan implementasi formula Haversine untuk menghitung jarak antara dua titik koordinat geografis di permukaan bumi. Baris 1-3 mendefinisikan fungsi toRadians yang mengonversi derajat ke radian. Baris 5-25 mendefinisikan fungsi haversineDistance yang menerima empat parameter yaitu lat1, lng1 (koordinat titik pertama) dan lat2, lng2 (koordinat titik kedua). Baris 11 mendefinisikan konstanta R = 6371 yang merupakan radius rata-rata bumi dalam kilometer. Baris 12-13 menghitung selisih latitude dan longitude dalam radian. Baris 15-20 menghitung nilai a menggunakan rumus Haversine. Baris 22 menghitung nilai c menggunakan fungsi atan2. Baris 24 mengembalikan hasil perkalian R dan c yang merupakan jarak dalam kilometer.

**Segmen 5.34 — Find Nearest Available Driver**

```
01: async findNearestAvailableDriver(storeLat: number, storeLng: number): Promise<Driver | null> {
02:   const availableDrivers = await this.findAvailableDrivers();
03:
04:   if (availableDrivers.length === 0) {
05:     return null;
06:   }
07:
08:   let nearestDriver: Driver | null = null;
09:   let shortestDistance: number = Infinity;
10:
11:   for (const driver of availableDrivers) {
12:     if (driver.currentLat === null || driver.currentLng === null) {
13:       nearestDriver = driver;
14:       break;
15:     }
16:
17:     const distance = haversineDistance(
18:       driver.currentLat,
19:       driver.currentLng,
20:       storeLat,
21:       storeLng,
22:     );
23:
24:     if (distance < shortestDistance) {
25:       shortestDistance = distance;
26:       nearestDriver = driver;
27:     }
28:   }
29:
30:   return nearestDriver;
31: }
```

Segmen Program 5.34 merupakan implementasi algoritma auto-dispatch yang mencari driver tersedia terdekat dari lokasi toko. Baris 1-6 fungsi findNearestAvailableDriver menerima storeLat dan storeLng sebagai koordinat lokasi toko. Baris 2 memanggil findAvailableDrivers untuk mendapatkan daftar driver yang aktif dan tersedia. Baris 4-6 menangani kasus jika tidak ada driver tersedia dengan mengembalikan null. Baris 8-9 inisialisasi variabel nearestDriver dan shortestDistance. Baris 11-28 merupakan perulangan untuk mencari driver dengan jarak terdekat. Baris 12-15 menangani kasus jika driver belum memiliki koordinat, maka driver tersebut langsung dipilih. Baris 17-22 menghitung jarak antara posisi driver dan toko menggunakan fungsi haversineDistance. Baris 24-27 membandingkan jarak tersebut dengan shortestDistance dan memperbarui nearestDriver jika jarak lebih pendek. Baris 30 mengembalikan objek driver yang telah dipilih.

> **Gambar 5.8** — Tampilan Fitur Auto-dispatch

---

## 5.9 Fitur Manajemen Pengiriman

Fitur manajemen pengiriman digunakan oleh courier untuk menerima dan memproses tugas pengiriman yang telah ditetapkan oleh sistem. Courier dapat melihat daftar pesanan yang masuk, memantau detail informasi setiap pesanan seperti alamat penjemputan dan tujuan pengiriman, serta memperbarui status pengiriman secara bertahap mulai dari pickup hingga pesanan selesai diantarkan. Setiap pembaruan status yang dilakukan courier akan langsung tersinkronisasi ke server dan diteruskan kepada customer secara real-time melalui koneksi WebSocket.

**Segmen 5.35 — Update Order Status**

```
01: async updateStatus(id: number, status: OrderStatus): Promise<Order | null> {
02:   const order = await this.orderRepo.findOne({ where: { id }, relations: ['driver'] });
03:   if (!order) return null;
04:   order.status = status;
05:   await this.orderRepo.save(order);
06:
07:   if ((status === OrderStatus.DELIVERED || status === OrderStatus.CANCELLED) && order.driverId) {
08:     await this.driversService.update(order.driverId, { isAvailable: true });
09:   }
10:
11:   return order;
12: }
```

Segmen Program 5.35 merupakan implementasi fungsi updateStatus pada OrdersService untuk mengupdate status pesanan. Baris 2 mencari order berdasarkan id dengan relasi driver. Baris 3 jika tidak ditemukan, return null. Baris 4-5 update status dan simpan ke database. Baris 7-9 jika status menjadi DELIVERED atau CANCELLED, maka driver yang mengerjakan pesanan tersebut di-set kembali menjadi available agar bisa menerima pesanan baru. Baris 11 mengembalikan objek order yang sudah diupdate.

**Segmen 5.36 — Location Tracking Initialization**

```
01: Future<void> _initLocationTracking() async {
02:   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
03:   if (!serviceEnabled) {
04:     debugPrint('[_initLocationTracking] Location services disabled');
05:     return;
06:   }
07:
08:   LocationPermission permission = await Geolocator.checkPermission();
09:   if (permission == LocationPermission.denied) {
10:     permission = await Geolocator.requestPermission();
11:     if (permission == LocationPermission.denied) {
12:       debugPrint('[_initLocationTracking] Location permission denied');
13:       return;
14:     }
15:   }
16:
17:   if (permission == LocationPermission.deniedForever) {
18:     debugPrint('[_initLocationTracking] Location permission permanently denied');
19:     return;
20:   }
21:
22:   _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
23:     _sendLocationUpdate();
24:   });
25:
26:   WebSocketService.instance.connect(widget.driverId);
27:   _sendLocationUpdate();
28: }
```

Segmen Program 5.36 merupakan implementasi inisialisasi location tracking pada Courier App. Baris 2-6 memeriksa apakah location service enabled, jika tidak maka keluar. Baris 8-14 meminta permission lokasi, jika denied maka minta lagi, jika masih denied keluar. Baris 17-20 jika permission permanently denied, keluar. Baris 26 koneksi ke WebSocket service dengan driverId. Baris 27 kirim lokasi pertama kali.

**Segmen 5.37 — Send Location Update**

```
01: Future<void> _sendLocationUpdate() async {
02:   try {
03:     final position = await Geolocator.getCurrentPosition(
04:       locationSettings: const LocationSettings(
05:         accuracy: LocationAccuracy.high,
06:         timeLimit: Duration(seconds: 10),
07:       ),
08:     );
09:
10:     _currentPosition = position;
11:
12:     final wsSuccess = await WebSocketService.instance.sendLocationUpdate(
13:       driverId: widget.driverId,
14:       lat: position.latitude,
15:       lng: position.longitude,
16:     );
17:
18:     if (!wsSuccess) {
19:       await ApiService.updateDriverLocation(
20:         driverId: widget.driverId,
21:         lat: position.latitude,
22:         lng: position.longitude,
23:       );
24:     }
25:   } catch (e) {
26:     debugPrint('[_sendLocationUpdate] Error: $e');
27:   }
28: }
```

Segmen Program 5.37 merupakan implementasi pengiriman update lokasi driver. Baris 3-8 mengambil posisi GPS saat ini dengan akurasi tinggi dan timeout 10 detik. Baris 10 menyimpan posisi ke variabel _currentPosition. Baris 12-16 mencoba mengirim lokasi via WebSocket, jika sukses return true. Baris 18-24 jika WebSocket gagal, fallback ke HTTP API untuk update lokasi via ApiService.updateDriverLocation. Baris 25-27 menangkap error dan print ke debug console.

**Segmen 5.38 — Order Status Machine**

```
01: OrderStatus? _nextStatus() {
02:   switch (_order.status) {
03:     case OrderStatus.pending:
04:       return OrderStatus.pickingUp;
05:     case OrderStatus.pickingUp:
06:       return OrderStatus.pickedUp;
07:     case OrderStatus.pickedUp:
08:       return OrderStatus.delivering;
09:     case OrderStatus.delivering:
10:       return OrderStatus.delivered;
11:     case OrderStatus.delivered:
12:       return null;
13:   }
14: }
15:
16: String _nextLabel() {
17:   switch (_order.status) {
18:     case OrderStatus.pending:
19:       return 'Mulai Pickup';
20:     case OrderStatus.pickingUp:
21:       return 'Barang Diambil';
22:     case OrderStatus.pickedUp:
23:       return 'Mulai Antar';
24:     case OrderStatus.delivering:
25:       return 'Selesai Antar';
26:     case OrderStatus.delivered:
27:       return 'Selesai';
28:   }
29: }
```

Segmen Program 5.38 merupakan implementasi state machine untuk menentukan status berikutnya dan label tombol aksi. Fungsi _nextStatus() (baris 1-14) mengembalikan status berikutnya berdasarkan status saat ini: pending → pickingUp → pickedUp → delivering → delivered, dan delivered tidak memiliki next status (return null). Fungsi _nextLabel() (baris 16-29) mengembalikan label yang sesuai untuk tombol aksi berdasarkan status saat ini, misalnya 'Mulai Pickup' saat status pending, 'Barang Diambil' saat pickingUp, dan seterusnya.

> **Gambar 5.8** — Tampilan Fitur Manajemen Pengiriman

---

## 5.10 Fitur Riwayat Pengiriman Courier

Fitur riwayat pengiriman digunakan oleh courier untuk melihat daftar pesanan yang telah diselesaikan sebelumnya. Setiap pesanan dalam riwayat menampilkan informasi meliputi status akhir dan tanggal penyelesaian, sehingga courier dapat memantau rekap aktivitas pengiriman yang telah dilakukan. Fitur ini juga membantu courier untuk melacak performa pengiriman mereka dari waktu ke waktu.

**Segmen 5.39 — Get Completed Orders**

```
01: @Get('orders/driver/:driverId')
02: async getOrdersByDriver(@Param('driverId') driverId: number) {
03:   return this.orderRepo.find({
04:     where: { driverId },
05:     order: { createdAt: 'DESC' },
06:   });
07: }
```

Segmen Program 5.39 merupakan implementasi endpoint untuk mendapatkan semua pesanan driver. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /orders/driver/:driverId dengan parameter driverId dari URL. Baris 3-6 query database menggunakan orderRepo.find dengan filter driverId dan diurutkan berdasarkan createdAt descending sehingga pesanan terbaru muncul pertama.

**Segmen 5.40 — Filter Completed Orders**

```
01: @Get('orders/driver/:driverId/completed')
02: async getCompletedOrders(@Param('driverId') driverId: number) {
03:   return this.orderRepo.find({
04:     where: { driverId, status: OrderStatus.DELIVERED },
05:     order: { updatedAt: 'DESC' },
06:   });
07: }
```

Segmen Program 5.40 merupakan implementasi endpoint untuk mendapatkan pesanan yang sudah selesai (status DELIVERED). Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /orders/driver/:driverId/completed. Baris 3-6 query database dengan filter driverId dan status = DELIVERED, diurutkan berdasarkan updatedAt descending.

**Segmen 5.41 — Delivery History Page**

```
01: class DeliveryHistoryPage extends StatefulWidget {
02:   @override
03:   State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
04: }
05:
06: class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
07:   List<Order> _completedOrders = [];
08:   bool _isLoading = true;
09:
10:   Future<void> _loadHistory() async {
11:     try {
12:       final orders = await ApiService.getDriverCompletedOrders(widget.driverId);
13:       if (mounted) {
14:         setState(() {
15:           _completedOrders = orders;
16:           _isLoading = false;
17:         });
18:       }
19:     } catch (e) {
20:       if (mounted) {
21:         setState(() {
22:           _isLoading = false;
23:         });
24:       }
25:     }
26:   }
27:
28:   @override
29:   void initState() {
30:     super.initState();
31:     _loadHistory();
32:   }
33: }
```

Segmen Program 5.41 merupakan implementasi halaman riwayat pengiriman pada Courier App. Baris 1-6 mendefinisikan StatefulWidget untuk delivery history page. Baris 10-26 fungsi _loadHistory yang memanggil ApiService.getDriverCompletedOrders dan update state dengan data yang diterima. Baris 28-32 inisialisasi state dengan memanggil _loadHistory saat halaman pertama kali dibuka.

**Segmen 5.42 — History List Widget**

```
01: ListView.builder(
02:   itemCount: _completedOrders.length,
03:   itemBuilder: (context, index) {
04:     final order = _completedOrders[index];
05:     return Card(
06:       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
07:       child: Padding(
08:         padding: const EdgeInsets.all(16),
09:         child: Column(
10:           crossAxisAlignment: CrossAxisAlignment.start,
11:           children: [
12:             Row(
13:               mainAxisAlignment: MainAxisAlignment.spaceBetween,
14:               children: [
15:               Text(
16:                 'Order #${order.id}',
17:                 style: const TextStyle(fontWeight: FontWeight.bold),
18:               ),
19:               const Icon(Icons.check_circle, color: Colors.green),
20:             ],
21:           ),
22:           const SizedBox(height: 8),
23:           Text(
24:             order.deliveryAddress,
25:             maxLines: 2,
26:             overflow: TextOverflow.ellipsis,
27:           ),
28:           const SizedBox(height: 4),
29:           Text(
30:             'Selesai: ${_formatDate(order.updatedAt)}',
31:             style: TextStyle(color: Colors.grey[600], fontSize: 12),
32:           ),
33:         ],
34:       ),
35:     ),
36:   },
37: );
```

Segmen Program 5.42 merupakan implementasi widget tampilan daftar riwayat pengiriman. Baris 1 membuat ListView dengan jumlah item sesuai panjang _completedOrders. Baris 4-37 membangun tampilan setiap card pesanan. Baris 12-21 menampilkan ID pesanan dengan icon check_circle hijau untuk menunjukkan pesanan selesai. Baris 23-27 menampilkan alamat pengiriman dengan max 2 baris dan ellipsis jika terlalu panjang. Baris 29-32 menampilkan tanggal penyelesaian pesanan.

> **Gambar 5.9** — Tampilan Fitur Riwayat Pengiriman Courier

---

## 5.11 Fitur Manajemen Employee

Fitur manajemen employee digunakan oleh admin untuk mengelola data driver atau kurir yang terdaftar dalam sistem. Admin dapat menambah driver baru, mengubah informasi driver yang sudah ada, serta menonaktifkan driver yang tidak lagi bertugas, termasuk mengelola informasi kendaraan seperti jenis, merek, plat nomor, dan warna kendaraan. Data driver yang dikelola melalui fitur ini akan langsung berpengaruh pada proses auto-dispatch, sehingga hanya driver yang aktif yang dapat menerima penugasan pesanan dari sistem.

**Segmen 5.43 — Create Driver**

```
01: @Post()
02: async create(@Body() dto: CreateDriverDto) {
03:   const driver = this.driverRepo.create({
04:     username: dto.username,
05:     password: dto.password,
06:     name: dto.name,
07:     phone: dto.phone ?? '',
08:     vehicleType: dto.vehicleType ?? 'motorcycle',
09:     vehicleBrand: dto.vehicleBrand ?? '',
10:     vehiclePlate: dto.vehiclePlate ?? '',
11:     vehicleColor: dto.vehicleColor ?? '',
12:     isActive: true,
13:     isAvailable: true,
14:   });
15:   return this.driverRepo.save(driver);
16: }
```

Segmen Program 5.43 merupakan implementasi endpoint untuk membuat driver baru. Baris 1-2 mendefinisikan decorator @Post untuk endpoint POST /drivers. Baris 3-14 membuat objek driver dari DTO dengan field-field yang diperlukan. Baris 15 menyimpan ke database dan mengembalikan driver yang baru dibuat.

**Segmen 5.44 — Get All Drivers**

```
01: @Get()
02: async findAll() {
03:   return this.driverRepo.find({
04:     order: { name: 'ASC' },
05:   });
06: }
```

Segmen Program 5.44 merupakan implementasi endpoint untuk mendapatkan semua driver. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /drivers. Baris 3-5 query database dengan order by name ascending.

**Segmen 5.45 — Delete/Deactivate Driver**

```
01: @Delete(':id')
02: async remove(@Param('id') id: number) {
03:   const driver = await this.driverRepo.findOne({ where: { id } });
04:   if (!driver) {
05:     throw new NotFoundException('Driver not found');
06:   }
07:   driver.isActive = false;
08:   driver.isAvailable = false;
09:   return this.driverRepo.save(driver);
10: }
```

Segmen Program 5.45 merupakan implementasi endpoint untuk menonaktifkan driver. Baris 1-2 mendefinisikan decorator @Delete untuk endpoint DELETE /drivers/:id. Baris 3-6 mencari driver berdasarkan id, jika tidak ditemukan lempar exception. Baris 7-8 set isActive dan isAvailable menjadi false. Baris 9 menyimpan perubahan. (Tidak dilakukan hard delete untuk menjaga data referensial).

**Segmen 5.46 — Add Employee Page**

```
01: async function addEmployee() {
02:     const nameVal = String(newName).trim();
03:     const usernameVal = String(newUsername).trim();
04:     const passwordVal = String(newPassword).trim();
05:     const phoneVal = String(newPhone).trim();
06:
07:     if (!nameVal || !usernameVal || !passwordVal) {
08:       formError = "Name, username, and password are required";
09:       return;
10:     }
11:
12:     try {
13:       await createDriver({
14:         name: nameVal,
15:         username: usernameVal,
16:         password: passwordVal,
17:         phone: phoneVal,
18:         vehicleBrand: newVehicleBrand,
19:         vehiclePlate: newVehiclePlate,
20:         vehicleColor: newVehicleColor,
21:       });
22:       await loadEmployees();
23:       closeModal();
24:     } catch (e) {
25:       formError = "Failed to add employee. Please try again.";
26:     }
27: }
```

Segmen Program 5.46 merupakan implementasi fungsi addEmployee untuk menambah driver baru melalui form modal. Baris 2-5 mengambil dan trim nilai dari form inputs. Baris 7-10 validasi bahwa name, username, dan password wajib diisi. Baris 12-21 memanggil createDriver API dengan data yang sudah di-parse, kemudian reload employees dan close modal. Baris 24-26 catch error dan set formError message.

**Segmen 5.47 — Employee List Page**

```
01: let employees = $state([]);
02:
03: async function loadEmployees() {
04:     const data = await fetchDrivers();
05:     employees = data.map((d: any) => ({
06:       id: d.id,
07:       name: d.name,
08:       username: d.username,
09:       phone: d.phone || "-",
10:       vehicle: `${d.vehicleBrand || ""} ${d.vehiclePlate || ""} ${d.vehicleColor || ""}`.trim(),
11:       isActive: d.isActive,
12:       isAvailable: d.isAvailable,
13:     }));
14: }
```

Segmen Program 5.47 merupakan implementasi state dan fungsi untuk memuat daftar employee. Baris 1 deklarasi state employees sebagai array. Baris 3-13 fungsi loadEmployees yang fetch data dari API, mapping setiap driver ke format yang diperlukan dengan menggabungkan informasi kendaraan menjadi satu string.

> **Gambar 5.10** — Tampilan Fitur Manajemen Employee

---

## 5.12 Fitur Lacak Driver

Fitur lacak driver digunakan oleh admin untuk memantau posisi real-time seluruh driver yang sedang bertugas. Admin dapat melihat lokasi setiap driver yang divisualisasikan sebagai marker di atas peta beserta status ketersediaan mereka, sehingga admin memiliki gambaran menyeluruh mengenai persebaran driver di lapangan. Data lokasi driver diperbarui secara otomatis melalui koneksi WebSocket, memastikan informasi yang ditampilkan kepada admin selalu mencerminkan posisi driver yang paling terkini.

**Segmen 5.48 — Get All Driver Locations**

```
01: @Get('drivers/locations')
02: async getAllDriverLocations() {
03:   const drivers = await this.driverRepo.find({
04:     where: { isActive: true },
05:     select: ['id', 'name', 'currentLat', 'currentLng', 'isAvailable'],
06:   });
07:   return drivers;
08: }
```

Segmen Program 5.48 merupakan implementasi endpoint untuk mendapatkan lokasi semua driver aktif. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /drivers/locations. Baris 3-6 query database dengan filter isActive = true dan select hanya field yang diperlukan (id, name, currentLat, currentLng, isAvailable). Baris 7 mengembalikan array lokasi driver.

**Segmen 5.49 — Update Driver Location**

```
01: @Put('drivers/:id/location')
02: async updateLocation(
03:   @Param('id') id: number,
04:   @Body() body: { lat: number; lng: number },
05: ) {
06:   const driver = await this.driverRepo.findOne({ where: { id } });
07:   if (!driver) {
08:     throw new NotFoundException('Driver not found');
09:   }
10:   driver.currentLat = body.lat;
11:   driver.currentLng = body.lng;
12:   return this.driverRepo.save(driver);
13: }
```

Segmen Program 5.49 merupakan implementasi endpoint untuk mengupdate lokasi driver. Baris 1-5 mendefinisikan decorator @Put untuk endpoint PUT /drivers/:id/location dengan parameter lat dan lng dari body. Baris 6-9 mencari driver berdasarkan id, jika tidak ditemukan lempar exception. Baris 10-11 update koordinat latitude dan longitude driver. Baris 12 menyimpan perubahan dan mengembalikan driver yang sudah diupdate.

**Segmen 5.50 — Locate Employee Page**

```
01: let drivers = $state([]);
02: let selectedDriver = $state(null);
03:
04: async function loadDrivers() {
05:     const data = await fetchDriverLocations();
06:     drivers = data.map((d: any) => ({
07:       id: d.id,
08:       name: d.name,
09:       lat: d.currentLat,
10:       lng: d.currentLng,
11:       isAvailable: d.isAvailable,
12:     }));
13: }
```

Segmen Program 5.50 merupakan implementasi state dan fungsi untuk memuat daftar driver dengan lokasi. Baris 1-2 deklarasi state drivers dan selectedDriver. Baris 4-13 fungsi loadDrivers yang fetch data dari API, mapping setiap driver ke format yang diperlukan dengan field id, name, lat, lng, dan isAvailable.

**Segmen 5.51 — Map Display with Driver Markers**

```
01: L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
02:   attribution: '&copy; OpenStreetMap contributors',
03: }).addTo(map);
04:
05: drivers.forEach(driver => {
06:   if (driver.lat && driver.lng) {
07:     const marker = L.marker([driver.lat, driver.lng]).addTo(map);
08:     marker.bindPopup(`
09:       <b>${driver.name}</b><br>
10:       Status: ${driver.isAvailable ? 'Tersedia' : 'Sedang Mengirim'}
11:     `);
12:   }
13: });
```

Segmen Program 5.51 merupakan implementasi untuk menampilkan marker driver di peta. Baris 1-3 menambahkan tile layer OpenStreetMap ke map. Baris 5-13 iterasi setiap driver, jika driver memiliki koordinat lat dan lng, maka tambahkan marker ke peta dengan popup yang menampilkan nama driver dan status ketersediaan.

> **Gambar 5.11** — Tampilan Fitur Lacak Driver

---

## 5.13 Fitur Pelacakan Pesanan

Fitur pelacakan pesanan digunakan oleh customer untuk memantau status pesanan secara real-time termasuk lokasi driver di peta. Halaman pelacakan menampilkan timeline status pesanan secara visual mulai dari menunggu konfirmasi, proses pickup, dalam pengiriman, hingga pesanan tiba di tujuan. Posisi driver yang ditampilkan di peta diperbarui secara otomatis melalui koneksi WebSocket, sehingga customer dapat mengetahui keberadaan driver tanpa perlu melakukan refresh halaman secara manual.

**Segmen 5.52 — Status Display**

```
01: String get _currentStatusText {
02:   if (_orderData == null) return 'Menunggu driver menerima pesanan...';
03:   switch (_orderData!['status']) {
04:     case 'pending':
05:       return 'Menunggu driver menerima pesanan...';
06:     case 'pickingUp':
07:       return 'Driver menuju pickup...';
08:     case 'pickedUp':
09:       return 'Driver mengambil pesanan';
10:     case 'delivering':
11:       return 'Driver dalam perjalanan ke lokasi Anda';
12:     case 'delivered':
13:       return 'Pesanan telah tiba!';
14:     default:
15:       return 'Menunggu...';
16:   }
17: }
18:
19: int get _currentStatusIndex {
20:   if (_orderData == null) return 0;
21:   switch (_orderData!['status']) {
22:     case 'pending':
23:       return 0;
24:     case 'pickingUp':
25:     case 'pickedUp':
26:       return 1;
27:     case 'delivering':
28:       return 2;
29:     case 'delivered':
30:       return 3;
31:     default:
32:       return 0;
33:   }
34: }
```

Segmen Program 5.52 merupakan implementasi getter untuk menampilkan status text dan index pada halaman tracking. Fungsi _currentStatusText (baris 1-17) mengembalikan teks deskriptif berdasarkan status pesanan: 'pending' menunjukkan menunggu driver, 'pickingUp' menunjukkan driver menuju lokasi pickup, 'pickedUp' menunjukkan driver sudah mengambil barang, 'delivering' menunjukkan driver dalam perjalanan ke customer, dan 'delivered' menunjukkan pesanan sudah diterima. Fungsi _currentStatusIndex (baris 19-34) mengembalikan index numerik untuk menentukan step aktif pada indikator progres: pending = 0, pickingUp/pickedUp = 1, delivering = 2, delivered = 3.

**Segmen 5.53 — Polyline Decoding**

```
01: List<LatLng> _decodePolyline(String encoded) {
02:   final List<LatLng> points = [];
03:   var index = 0;
04:   var lat = 0;
05:   var lng = 0;
06:   while (index < encoded.length) {
07:     int b;
08:     var shift = 0;
09:     var result = 0;
10:     do {
11:       b = encoded.codeUnitAt(index++) - 63;
12:       result |= (b & 0x1f) << shift;
13:       shift += 5;
14:     } while (b >= 0x20);
15:     final dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
16:     lat += dlat;
17:     shift = 0;
18:     result = 0;
19:     do {
20:       b = encoded.codeUnitAt(index++) - 63;
21:       result |= (b & 0x1f) << shift;
22:       shift += 5;
23:     } while (b >= 0x20);
24:     final dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
25:     lng += dlng;
26:     points.add(LatLng(lat / 1e5, lng / 1e5));
27:   }
28:   return points;
29: }
```

Segmen Program 5.53 merupakan implementasi algoritma decoding polyline untuk menampilkan rute di peta. Fungsi ini menerima string encoded polyline dari OpenStreetMap/OSRM dan mengembalikan list of LatLng points. Baris 6-27 merupakan loop utama yang mengekstrak koordinat lat dan lng dari string menggunakan algoritma Google Polyline Encoding. Setiap koordinat di-encode dengan prinsip bahwa nilai dikonversi ke signed integer, kemudian setiap batch 5-bit dibaca dan di-decode kembali. Baris 26 menambahkan point ke list dengan konversi dari format integer (dibagi 1e5 untuk mendapatkan nilai desimal).

> **Gambar 5.12** — Tampilan Fitur Pelacakan Pesanan

---

## 5.14 Fitur Dashboard Admin

Fitur dashboard admin digunakan oleh administrator untuk memantau statistik pesanan, revenue, dan aktivitas driver secara real-time. Dashboard menampilkan berbagai informasi ringkas seperti jumlah pesanan aktif, total pendapatan, serta daftar driver yang sedang bertugas, sehingga administrator dapat mengawasi jalannya operasional sistem secara menyeluruh dalam satu halaman. Seluruh data yang ditampilkan diperbarui secara otomatis, memungkinkan administrator untuk mengambil keputusan dengan cepat berdasarkan kondisi terkini tanpa perlu berpindah halaman.

**Segmen 5.54 — Dashboard Stats**

```
01: let stats = $state([
02:     { label: "Total Employee", value: "48", icon: "employee", color: "#6c63ff" },
03:     { label: "Revenue Today", value: "Rp 0", icon: "revenue", color: "#00d4aa" },
04:     { label: "Total Orders Today", value: "0", icon: "orders-today", color: "#42a5f5" },
05:     { label: "Total Orders This Month", value: "0", icon: "orders-month", color: "#ffb74d" },
06: ]);
07:
08: let ordersToday = $state(Array.from({ length: 24 }, () => 0));
09: let ordersMonth = $state(Array.from({ length: 30 }, () => 0));
10:
11: let maxOrderToday = $derived(Math.max(...ordersToday, 1));
12: let maxOrderMonth = $derived(Math.max(...ordersMonth, 1));
```

Segmen Program 5.54 merupakan implementasi state management pada dashboard admin menggunakan Svelte. Baris 1-6 mendefinisikan array stats dengan informasi kartu statistik yang menampilkan Total Employee, Revenue Today, Total Orders Today, dan Total Orders This Month, masing-masing dengan warna dan icon yang berbeda. Baris 8-9 mendefinisikan array ordersToday dan ordersMonth untuk menyimpan data grafik (24 jam dan 30 hari). Baris 11-12 menggunakan $derived untuk menghitung nilai maximum dari array untuk keperluan scaling grafik.

**Segmen 5.55 — Load Stats and Polling**

```
01: onMount(async () => {
02:     await loadStats();
03:     pollInterval = setInterval(() => {
04:         loadStats();
05:     }, 30000);
06: });
07:
08: async function loadStats() {
09:     try {
10:         const data = await fetchOrderStats();
11:         const revenue = Number(data.revenueToday || 0);
12:         stats = [
13:             { label: "Total Employee", value: "48", icon: "employee", color: "#6c63ff" },
14:             { label: "Revenue Today", value: "Rp " + revenue.toLocaleString("id-ID"), icon: "revenue", color: "#00d4aa" },
15:             { label: "Total Orders Today", value: String(data.totalOrdersToday || 0), icon: "orders-today", color: "#42a5f5" },
16:             { label: "Total Orders This Month", value: String(data.totalOrdersThisMonth || 0), icon: "orders-month", color: "#ffb74d" },
17:         ];
18:         if (data.ordersPerHour) ordersToday = data.ordersPerHour;
19:         if (data.ordersPerDay) ordersMonth = data.ordersPerDay;
20:     } catch (e) {
21:         console.error("Failed to load dashboard stats:", e);
22:     }
23: }
```

Segmen Program 5.55 merupakan implementasi fungsi loadStats dan auto-refresh polling. Baris 1-6 menggunakan onMount lifecycle hook untuk memanggil loadStats saat komponen dimount, kemudian setup setInterval untuk refresh setiap 30 detik (30000ms). Baris 8-23 mendefinisikan fungsi loadStats yang fetch data statistik dari API, parse revenue sebagai number, update array stats dengan data baru, dan jika ada data ordersPerHour atau ordersPerDay dari response, update juga array untuk grafik. Error handling menangkap dan log error ke console.

> **Gambar 5.13** — Tampilan Fitur Dashboard Admin

---

## 5.15 Fitur Manajemen Stok

Fitur manajemen stok digunakan oleh admin untuk mengelola inventori produk termasuk penambahan produk baru dan monitoring reorder point (ROP). Admin dapat menambahkan produk baru ke katalog serta memantau jumlah stok setiap produk secara langsung melalui halaman manajemen. Sistem akan memberikan peringatan secara otomatis apabila stok suatu produk telah mencapai atau melewati batas reorder point, sehingga admin dapat segera mengambil tindakan pengisian stok sebelum produk habis.

**Segmen 5.56 — ROP Calculation**

```
01: calculateROP(leadTime: number, safetyStock: number, avgDailySales: number): number {
02:   return (leadTime * avgDailySales) + safetyStock;
03: }
04:
05: needsReorder(product: Product): boolean {
06:   const leadTime = product.leadTime ?? 3;
07:   const safetyStock = product.safetyStock ?? 5;
08:   const stock = product.stock ?? 0;
09:   const sold = product.sold ?? 0;
10:
11:   if (sold === 0) {
12:     return stock <= safetyStock;
13:   }
14:
15:   if (sold < 7) {
16:     const rop = safetyStock + leadTime;
17:     return stock <= rop;
18:   }
19:
20:   const avgDailySales = Math.min(sold / 7, 10);
21:   const rop = (leadTime * avgDailySales) + safetyStock;
22:   return stock <= rop;
23: }
```

Segmen Program 5.56 merupakan implementasi perhitungan Reorder Point (ROP) untuk manajemen stok. Fungsi calculateROP (baris 1-3) menghitung ROP dengan formula: (leadTime × avgDailySales) + safetyStock. Fungsi needsReorder (baris 5-23) menentukan apakah produk perlu di-reorder: jika sold = 0, bandingkan stok dengan safetyStock saja; jika sold < 7 (produk baru atau sedikit penjualan), gunakan ROP sederhana (safetyStock + leadTime); jika sold >= 7, hitung rata-rata penjualan harian dengan cap 10 unit/hari untuk menghindari ROP ekstrem, kemudian hitung ROP lengkap. Return true jika stok saat ini <= ROP.

**Segmen 5.57 — Calculate Average Daily Sales**

```
01: async calculateAvgDailySales(productName: string): Promise<number> {
02:   const sevenDaysAgo = new Date();
03:   sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
04:
05:   const orders = await this.orderItemRepo
06:     .createQueryBuilder('item')
07:     .innerJoin('item.order', 'order')
08:     .where('item.productName = :name', { name: productName })
09:     .andWhere('order.createdAt >= :date', { date: sevenDaysAgo })
10:     .andWhere('order.status = :status', { status: 'delivered' })
11:     .getMany();
12:
13:   const totalSold = orders.reduce((sum, item) => sum + (item.quantity ?? 0), 0);
14:   return totalSold / 7;
15: }
```

Segmen Program 5.57 merupakan implementasi fungsi untuk menghitung rata-rata penjualan harian dalam 7 hari terakhir. Baris 2-3 hitung tanggal 7 hari yang lalu. Baris 5-11 query database menggunakan QueryBuilder untuk mengambil semua order items dengan productName yang sesuai, yang dibuat dalam 7 hari terakhir, dan statusnya 'delivered'. Baris 13 jumlahkan semua quantity dari item pesanan. Baris 14 return totalSold dibagi 7 untuk mendapatkan rata-rata harian.

**Segmen 5.58 — Reorder Point Logic**

```
01: function needsReorder(item: any): boolean {
02:     const leadTime = item.leadTime ?? 3;
03:     const safetyStock = item.safetyStock ?? 5;
04:     const stock = item.stock ?? 0;
05:     const sold = item.sold ?? 0;
06:
07:     if (sold === 0) {
08:       return stock <= safetyStock;
09:     }
10:
11:     if (sold < 7) {
12:       const rop = safetyStock + leadTime;
13:       return stock <= rop;
14:     }
15:
16:     const avgDailySales = Math.min(sold / 7, 10);
17:     const rop = (leadTime * avgDailySales) + safetyStock;
18:     return stock <= rop;
19: }
```

Segmen Program 5.58 merupakan implementasi logika reorder point di frontend admin panel. Sama seperti backend, fungsi ini menghitung apakah produk perlu reorder: jika sold = 0, cek terhadap safetyStock saja; jika sold < 7, gunakan ROP sederhana; jika sold >= 7, hitung avgDailySales dengan cap 10, kemudian hitung ROP = (leadTime × avgDailySales) + safetyStock. Return true jika stock <= ROP.

**Segmen 5.59 — Add Product**

```
01: async function addItem() {
02:     const nameVal = String(newName).trim();
03:     const priceVal = String(newPrice).trim();
04:     const stockVal = String(newStock).trim();
05:
06:     if (!nameVal) {
07:       formError = "Item name is required";
08:       return;
09:     }
10:     if (!priceVal || isNaN(Number(priceVal)) || Number(priceVal) <= 0) {
11:       formError = "Valid price is required";
12:       return;
13:     }
14:     if (!stockVal || isNaN(Number(stockVal)) || Number(stockVal) < 0) {
15:       formError = "Valid stock quantity is required";
16:       return;
17:     }
18:
19:     try {
20:       await createProduct({
21:         name: nameVal,
22:         price: Number(priceVal),
23:         stock: Number(stockVal),
24:         unit: newUnit,
25:         image: newImage,
26:       });
27:       await loadProducts();
28:       closeModal();
29:     } catch (e) {
30:       formError = "Failed to save item. Please try again.";
31:     }
32: }
```

Segmen Program 5.59 merupakan implementasi fungsi addItem untuk menambah produk baru melalui form modal. Baris 2-4 mengambil dan trim nilai dari form inputs. Baris 6-17 melakukan validasi: nama tidak boleh kosong, harga harus number positif, stock harus number non-negatif. Baris 19-28 jika validasi lolos, panggil createProduct API dengan data yang sudah di-parse, kemudian reload products dan close modal. Baris 29-31 catch error dan set formError message.

> **Gambar 5.14** — Tampilan Fitur Manajemen Stok

---

## 5.16 Fitur Time Slot Booking

Fitur time slot booking digunakan oleh customer untuk memilih jadwal waktu pengiriman yang diinginkan saat melakukan checkout. Setiap slot waktu hanya dapat menampung maksimal tiga pesanan sesuai dengan jumlah driver yang bertugas, sehingga ketersediaan slot akan berkurang seiring bertambahnya pesanan yang masuk. Apabila suatu slot telah mencapai batas maksimum tiga pesanan, slot tersebut secara otomatis dinonaktifkan oleh sistem sehingga tidak dapat dipilih kembali oleh customer.

**Segmen 5.60 — Create Time Slot**

```
01: @Post()
02: async create(@Body() dto: CreateTimeSlotDto) {
03:   const slot = this.timeSlotRepo.create({
04:     date: dto.date,
05:     startTime: dto.startTime,
06:     endTime: dto.endTime,
07:     maxDrivers: dto.maxDrivers ?? 10,
08:     isActive: true,
09:   });
10:   return this.timeSlotRepo.save(slot);
11: }
```

Segmen Program 5.60 merupakan implementasi endpoint untuk membuat time slot baru. Baris 1-2 mendefinisikan decorator @Post untuk endpoint POST /time-slots. Baris 3-9 membuat objek time slot dari DTO dengan field date, startTime, endTime, dan maxDrivers. Baris 10 menyimpan ke database dan mengembalikan time slot yang baru dibuat.

**Segmen 5.61 — Get All Time Slots**

```
01: @Get()
02: async findAll() {
03:   return this.timeSlotRepo.find({
04:     where: { isActive: true },
05:     order: { date: 'ASC', startTime: 'ASC' },
06:   });
07: }
```

Segmen Program 5.61 merupakan implementasi endpoint untuk mendapatkan semua time slot aktif. Baris 1-2 mendefinisikan decorator @Get untuk endpoint GET /time-slots. Baris 3-6 query database dengan filter isActive = true dan order by date dan startTime ascending.

**Segmen 5.62 — Time Slot List Page**

```
01: let timeSlots = $state([]);
02:
03: async function loadTimeSlots() {
04:     const data = await fetchTimeSlots();
05:     timeSlots = data.map((s: any) => ({
06:       id: s.id,
07:       date: s.date,
08:       time: `${s.startTime} - ${s.endTime}`,
09:       maxDrivers: s.maxDrivers,
10:       isActive: s.isActive,
11:     }));
12: }
```

Segmen Program 5.62 merupakan implementasi state dan fungsi untuk memuat daftar time slot. Baris 1 deklarasi state timeSlots sebagai array. Baris 3-12 fungsi loadTimeSlots yang fetch data dari API, mapping setiap time slot ke format yang diperlukan dengan menggabungkan startTime dan endTime menjadi satu string.

**Segmen 5.63 — Time Slot Calendar View**

```
01: async function loadCalendarView() {
02:     const slots = await fetchTimeSlots();
03:     const grouped = {};
04:     slots.forEach(s => {
05:       const key = s.date;
06:       if (!grouped[key]) grouped[key] = [];
07:       grouped[key].push({
08:         id: s.id,
09:         time: `${s.startTime} - ${s.endTime}`,
10:         maxDrivers: s.maxDrivers,
11:       });
12:     });
13:     calendarData = grouped;
14: }
```

Segmen Program 5.63 merupakan implementasi fungsi untuk melihat time slot dalam format kalender. Baris 2 fetch semua time slots dari API. Baris 3-12 grouping time slots berdasarkan tanggal, setiap grup berisi array time slot untuk tanggal tersebut. Baris 13 set calendarData ke grouped object untuk ditampilkan dalam view kalender.

> **Gambar 5.15** — Tampilan Fitur Time Slot Booking

---

## 5.17 WebSocket Gateway Setup

Backend menggunakan Socket.IO untuk komunikasi real-time antara server dan klien, memungkinkan pertukaran data terjadi secara instan tanpa perlu polling berulang dari sisi klien. Setiap koneksi dikelola dalam room yang terpisah berdasarkan ID pesanan, sehingga pembaruan status dan posisi driver hanya dikirimkan kepada klien yang relevan. Server akan memancarkan event secara otomatis setiap kali terjadi perubahan status pesanan atau pergerakan lokasi driver, yang kemudian ditampilkan langsung di antarmuka pengguna tanpa perlu refresh halaman.

**Segmen 5.64 — Setup WebSocket Adapter**

```
01: import 'dotenv/config';
02: import { NestFactory } from '@nestjs/core';
03: import { ValidationPipe } from '@nestjs/common';
04: import { AppModule } from './app.module.js';
05: import { NestExpressApplication } from '@nestjs/platform-express';
06: import { join } from 'path';
07: import { IoAdapter } from '@nestjs/platform-socket.io';
08:
09: async function bootstrap() {
10:   const app = await NestFactory.create<NestExpressApplication>(AppModule);
11:
12:   app.useStaticAssets(join(__dirname, '..', 'uploads'), {
13:     prefix: '/uploads',
14:   });
15:
16:   app.enableCors({
17:     origin: '*',
18:     methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
19:     credentials: true,
20:   });
21:
22:   app.useWebSocketAdapter(new IoAdapter(app));
23:
24:   app.useGlobalPipes(
25:     new ValidationPipe({
26:       whitelist: true,
27:       transform: true,
28:       transformOptions: { enableImplicitConversion: true },
29:     }),
30:   );
31:
32:   const port = process.env.PORT ?? 3000;
33:   await app.listen(port);
34:   console.log(`🚀 Backend API running on http://localhost:${port}`);
35:   console.log(`📦 Database: ${process.env.DB_NAME || 'kelun_db'}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}`);
36:   console.log(`🔌 WebSocket running on ws://localhost:${port}/driver-location`);
37: }
38: bootstrap();
```

Segmen Program 5.64 merupakan konfigurasi utama aplikasi backend NestJS pada file main.ts. Baris 1 melakukan import dotenv untuk membaca environment variable. Baris 2-7 import modul-modul yang diperlukan. Baris 10 membuat instance aplikasi NestJS dengan tipe NestExpressApplication. Baris 12-14 konfigurasi static assets untuk serving file upload dengan prefix '/uploads'. Baris 16-20 meng-enable CORS dengan mengizinkan semua origin. Baris 22 mengkonfigurasi WebSocket adapter menggunakan IoAdapter. Baris 24-30 konfigurasi global validation pipe. Baris 32-36 menentukan port, menjalankan aplikasi, dan print informasi startup termasuk URL API dan WebSocket.