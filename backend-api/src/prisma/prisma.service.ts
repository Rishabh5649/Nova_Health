// src/prisma/prisma.service.ts
import {
  Injectable,
  INestApplication,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Prisma service with lightweight event logging.
 *
 * Notes:
 * - Some Prisma versions produce tight TS types for $on event names.
 *   To avoid 'never' typing issues we cast event handlers to `any`.
 * - Set PRISMA_LOG_QUERIES=1 when running to print SQL queries.
 */
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    // cast `log` to any to avoid some TS narrowing problems across Prisma versions
    super({
      log: [
        { emit: 'event', level: 'query' },
        { emit: 'event', level: 'error' },
        { emit: 'event', level: 'warn' },
      ] as any,
    });
  }

  async onModuleInit() {
    // Use `any` for handlers so TS doesn't narrow the event union to `never`.
    // We still get the actual event objects at runtime.
    (this as any).$on('error', (e: any) => {
      // eslint-disable-next-line no-console
      console.error('[Prisma error]', e);
    });

    (this as any).$on('warn', (e: any) => {
      // eslint-disable-next-line no-console
      console.warn('[Prisma warn]', e);
    });

    const logQueries =
      (process.env.PRISMA_LOG_QUERIES ?? '').toLowerCase() === '1';
    if (logQueries) {
      (this as any).$on('query', (e: any) => {
        // eslint-disable-next-line no-console
        console.log('[Prisma query]', e.query, e.params);
      });
    }

    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  /**
   * Optional: call from main.ts so Prisma and Nest shut down cleanly.
   *
   * Example:
   *   const app = await NestFactory.create(AppModule);
   *   const prisma = app.get(PrismaService);
   *   prisma.enableShutdownHooks(app);
   */
  enableShutdownHooks(app: INestApplication) {
    const shutdown = async () => {
      try {
        await this.$disconnect();
      } catch {
        /* ignore */
      }
      try {
        await app.close();
      } catch {
        /* ignore */
      }
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
  }
}
