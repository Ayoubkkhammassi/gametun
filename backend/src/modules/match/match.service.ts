import { Injectable } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  compatibilityScore,
  MatchCriteria,
} from '../smart-match/compatibility';
import { SearchMatchDto } from './dto/search-match.dto';

export interface RankedPlayer {
  id: string;
  pseudo: string;
  avatarUrl: string | null;
  level: string;
  region: string;
  language: string;
  compatibility: number;
  games: string[];
}

@Injectable()
export class MatchService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  /**
   * Cherche des joueurs compatibles (Smart Match) et propose une équipe.
   */
  async search(userId: string, dto: SearchMatchDto) {
    // Utilisateurs bloqués (dans les deux sens) — à exclure.
    const blocks = await this.prisma.blockedUser.findMany({
      where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
      select: { blockerId: true, blockedId: true },
    });
    const excluded = new Set<string>([userId]);
    for (const b of blocks) {
      excluded.add(b.blockerId);
      excluded.add(b.blockedId);
    }

    // Candidats : comptes actifs jouant à au moins un des jeux demandés.
    const candidates = await this.prisma.user.findMany({
      where: {
        status: 'ACTIVE',
        id: { notIn: [...excluded] },
        games: { some: { game: { slug: { in: dto.gameSlugs } } } },
      },
      include: {
        profile: true,
        games: { include: { game: { select: { slug: true } } } },
      },
      take: 100,
    });

    const criteria: MatchCriteria & { region?: string } = {
      gameSlugs: dto.gameSlugs,
      level: dto.level,
      language: dto.language,
      availabilityFrom: dto.availabilityFrom,
      availabilityTo: dto.availabilityTo,
    };

    const ranked: RankedPlayer[] = candidates
      .map((c) => {
        const gameSlugs = c.games.map((g) => g.game.slug);
        const score = compatibilityScore(criteria, {
          gameSlugs,
          level: c.profile?.level ?? 'BEGINNER',
          language: c.language,
          region: c.region,
          availabilityFrom: c.profile?.availabilityFrom,
          availabilityTo: c.profile?.availabilityTo,
        });
        return {
          id: c.id,
          pseudo: c.pseudo,
          avatarUrl: c.avatarUrl,
          level: c.profile?.level ?? 'BEGINNER',
          region: c.region,
          language: c.language,
          compatibility: score,
          games: gameSlugs,
        };
      })
      .sort((a, b) => b.compatibility - a.compatibility);

    const teamSize = Math.max(1, (dto.players ?? 4) - 1); // -1 = l'utilisateur
    const proposedTeam = ranked.slice(0, teamSize);
    const averageCompatibility =
      proposedTeam.length > 0
        ? Math.round(
            proposedTeam.reduce((s, p) => s + p.compatibility, 0) /
              proposedTeam.length,
          )
        : 0;

    return {
      results: ranked.slice(0, 20),
      proposedTeam,
      averageCompatibility,
      totalFound: ranked.length,
    };
  }

  /** L'utilisateur accepte un joueur proposé → enregistre l'intérêt + notifie. */
  async accept(userId: string, targetId: string) {
    if (userId === targetId) {
      return { matched: false };
    }
    await this.prisma.socialAction.upsert({
      where: { actorId_targetId: { actorId: userId, targetId } },
      update: { type: 'LIKE' },
      create: { actorId: userId, targetId, type: 'LIKE' },
    });

    await this.notifications.create({
      userId: targetId,
      type: NotificationType.CONNECTION_REQUEST,
      title: 'Nouvelle demande de coéquipier',
      body: 'Un joueur souhaite faire équipe avec toi.',
      data: { fromUserId: userId },
    });
    return { accepted: true };
  }

  /** L'utilisateur passe un joueur proposé. */
  async pass(userId: string, targetId: string) {
    await this.prisma.socialAction.upsert({
      where: { actorId_targetId: { actorId: userId, targetId } },
      update: { type: 'PASS' },
      create: { actorId: userId, targetId, type: 'PASS' },
    });
    return { passed: true };
  }
}
