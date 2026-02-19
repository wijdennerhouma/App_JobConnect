import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type WorkExperienceDocument = WorkExperience & Document;
@Schema()
export class WorkExperience {
  @Prop()
  jobTitle: string;

  @Prop()
  company: string;

  @Prop()
  startDate: Date;

  @Prop()
  endDate: Date;

  @Prop()
  description: string;
  @Prop({ type: Types.ObjectId, ref: 'Resume' })
  resumeId: string;
}

export const WorkExperienceSchema =
  SchemaFactory.createForClass(WorkExperience);
