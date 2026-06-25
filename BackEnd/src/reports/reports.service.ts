import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { Order } from '../orders/order.entity.js';
import { Driver } from '../drivers/driver.entity.js';

export interface DriverReportStats {
  totalOrders: number;
  pending: number;
  processing: number;
  delivered: number;
  cancelled: number;
  totalRevenue: number;
  averageOrderValue: number;
  completionRate: number;
  firstOrder: Date | null;
  lastOrder: Date | null;
}

export interface DriverReport {
  driver: Driver | null;
  stats: DriverReportStats;
  recentOrders: Order[];
}

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Order) private orderRepo: Repository<Order>,
    @InjectRepository(Driver) private driverRepo: Repository<Driver>,
  ) {}

  async getDriverReport(
    driverId: number,
    startDate?: string,
    endDate?: string,
  ): Promise<DriverReport> {
    const driver = await this.driverRepo.findOne({ where: { id: driverId } });

    const qb = this.orderRepo
      .createQueryBuilder('order')
      .where('order.driverId = :driverId', { driverId })
      .orderBy('order.createdAt', 'DESC');

    if (startDate && endDate) {
      qb.andWhere('order.createdAt BETWEEN :start AND :end', {
        start: new Date(startDate),
        end: new Date(endDate),
      });
    } else if (startDate) {
      qb.andWhere('order.createdAt >= :start', { start: new Date(startDate) });
    } else if (endDate) {
      qb.andWhere('order.createdAt <= :end', { end: new Date(endDate) });
    }

    const orders = await qb.getMany();

    const stats = this.computeStats(orders);
    const recentOrders = orders.slice(0, 10);

    return {
      driver,
      stats,
      recentOrders,
    };
  }

  async getAllDriversReport(
    startDate?: string,
    endDate?: string,
  ): Promise<DriverReport[]> {
    const drivers = await this.driverRepo.find({
      order: { name: 'ASC' },
    });

    const reports = await Promise.all(
      drivers.map((d) => this.getDriverReport(d.id, startDate, endDate)),
    );

    return reports;
  }

  private computeStats(orders: Order[]): DriverReportStats {
    const pending = orders.filter((o) => o.status === 'pending').length;
    const processing = orders.filter((o) =>
      ['pickingUp', 'pickedUp', 'delivering'].includes(o.status),
    ).length;
    const delivered = orders.filter((o) => o.status === 'delivered').length;
    const cancelled = orders.filter((o) => o.status === 'cancelled').length;

    const deliveredOrders = orders.filter((o) => o.status === 'delivered');
    const totalRevenue = deliveredOrders.reduce(
      (sum, o) => sum + Number(o.totalAmount ?? 0),
      0,
    );

    const averageOrderValue = delivered > 0 ? totalRevenue / delivered : 0;
    const completionRate =
      delivered + cancelled > 0
        ? (delivered / (delivered + cancelled)) * 100
        : 0;

    const firstOrder =
      orders.length > 0
        ? orders[orders.length - 1].createdAt ?? null
        : null;
    const lastOrder = orders.length > 0 ? orders[0].createdAt ?? null : null;

    return {
      totalOrders: orders.length,
      pending,
      processing,
      delivered,
      cancelled,
      totalRevenue,
      averageOrderValue,
      completionRate,
      firstOrder,
      lastOrder,
    };
  }
}