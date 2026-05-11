import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

export interface OrderForExport {
  id: string;
  rawId: number;
  customer: string;
  phone: string;
  address: string;
  date: string;
  createdAt: Date;
  total: number;
  totalFormatted: string;
  status: string;
  rawStatus: string;
  paymentMethod: string;
  deliveryPhoto: string | null;
  items: any[];
}

export interface MonthlyStats {
  totalOrders: number;
  pending: number;
  processing: number;
  completed: number;
  cancelled: number;
  totalRevenue: number;
}

export function exportMonthlyOrdersPDF(
  orders: OrderForExport[],
  dateRangeLabel: string,
  year: string,
  stats: MonthlyStats
): void {
  const doc = new jsPDF();

  const primaryColor: [number, number, number] = [21, 101, 192];
  const headerBg: [number, number, number] = [21, 101, 192];
  const summaryBg: [number, number, number] = [245, 247, 250];
  const tableHeaderBg: [number, number, number] = [238, 238, 238];

  doc.setFillColor(...headerBg);
  doc.rect(0, 0, 210, 40, 'F');

  doc.setTextColor(255, 255, 255);
  doc.setFontSize(20);
  doc.setFont('helvetica', 'bold');
  doc.text('LAPORAN PESANAN', 105, 18, { align: 'center' });

  doc.setFontSize(14);
  doc.setFont('helvetica', 'normal');
  doc.text(`${dateRangeLabel}`, 105, 28, { align: 'center' });

  doc.setTextColor(180, 180, 180);
  doc.setFontSize(9);
  doc.text(
    `Dicetak: ${new Date().toLocaleDateString('id-ID', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })}`,
    105,
    35,
    { align: 'center' }
  );

  doc.setTextColor(33, 33, 33);
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text('RINGKASAN', 14, 50);

  doc.setFillColor(...summaryBg);
  doc.rect(14, 54, 182, 50, 'F');

  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');

  const summaryData = [
    ['Total Pesanan', stats.totalOrders.toString()],
    ['Pending', stats.pending.toString()],
    ['Processing', stats.processing.toString()],
    ['Selesai', stats.completed.toString()],
    ['Dibatalkan', stats.cancelled.toString()],
  ];

  let yPos = 60;
  for (const [label, value] of summaryData) {
    doc.text(label, 20, yPos);
    doc.setFont('helvetica', 'bold');
    doc.text(value, 60, yPos);
    doc.setFont('helvetica', 'normal');
    yPos += 9;
  }

  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.text('Total Pendapatan:', 100, 60);
  doc.setTextColor(21, 101, 192);
  doc.text(`Rp ${stats.totalRevenue.toLocaleString('id-ID')}`, 100, 70);

  doc.setTextColor(33, 33, 33);
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text('DAFTAR PESANAN', 14, 115);

  const tableData = orders.map((order, index) => [
    (index + 1).toString(),
    formatTableDate(order.createdAt),
    order.customer,
    order.totalFormatted,
    order.status,
  ]);

  autoTable(doc, {
    startY: 120,
    head: [['No.', 'Tanggal', 'Pelanggan', 'Total', 'Status']],
    body: tableData,
    headStyles: {
      fillColor: tableHeaderBg,
      textColor: [33, 33, 33],
      fontStyle: 'bold',
      fontSize: 10,
    },
    bodyStyles: {
      fontSize: 9,
      textColor: [33, 33, 33],
    },
    alternateRowStyles: {
      fillColor: [255, 255, 255],
    },
    columnStyles: {
      0: { cellWidth: 15, halign: 'center' },
      1: { cellWidth: 35 },
      2: { cellWidth: 50 },
      3: { cellWidth: 45, halign: 'right' },
      4: { cellWidth: 35, halign: 'center' },
    },
    margin: { left: 14, right: 14 },
    styles: {
      lineColor: [220, 220, 220],
      lineWidth: 0.1,
    },
    didParseCell: (data) => {
      if (data.section === 'body' && data.column.index === 4) {
        const status = data.cell.raw as string;
        let color: [number, number, number] = [100, 100, 100];
        if (status === 'Completed') {
          color = [76, 175, 80];
        } else if (status === 'Processing') {
          color = [33, 150, 243];
        } else if (status === 'Pending') {
          color = [255, 167, 38];
        } else if (status === 'Cancelled') {
          color = [229, 57, 53];
        }
        data.cell.styles.textColor = color;
      }
    },
  });

  const pageCount = doc.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFontSize(8);
    doc.setTextColor(150, 150, 150);
    doc.text(
      `Halaman ${i} dari ${pageCount}`,
      105,
      doc.internal.pageSize.height - 10,
      { align: 'center' }
    );
  }

  const filename = `Laporan-Orders-${dateRangeLabel}.pdf`;
  doc.save(filename);
}

function formatTableDate(date: Date): string {
  const d = new Date(date);
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  return `${day}/${month}`;
}

export function calculateMonthlyStats(orders: OrderForExport[]): MonthlyStats {
  const stats: MonthlyStats = {
    totalOrders: orders.length,
    pending: 0,
    processing: 0,
    completed: 0,
    cancelled: 0,
    totalRevenue: 0,
  };

  for (const order of orders) {
    if (order.rawStatus === 'pending') {
      stats.pending++;
    } else if (['pickingUp', 'pickedUp', 'delivering'].includes(order.rawStatus)) {
      stats.processing++;
    } else if (order.rawStatus === 'delivered') {
      stats.completed++;
    } else if (order.rawStatus === 'cancelled') {
      stats.cancelled++;
    }
    stats.totalRevenue += Number(order.total) || 0;
  }

  return stats;
}

export function filterOrdersByMonth(
  orders: OrderForExport[],
  month: number,
  year: number
): OrderForExport[] {
  return orders.filter((order) => {
    const date = new Date(order.createdAt);
    return date.getMonth() === month && date.getFullYear() === year;
  });
}

export function parseOrderForExport(rawOrder: any): OrderForExport {
  return {
    id: `#ORD-${String(rawOrder.id).padStart(3, '0')}`,
    rawId: rawOrder.id,
    customer: rawOrder.customerName || '-',
    phone: rawOrder.customerPhone || '-',
    address: rawOrder.deliveryAddress || '-',
    date: new Date(rawOrder.createdAt).toLocaleDateString('id-ID', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }),
    createdAt: new Date(rawOrder.createdAt),
    total: Number(rawOrder.totalAmount) || 0,
    totalFormatted: `Rp ${Number(rawOrder.totalAmount || 0).toLocaleString('id-ID')}`,
    status: mapStatus(rawOrder.status),
    rawStatus: rawOrder.status,
    paymentMethod: rawOrder.paymentMethod || 'COD',
    deliveryPhoto: rawOrder.deliveryPhoto || null,
    items: (rawOrder.items || []).map((i: any) => ({
      name: i.productName,
      unitName: i.unitName || '',
      price: Number(i.unitPrice),
      qty: i.quantity,
      subtotal: Number(i.unitPrice) * Number(i.quantity),
    })),
  };
}

function mapStatus(status: string): string {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'pickingUp':
    case 'pickedUp':
    case 'delivering':
      return 'Processing';
    case 'delivered':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}