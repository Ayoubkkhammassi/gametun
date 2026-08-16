import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import { loadConfiguration } from './config/configuration';
import { PrismaModule } from './prisma/prisma.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { PrismaExceptionFilter } from './common/prisma-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';

import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { GamesModule } from './modules/games/games.module';
import { HealthModule } from './modules/health/health.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { MatchModule } from './modules/match/match.module';
import { SocialModule } from './modules/social/social.module';
import { ChatModule } from './modules/chat/chat.module';
import { SquadsModule } from './modules/squads/squads.module';
import { ModerationModule } from './modules/moderation/moderation.module';
import { PremiumModule } from './modules/premium/premium.module';
import { StatisticsModule } from './modules/statistics/statistics.module';
import { ReputationModule } from './modules/reputation/reputation.module';
import { MinigamesModule } from './modules/minigames/minigames.module';
import { GameSessionModule } from './modules/game-session/game-session.module';
import { AdminModule } from './modules/admin/admin.module';
import { AppUpdateModule } from './modules/app-update/app-update.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      load: [loadConfiguration],
    }),
    // Rate limiting global (anti-spam, spec §17/§22).
    ThrottlerModule.forRoot([
      {
        ttl: Number(process.env.THROTTLE_TTL_MS ?? 60_000),
        limit: Number(process.env.THROTTLE_LIMIT ?? 120),
      },
    ]),
    PrismaModule,
    NotificationsModule, // global — utilisé par plusieurs modules

    // Modules métier (spec §18).
    AuthModule,
    UsersModule,
    ProfilesModule,
    GamesModule,
    MatchModule,
    SocialModule,
    ChatModule,
    SquadsModule,
    StatisticsModule,
    ReputationModule,
    ModerationModule,
    MinigamesModule,
    GameSessionModule,
    PremiumModule,
    AdminModule,
    AppUpdateModule,
    HealthModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: TransformInterceptor },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_FILTER, useClass: PrismaExceptionFilter },
  ],
})
export class AppModule {}
