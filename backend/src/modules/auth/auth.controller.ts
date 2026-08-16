import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { GoogleDto } from './dto/google.dto';
import { Public } from '../../common/decorators/public.decorator';
import {
  CurrentUser,
  AuthUser,
} from '../../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // Limites strictes contre le brute-force (spec §17).
  @Public()
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  /** Vérifie en direct si un pseudo est disponible (pour l'inscription). */
  @Public()
  @HttpCode(200)
  @Get('check-pseudo')
  checkPseudo(@Query('pseudo') pseudo: string) {
    return this.authService.isPseudoAvailable(pseudo ?? '');
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @HttpCode(200)
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Public()
  @HttpCode(200)
  @Post('refresh')
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @HttpCode(200)
  @Post('google')
  google(@Body() dto: GoogleDto) {
    return this.authService.googleLogin(dto.idToken);
  }

  @HttpCode(200)
  @Post('logout')
  async logout(@CurrentUser() user: AuthUser) {
    await this.authService.logout(user.sub);
    return { message: 'Déconnecté' };
  }

  /** Renvoie l'utilisateur courant (vérifie que le token est valide). */
  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return user;
  }
}
