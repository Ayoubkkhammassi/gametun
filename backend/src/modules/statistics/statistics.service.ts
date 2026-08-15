import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Agrège les statistiques réelles de l'utilisateur (spec §13). */
  async getFor(userId: string) {
    const [stats, connections, squads, favoriteGames, reputation] =
      await this.prisma.$transaction([
        this.prisma.statistics.findUnique({ where: { userId } }),
        this.prisma.match.count({
          where: { OR: [{ userAId: userId }, { userBId: userId }] },
        }),
        this.prisma.squadMember.count({ where: { userId } }),
        this.prisma.userGame.findMany({
          where: { userId },
          include: { game: { select: { slug: true, name: true } } },
          take: 5,
        }),
        this.prisma.profile.findUnique({
          where: { userId },
          select: { reputationScore: true, reputationCount: true },
        }),
      ]);

    const matchesPlayed = stats?.matchesPlayed ?? 0;
    const wins = stats?.wins ?? 0;
    const winRate = matchesPlayed > 0 ? Math.round((wins / matchesPlayed) * 100) : 0;

    return {
      matchesPlayed,
      winRate,
      connections,
      squadsJoined: squads,
      hoursPlayed: stats?.hoursPlayed ?? 0,
      kdRatio: stats?.kdRatio ?? 0,
      favoriteGames: favoriteGames.map((g) => g.game),
      reputation: {
        score: reputation?.reputationScore ?? 0,
        count: reputation?.reputationCount ?? 0,
      },
    };
  }
}
