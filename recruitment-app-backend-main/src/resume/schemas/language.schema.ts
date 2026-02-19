import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type LanguageDocument = Language & Document;

@Schema()
export class Language {
  @Prop()
  name: string;

  @Prop()
  proficiency: string;
  @Prop({ type: Types.ObjectId, ref: 'Resume' })
  resumeId: string;
}
export const LanguageSchema = SchemaFactory.createForClass(Language);
