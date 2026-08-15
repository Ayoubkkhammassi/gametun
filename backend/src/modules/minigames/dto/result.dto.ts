import { IsBoolean, IsIn, IsString } from 'class-validator';

const GAMES = [
  'tic-tac-toe',
  'connect-four',
  'quiz',
  'rock-paper-scissors',
  'reaction',
];

export class MiniGameResultDto {
  @IsString()
  @IsIn(GAMES)
  game!: string;

  // true = victoire (contre l'app ou un autre joueur).
  @IsBoolean()
  won!: boolean;
}
