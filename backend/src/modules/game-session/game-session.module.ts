import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { GameGateway } from './game.gateway';

@Module({
  imports: [JwtModule.register({})],
  providers: [GameGateway],
})
export class GameSessionModule {}
