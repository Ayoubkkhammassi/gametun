import { Body, Controller, Get, Post } from '@nestjs/common';
import { GamesService } from './games.service';
import { SetGamePreferencesDto } from './dto/set-preferences.dto';
import { Public } from '../../common/decorators/public.decorator';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('games')
export class GamesController {
  constructor(private readonly gamesService: GamesService) {}

  // Le catalogue est public (utile pendant l'onboarding).
  @Public()
  @Get()
  listGames() {
    return this.gamesService.listGames();
  }

  @Get('preferences')
  getMyGames(@CurrentUser() user: AuthUser) {
    return this.gamesService.getMyGames(user.sub);
  }

  @Post('preferences')
  setPreferences(
    @CurrentUser() user: AuthUser,
    @Body() dto: SetGamePreferencesDto,
  ) {
    return this.gamesService.setPreferences(user.sub, dto);
  }
}
