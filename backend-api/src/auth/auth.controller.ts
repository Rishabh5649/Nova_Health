import {
  Body,
  Controller,
  Post,
  BadRequestException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { Role } from '@prisma/client';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Register a new user.
   *
   * Body must include:
   * {
   *   "name": "Dr. Strange",
   *   "email": "dr@example.com",
   *   "password": "secret123",
   *   "role": "DOCTOR",        // or "PATIENT" | "ADMIN" | "RECEPTIONIST"
   *   "phone": "9999999999"    // optional
   * }
   */
  @Post('register')
  async register(
    @Body()
    body: {
      name: string;
      email: string;
      password: string;
      role: Role;
      phone?: string;
    },
  ) {
    if (!body.name || !body.email || !body.password || !body.role) {
      throw new BadRequestException(
        'name, email, password, and role are required',
      );
    }

    return this.authService.register(
      body.name,
      body.email,
      body.password,
      body.role,
      body.phone,
    );
  }

  /**
   * Login with email + password
   *
   * Body:
   * {
   *   "email": "dr@example.com",
   *   "password": "secret123"
   * }
   *
   * Returns: { token, user }
   */
  @Post('login')
  async login(
    @Body()
    body: {
      email: string;
      password: string;
    },
  ) {
    if (!body.email || !body.password) {
      throw new BadRequestException('email and password are required');
    }
    return this.authService.login(body.email, body.password);
  }

  /**
   * Forgot password (email-based)
   * Body:
   * { "email": "user@example.com" }
   *
   * Returns: { message: string }
   */
  @Post('forgot-password')
  async forgotPassword(@Body() body: { email: string }) {
    if (!body.email) {
      throw new BadRequestException('email is required');
    }
    return this.authService.forgotPassword(body.email);
  }
}
