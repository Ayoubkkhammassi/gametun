import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { MessageType } from '@prisma/client';

export class SendMessageDto {
  @IsOptional()
  @IsEnum(MessageType)
  type?: MessageType; // TEXT (défaut) | VOICE

  // Texte requis seulement pour un message texte.
  @ValidateIf((o) => o.type !== 'VOICE')
  @IsString()
  @MaxLength(2000, { message: 'Message trop long' })
  body!: string;

  // Audio en data URI base64 (message vocal), requis si type = VOICE.
  @ValidateIf((o) => o.type === 'VOICE')
  @IsString()
  mediaData?: string;

  @IsOptional()
  @IsInt()
  mediaDuration?: number;
}
