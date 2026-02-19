import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { Resume } from 'src/resume/schemas/resume.schema';

export type UserDocument = User & Document;

@Schema()
export class User {
  @Prop({ required: true })
  name: string;

  @Prop()
  firstName: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string;
  @Prop()
  phoneNumber: string;

  @Prop()
  avatar: string;

  @Prop()
  cinOrPassport: string;

  @Prop()
  identityPic: string;
  @Prop()
  address: string;
  @Prop()
  city: string;
  @Prop()
  country: string;
  @Prop()
  postalCode: string;

  @Prop()
  bio: string;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Job' }] })
  savedJobs: Types.ObjectId[];

  @Prop({ required: true, enum: ['entreprise', 'employee'] })
  type: string;
  @Prop({ type: Types.ObjectId, ref: 'Resume' })
  resume: Resume;

  @Prop({ default: true })
  isPublicProfile: boolean;

  @Prop({ default: false })
  showEmail: boolean;

  @Prop({ default: false })
  showPhoneNumber: boolean;

  @Prop()
  fcmToken: string;

  @Prop({ default: false })
  isTwoFactorEnabled: boolean;
}

export const UserSchema = SchemaFactory.createForClass(User);
