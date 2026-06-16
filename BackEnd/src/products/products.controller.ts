import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  Body,
  NotFoundException,
  ParseIntPipe,
  UseInterceptors,
  UploadedFile,
  Res,
  Logger,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import type { Response } from 'express';
import { ProductsService } from './products.service.js';
import { CreateProductDto } from './dto/create-product.dto.js';
import { SupabaseService } from '../supabase/supabase.service.js';

const uploadDir = join(process.cwd(), 'uploads');
if (!existsSync(uploadDir)) {
  mkdirSync(uploadDir, { recursive: true });
}

const PRODUCT_BUCKET = 'product-images';

@Controller('products')
export class ProductsController {
  private readonly logger = new Logger(ProductsController.name);

  constructor(
    private readonly productsService: ProductsService,
    private readonly supabaseService: SupabaseService,
  ) {}

  @Get()
  findAll() {
    return this.productsService.findAll();
  }

  @Get('uploads/:filename')
  serveFile(@Param('filename') filename: string, @Res() res: Response) {
    const filePath = join(uploadDir, filename);
    if (existsSync(filePath)) {
      return res.sendFile(filePath);
    }
    return res.status(404).json({ message: 'File not found' });
  }

  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const product = await this.productsService.findOne(id);
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  @Get('low-stock')
  getLowStockProducts() {
    return this.productsService.getLowStockProducts();
  }

  @Get(':id/rop')
  async getProductROP(@Param('id', ParseIntPipe) id: number) {
    const result = await this.productsService.getProductROPDetails(id);
    if (!result) throw new NotFoundException('Product not found');
    return result;
  }

  @Patch(':id/rop-config')
  async updateROPConfig(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { leadTime?: number; safetyStock?: number },
  ) {
    const product = await this.productsService.updateROPConfig(id, body);
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  @Post()
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: uploadDir,
        filename: (req, file, cb) => {
          const uniqueSuffix =
            Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          cb(null, `${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|gif|webp)$/)) {
          return cb(new Error('Only image files are allowed'), false);
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async create(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: Record<string, any>,
  ) {
    let imageUrl = body.imageUrl || '';

    if (file) {
      // Try Supabase upload first; fall back to local URL if not configured.
      const supabaseUrl = await this.uploadToSupabase(file);
      if (supabaseUrl) {
        imageUrl = supabaseUrl;
        this.logger.log(
          `[create] Uploaded ${file.filename} to Supabase: ${supabaseUrl}`,
        );
      } else {
        const publicBase = (
          process.env.PUBLIC_URL || 'http://localhost:3000'
        ).replace(/\/+$/, '');
        imageUrl = `${publicBase}/products/uploads/${file.filename}`;
        this.logger.warn(
          `[create] Supabase upload failed for ${file.filename}; falling back to local URL`,
        );
      }
    }

    const dto: CreateProductDto = {
      name: body.name,
      price: parseFloat(body.price) || 0,
      stock: parseInt(body.stock, 10) || 0,
      unit: body.unit || 'Piece',
      description: body.description || '',
      category: body.category || '',
      imageUrl,
    };

    return this.productsService.create(dto);
  }

  @Put(':id')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: uploadDir,
        filename: (req, file, cb) => {
          const uniqueSuffix =
            Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          cb(null, `${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|gif|webp)$/)) {
          return cb(new Error('Only image files are allowed'), false);
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async update(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
    @Body() body: Record<string, any>,
  ) {
    const dto: Partial<CreateProductDto> = {};

    if (body.name !== undefined) dto.name = body.name;
    if (body.price !== undefined) dto.price = parseFloat(body.price);
    if (body.stock !== undefined) dto.stock = parseInt(body.stock, 10);
    if (body.unit !== undefined) dto.unit = body.unit;
    if (body.description !== undefined) dto.description = body.description;
    if (body.category !== undefined) dto.category = body.category;
    if (body.rating !== undefined) dto.rating = parseFloat(body.rating);
    if (body.sold !== undefined) dto.sold = parseInt(body.sold, 10);
    if (body.seller !== undefined) dto.seller = body.seller;
    if (body.sellerCity !== undefined) dto.sellerCity = body.sellerCity;

    if (file) {
      const supabaseUrl = await this.uploadToSupabase(file);
      if (supabaseUrl) {
        dto.imageUrl = supabaseUrl;
        this.logger.log(
          `[update] Uploaded ${file.filename} to Supabase: ${supabaseUrl}`,
        );
      } else {
        const publicBase = (
          process.env.PUBLIC_URL || 'http://localhost:3000'
        ).replace(/\/+$/, '');
        dto.imageUrl = `${publicBase}/products/uploads/${file.filename}`;
        this.logger.warn(
          `[update] Supabase upload failed for ${file.filename}; falling back to local URL`,
        );
      }
    }

    const product = await this.productsService.update(id, dto);
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  @Delete(':id')
  async remove(@Param('id', ParseIntPipe) id: number) {
    const deleted = await this.productsService.remove(id);
    if (!deleted) throw new NotFoundException('Product not found');
    return { message: 'Product deleted' };
  }

  /**
   * Upload an uploaded product image to Supabase Storage. Returns the public
   * URL on success, or null if Supabase is not configured / upload fails.
   * The caller should fall back to the local /uploads/ URL in that case.
   */
  private async uploadToSupabase(
    file: Express.Multer.File,
  ): Promise<string | null> {
    if (!this.supabaseService.isEnabled()) {
      return null;
    }
    try {
      const buffer = await import('fs/promises').then((m) =>
        m.readFile(file.path),
      );
      return await this.supabaseService.uploadFile(
        PRODUCT_BUCKET,
        file.filename,
        buffer,
      );
    } catch (e) {
      this.logger.error(
        `uploadToSupabase failed for ${file.filename}: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
      return null;
    }
  }
}
