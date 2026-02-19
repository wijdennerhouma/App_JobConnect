import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('chat')
@UseGuards(AuthGuard('jwt'))
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('send')
  async sendMessage(
    @Body() body: { receiverId: string; content: string },
    @Req() req,
  ) {
    return this.chatService.sendMessage(
      req.user._id,
      body.receiverId,
      body.content,
    );
  }

  @Get('conversations')
  async getConversations(@Req() req) {
    return this.chatService.getConversations(req.user._id);
  }

  @Get('messages/:conversationId')
  async getMessages(
    @Param('conversationId') conversationId: string,
    @Req() req,
  ) {
    return this.chatService.getMessages(conversationId, req.user._id);
  }

  @Get('conversation/user/:otherUserId')
  async getConversationWithUser(
    @Param('otherUserId') otherUserId: string,
    @Req() req,
  ) {
    return this.chatService.getConversationWithUser(req.user._id, otherUserId);
  }

  @Get('debug/all')
  async debugAll() {
    return this.chatService.getAllDebug();
  }
}
