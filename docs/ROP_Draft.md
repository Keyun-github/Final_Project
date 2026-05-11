# Reorder Point (ROP) Algorithm

## Overview

Reorder Point (ROP) adalah titik pemesanan ulang yang menentukan kapan stok harus dilakukan pemesanan ulang. Implementasi ini digunakan untuk menghindari kondisi out-of-stock dan memastikan ketersediaan barang.

## Formula

```
ROP = (Lead Time × Average Daily Sales) + Safety Stock
```

### Komponen:
- **Lead Time**: Waktu tunggu (dalam hari) dari saat order hingga barang tiba di gudang
- **Average Daily Sales**: Rata-rata jumlah penjualan per hari
- **Safety Stock**: Buffer/stok pengaman untuk kondisi darurat

## Implementation Details

### File Locations:
- Backend: `BackEnd/src/products/products.service.ts`
- Frontend Admin: `admin_panel/src/routes/dashboard/stock/+page.svelte`

### Decision Logic:

```
START
  │
  ├─ sold = 0 (Produk baru tanpa data penjualan)?
  │     YES → ROP = safetyStock
  │           IF stock <= safetyStock → REORDER
  │
  ├─ sold < 7 (Data penjualan sangat sedikit)?
  │     YES → ROP = safetyStock + leadTime
  │           IF stock <= ROP → REORDER
  │
  └─ sold >= 7 (Data penjualan cukup)?
        ROP = (leadTime × min(sold/7, 10)) + safetyStock
        IF stock <= ROP → REORDER
```

### Capping Mechanism:

Untuk menghindari ROP yang terlalu tinggi akibat akumulasi penjualan (cumulative `sold`), dilakukan capping:

```javascript
avgDailySales = Math.min(sold / 7, 10)  // Maksimum 10 unit/hari
```

**Alasan:**
- Field `sold` adalah total penjualan kumulatif seluruh masa
- Tidak seharusnya langsung dibagi 7 untuk mendapat daily average
- Capping memastikan ROP tetap reasonable

## Example Calculations

| Product | stock | sold | leadTime | safetyStock | avgDailySales | ROP | Status |
|---------|-------|------|----------|-------------|---------------|-----|--------|
| Gula Pasir | 40 | 21500 | 3 | 5 | min(3071,10)=10 | 35 | OK |
| Kopi Kapal Api | 90 | 15420 | 3 | 5 | 10 | 35 | OK |
| Product Baru | 3 | 0 | 3 | 5 | - | 5 | REORDER |
| Product Baru | 10 | 0 | 3 | 5 | - | 5 | OK |
| Sedikit Sales | 5 | 5 | 3 | 5 | - | 8 | REORDER |

## Advantages

1. **Otomatis**: Tidak perlu cek manual setiap saat
2. **Adaptif**: Bisa disesuaikan dengan karakteristik produk
3. **Simple**: Mudah diimplementasikan dan dipahami

## Limitations

1. **Cumulative vs Real-time**: Field `sold` adalah akumulatif, bukan 7-day rolling average
2. **Tidak mempertimbangkan seasonality**: Tidak ada adjustment untuk variasi musiman
3. **Static lead time**: Lead time dianggap konstan

## Future Improvements

1. Implementasi true 7-day rolling average berdasarkan tanggal order
2. Dynamic lead time berdasarkan historical data supplier
3. Seasonal adjustment factor
4. Integration dengan supplier system untuk auto-order