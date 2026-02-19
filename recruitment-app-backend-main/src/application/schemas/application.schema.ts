// application.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema()
export class Application extends Document {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Job' })
  job_id: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  user_id: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  entreprise_id: string;

  @Prop({
    required: true,
    enum: [
      'pending',
      'reviewed',
      'accepted',
      'rejected',
      'contract_signed',
      'started',
      'finished',
    ],
  })
  status: string;

  @Prop({ required: false })
  coverLetter: string;

  @Prop({ required: false })
  skills: string[];
}

export const ApplicationSchema = SchemaFactory.createForClass(Application);
