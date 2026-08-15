import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
import { MinigamesService } from './minigames.service';
import { MiniGameResultDto } from './dto/result.dto';
import { Public } from '../../common/decorators/public.decorator';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('minigames')
export class MinigamesController {
  constructor(private readonly minigamesService: MinigamesService) {}

  @Public()
  @Get()
  catalog() {
    return this.minigamesService.catalog();
  }

  /** Questions de quiz en ligne (OpenTDB). category: 15=Jeux vidéo, 9=Général. */
  @Public()
  @Get('quiz')
  quiz(
    @Query('category') category = '15',
    @Query('amount') amount = '10',
  ) {
    return this.minigamesService.fetchQuiz(Number(category), Number(amount));
  }

  @HttpCode(200)
  @Post('result')
  result(@CurrentUser() user: AuthUser, @Body() dto: MiniGameResultDto) {
    return this.minigamesService.recordResult(user.sub, dto);
  }
}
