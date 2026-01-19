import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { Role } from '@prisma/client';

type JwtPayload = {
  sub: string;
  email: string;
  role: 'PATIENT' | 'DOCTOR' | 'ADMIN';
};

@Injectable()
export class AuthService {
  constructor(private users: UsersService, private jwt: JwtService) { }

  private toPublicUser(u: any) {
    return {
      id: u.id,
      email: u.email,
      role: u.role,
      name: u.name,
      memberships: u.memberships, // Include memberships in public user object
    };
  }

  /**
   * Internal helper that signs the JWT.
   * JwtModule.register(...) in your module should configure secret + expiresIn.
   */
  private sign(sub: string, email: string, role: Role) {
    const payload: JwtPayload = {
      sub,
      email,
      role: (role as unknown) as JwtPayload['role'],
    };
    return this.jwt.signAsync(payload);
  }

  /**
   * Register a new user.
   * - Ensures unique email.
   * - Hashes password.
   * - Returns { token, user }
   */
  async register(
    name: string,
    email: string,
    password: string,
    role: Role,
    phone?: string,
  ) {
    if (role === 'DOCTOR') {
      throw new BadRequestException(
        'Doctors cannot register publicly. Please contact your organization admin.',
      );
    }

    const existing = await this.users.findByEmail(email);
    if (existing) {
      throw new BadRequestException('Email already registered');
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await this.users.createUser({
      name,
      email,
      password: hashedPassword,
      role, // This will be PATIENT or ADMIN (if allowed), but mostly PATIENT
      phone,
    });

    return {
      token: await this.sign(user.id, user.email, user.role),
      user: this.toPublicUser(user),
    };
  }

  /**
   * Login with email + password.
   * - Returns { token, user }
   */
  async login(email: string, password: string) {
    console.log(`Login attempt for: ${email}`);
    const user = await this.users.findByEmail(email);
    if (!user) {
      console.log(`User not found: ${email}`);
      throw new UnauthorizedException('Invalid credentials');
    }

    const ok = await bcrypt.compare(password, user.password).catch(() => false);
    if (!ok) {
      console.log(`Password mismatch for: ${email}`);
      throw new UnauthorizedException('Invalid credentials');
    }

    // If doctor, ensure verificationStatus is APPROVED before allowing login
    // EXCEPTION: If they are an ORG_ADMIN or RECEPTIONIST (who share the DOCTOR global role), 
    // they might not have a doctor profile, so we skip this check.
    if (user.role === 'DOCTOR') {
      const memberships = (user as any).memberships || [];
      const isAdminOrStaff = memberships.some((m: any) => m.role === 'ORG_ADMIN' || m.role === 'RECEPTIONIST');

      if (!isAdminOrStaff) {
        const status = await this.users.getDoctorVerificationStatus(user.id).catch(
          () => null,
        );
        if (!status || status.verificationStatus !== 'APPROVED') {
          console.log(`Doctor not approved: ${email}`);
          throw new UnauthorizedException(
            'Doctor account is pending admin approval',
          );
        }
      }
    }

    // Check if user has any organization memberships
    // If they do, ensure at least one is APPROVED
    const userWithMemberships = await this.users.findUserWithMemberships(user.id);
    if (userWithMemberships?.memberships && userWithMemberships.memberships.length > 0) {
      const hasApprovedMembership = userWithMemberships.memberships.some(
        (m: any) => m.status === 'APPROVED'
      );

      if (!hasApprovedMembership) {
        console.log(`User has no approved memberships: ${email}`);
        throw new UnauthorizedException(
          'Your account is pending organization admin approval. Please contact your organization administrator.',
        );
      }
    }

    console.log(`Login successful for: ${email}`);
    return {
      token: await this.sign(user.id, user.email, user.role),
      user: this.toPublicUser(userWithMemberships || user),
    };
  }

  /**
   * Forgot password (email-based).
   * - If UsersService has beginPasswordReset(email), call it.
   * - Otherwise return generic message (prevents user enumeration).
   */
  async forgotPassword(email: string) {
    // Try fetch user; ignore errors to avoid leaking existence
    const user = await this.users.findByEmail(email).catch(() => null);

    const svc: any = this.users as any;
    if (user && typeof svc.beginPasswordReset === 'function') {
      await svc.beginPasswordReset(email);
      return { message: 'If that email exists, a reset link has been sent.' };
    }

    // Generic response (safe default)
    return { message: 'If that email exists, a reset link has been sent.' };
  }
}
