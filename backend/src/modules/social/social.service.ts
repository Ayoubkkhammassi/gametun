import { Injectable } from '@nestjs/common';
import { ConversationType, NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ageGroup, computeAge } from '../../common/privacy.util';
import { SwipeDto } from './dto/swipe.dto';

@Injectable()
export class SocialService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  /**
   * Profils à découvrir : actifs, non bloqués, pas encore swipés, hors soi-même.
   * Orienté amitié/gaming (spec §10) — aucun critère physique.
   */
  async discover(userId: string, limit = 20) {
    const [blocks, actions] = await this.prisma.$transaction([
      this.prisma.blockedUser.findMany({
        where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
        select: { blockerId: true, blockedId: true },
      }),
      this.prisma.socialAction.findMany({
        where: { actorId: userId },
        select: { targetId: true },
      }),
    ]);

    const excluded = new Set<string>([userId]);
    for (const b of blocks) {
      excluded.add(b.blockerId);
      excluded.add(b.blockedId);
    }
    for (const a of actions) excluded.add(a.targetId);

    const users = await this.prisma.user.findMany({
      where: { status: 'ACTIVE', id: { notIn: [...excluded] } },
      include: {
        profile: true,
        games: { include: { game: { select: { slug: true, name: true } } } },
      },
      take: limit,
      orderBy: { lastSeenAt: 'desc' },
    });

    return users.map((u) => ({
      id: u.id,
      pseudo: u.pseudo,
      avatarUrl: u.avatarUrl,
      region: u.region,
      language: u.language,
      ageGroup: ageGroup(computeAge(u.birthDate)),
      isOnline: u.isOnline,
      level: u.profile?.level ?? 'BEGINNER',
      playStyle: u.profile?.playStyle ?? 'CASUAL',
      bio: u.profile?.bio ?? null,
      games: u.games.map((g) => g.game.name),
    }));
  }

  /**
   * Enregistre un swipe. Si LIKE/FAVORITE réciproque → crée un Match + conversation.
   */
  async swipe(userId: string, dto: SwipeDto) {
    if (userId === dto.targetId) {
      return { matched: false };
    }

    await this.prisma.socialAction.upsert({
      where: { actorId_targetId: { actorId: userId, targetId: dto.targetId } },
      update: { type: dto.type },
      create: { actorId: userId, targetId: dto.targetId, type: dto.type },
    });

    // Un PASS ne peut pas créer de match.
    if (dto.type === 'PASS') {
      return { matched: false };
    }

    // Le candidat m'a-t-il aussi liké/mis en favori ?
    const reciprocal = await this.prisma.socialAction.findUnique({
      where: {
        actorId_targetId: { actorId: dto.targetId, targetId: userId },
      },
    });
    if (!reciprocal || reciprocal.type === 'PASS') {
      return { matched: false };
    }

    return this.createMatch(userId, dto.targetId);
  }

  /** Liste des connexions (matches) de l'utilisateur. */
  async listMatches(userId: string) {
    const matches = await this.prisma.match.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      include: {
        userA: { select: { id: true, pseudo: true, avatarUrl: true, isOnline: true } },
        userB: { select: { id: true, pseudo: true, avatarUrl: true, isOnline: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return matches.map((m) => {
      const other = m.userAId === userId ? m.userB : m.userA;
      return {
        matchId: m.id,
        conversationId: m.conversationId,
        user: other,
        createdAt: m.createdAt,
      };
    });
  }

  // ---- Interne : création atomique match + conversation ------------------

  private async createMatch(userId: string, targetId: string) {
    // Ordre canonique pour respecter l'unicité (userA, userB).
    const [a, b] = [userId, targetId].sort();

    const existing = await this.prisma.match.findUnique({
      where: { userAId_userBId: { userAId: a, userBId: b } },
    });
    if (existing) {
      return { matched: true, conversationId: existing.conversationId };
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const conversation = await tx.conversation.create({
        data: {
          type: ConversationType.DIRECT,
          participants: {
            create: [{ userId: a }, { userId: b }],
          },
        },
      });
      const match = await tx.match.create({
        data: { userAId: a, userBId: b, conversationId: conversation.id },
      });
      return { conversationId: conversation.id, matchId: match.id };
    });

    // Notifie les deux joueurs.
    const payload = (from: string): Prisma.InputJsonValue => ({
      conversationId: result.conversationId,
      fromUserId: from,
    });
    await Promise.all([
      this.notifications.create({
        userId: a,
        type: NotificationType.NEW_MATCH,
        title: 'Nouveau match ! 🎉',
        body: 'Vous vous êtes connectés. Lancez la discussion !',
        data: payload(b),
      }),
      this.notifications.create({
        userId: b,
        type: NotificationType.NEW_MATCH,
        title: 'Nouveau match ! 🎉',
        body: 'Vous vous êtes connectés. Lancez la discussion !',
        data: payload(a),
      }),
    ]);

    return { matched: true, ...result };
  }
}
