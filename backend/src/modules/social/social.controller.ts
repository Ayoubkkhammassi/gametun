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
  discover(@CurrentUser() user: AuthUser, @Query('limit') limit = '20') {
    return this.socialService.discover(user.sub, Number(limit));
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
}
