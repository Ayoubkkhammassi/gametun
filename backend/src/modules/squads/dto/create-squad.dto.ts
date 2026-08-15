import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Max,
  Min,
  MinLength,
} from 'class-validator';
import { GameMode, Language, SkillLevel } from '@prisma/client';

const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/;

export class CreateSquadDto {
  @IsString()
  @MinLength(3)
  @MaxLength(40)
  name!: string;

  @IsString()
  gameSlug!: string;

  @IsEnum(GameMode)
  mode!: GameMode;

  @IsInt()
  @Min(2)
  @Max(10)
  maxPlayers!: number;

  @IsEnum(SkillLevel)
  requiredLevel!: SkillLevel;

  @IsEnum(Language)
  language!: Language;

  @IsOptional()
  @Matches(TIME_REGEX)
  availabilityFrom?: string;

  @IsOptional()
  @Matches(TIME_REGEX)
  availabilityTo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  description?: string;
}
