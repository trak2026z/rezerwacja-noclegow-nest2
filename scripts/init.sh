#!/bin/bash
set -e

PROJECT="rezerwacja-noclegow-nest2"

# 1. Tworzymy projekt NestJS
npx @nestjs/cli new $PROJECT --package-manager npm -g

cd $PROJECT

# 2. Instalujemy zależności
npm i @nestjs/config @nestjs/mongoose mongoose
npm i @nestjs/swagger swagger-ui-express
npm i class-validator class-transformer
npm i @nestjs/jwt @nestjs/passport passport passport-jwt
npm i bcrypt
npm i -D @types/bcrypt

# 3. Tworzymy katalogi pomocnicze
mkdir -p src/config src/filters

# 4. Plik konfiguracyjny
cat > src/config/configuration.ts <<'EOF'
export default () => ({
  app: {
    port: parseInt(process.env.PORT ?? '3000', 10),
    nodeEnv: process.env.NODE_ENV ?? 'development',
  },
  mongo: {
    uri: process.env.MONGO_URI ?? 'mongodb://localhost:27017/bookings',
  },
  jwt: {
    secret: process.env.JWT_SECRET ?? 'dev_secret_change_me',
    expires: process.env.JWT_EXPIRES ?? '1d',
  },
});
EOF

# 5. Globalny filtr wyjątków
cat > src/filters/http-exception.filter.ts <<'EOF'
import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { MongoServerError } from 'mongodb';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    if (exception instanceof MongoServerError && (exception as any).code === 11000) {
      return response.status(HttpStatus.CONFLICT).json({
        statusCode: HttpStatus.CONFLICT,
        error: 'Conflict',
        message: 'Duplicate key error',
        timestamp: new Date().toISOString(),
        path: request.url,
      });
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const res = exception.getResponse();
      return response.status(status).json({
        statusCode: status,
        ...(typeof res === 'object' ? res : { message: res }),
        timestamp: new Date().toISOString(),
        path: request.url,
      });
    }

    return response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      error: 'InternalServerError',
      message: 'Unexpected error',
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
EOF

# 6. main.ts
cat > src/main.ts <<'EOF'
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { HttpExceptionFilter } from './filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());

  const config = new DocumentBuilder()
    .setTitle('Rezerwacja noclegów — API')
    .setDescription('API do rezerwacji noclegów w NestJS')
    .setVersion('0.0.1')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port);
  console.log(`API running on http://localhost:${port} | Swagger: /api`);
}
bootstrap();
EOF

# 7. app.module.ts
cat > src/app.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import configuration from './config/configuration';
import { MongooseModule } from '@nestjs/mongoose';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      envFilePath: ['.env', '.env.dev'],
    }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.get<string>('mongo.uri'),
      }),
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
EOF

# 8. app.controller.ts
cat > src/app.controller.ts <<'EOF'
import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { HealthResponseDto } from './common/dto/health-response.dto';


@ApiTags('App')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  @ApiOkResponse({ type: HealthResponseDto })
  health(): HealthResponseDto {
    return this.appService.health();
  }
}
EOF

# 9. app.service.ts
cat > src/app.service.ts <<'EOF'
import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  health() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }
}
EOF

# 10. .env.dev
cat > .env.dev <<'EOF'
PORT=3000
NODE_ENV=development
MONGO_URI=mongodb://mongo:27017/bookings
JWT_SECRET=dev_secret_change_me
JWT_EXPIRES=1d
EOF

# 11. Dockerfile.dev
cat > Dockerfile.dev <<'EOF'
FROM node:20-alpine

WORKDIR /usr/src/app
ENV CHOKIDAR_USEPOLLING=true

COPY package*.json ./
RUN npm ci

COPY nest-cli.json tsconfig*.json ./
COPY src ./src

RUN mkdir -p /app/dist && chown -R node:node /app
USER node

EXPOSE 3000
CMD ["npm", "run", "start:dev"]
EOF

# 12. docker-compose.dev.yml
cat > docker-compose.dev.yml <<'EOF'
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: booking_nest_api_dev
    env_file:
      - .env.dev
    ports:
      - '3000:3000'
    volumes:
      - ./:/usr/src/app
      - /usr/src/app/node_modules
    depends_on:
      - mongo
    restart: unless-stopped

  mongo:
    image: mongo:7
    container_name: booking_nest_db_dev
    ports:
      - '27017:27017'
    volumes:
      - mongo_data:/data/db
    command: ["mongod", "--quiet", "--logpath", "/dev/null", "--bind_ip_all"]
    restart: unless-stopped
volumes:
  mongo_data:
    name: booking_nest_mongo_data_dev
EOF

# 13. .dockerignore
cat > .dockerignore <<'EOF'
node_modules
npm-debug.log
dist
.git
.github
.vscode
.env
EOF

# 14. health-response.dto.ts
mkdir -p src/common src/common/dto

cat > health-response.dto.ts <<'EOF'
import { ApiProperty } from '@nestjs/swagger';

export class HealthResponseDto {
  @ApiProperty({ example: 'ok', description: 'Aktualny status aplikacji' })
  status: string;

  @ApiProperty({ example: '2025-09-21T16:10:00.000Z', description: 'Znacznik czasu w ISO8601' })
  timestamp: string;
}
EOF

echo "✅ Projekt $PROJECT gotowy. Uruchom:"
echo "   cd $PROJECT"
echo "   ./reset-dev.sh"