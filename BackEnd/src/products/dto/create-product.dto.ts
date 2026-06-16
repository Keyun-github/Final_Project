import {
  IsString,
  IsNumber,
  IsInt,
  IsOptional,
  IsArray,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateVariantDto {
  @IsString()
  unitName: string;

  @IsNumber()
  price: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  stock?: number;
}

export class CreateProductDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  price: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsNumber()
  rating?: number;

  @IsOptional()
  @IsNumber()
  sold?: number;

  @IsOptional()
  @IsString()
  seller?: string;

  @IsOptional()
  @IsString()
  sellerCity?: string;

  @IsOptional()
  @IsNumber()
  stock?: number;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateVariantDto)
  variants?: CreateVariantDto[];
}
