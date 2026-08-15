import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RateDto } from './dto/rate.dto';

@Injectable()
export class ReputationService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Enregistre une évaluation et recalcule la réputation moyenne.
   * Anti-abus : unicité (rater, rated, contexte) + interdiction de s'auto-noter.
   */
  async rate(raterId: string, dto: RateDto) {
    if (raterId === dto.ratedUserId) {
      throw new BadRequestException('Impossible de s\'auto-évaluer');
    }

    // Vérifie qu'un vrai lien existe (squad commune ou match) pour ce contexte.
    const legit = await this.hasSharedContext(raterId, dto.ratedUserId);
    if (!legit) {
      throw new BadRequestException(
        'Évaluation autorisée seulement après une interaction réelle',
      );
    }

    try {
      await this.prisma.reputation.create({
        data: {
          raterId,
          ratedUserId: dto.ratedUserId,
          context: dto.context,
          cooperation: dto.cooperation,
          respect: dto.respect,
          teamSpirit: dto.teamSpirit,
        },
      });
    } catch {
      throw new ConflictException('Tu as déjà évalué ce joueur pour ce contexte');
    }

    await this.recompute(dto.ratedUserId);
    return { rated: true };
  }

  /** Recalcule la réputation moyenne (0..5) et la dénormalise sur le profil. */
  private async recompute(userId: string) {
    const ratings = await this.prisma.reputation.findMany({
      where: { ratedUserId: userId },
      select: { cooperation: true, respect: true, teamSpirit: true },
    });
    if (ratings.length === 0) return;

    const total = ratings.reduce(
      (sum, r) => sum + (r.cooperation + r.respect + r.teamSpirit) / 3,
      0,
    );
    const avg = total / ratings.length;

    await this.prisma.profile.update({
      where: { userId },
      data: {
        reputationScore: Math.round(avg * 100) / 100,
        reputationCount: ratings.length,
      },
    });
  }

  /** Existe-t-il une squad commune ou un match entre les deux utilisateurs ? */
  private async hasSharedContext(a: string, b: string): Promise<boolean> {
    const [match, squad] = await this.prisma.$transaction([
      this.prisma.match.findFirst({
        where: {
          OR: [
            { userAId: a, userBId: b },
            { userAId: b, userBId: a },
          ],
        },
        select: { id: true },
      }),
      this.prisma.squad.findFirst({
        where: {
          members: { some: { userId: a } },
          AND: { members: { some: { userId: b } } },
        },
        select: { id: true },
      }),
    ]);
    return !!match || !!squad;
  }
}
