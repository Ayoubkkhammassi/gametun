import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
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

  // ---- Profil enrichi (carte joueur, façon Tinder adapté gaming) ---------

  // Galerie photos : URLs Cloudinary (ou data URI). Max 6 côté app.
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @MaxLength(3000000, { each: true })
  photoUrls?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(40)
  platform?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  rank?: string;

  @IsOptional()
  @IsBoolean()
  hasMic?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  playerType?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  favoriteGenres?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  spokenLanguages?: string[];

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(60)
  yearsExperience?: number;

  // Prompts/fun facts : [{ question, answer }].
  @IsOptional()
  @IsArray()
  funFacts?: { question: string; answer: string }[];
}
