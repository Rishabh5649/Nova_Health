import { SetMetadata } from '@nestjs/common';
export const ROLES_KEY = 'roles';
export const Roles = (...roles: Array<'PATIENT'|'DOCTOR'|'ADMIN'>) => SetMetadata(ROLES_KEY, roles);
