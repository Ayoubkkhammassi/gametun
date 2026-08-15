import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { MatchService } from './match.service';
import { SearchMatchDto } from './dto/search-match.dto';
import { TargetDto } from './dto/target.dto';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('match')
export class MatchController {
  constructor(private readonly matchService: MatchService) {}

  @HttpCode(200)
  @Post('search')
  search(@CurrentUser() user: AuthUser, @Body() dto: SearchMatchDto) {
    return this.matchService.search(user.sub, dto);
  }

  @HttpCode(200)
  @Post('accept')
  accept(@CurrentUser() user: AuthUser, @Body() dto: TargetDto) {
    return this.matchService.accept(user.sub, dto.targetId);
  }

  @HttpCode(200)
  @Post('pass')
  pass(@CurrentUser() user: AuthUser, @Body() dto: TargetDto) {
    return this.matchService.pass(user.sub, dto.targetId);
  }
}
