import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  /** Conversations de l'utilisateur, avec dernier message et non-lus. */
  async listConversations(userId: string) {
    const parts = await this.prisma.conversationParticipant.findMany({
      where: { userId },
      include: {
        conversation: {
          include: {
            participants: {
              include: {
                user: {
                  select: {
                    id: true,
                    pseudo: true,
                    avatarUrl: true,
                    isOnline: true,
                    lastSeenAt: true,
                  },
                },
              },
            },
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
          },
        },
      },
      orderBy: { conversation: { updatedAt: 'desc' } },
    });

    return parts.map((p) => {
      const conv = p.conversation;
      const others = conv.participants
        .filter((cp) => cp.userId !== userId)
        .map((cp) => cp.user);
      const last = conv.messages[0];
      return {
        conversationId: conv.id,
        type: conv.type,
        participants: others,
        lastMessage: last
          ? { body: last.body, senderId: last.senderId, createdAt: last.createdAt }
          : null,
        updatedAt: conv.updatedAt,
      };
    });
  }

  /** Messages paginés d'une conversation (vérifie l'appartenance). */
  async getMessages(userId: string, conversationId: string, page = 1, limit = 30) {
    await this.assertParticipant(userId, conversationId);
    const skip = (page - 1) * limit;
    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    // Marque la conversation comme lue.
    await this.prisma.conversationParticipant.updateMany({
      where: { conversationId, userId },
      data: { lastReadAt: new Date() },
    });

    return { items: messages.reverse(), page, limit };
  }

  /** Envoie un message (texte ou vocal). L'émission temps réel est faite par la gateway. */
  async sendMessage(
    userId: string,
    conversationId: string,
    params: {
      type?: 'TEXT' | 'VOICE';
      body?: string;
      mediaData?: string;
      mediaDuration?: number;
    },
  ) {
    const others = await this.assertParticipant(userId, conversationId);

    // Anti-abus : refuse si l'un des participants a bloqué l'autre.
    const blocked = await this.prisma.blockedUser.findFirst({
      where: {
        OR: others.flatMap((o) => [
          { blockerId: o, blockedId: userId },
          { blockerId: userId, blockedId: o },
        ]),
      },
    });
    if (blocked) {
      throw new ForbiddenException('Conversation indisponible.');
    }

    const isVoice = params.type === 'VOICE';
    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderId: userId,
        type: isVoice ? 'VOICE' : 'TEXT',
        body: isVoice ? '🎤 Message vocal' : (params.body ?? ''),
        mediaData: isVoice ? params.mediaData : null,
        mediaDuration: isVoice ? params.mediaDuration : null,
      },
    });
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    // Notifie les autres participants.
    const preview = isVoice
      ? '🎤 Message vocal'
      : (params.body ?? '').length > 60
        ? `${(params.body ?? '').slice(0, 57)}...`
        : (params.body ?? '');
    await Promise.all(
      others.map((o) =>
        this.notifications.create({
          userId: o,
          type: NotificationType.NEW_MESSAGE,
          title: 'Nouveau message',
          body: preview,
          data: { conversationId, fromUserId: userId },
        }),
      ),
    );

    return message;
  }

  /** Supprime un message (seul l'expéditeur peut supprimer le sien). */
  async deleteMessage(userId: string, messageId: string) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
      select: { id: true, senderId: true, conversationId: true },
    });
    if (!message) throw new NotFoundException('Message introuvable');
    if (message.senderId !== userId) {
      throw new ForbiddenException('Tu ne peux supprimer que tes messages');
    }
    await this.prisma.message.delete({ where: { id: messageId } });
    return { id: messageId, conversationId: message.conversationId };
  }

  /** Ajoute/retire une réaction emoji sur un message. */
  async react(userId: string, messageId: string, emoji: string) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
      select: { id: true, conversationId: true, reactions: true },
    });
    if (!message) throw new NotFoundException('Message introuvable');
    await this.assertParticipant(userId, message.conversationId);

    const reactions =
      (message.reactions as Record<string, string[]> | null) ?? {};
    const users = new Set(reactions[emoji] ?? []);
    if (users.has(userId)) {
      users.delete(userId); // toggle off
    } else {
      users.add(userId);
    }
    if (users.size === 0) {
      delete reactions[emoji];
    } else {
      reactions[emoji] = [...users];
    }

    const updated = await this.prisma.message.update({
      where: { id: messageId },
      data: { reactions },
    });
    return updated;
  }

  /** Vérifie que l'utilisateur appartient à la conversation. Renvoie les autres IDs. */
  private async assertParticipant(
    userId: string,
    conversationId: string,
  ): Promise<string[]> {
    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { participants: { select: { userId: true } } },
    });
    if (!conv) throw new NotFoundException('Conversation introuvable');
    const ids = conv.participants.map((p) => p.userId);
    if (!ids.includes(userId)) {
      throw new ForbiddenException('Accès refusé à cette conversation');
    }
    return ids.filter((id) => id !== userId);
  }
}
