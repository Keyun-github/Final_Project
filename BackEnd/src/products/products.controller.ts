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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import type { Response } from 'express';
import { ProductsService } from './products.service.js';
import { CreateProductDto } from './dto/create-product.dto.js';

const uploadDir = join(process.cwd(), 'uploads');
if (!existsSync(uploadDir)) {
  mkdirSync(uploadDir, { recursive: true });
}

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

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
    const publicBase = (process.env.PUBLIC_URL || 'http://localhost:3000').replace(/\/+$/, '');
    const imageUrl = file
      ? `${publicBase}/products/uploads/${file.filename}`
      : body.imageUrl || '';

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
      dto.imageUrl = `http://localhost:3000/products/uploads/${file.filename}`;
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
}
