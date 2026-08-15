import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SetGamePreferencesDto } from './dto/set-preferences.dto';

@Injectable()
export class GamesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Catalogue des jeux disponibles. */
  listGames() {
    return this.prisma.game.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  /** Jeux favoris de l'utilisateur courant. */
  async getMyGames(userId: string) {
    const rows = await this.prisma.userGame.findMany({
      where: { userId },
      include: { game: true },
    });
    return rows.map((r) => ({
      id: r.game.id,
      slug: r.game.slug,
      name: r.game.name,
      iconUrl: r.game.iconUrl,
      category: r.game.category,
      level: r.level,
      isFavorite: r.isFavorite,
    }));
  }

  /** Remplace les préférences de jeux de l'utilisateur. */
  async setPreferences(userId: string, dto: SetGamePreferencesDto) {
    const games = await this.prisma.game.findMany({
      where: { slug: { in: dto.gameSlugs }, isActive: true },
      select: { id: true, slug: true },
    });

    const foundSlugs = new Set(games.map((g) => g.slug));
    const unknown = dto.gameSlugs.filter((s) => !foundSlugs.has(s));
    if (unknown.length > 0) {
      throw new BadRequestException(`Jeux inconnus: ${unknown.join(', ')}`);
    }

    await this.prisma.$transaction([
      this.prisma.userGame.deleteMany({ where: { userId } }),
      this.prisma.userGame.createMany({
        data: games.map((g) => ({ userId, gameId: g.id })),
        skipDuplicates: true,
      }),
    ]);

    return this.getMyGames(userId);
  }
}
