import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
import { SocialService } from './social.service';
import { SwipeDto } from './dto/swipe.dto';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('social')
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @Get('discover')
  discover(
    @CurrentUser() user: AuthUser,
    @Query('limit') limit = '20',
    @Query('region') region?: string,
    @Query('level') level?: string,
    @Query('game') gameSlug?: string,
    @Query('onlineOnly') onlineOnly?: string,
  ) {
    return this.socialService.discover(user.sub, Number(limit), {
      region: region || undefined,
      level: level || undefined,
      gameSlug: gameSlug || undefined,
      onlineOnly: onlineOnly === 'true' || onlineOnly === '1',
    });
  }

  @HttpCode(200)
  @Post('swipe')
  swipe(@CurrentUser() user: AuthUser, @Body() dto: SwipeDto) {
    return this.socialService.swipe(user.sub, dto);
  }

  @Get('matches')
  matches(@CurrentUser() user: AuthUser) {
    return this.socialService.listMatches(user.sub);
  }

  /** Qui m'a liké (identités réservées au Premium). */
  @Get('liked-me')
  likedMe(@CurrentUser() user: AuthUser) {
    return this.socialService.likedMe(user.sub);
  }
}
