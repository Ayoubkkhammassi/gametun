import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { SendMessageDto } from './dto/send-message.dto';
import { ReactDto } from './dto/react.dto';
import {
  AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';

@Controller()
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly gateway: ChatGateway,
  ) {}

  @Get('conversations')
  listConversations(@CurrentUser() user: AuthUser) {
    return this.chatService.listConversations(user.sub);
  }

  @Get('conversations/:id/messages')
  getMessages(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Query('page') page = '1',
    @Query('limit') limit = '30',
  ) {
    return this.chatService.getMessages(user.sub, id, Number(page), Number(limit));
  }

  @Post('conversations/:id/messages')
  async sendMessage(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    const message = await this.chatService.sendMessage(user.sub, id, {
      type: dto.type,
      body: dto.body,
      mediaData: dto.mediaData,
      mediaDuration: dto.mediaDuration,
    });
    // Diffusion temps réel aux membres connectés.
    this.gateway.emitNewMessage(id, message);
    return message;
  }

  @Delete('messages/:id')
  async deleteMessage(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ) {
    const res = await this.chatService.deleteMessage(user.sub, id);
    this.gateway.emitDeletedMessage(res.conversationId, res.id);
    return res;
  }

  @Post('messages/:id/react')
  async react(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: ReactDto,
  ) {
    const message = await this.chatService.react(user.sub, id, dto.emoji);
    this.gateway.emitNewMessage(message.conversationId, message);
    return message;
  }
}
