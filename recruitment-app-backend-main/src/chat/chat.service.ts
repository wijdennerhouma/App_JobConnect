import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Message, MessageDocument } from './schemas/message.schema';
import {
  Conversation,
  ConversationDocument,
} from './schemas/conversation.schema';
import { User } from '../auth/schemas/user.schema';

import { NotificationService } from 'src/notification/notification.service';

/** Réponse API pour un message (IDs en string pour le client). */
export interface ChatMessageResponse {
  _id: string;
  sender: string;
  receiver: string;
  content: string;
  timestamp: string;
  conversationId: string;
  isRead: boolean;
}

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Message.name) private messageModel: Model<Message>,
    @InjectModel(Conversation.name)
    private conversationModel: Model<Conversation>,
    @InjectModel(User.name) private userModel,
    private readonly notificationService: NotificationService,
  ) { }

  async sendMessage(
    senderId: string,
    receiverId: string,
    content: string,
  ): Promise<ChatMessageResponse> {
    console.log(
      `sendMessage: sender=${senderId}, receiver=${receiverId}, content=${content}`,
    );
    let conversation = await this.conversationModel.findOne({
      participants: { $all: [senderId, receiverId] },
    });

    if (!conversation) {
      console.log('sendMessage: No conversation found, creating new one.');
      conversation = new this.conversationModel({
        participants: [senderId, receiverId],
        lastMessage: content,
        lastMessageDate: new Date(),
      });
      await conversation.save();
      console.log(`sendMessage: Created conversation ${conversation._id}`);
    } else {
      console.log(`sendMessage: Found conversation ${conversation._id}`);
      conversation.lastMessage = content;
      conversation.lastMessageDate = new Date();
      await conversation.save();
      console.log('sendMessage: Updated conversation lastMessage');
    }

    const message = new this.messageModel({
      sender: senderId,
      receiver: receiverId,
      content,
      conversationId: conversation._id,
      timestamp: new Date(),
    });

    const savedMessage = await message.save();
    console.log(`sendMessage: Saved message ${savedMessage._id}`);

    try {
      const sender = await this.userModel.findById(senderId);
      let senderName = 'Utilisateur';

      if (sender) {
        const parts = [];
        if (sender.firstName && sender.firstName !== 'undefined')
          parts.push(sender.firstName);
        if (sender.name && sender.name !== 'undefined') parts.push(sender.name);

        if (parts.length > 0) {
          senderName = parts.join(' ');
        }
      }

      await this.notificationService.send(
        receiverId,
        'Nouveau message',
        `Message from: ${senderName}`,
        conversation._id.toString(),
        'new_message',
      );
    } catch (e) {
      console.error('Failed to send notification for new message', e);
    }

    return this.toMessageResponse(savedMessage);
  }

  /** Sérialise un document Message pour l’API (persistance en base déjà faite). */
  toMessageResponse(doc: MessageDocument): ChatMessageResponse {
    return {
      _id: doc._id.toString(),
      sender: doc.sender?.toString() ?? '',
      receiver: doc.receiver?.toString() ?? '',
      content: doc.content ?? '',
      timestamp: (doc.timestamp ?? doc['createdAt'] ?? new Date()).toISOString(),
      conversationId: doc.conversationId?.toString() ?? '',
      isRead: doc.isRead ?? false,
    };
  }

  async getConversations(userId: string): Promise<any[]> {
    const conversations = await this.conversationModel
      .find({ participants: userId })
      .sort({ lastMessageDate: -1 })
      .populate('participants', 'name firstName avatar email')
      .exec();

    return conversations;
  }

  async getMessages(
    conversationId: string,
    currentUserId: string,
  ): Promise<ChatMessageResponse[]> {
    console.log(
      `getMessages: Fetching messages for conversationId=${conversationId} (type: ${typeof conversationId})`,
    );

    try {
      const objectId = new Types.ObjectId(conversationId);
      const messages = await this.messageModel
        .find({ conversationId: objectId })
        .sort({ timestamp: 1 })
        .exec();

      console.log(
        `getMessages: Found ${messages.length} messages for ID ${conversationId}`,
      );


      const unreadMessagesIds = messages
        .filter(
          (msg) =>
            msg.receiver.toString() === currentUserId.toString() && !msg.isRead,
        )
        .map((msg) => msg._id);

      if (unreadMessagesIds.length > 0) {
        await this.messageModel.updateMany(
          { _id: { $in: unreadMessagesIds } },
          { $set: { isRead: true } },
        );
        console.log(
          `getMessages: Marked ${unreadMessagesIds.length} messages as read`,
        );
      }

      return messages.map((m) => this.toMessageResponse(m as MessageDocument));
    } catch (e) {
      console.error('getMessages error:', e);
      return [];
    }
  }

  async getConversationWithUser(
    currentUserId: string,
    otherUserId: string,
  ): Promise<Conversation> {
    const conversation = await this.conversationModel
      .findOne({
        participants: { $all: [currentUserId, otherUserId] },
      })
      .populate('participants', 'name firstName avatar email')
      .exec();

    if (!conversation) {
      return null;
    }
    return conversation;
  }

  async getAllDebug(): Promise<any> {
    const conversations = await this.conversationModel.find().exec();
    const messages = await this.messageModel.find().exec();
    return {
      conversations,
      messages,
    };
  }
}
