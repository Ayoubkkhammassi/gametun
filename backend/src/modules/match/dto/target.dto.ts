import { IsString, MinLength } from 'class-validator';

export class TargetDto {
  @IsString()
  @MinLength(1)
  targetId!: string;
}
