import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './product.entity.js';
import { ProductVariant } from './product-variant.entity.js';
import { CreateProductDto } from './dto/create-product.dto.js';
import { Order } from '../orders/order.entity.js';
import { OrderItem } from '../orders/order-item.entity.js';
import { ProductsGateway } from './products.gateway.js';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(ProductVariant)
    private readonly variantRepo: Repository<ProductVariant>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    private readonly productsGateway: ProductsGateway,
  ) {}

  async findAll(): Promise<Product[]> {
    return this.productRepo.find({ order: { id: 'ASC' } });
  }

  async findOne(id: number): Promise<Product | null> {
    return this.productRepo.findOne({ where: { id } });
  }

  async create(
    dto: CreateProductDto,
  ): Promise<{ action: 'created' | 'updated'; product: Product }> {
    // Check if product with same name already exists
    const existing = await this.productRepo.findOne({
      where: { name: dto.name },
      relations: ['variants'],
    });

    if (existing) {
      // Merge: Add unit as a new variant if it doesn't exist
      const existingVariant = existing.variants?.find(
        (v) => v.unitName.toLowerCase() === (dto.unit ?? 'Piece').toLowerCase(),
      );

      if (existingVariant) {
        // Update existing variant's price
        existingVariant.price = dto.price;
        await this.variantRepo.save(existingVariant);

        // Replace main product price with new price, add stock
        existing.price = dto.price;
        existing.stock = (existing.stock ?? 0) + (dto.stock ?? 0);
        if (dto.imageUrl && !existing.imageUrl) {
          existing.imageUrl = dto.imageUrl;
        }
        if (dto.description && !existing.description) {
          existing.description = dto.description;
        }
        const saved = await this.productRepo.save(existing);
        this.productsGateway.broadcastProductUpdated(saved);
        return { action: 'updated', product: saved };
      } else {
        // Add new variant
        const newVariant = this.variantRepo.create({
          unitName: dto.unit ?? 'Piece',
          price: dto.price,
          product: existing,
        });
        await this.variantRepo.save(newVariant);

        // Update main product price and stock
        existing.price = dto.price;
        existing.stock = (existing.stock ?? 0) + (dto.stock ?? 0);
        existing.variants.push(newVariant);

        const saved = await this.productRepo.save(existing);
        this.productsGateway.broadcastProductUpdated(saved);
        return { action: 'updated', product: saved };
      }
    } else {
      // Create new product with first variant
      const product = this.productRepo.create({
        name: dto.name,
        description: dto.description ?? '',
        price: dto.price,
        imageUrl: dto.imageUrl ?? '',
        category: dto.category ?? '',
        rating: dto.rating ?? 0,
        sold: dto.sold ?? 0,
        seller: dto.seller ?? '',
        sellerCity: dto.sellerCity ?? '',
        stock: dto.stock ?? 0,
        unit: dto.unit ?? 'Piece',
        variants: [
          this.variantRepo.create({
            unitName: dto.unit ?? 'Piece',
            price: dto.price,
          }),
        ],
      });
      const saved = await this.productRepo.save(product);
      this.productsGateway.broadcastProductCreated(saved);
      return { action: 'created', product: saved };
    }
  }

  async update(
    id: number,
    dto: Partial<CreateProductDto>,
  ): Promise<Product | null> {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) return null;

    Object.assign(product, {
      ...(dto.name !== undefined && { name: dto.name }),
      ...(dto.description !== undefined && { description: dto.description }),
      ...(dto.price !== undefined && { price: dto.price }),
      ...(dto.imageUrl !== undefined && { imageUrl: dto.imageUrl }),
      ...(dto.category !== undefined && { category: dto.category }),
      ...(dto.rating !== undefined && { rating: dto.rating }),
      ...(dto.sold !== undefined && { sold: dto.sold }),
      ...(dto.seller !== undefined && { seller: dto.seller }),
      ...(dto.sellerCity !== undefined && { sellerCity: dto.sellerCity }),
      ...(dto.stock !== undefined && { stock: dto.stock }),
      ...(dto.unit !== undefined && { unit: dto.unit }),
    });

    if (dto.variants !== undefined) {
      // Remove old variants and replace
      await this.variantRepo.delete({ product: { id } });
      product.variants = dto.variants.map((v) =>
        this.variantRepo.create({ unitName: v.unitName, price: v.price }),
      );
    }

    const saved = await this.productRepo.save(product);
    this.productsGateway.broadcastProductUpdated(saved);
    return saved;
  }

  async remove(id: number): Promise<boolean> {
    const result = await this.productRepo.delete(id);
    if ((result.affected ?? 0) > 0) {
      this.productsGateway.broadcastProductDeleted(id);
      return true;
    }
    return false;
  }

  async getLowStockProducts(): Promise<Product[]> {
    const allProducts = await this.findAll();
    return allProducts.filter((p) => this.needsReorder(p));
  }

  async getProductROPDetails(id: number): Promise<any> {
    const product = await this.findOne(id);
    if (!product) return null;

    const avgDailySales = await this.calculateAvgDailySales(product.name);
    const rop = this.calculateROP(product.leadTime, product.safetyStock, avgDailySales);

    return {
      productId: product.id,
      productName: product.name,
      currentStock: product.stock,
      leadTime: product.leadTime,
      safetyStock: product.safetyStock,
      avgDailySales: Math.round(avgDailySales * 100) / 100,
      reorderPoint: Math.round(rop * 100) / 100,
      needsReorder: product.stock <= rop,
    };
  }

  async updateROPConfig(
    id: number,
    dto: { leadTime?: number; safetyStock?: number },
  ): Promise<Product | null> {
    const product = await this.findOne(id);
    if (!product) return null;

    if (dto.leadTime !== undefined) {
      product.leadTime = dto.leadTime;
    }
    if (dto.safetyStock !== undefined) {
      product.safetyStock = dto.safetyStock;
    }

    return this.productRepo.save(product);
  }

  calculateROP(leadTime: number, safetyStock: number, avgDailySales: number): number {
    return (leadTime * avgDailySales) + safetyStock;
  }

  needsReorder(product: Product): boolean {
    const leadTime = product.leadTime ?? 3;
    const safetyStock = product.safetyStock ?? 5;
    const stock = product.stock ?? 0;
    const sold = product.sold ?? 0;

    if (sold === 0) {
      return stock <= safetyStock;
    }

    if (sold < 7) {
      const rop = safetyStock + leadTime;
      return stock <= rop;
    }

    // Cap avgDailySales to avoid extreme ROP from high cumulative sales
    const avgDailySales = Math.min(sold / 7, 10);
    const rop = (leadTime * avgDailySales) + safetyStock;
    return stock <= rop;
  }

  async calculateAvgDailySales(productName: string): Promise<number> {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const orders = await this.orderItemRepo
      .createQueryBuilder('item')
      .innerJoin('item.order', 'order')
      .where('item.productName = :name', { name: productName })
      .andWhere('order.createdAt >= :date', { date: sevenDaysAgo })
      .andWhere('order.status = :status', { status: 'delivered' })
      .getMany();

    const totalSold = orders.reduce((sum, item) => sum + (item.quantity ?? 0), 0);
    return totalSold / 7;
  }

  async seed(): Promise<void> {
    const count = await this.productRepo.count();
    if (count > 0) return; // Already seeded

    const seedData: CreateProductDto[] = [
      {
        name: 'Gula Pasir Premium',
        description:
          'Gula pasir putih kualitas premium, cocok untuk kebutuhan masakan dan minuman sehari-hari.',
        price: 15000,
        imageUrl: 'https://awsimages.detik.net.id/community/media/visual/2015/09/02/0304cf7b-5d92-4636-8ccc-8fe21e13f881.jpg?w=600&q=90',
        category: 'Food & Drinks',
        rating: 4.8,
        sold: 21500,
        seller: 'Distributor Sembako',
        sellerCity: 'Jakarta',
        stock: 40,
        unit: 'KG',
        variants: [
          { unitName: 'KG', price: 15000 },
          { unitName: 'Sack 25KG', price: 360000 },
          { unitName: 'Sack 50KG', price: 710000 },
        ],
      },
      {
        name: 'Kopi Kapal Api Special',
        description:
          'Kopi bubuk instan dengan aroma yang khas dan nikmat, sangat cocok menemani pagi hari Anda.',
        price: 3500,
        imageUrl: 'https://secangkirsemangat.id/storage/products/155/01JCFZWEWQTQ0Y3GKABHSW1G8N.jpg',
        category: 'Food & Drinks',
        rating: 4.9,
        sold: 15420,
        seller: 'Kopi Nusantara',
        sellerCity: 'Surabaya',
        stock: 90,
        unit: 'Piece',
        variants: [
          { unitName: 'Piece', price: 3500 },
          { unitName: 'Box', price: 82000 },
        ],
      },
      {
        name: 'Wireless Bluetooth Earbuds Pro',
        description:
          'Premium wireless earbuds with active noise cancellation, 30-hour battery life, and IPX5 water resistance.',
        price: 299000,
        imageUrl: 'https://picsum.photos/seed/earbuds/400/400',
        category: 'Electronics',
        rating: 4.8,
        sold: 1250,
        seller: 'TechStore Official',
        sellerCity: 'Jakarta',
        stock: 50,
        unit: 'Piece',
      },
      {
        name: 'Kaos Polos Katun Premium',
        description:
          'Kaos polos bahan katun combed 30s yang adem dan nyaman dipakai sehari-hari.',
        price: 89000,
        imageUrl: 'https://picsum.photos/seed/tshirt/400/400',
        category: 'Fashion',
        rating: 4.6,
        sold: 5420,
        seller: 'Fashion House',
        sellerCity: 'Bandung',
        stock: 100,
        unit: 'Piece',
      },
      {
        name: 'Sepatu Running Ultralight',
        description:
          'Sepatu olahraga ultralight dengan sol empuk untuk kenyamanan maksimal saat berlari.',
        price: 459000,
        imageUrl: 'https://picsum.photos/seed/shoes/400/400',
        category: 'Fashion',
        rating: 4.7,
        sold: 890,
        seller: 'Sport Zone',
        sellerCity: 'Surabaya',
        stock: 30,
        unit: 'Piece',
      },
      {
        name: 'Tas Ransel Anti Air 30L',
        description:
          'Tas ransel kapasitas 30L dengan bahan anti air, cocok untuk sekolah, kuliah, atau travelling.',
        price: 175000,
        imageUrl: 'https://picsum.photos/seed/backpack/400/400',
        category: 'Fashion',
        rating: 4.5,
        sold: 3200,
        seller: 'Bag Corner',
        sellerCity: 'Yogyakarta',
        stock: 60,
        unit: 'Piece',
      },
      {
        name: 'Skincare Set Brightening',
        description:
          'Paket lengkap skincare untuk mencerahkan wajah: facial wash, toner, serum, moisturizer, dan sunscreen SPF50.',
        price: 249000,
        imageUrl: 'https://picsum.photos/seed/skincare/400/400',
        category: 'Health & Beauty',
        rating: 4.9,
        sold: 7800,
        seller: 'Beauty Official',
        sellerCity: 'Jakarta',
        stock: 80,
        unit: 'Piece',
      },
      {
        name: 'Mie Instan Premium Box (40 pcs)',
        description:
          'Mie instan premium dengan bumbu spesial. Tersedia rasa: Ayam Bawang, Soto, Kari Ayam, Goreng Spesial.',
        price: 120000,
        imageUrl: 'https://picsum.photos/seed/noodles/400/400',
        category: 'Food & Drinks',
        rating: 4.4,
        sold: 15000,
        seller: 'Grocery Mart',
        sellerCity: 'Semarang',
        stock: 200,
        unit: 'Box',
      },
      {
        name: 'Mechanical Keyboard RGB',
        description:
          'Keyboard mekanikal dengan switch Cherry MX, backlight RGB, dan keycap PBT doubleshot.',
        price: 550000,
        imageUrl: 'https://picsum.photos/seed/keyboard/400/400',
        category: 'Electronics',
        rating: 4.7,
        sold: 620,
        seller: 'TechStore Official',
        sellerCity: 'Jakarta',
        stock: 25,
        unit: 'Piece',
      },
      {
        name: 'Tumbler Stainless 750ml',
        description:
          'Tumbler premium bahan stainless steel, tahan panas/dingin hingga 12 jam. BPA-free dan food grade.',
        price: 135000,
        imageUrl: 'https://picsum.photos/seed/tumbler/400/400',
        category: 'Home & Living',
        rating: 4.6,
        sold: 2100,
        seller: 'Home Essentials',
        sellerCity: 'Bandung',
        stock: 75,
        unit: 'Piece',
      },
      {
        name: 'Phone Case Premium Leather',
        description:
          'Case HP bahan kulit premium dengan slot kartu. Cocok untuk iPhone dan Android flagship.',
        price: 99000,
        imageUrl: 'https://picsum.photos/seed/phonecase/400/400',
        category: 'Electronics',
        rating: 4.3,
        sold: 4500,
        seller: 'Gadget World',
        sellerCity: 'Jakarta',
        stock: 150,
        unit: 'Piece',
      },
      {
        name: 'Vitamin C 1000mg (30 Tablet)',
        description:
          'Suplemen vitamin C dosis tinggi untuk daya tahan tubuh. Aman dikonsumsi setiap hari.',
        price: 65000,
        imageUrl: 'https://picsum.photos/seed/vitamin/400/400',
        category: 'Health & Beauty',
        rating: 4.8,
        sold: 9200,
        seller: 'Health Plus',
        sellerCity: 'Surabaya',
        stock: 300,
        unit: 'Piece',
      },
      {
        name: 'Lampu LED Desk Lamp USB',
        description:
          'Lampu meja LED dengan pengaturan kecerahan 3 level. Port USB charging, hemat energi dan tahan lama.',
        price: 85000,
        imageUrl: 'https://picsum.photos/seed/desklamp/400/400',
        category: 'Home & Living',
        rating: 4.5,
        sold: 1800,
        seller: 'Home Essentials',
        sellerCity: 'Bandung',
        stock: 45,
        unit: 'Piece',
      },
      {
        name: 'Kopi Arabica Specialty 250g',
        description:
          'Biji kopi arabica specialty grade dari Toraja. Roast level: medium. Cupping score 85+.',
        price: 95000,
        imageUrl: 'https://picsum.photos/seed/coffee/400/400',
        category: 'Food & Drinks',
        rating: 4.9,
        sold: 6300,
        seller: 'Coffee Lab',
        sellerCity: 'Makassar',
        stock: 60,
        unit: 'Piece',
      },
    ];

    for (const data of seedData) {
      await this.create(data);
    }
  }
}
