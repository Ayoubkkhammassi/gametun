import { Controller, Get } from '@nestjs/common';
import { StatisticsService } from './statistics.service';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get()
  get(@CurrentUser() user: AuthUser) {
    return this.statisticsService.getFor(user.sub);
  }
}
