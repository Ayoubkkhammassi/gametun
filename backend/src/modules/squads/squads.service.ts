import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ConversationType,
  NotificationType,
  SquadMemberRole,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { compatibilityScore } from '../smart-match/compatibility';
import { CreateSquadDto } from './dto/create-squad.dto';

@Injectable()
export class SquadsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async create(userId: string, dto: CreateSquadDto) {
    const game = await this.prisma.game.findUnique({
      where: { slug: dto.gameSlug },
    });
    if (!game) throw new BadRequestException('Jeu inconnu');

    return this.prisma.$transaction(async (tx) => {
      const squad = await tx.squad.create({
        data: {
          name: dto.name,
          gameId: game.id,
          mode: dto.mode,
          maxPlayers: dto.maxPlayers,
          requiredLevel: dto.requiredLevel,
          language: dto.language,
          availabilityFrom: dto.availabilityFrom,
          availabilityTo: dto.availabilityTo,
          description: dto.description,
          ownerId: userId,
          members: {
            create: { userId, role: SquadMemberRole.CAPTAIN },
          },
        },
      });
      // Conversation de groupe liée à la squad.
      await tx.conversation.create({
        data: {
          type: ConversationType.SQUAD,
          squadId: squad.id,
          participants: { create: { userId } },
        },
      });
      return squad;
    });
  }

  /** Squads dont l'utilisateur est membre. */
  async listMine(userId: string) {
    const memberships = await this.prisma.squadMember.findMany({
      where: { userId },
      include: {
        squad: {
          include: { game: true, _count: { select: { members: true } } },
        },
      },
    });
    return memberships.map((m) => this.shape(m.squad, m.squad._count.members));
  }

  /** Squads ouvertes à découvrir (non pleines, où l'utilisateur n'est pas). */
  async discover(userId: string) {
    const squads = await this.prisma.squad.findMany({
      where: {
        isOpen: true,
        members: { none: { userId } },
      },
      include: {
        game: true,
        _count: { select: { members: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return squads
      .filter((s) => s._count.members < s.maxPlayers)
      .map((s) => this.shape(s, s._count.members));
  }

  async getOne(squadId: string) {
    const squad = await this.prisma.squad.findUnique({
      where: { id: squadId },
      include: {
        game: true,
        members: {
          include: {
            user: {
              select: {
                id: true,
                pseudo: true,
                avatarUrl: true,
                isOnline: true,
              },
            },
          },
        },
      },
    });
    if (!squad) throw new NotFoundException('Squad introuvable');
    return {
      ...this.shape(squad, squad.members.length),
      members: squad.members.map((m) => ({ ...m.user, role: m.role })),
    };
  }

  async join(userId: string, squadId: string) {
    const squad = await this.prisma.squad.findUnique({
      where: { id: squadId },
      include: { _count: { select: { members: true } } },
    });
    if (!squad) throw new NotFoundException('Squad introuvable');
    if (!squad.isOpen) throw new ForbiddenException('Squad fermée');
    if (squad._count.members >= squad.maxPlayers) {
      throw new ForbiddenException('Squad complète');
    }

    const existing = await this.prisma.squadMember.findUnique({
      where: { squadId_userId: { squadId, userId } },
    });
    if (existing) return { joined: true };

    await this.prisma.$transaction(async (tx) => {
      await tx.squadMember.create({ data: { squadId, userId } });
      // Ajoute à la conversation de la squad.
      const conv = await tx.conversation.findUnique({ where: { squadId } });
      if (conv) {
        await tx.conversationParticipant.upsert({
          where: {
            conversationId_userId: { conversationId: conv.id, userId },
          },
          update: {},
          create: { conversationId: conv.id, userId },
        });
      }
    });

    // Notifie le capitaine ; alerte si presque complète.
    const count = squad._count.members + 1;
    await this.notifications.create({
      userId: squad.ownerId,
      type:
        count >= squad.maxPlayers - 1
          ? NotificationType.SQUAD_ALMOST_FULL
          : NotificationType.INVITATION,
      title:
        count >= squad.maxPlayers - 1
          ? 'Ta squad est presque complète !'
          : 'Nouveau membre',
      body: `${count}/${squad.maxPlayers} joueurs dans "${squad.name}".`,
      data: { squadId },
    });

    return { joined: true };
  }

  async leave(userId: string, squadId: string) {
    const squad = await this.prisma.squad.findUnique({
      where: { id: squadId },
    });
    if (!squad) throw new NotFoundException('Squad introuvable');

    await this.prisma.squadMember.deleteMany({ where: { squadId, userId } });
    const conv = await this.prisma.conversation.findUnique({
      where: { squadId },
    });
    if (conv) {
      await this.prisma.conversationParticipant.deleteMany({
        where: { conversationId: conv.id, userId },
      });
    }

    // Si le capitaine part, on transfère ou on ferme la squad.
    if (squad.ownerId === userId) {
      const next = await this.prisma.squadMember.findFirst({
        where: { squadId },
        orderBy: { joinedAt: 'asc' },
      });
      if (next) {
        await this.prisma.$transaction([
          this.prisma.squad.update({
            where: { id: squadId },
            data: { ownerId: next.userId },
          }),
          this.prisma.squadMember.update({
            where: { squadId_userId: { squadId, userId: next.userId } },
            data: { role: SquadMemberRole.CAPTAIN },
          }),
        ]);
      } else {
        await this.prisma.squad.delete({ where: { id: squadId } });
      }
    }
    return { left: true };
  }

  /**
   * Smart Squad (spec §9) : suggère des joueurs pour compléter une squad,
   * classés par compatibilité. Fonctionnalité mise en avant côté Premium.
   */
  async smartComplete(userId: string, squadId: string) {
    const squad = await this.prisma.squad.findUnique({
      where: { id: squadId },
      include: {
        game: true,
        members: { select: { userId: true } },
      },
    });
    if (!squad) throw new NotFoundException('Squad introuvable');
    if (squad.ownerId !== userId) {
      throw new ForbiddenException('Seul le capitaine peut compléter la squad');
    }

    const memberIds = squad.members.map((m) => m.userId);
    const missing = squad.maxPlayers - memberIds.length;
    if (missing <= 0) return { missing: 0, suggestions: [] };

    const candidates = await this.prisma.user.findMany({
      where: {
        status: 'ACTIVE',
        id: { notIn: memberIds },
        games: { some: { gameId: squad.gameId } },
      },
      include: {
        profile: true,
        games: { include: { game: { select: { slug: true } } } },
      },
      take: 60,
    });

    const suggestions = candidates
      .map((c) => {
        const score = compatibilityScore(
          {
            gameSlugs: [squad.game.slug],
            level: squad.requiredLevel,
            language: squad.language,
            availabilityFrom: squad.availabilityFrom,
            availabilityTo: squad.availabilityTo,
          },
          {
            gameSlugs: c.games.map((g) => g.game.slug),
            level: c.profile?.level ?? 'BEGINNER',
            language: c.language,
            region: c.region,
            availabilityFrom: c.profile?.availabilityFrom,
            availabilityTo: c.profile?.availabilityTo,
          },
        );
        return {
          id: c.id,
          pseudo: c.pseudo,
          avatarUrl: c.avatarUrl,
          level: c.profile?.level ?? 'BEGINNER',
          compatibility: score,
        };
      })
      .sort((a, b) => b.compatibility - a.compatibility)
      .slice(0, missing * 3);

    return { missing, suggestions };
  }

  // ---- Helper de formatage ----------------------------------------------

  private shape(
    squad: {
      id: string;
      name: string;
      mode: string;
      maxPlayers: number;
      requiredLevel: string;
      language: string;
      isOpen: boolean;
      description: string | null;
      game: { slug: string; name: string; iconUrl: string | null };
    },
    memberCount: number,
  ) {
    return {
      id: squad.id,
      name: squad.name,
      game: squad.game,
      mode: squad.mode,
      maxPlayers: squad.maxPlayers,
      memberCount,
      requiredLevel: squad.requiredLevel,
      language: squad.language,
      isOpen: squad.isOpen,
      description: squad.description,
    };
  }
}
