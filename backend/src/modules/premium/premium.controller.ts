import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { IsString, MinLength } from 'class-validator';
import { PremiumService } from './premium.service';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

class RequestDto {
  @IsString()
  @MinLength(3)
  reference!: string;
}

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

  // ---- Paiement manuel D17 ----

  @HttpCode(200)
  @Post('request')
  request(@CurrentUser() user: AuthUser, @Body() dto: RequestDto) {
    return this.premiumService.createRequest(user.sub, dto.reference);
  }

  @Get('request/mine')
  myRequest(@CurrentUser() user: AuthUser) {
    return this.premiumService.myLatestRequest(user.sub);
  }

  // ---- Admin (validation des paiements) ----

  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  @Get('requests')
  pendingRequests() {
    return this.premiumService.listPendingRequests();
  }

  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  @HttpCode(200)
  @Post('requests/:id/approve')
  approve(@Param('id') id: string) {
    return this.premiumService.approveRequest(id);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  @HttpCode(200)
  @Post('requests/:id/reject')
  reject(@Param('id') id: string) {
    return this.premiumService.rejectRequest(id);
  }

  @HttpCode(200)
  @Post('cancel')
  cancel(@CurrentUser() user: AuthUser) {
    return this.premiumService.cancel(user.sub);
  }
}
