import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class CreateDriverDto {
  @IsString()
  username: string;

  @IsString()
  password: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;
}

export class LoginDriverDto {
  @IsString()
  username: string;

  @IsString()
  password: string;
}
