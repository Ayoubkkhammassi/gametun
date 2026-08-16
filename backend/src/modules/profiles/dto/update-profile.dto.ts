import {
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { PlayStyle, SkillLevel } from '@prisma/client';

const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/; // "HH:MM"

export class UpdateProfileDto {
  @IsOptional()
  @IsEnum(SkillLevel)
  level?: SkillLevel;

  @IsOptional()
  @IsEnum(PlayStyle)
  playStyle?: PlayStyle;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'availabilityFrom doit être au format HH:MM' })
  availabilityFrom?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'availabilityTo doit être au format HH:MM' })
  availabilityTo?: string;

  // Peut être une URL OU une image base64 (data URI) → pas de limite courte.
  @IsOptional()
  @IsString()
  @MaxLength(3000000)
  avatarUrl?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  favoriteGameSlugs?: string[];
}
