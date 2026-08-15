import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class ReportDto {
  @IsString()
  @MinLength(1)
  reportedUserId!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(80)
  reason!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  details?: string;
}

export class BlockDto {
  @IsString()
  @MinLength(1)
  userId!: string;
}
