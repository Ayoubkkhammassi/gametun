import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getMyProfile(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
    });
    if (!profile) {
      throw new NotFoundException('Profil introuvable');
    }
    return profile;
  }

  async updateMyProfile(userId: string, dto: UpdateProfileDto) {
    const { avatarUrl, favoriteGameSlugs, funFacts, ...profileData } = dto;

    // Met à jour l'avatar sur le compte utilisateur si fourni.
    if (avatarUrl !== undefined) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { avatarUrl },
      });
    }

    // Synchronise les jeux favoris si fournis.
    if (favoriteGameSlugs) {
      await this.syncFavoriteGames(userId, favoriteGameSlugs);
    }

    // funFacts est un champ JSON : cast explicite pour Prisma.
    const data: Prisma.ProfileUpdateInput = { ...profileData };
    if (funFacts !== undefined) {
      data.funFacts = funFacts as unknown as Prisma.InputJsonValue;
    }

    return this.prisma.profile.update({
      where: { userId },
      data,
    });
  }

  /** Remplace la liste des jeux favoris de l'utilisateur. */
  private async syncFavoriteGames(userId: string, slugs: string[]) {
    const games = await this.prisma.game.findMany({
      where: { slug: { in: slugs }, isActive: true },
      select: { id: true },
    });

    await this.prisma.$transaction([
      this.prisma.userGame.deleteMany({ where: { userId } }),
      this.prisma.userGame.createMany({
        data: games.map((g) => ({ userId, gameId: g.id })),
        skipDuplicates: true,
      }),
    ]);
  }
}
