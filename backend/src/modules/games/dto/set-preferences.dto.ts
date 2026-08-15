import { IsArray, IsString, ArrayMaxSize } from 'class-validator';

export class SetGamePreferencesDto {
  // Liste des slugs de jeux favoris (ex: ["valorant", "fortnite"]).
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  gameSlugs!: string[];
}
