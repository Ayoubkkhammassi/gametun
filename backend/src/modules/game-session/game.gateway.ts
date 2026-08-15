import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AppConfig } from '../../config/configuration';
import {
  applyMove,
  createBoard,
  GameState,
  GameType,
} from './game-logic';

interface Room {
  state: GameState;
  players: { userId: string; pseudo: string; symbol: 1 | 2 }[];
}

/**
 * Passerelle temps réel pour les mini-jeux à 2 (spec §12).
 * Une "room" = un identifiant (souvent = conversationId) + un type de jeu.
 * L'état vit en mémoire le temps de la partie.
 */
@WebSocketGateway({ cors: { origin: true }, namespace: '/games' })
export class GameGateway implements OnGatewayDisconnect {
  @WebSocketServer() server!: Server;
  private readonly logger = new Logger(GameGateway.name);
  private readonly rooms = new Map<string, Room>();

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService<AppConfig, true>,
  ) {}

  private async auth(client: Socket): Promise<{ sub: string; pseudo: string } | null> {
    try {
      const token =
        (client.handshake.auth?.token as string | undefined) ??
        client.handshake.headers.authorization?.replace('Bearer ', '');
      if (!token) return null;
      return await this.jwt.verifyAsync<{ sub: string; pseudo: string }>(token, {
        secret: this.config.get('jwt', { infer: true }).accessSecret,
      });
    } catch {
      return null;
    }
  }

  private roomKey(roomId: string, game: GameType): string {
    return `${game}:${roomId}`;
  }

  /** Rejoint (ou crée) une partie. Assigne le symbole 1 (créateur) ou 2. */
  @SubscribeMessage('game:join')
  async onJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; game: GameType },
  ): Promise<void> {
    const user = await this.auth(client);
    if (!user || !data?.roomId || !data?.game) return;

    const key = this.roomKey(data.roomId, data.game);
    client.join(key);
    client.data.userId = user.sub;

    let room = this.rooms.get(key);
    if (!room) {
      room = {
        state: { game: data.game, board: createBoard(data.game), turn: 1, winner: 0 },
        players: [],
      };
      this.rooms.set(key, room);
    }

    // (Ré)assigne un symbole à l'utilisateur.
    let me = room.players.find((p) => p.userId === user.sub);
    if (!me && room.players.length < 2) {
      const symbol: 1 | 2 = room.players.length === 0 ? 1 : 2;
      me = { userId: user.sub, pseudo: user.pseudo, symbol };
      room.players.push(me);
    }

    this.broadcast(key, room);
  }

  /** Joue un coup (index case pour TTT, colonne pour C4). */
  @SubscribeMessage('game:move')
  async onMove(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; game: GameType; index: number },
  ): Promise<void> {
    const user = await this.auth(client);
    if (!user) return;
    const key = this.roomKey(data.roomId, data.game);
    const room = this.rooms.get(key);
    if (!room) return;

    const me = room.players.find((p) => p.userId === user.sub);
    if (!me) return;

    if (applyMove(room.state, me.symbol, data.index)) {
      this.broadcast(key, room);
    }
  }

  /** Recommence une partie dans la même room. */
  @SubscribeMessage('game:reset')
  async onReset(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; game: GameType },
  ): Promise<void> {
    const user = await this.auth(client);
    if (!user) return;
    const key = this.roomKey(data.roomId, data.game);
    const room = this.rooms.get(key);
    if (!room) return;
    room.state = {
      game: data.game,
      board: createBoard(data.game),
      turn: 1,
      winner: 0,
    };
    this.broadcast(key, room);
  }

  handleDisconnect(): void {
    // Les rooms sans activité seront nettoyées à la prochaine partie.
  }

  private broadcast(key: string, room: Room): void {
    this.server.to(key).emit('game:state', {
      state: room.state,
      players: room.players.map((p) => ({
        userId: p.userId,
        pseudo: p.pseudo,
        symbol: p.symbol,
      })),
    });
  }
}
