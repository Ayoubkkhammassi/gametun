import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { SquadsService } from './squads.service';
import { CreateSquadDto } from './dto/create-squad.dto';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('squads')
export class SquadsController {
  constructor(private readonly squadsService: SquadsService) {}

  @Get()
  list(@CurrentUser() user: AuthUser, @Query('scope') scope = 'mine') {
    return scope === 'discover'
      ? this.squadsService.discover(user.sub)
      : this.squadsService.listMine(user.sub);
  }

  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateSquadDto) {
    return this.squadsService.create(user.sub, dto);
  }

  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.squadsService.getOne(id);
  }

  @HttpCode(200)
  @Post(':id/join')
  join(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.squadsService.join(user.sub, id);
  }

  @HttpCode(200)
  @Post(':id/leave')
  leave(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.squadsService.leave(user.sub, id);
  }

  @Get(':id/smart-complete')
  smartComplete(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.squadsService.smartComplete(user.sub, id);
  }
}
