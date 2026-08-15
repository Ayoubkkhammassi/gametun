import { IsString, MinLength } from 'class-validator';

export class LoginDto {
  // Accepte email OU pseudo (identifiant unique).
  @IsString()
  identifier!: string;

  @IsString()
  @MinLength(1)
  password!: string;
}
