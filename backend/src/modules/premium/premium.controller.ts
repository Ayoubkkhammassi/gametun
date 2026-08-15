import { Controller, Get, HttpCode, Post } from '@nestjs/common';
import { PremiumService } from './premium.service';
import { Public } from '../../common/decorators/public.decorator';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('premium')
export class PremiumController {
  constructor(private readonly premiumService: PremiumService) {}

  @Public()
  @Get('plans')
  plans() {
    return this.premiumService.plans();
  }

  @Get('status')
  status(@CurrentUser() user: AuthUser) {
    return this.premiumService.status(user.sub);
  }

  @HttpCode(200)
  @Post('subscribe')
  subscribe(@CurrentUser() user: AuthUser) {
    return this.premiumService.subscribe(user.sub);
  }

  @HttpCode(200)
  @Post('cancel')
  cancel(@CurrentUser() user: AuthUser) {
    return this.premiumService.cancel(user.sub);
  }
}
