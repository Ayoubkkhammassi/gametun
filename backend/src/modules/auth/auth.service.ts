import {
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { User } from '@prisma/client';
import { AppConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';
import { computeAge, toSelfUser } from '../../common/privacy.util';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService<AppConfig, true>,
  ) {}

  // ---- Inscription -------------------------------------------------------

  async register(dto: RegisterDto) {
    const birthDate = new Date(dto.birthDate);
    const minAge = this.config.get('minAge', { infer: true });
    const age = computeAge(birthDate);

    if (Number.isNaN(birthDate.getTime())) {
      throw new ForbiddenException('Date de naissance invalide');
    }
    // Protection des mineurs (spec §4/§17)
    if (age < minAge) {
      throw new ForbiddenException(
        `Vous devez avoir au moins ${minAge} ans pour vous inscrire.`,
      );
    }

    const email = dto.email.toLowerCase().trim();
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ email }, { pseudo: dto.pseudo }] },
      select: { email: true, pseudo: true },
    });
    if (existing) {
      throw new ConflictException(
        existing.email === email ? 'Email déjà utilisé' : 'Pseudo déjà pris',
      );
    }

    const passwordHash = await argon2.hash(dto.password);

    // Création atomique: compte + profil + statistiques vides.
    const user = await this.prisma.user.create({
      data: {
        email,
        pseudo: dto.pseudo,
        passwordHash,
        birthDate,
        language: dto.language ?? 'FR',
        region: dto.region ?? 'Tunisie',
        avatarUrl: dto.avatarUrl,
        profile: { create: {} },
        statistics: { create: {} },
      },
    });

    const tokens = await this.issueTokens(user);
    return { user: toSelfUser(user), tokens };
  }

  /** Renvoie si un pseudo est disponible + valide (pour la vérif en direct). */
  async isPseudoAvailable(pseudo: string) {
    const trimmed = pseudo.trim();
    const valid = /^[a-zA-Z0-9_-]{3,20}$/.test(trimmed);
    if (!valid) {
      return { available: false, valid: false };
    }
    const existing = await this.prisma.user.findUnique({
      where: { pseudo: trimmed },
      select: { id: true },
    });
    return { available: !existing, valid: true };
  }

  // ---- Connexion ---------------------------------------------------------

  async login(dto: LoginDto) {
    const identifier = dto.identifier.trim();
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: identifier.toLowerCase() }, { pseudo: identifier }],
      },
    });

    // Message générique — on ne révèle pas si l'identifiant existe.
    if (!user) {
      throw new UnauthorizedException('Identifiants incorrects');
    }
    if (user.status === 'BANNED') {
      throw new ForbiddenException('Ce compte a été banni.');
    }

    const valid = await argon2.verify(user.passwordHash, dto.password);
    if (!valid) {
      throw new UnauthorizedException('Identifiants incorrects');
    }

    const tokens = await this.issueTokens(user);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { isOnline: true, lastSeenAt: new Date() },
    });
    return { user: toSelfUser(user), tokens };
  }

  // ---- Rafraîchissement de token (rotation) ------------------------------

  async refresh(refreshToken: string): Promise<AuthTokens> {
    let payload: { sub: string };
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.get('jwt', { infer: true }).refreshSecret,
      });
    } catch {
      throw new UnauthorizedException('Refresh token invalide ou expiré');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
    if (!user || !user.refreshTokenHash) {
      throw new UnauthorizedException('Session invalide');
    }

    const matches = await argon2.verify(user.refreshTokenHash, refreshToken);
    if (!matches) {
      throw new UnauthorizedException('Session invalide');
    }

    return this.issueTokens(user);
  }

  // ---- Déconnexion -------------------------------------------------------

  async logout(userId: string): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { refreshTokenHash: null, isOnline: false, lastSeenAt: new Date() },
    });
  }

  // ---- Interne -----------------------------------------------------------

  private async issueTokens(user: User): Promise<AuthTokens> {
    const jwtCfg = this.config.get('jwt', { infer: true });
    const payload = { sub: user.id, pseudo: user.pseudo, role: user.role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(payload, {
        secret: jwtCfg.accessSecret,
        expiresIn: jwtCfg.accessTtl,
      }),
      this.jwt.signAsync(
        { sub: user.id },
        { secret: jwtCfg.refreshSecret, expiresIn: jwtCfg.refreshTtl },
      ),
    ]);

    // On stocke le hash du refresh token courant -> révocation/rotation.
    const refreshTokenHash = await argon2.hash(refreshToken);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { refreshTokenHash },
    });

    return { accessToken, refreshToken };
  }
}
