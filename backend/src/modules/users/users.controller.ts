import { Controller, Get, Param } from '@nestjs/common';
import { UsersService } from './users.service';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  getMe(@CurrentUser() user: AuthUser) {
    return this.usersService.getMe(user.sub);
  }

  @Get(':id')
  getPublicProfile(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.usersService.getPublicProfile(id, user.sub);
  }
}
