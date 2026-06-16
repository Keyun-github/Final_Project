import { IsString, IsOptional, IsNotEmpty } from 'class-validator';

export class CreateCustomerDto {
  @IsString()
  @IsNotEmpty()
  name!: string;
  @IsString()
  @IsNotEmpty()
  username!: string;
  @IsString()
  @IsNotEmpty()
  phone!: string;
  @IsString()
  @IsNotEmpty()
  password!: string;
  @IsOptional()
  @IsString()
  address?: string;
}

export class LoginCustomerDto {
  @IsString()
  @IsNotEmpty()
  usernameOrPhone!: string;
  @IsString()
  @IsNotEmpty()
  password!: string;}
