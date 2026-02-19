import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SkillsDocument = Skills & Document;

@Schema()
export class Skills {
  @Prop()
  name: string;

  @Prop()
  proficiency: string;
  @Prop({ type: Types.ObjectId, ref: 'Resume' })
  resumeId: string;
}

export const SkillsSchema = SchemaFactory.createForClass(Skills);
