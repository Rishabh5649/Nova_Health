// src/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { JwtModule, JwtSignOptions } from '@nestjs/jwt';
import { UsersModule } from '../users/users.module';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';

// Accept either seconds (number) or strings like "7d", "12h", "30m", "45s"
type DurationString = `${number}${'s' | 'm' | 'h' | 'd'}`;

function resolveExpiresIn(): JwtSignOptions['expiresIn'] {
  const v = process.env.JWT_EXPIRES_IN;
  if (!v) return '7d'; // default

  // If user set a number of seconds (e.g., "604800"), use it as number
  const asNum = Number(v);
  if (Number.isFinite(asNum)) return asNum;

  // Otherwise assume a duration string like "7d", "12h"
  return v as DurationString;
}

@Module({
  imports: [
    UsersModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'dev-secret',
      signOptions: {
        expiresIn: resolveExpiresIn(), // <-- properly typed now
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [JwtModule],
})
export class AuthModule {}
