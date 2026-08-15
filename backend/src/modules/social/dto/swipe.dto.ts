import { IsEnum, IsString, MinLength } from 'class-validator';
import { SocialActionType } from '@prisma/client';

export class SwipeDto {
  @IsString()
  @MinLength(1)
  targetId!: string;

  @IsEnum(SocialActionType)
  type!: SocialActionType; // LIKE | PASS | FAVORITE
}
