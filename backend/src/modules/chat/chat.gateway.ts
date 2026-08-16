import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Message } from '@prisma/client';
import { AppConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Passerelle temps réel du chat.
 * - Authentifie chaque socket via le JWT (handshake.auth.token).
 * - Gère les "rooms" par conversation.
 * - Diffuse les nouveaux messages et le statut en ligne.
 */
@WebSocketGateway({ cors: { origin: true }, namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server!: Server;
  private readonly logger = new Logger(ChatGateway.name);

  // userId -> nombre de sockets connectées (multi-appareils).
  private readonly online = new Map<string, number>();

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService<AppConfig, true>,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const token =
        (client.handshake.auth?.token as string | undefined) ??
        (client.handshake.headers.authorization?.replace('Bearer ', ''));
      if (!token) throw new Error('no token');

      const payload = await this.jwt.verifyAsync<{ sub: string }>(token, {
        secret: this.config.get('jwt', { infer: true }).accessSecret,
      });
      const userId = payload.sub;
      client.data.userId = userId;

      // Rejoint une room personnelle + les rooms de ses conversations.
      client.join(`user:${userId}`);
      const parts = await this.prisma.conversationParticipant.findMany({
        where: { userId },
        select: { conversationId: true },
      });
      for (const p of parts) client.join(`conv:${p.conversationId}`);

      await this.setOnline(userId, true);
    } catch {
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket): Promise<void> {
    const userId = client.data.userId as string | undefined;
    if (userId) await this.setOnline(userId, false);
  }

  /** Le client rejoint explicitement une conversation (nouvelle conv). */
  @SubscribeMessage('join')
  onJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ): void {
    if (data?.conversationId) client.join(`conv:${data.conversationId}`);
  }

  /** Indicateur "en train d'écrire". */
  @SubscribeMessage('typing')
  onTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ): void {
    const userId = client.data.userId as string;
    if (data?.conversationId) {
      client
        .to(`conv:${data.conversationId}`)
        .emit('typing', { conversationId: data.conversationId, userId });
    }
  }

  /** Appelée par le contrôleur après persistance d'un message. */
  emitNewMessage(conversationId: string, message: Message): void {
    this.server.to(`conv:${conversationId}`).emit('message', message);
  }

  /** Diffuse la suppression d'un message aux membres connectés. */
  emitDeletedMessage(conversationId: string, messageId: string): void {
    this.server
      .to(`conv:${conversationId}`)
      .emit('message:deleted', { id: messageId, conversationId });
  }

  // ---- Statut en ligne ---------------------------------------------------

  private async setOnline(userId: string, online: boolean): Promise<void> {
    const count = this.online.get(userId) ?? 0;
    const next = online ? count + 1 : Math.max(0, count - 1);
    if (next === 0) this.online.delete(userId);
    else this.online.set(userId, next);

    const isOnline = next > 0;
    // On ne met à jour la base qu'aux transitions (0<->1).
    if ((online && count === 0) || (!online && next === 0)) {
      await this.prisma.user
        .update({
          where: { id: userId },
          data: { isOnline, lastSeenAt: new Date() },
        })
        .catch(() => undefined);
      this.server.emit('presence', { userId, isOnline });
    }
  }
}
