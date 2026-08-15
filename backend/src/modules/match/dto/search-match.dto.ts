import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';
import { GameMode, Language, SkillLevel } from '@prisma/client';

const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/;

export class SearchMatchDto {
  // Jeux recherchés (slugs) — au moins un.
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  gameSlugs!: string[];

  @IsOptional()
  @IsEnum(GameMode)
  mode?: GameMode;

  @IsOptional()
  @IsEnum(SkillLevel)
  level?: SkillLevel;

  @IsOptional()
  @IsEnum(Language)
  language?: Language;

  @IsOptional()
  @Matches(TIME_REGEX)
  availabilityFrom?: string;

  @IsOptional()
  @Matches(TIME_REGEX)
  availabilityTo?: string;

  // Nombre de joueurs souhaités dans l'équipe (2..10).
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(10)
  players?: number;
}
