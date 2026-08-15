import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Language } from '@prisma/client';

export class RegisterDto {
  @IsEmail({}, { message: 'Email invalide' })
  email!: string;

  // 3-20 caractères, lettres/chiffres/underscore/tiret
  @IsString()
  @MinLength(3, { message: 'Le pseudo doit faire au moins 3 caractères' })
  @MaxLength(20, { message: 'Le pseudo ne peut dépasser 20 caractères' })
  @Matches(/^[a-zA-Z0-9_-]+$/, {
    message: 'Le pseudo ne peut contenir que lettres, chiffres, _ et -',
  })
  pseudo!: string;

  @IsString()
  @MinLength(8, { message: 'Le mot de passe doit faire au moins 8 caractères' })
  @MaxLength(72, { message: 'Mot de passe trop long' })
  password!: string;

  // Format ISO (YYYY-MM-DD). L'âge minimum est vérifié côté service.
  @IsDateString({}, { message: 'Date de naissance invalide (format YYYY-MM-DD)' })
  birthDate!: string;

  @IsOptional()
  @IsEnum(Language)
  language?: Language;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  region?: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
