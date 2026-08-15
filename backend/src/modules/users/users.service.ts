import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { toPublicUser, toSelfUser } from '../../common/privacy.util';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  /** Profil complet du compte propriétaire (avec email, profil, stats, jeux). */
  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        statistics: true,
        games: { include: { game: true } },
        subscription: true,
      },
    });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }
    return {
      ...toSelfUser(user),
      profile: user.profile,
      statistics: user.statistics,
      games: user.games.map((ug) => ({
        id: ug.game.id,
        slug: ug.game.slug,
        name: ug.game.name,
        iconUrl: ug.game.iconUrl,
        level: ug.level,
        isFavorite: ug.isFavorite,
      })),
      isPremium: user.isPremium,
    };
  }

  /** Vue publique d'un joueur (sans données sensibles). */
  async getPublicProfile(userId: string, viewerId: string) {
    // On masque les utilisateurs bloqués dans les deux sens.
    const blocked = await this.prisma.blockedUser.findFirst({
      where: {
        OR: [
          { blockerId: viewerId, blockedId: userId },
          { blockerId: userId, blockedId: viewerId },
        ],
      },
    });
    if (blocked) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        statistics: true,
        games: { include: { game: true } },
      },
    });
    if (!user || user.status !== 'ACTIVE') {
      throw new NotFoundException('Utilisateur introuvable');
    }

    return {
      ...toPublicUser(user),
      profile: user.profile,
      statistics: user.statistics,
      games: user.games.map((ug) => ({
        id: ug.game.id,
        slug: ug.game.slug,
        name: ug.game.name,
        iconUrl: ug.game.iconUrl,
        level: ug.level,
      })),
    };
  }
}
