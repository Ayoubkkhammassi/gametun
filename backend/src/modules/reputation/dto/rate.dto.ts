import { IsInt, IsString, Max, Min, MinLength } from 'class-validator';

/**
 * Évaluation post-interaction (spec §14). Uniquement des critères de
 * comportement (coopération, respect, esprit d'équipe) — jamais l'apparence.
 */
export class RateDto {
  @IsString()
  @MinLength(1)
  ratedUserId!: string;

  // Contexte (id de squad/match) — empêche les évaluations répétées (anti-abus).
  @IsString()
  @MinLength(1)
  context!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  cooperation!: number;

  @IsInt()
  @Min(1)
  @Max(5)
  respect!: number;

  @IsInt()
  @Min(1)
  @Max(5)
  teamSpirit!: number;
}
