import { Body, Controller, Get, HttpCode, Post } from '@nestjs/common';
import { ModerationService } from './moderation.service';
import { BlockDto, ReportDto } from './dto/report.dto';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('users')
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @HttpCode(200)
  @Post('report')
  report(@CurrentUser() user: AuthUser, @Body() dto: ReportDto) {
    return this.moderation.report(
      user.sub,
      dto.reportedUserId,
      dto.reason,
      dto.details,
    );
  }

  @HttpCode(200)
  @Post('block')
  block(@CurrentUser() user: AuthUser, @Body() dto: BlockDto) {
    return this.moderation.block(user.sub, dto.userId);
  }

  @HttpCode(200)
  @Post('unblock')
  unblock(@CurrentUser() user: AuthUser, @Body() dto: BlockDto) {
    return this.moderation.unblock(user.sub, dto.userId);
  }

  @Get('me/blocked')
  listBlocked(@CurrentUser() user: AuthUser) {
    return this.moderation.listBlocked(user.sub);
  }
}
