import { Module } from '@nestjs/common';
import { MinigamesService } from './minigames.service';
import { MinigamesController } from './minigames.controller';

@Module({
  providers: [MinigamesService],
  controllers: [MinigamesController],
})
export class MinigamesModule {}
