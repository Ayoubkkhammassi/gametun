import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ReputationService } from './reputation.service';
import { RateDto } from './dto/rate.dto';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('reputation')
export class ReputationController {
  constructor(private readonly reputationService: ReputationService) {}

  @HttpCode(200)
  @Post('rate')
  rate(@CurrentUser() user: AuthUser, @Body() dto: RateDto) {
    return this.reputationService.rate(user.sub, dto);
  }
}
