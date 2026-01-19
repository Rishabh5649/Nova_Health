import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export type JwtUser = { sub: string; email: string; role: 'PATIENT' | 'DOCTOR' | 'ADMIN' | 'RECEPTIONIST' };

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtUser | undefined => {
    const req = ctx.switchToHttp().getRequest();
    return req.user as JwtUser | undefined;
  },
);
