import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ModerationService {
  constructor(private readonly prisma: PrismaService) {}

  // ---- Signalements ------------------------------------------------------

  async report(reporterId: string, reportedUserId: string, reason: string, details?: string) {
    if (reporterId === reportedUserId) {
      throw new BadRequestException('Impossible de se signaler soi-même');
    }
    await this.prisma.report.create({
      data: { reporterId, reportedUserId, reason, details },
    });
    return { reported: true };
  }

  // ---- Blocages ----------------------------------------------------------

  async block(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new BadRequestException('Impossible de se bloquer soi-même');
    }
    await this.prisma.blockedUser.upsert({
      where: { blockerId_blockedId: { blockerId, blockedId } },
      update: {},
      create: { blockerId, blockedId },
    });
    return { blocked: true };
  }

  async unblock(blockerId: string, blockedId: string) {
    await this.prisma.blockedUser.deleteMany({
      where: { blockerId, blockedId },
    });
    return { unblocked: true };
  }

  async listBlocked(userId: string) {
    const rows = await this.prisma.blockedUser.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          select: { id: true, pseudo: true, avatarUrl: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => r.blocked);
  }
}
