import { BadRequestException, Injectable } from '@nestjs/common';
import { AccountStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  /** Liste tous les comptes (recherche optionnelle par pseudo/email). */
  async listUsers(search?: string) {
    const where = search
      ? {
          OR: [
            { pseudo: { contains: search, mode: 'insensitive' as const } },
            { email: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : {};
    return this.prisma.user.findMany({
      where,
      select: {
        id: true,
        pseudo: true,
        email: true,
        role: true,
        status: true,
        isPremium: true,
        region: true,
        avatarUrl: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  /** Change le statut d'un compte (ACTIVE / SUSPENDED / BANNED). */
  async setStatus(adminId: string, userId: string, status: AccountStatus) {
    if (adminId === userId) {
      throw new BadRequestException('Tu ne peux pas changer ton propre statut.');
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        status,
        // Un compte suspendu/banni est déconnecté (refresh révoqué).
        refreshTokenHash: status === 'ACTIVE' ? undefined : null,
        isOnline: status === 'ACTIVE' ? undefined : false,
      },
    });
    return { ok: true, status };
  }

  /** Active/retire le Premium manuellement (cadeau / correction). */
  async setPremium(userId: string, isPremium: boolean) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { isPremium },
    });
    return { ok: true, isPremium };
  }

  /** Statistiques globales (tableau de bord admin). */
  async stats() {
    const [users, premium, banned, squads, matches] =
      await this.prisma.$transaction([
        this.prisma.user.count(),
        this.prisma.user.count({ where: { isPremium: true } }),
        this.prisma.user.count({ where: { status: 'BANNED' } }),
        this.prisma.squad.count(),
        this.prisma.match.count(),
      ]);
    return { users, premium, banned, squads, matches };
  }
}
