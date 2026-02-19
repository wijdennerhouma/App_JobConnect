import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as admin from 'firebase-admin';
import {
  Notification,
  NotificationDocument,
} from './schemas/notification.schema';
import { User } from '../auth/schemas/user.schema';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name)
    private notificationModel: Model<NotificationDocument>,
    @InjectModel(User.name) private userModel,
  ) {
    // Initialize Firebase Admin if not already initialized
    // Ideally this should be done in a dedicated config module or main.ts
    // For now we assume the credentials are in environment variables or default app is used
    if (admin.apps.length === 0) {
      try {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          // Or use specific path if GOOGLE_APPLICATION_CREDENTIALS is not set
        });
        this.logger.log('Firebase Admin Initialized');
      } catch (e) {
        this.logger.error('Failed to initialize Firebase Admin', e);
      }
    }
  }

  async send(
    userId: string,
    title: string,
    body: string,
    relatedId?: string,
    type: string = 'general',
  ) {
    // 1. Save to Database
    const notification = new this.notificationModel({
      userId: new Types.ObjectId(userId),
      title,
      body,
      type,
      relatedId: relatedId ? new Types.ObjectId(relatedId) : null,
    });
    await notification.save();

    // 2. Send via FCM if token exists
    try {
      const user = await this.userModel.findById(userId);
      if (user && user.fcmToken) {
        await admin.messaging().send({
          token: user.fcmToken,
          notification: {
            title,
            body,
          },
          data: {
            type,
            relatedId: relatedId || '',
          },
        });
        this.logger.log(`Notification sent to user ${userId}`);
      }
    } catch (error) {
      this.logger.error(`Error sending FCM to user ${userId}`, error);
    }

    return notification;
  }

  async findAll(userId: string) {
    return this.notificationModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec();
  }

  async markAsRead(id: string) {
    return this.notificationModel
      .findByIdAndUpdate(id, { isRead: true }, { new: true })
      .exec();
  }
}
