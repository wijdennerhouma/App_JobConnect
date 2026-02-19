import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ResumeDocument = Resume & Document;

@Schema()
export class Resume {
  @Prop()
  file: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  userId: string;

  @Prop({ type: Types.ObjectId, ref: 'Education' })
  education: string[];

  @Prop({ type: Types.ObjectId, ref: 'WorkExperience' })
  workExperience: string[];

  @Prop({ type: Types.ObjectId, ref: 'Skills' })
  skills: string[];

  @Prop({ type: Types.ObjectId, ref: 'Certification' })
  certifications: string[];

  @Prop({ type: Types.ObjectId, ref: 'Language' })
  languages: string[];
}

export const ResumeSchema = SchemaFactory.createForClass(Resume);
