import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) { }

  /**
   * Create a new user.
   * NOTE: `password` MUST be ALREADY hashed (AuthService handles hashing).
   * Signature stays compatible with AuthService.register().
   */
  async createUser(params: {
    name: string;
    email: string;
    password: string; // hashed password
    role: Role;
    phone?: string;
  }) {
    const { name, email, password, role, phone } = params;

    // Optional defensive check — DB should also enforce unique email
    // If you prefer to keep this in AuthService only, you can remove this block.
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new BadRequestException('Email already registered');
    }

    const user = await this.prisma.user.create({
      data: {
        name,
        email,
        password, // store hashed password
        role,
        phone: phone ?? null,
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phone: true,
        createdAt: true,
        memberships: {
          include: {
            organization: {
              select: { id: true, name: true, type: true }
            }
          }
        }
      },
    });

    return user;
  }

  /**
   * For login: find by email and return hashed password so we can compare.
   */
  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        name: true,
        email: true,
        password: true, // needed for bcrypt.compare
        role: true,
        phone: true,
        createdAt: true,
        memberships: {
          include: {
            organization: {
              select: { id: true, name: true, type: true }
            }
          }
        }
      },
    });
  }

  /**
   * Optional helper (if you need it elsewhere).
   */
  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phone: true,
        createdAt: true,
        memberships: {
          include: {
            organization: {
              select: { id: true, name: true, type: true }
            }
          }
        }
      },
    });
  }

  /**
   * OPTIONAL for future: update password (expects ALREADY HASHED password).
   * Useful when you implement a real forgot/reset password flow.
   */
  async updatePassword(userId: string, hashedPassword: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
      select: {
        id: true,
        email: true,
        role: true,
        updatedAt: true,
      },
    });
  }

  /**
   * OPTIONAL for future: phone-based lookup (if you add phone login later).
   * If `phone` is unique in your Prisma model, switch to findUnique.
   */
  async findByPhone(phone: string) {
    if (!phone) return null;
    return this.prisma.user.findFirst({
      where: { phone },
      select: {
        id: true,
        name: true,
        email: true,
        password: true, // include if you plan password-based phone login; remove if OTP-only
        role: true,
        phone: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' }, // remove if you don't have createdAt
    });
  }

  /**
   * Fetch a doctor's verificationStatus by userId.
   * Returns null if no Doctor profile exists yet.
   */
  async getDoctorVerificationStatus(userId: string) {
    return this.prisma.doctor.findUnique({
      where: { userId },
      select: { verificationStatus: true },
    });
  }

  /**
   * Find user with full membership details including approval status
   */
  /**
   * Find user with full membership details including approval status
   */
  async findUserWithMemberships(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phone: true,
        createdAt: true,
        memberships: {
          include: {
            organization: {
              select: { id: true, name: true, type: true }
            }
          }
        }
      },
    });
  }

  /**
   * Find all users, optionally filtered by role.
   */
  async findAll(role?: Role) {
    return this.prisma.user.findMany({
      where: role ? { role } : {},
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phone: true,
        createdAt: true,
        memberships: {
          include: {
            organization: {
              select: { id: true, name: true }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
