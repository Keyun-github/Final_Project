import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module.js';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { IoAdapter } from '@nestjs/platform-socket.io';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Trust proxy headers (X-Forwarded-*) from Dokploy load balancer
  app.set('trust proxy', 1);

  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads',
  });

  // Cors perlu di perbaiki
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  app.useWebSocketAdapter(new IoAdapter(app));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  const port = process.env.PORT ?? 3000;
  const publicUrl = process.env.PUBLIC_URL || `http://localhost:${port}`;
  const isProd = process.env.NODE_ENV === 'production';

  await app.listen(port);

  // Production-friendly logs (no sensitive info, no localhost hardcoded)
  if (!isProd) {
    console.log(`🚀 Backend API running at ${publicUrl}`);
    console.log(
      `📦 Database: ${process.env.DB_NAME || 'kelun_db'}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}`,
    );
    console.log(`🔌 WebSocket running at ${publicUrl}/driver-location`);
  } else {
    console.log(`🚀 Backend started on port ${port} (${process.env.NODE_ENV})`);
  }
}
bootstrap();
