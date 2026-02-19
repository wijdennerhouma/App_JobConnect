import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type EducationDocument = Education & Document;

@Schema()
export class Education {
  @Prop()
  school: string;

  @Prop()
  degree: string;

  @Prop()
  field: string;

  @Prop()
  startDate: string;

  @Prop()
  endDate: string;

  @Prop({ type: Types.ObjectId, ref: 'Resume' })
  resumeId: string;
}

export const EducationSchema = SchemaFactory.createForClass(Education);
