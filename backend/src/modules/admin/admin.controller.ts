import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AccountStatus, Role } from '@prisma/client';
import { IsBoolean, IsEnum } from 'class-validator';
import { AdminService } from './admin.service';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

class StatusDto {
  @IsEnum(AccountStatus)
  status!: AccountStatus;
}

class PremiumDto {
  @IsBoolean()
  isPremium!: boolean;
}

/** Espace admin : gestion des comptes. Réservé au rôle ADMIN. */
@UseGuards(RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  stats() {
    return this.adminService.stats();
  }

  @Get('users')
  users(@Query('search') search?: string) {
    return this.adminService.listUsers(search);
  }

  @HttpCode(200)
  @Post('users/:id/status')
  setStatus(
    @CurrentUser() admin: AuthUser,
    @Param('id') id: string,
    @Body() dto: StatusDto,
  ) {
    return this.adminService.setStatus(admin.sub, id, dto.status);
  }

  @HttpCode(200)
  @Post('users/:id/premium')
  setPremium(@Param('id') id: string, @Body() dto: PremiumDto) {
    return this.adminService.setPremium(id, dto.isPremium);
  }
}
