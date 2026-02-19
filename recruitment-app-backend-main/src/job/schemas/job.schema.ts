import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { now } from 'mongoose';

export enum PricingType {
  PER_HOUR = 'per hour',
  PER_DAY = 'per day',
}

@Schema({
  timestamps: true,
})
export default class Job {
  @Prop({ required: true })
  title: string;
  @Prop({ required: true })
  description: string;
  @Prop({ required: true })
  startTime: string;
  @Prop({ required: true })
  endTime: string;
  @Prop({ required: true })
  duration: string;
  @Prop({ required: true })
  contract: string;
  @Prop({ required: true })
  entreprise_id: string;
  @Prop({ required: true })
  startDate: string;
  @Prop({ required: true })
  endDate: string;
  @Prop({ required: true })
  work_hours: number;
  @Prop({ required: true, default: [] })
  applicants_ids: string[];
  @Prop({ required: true })
  price: number;
  @Prop({ required: true })
  pricing_type: PricingType;
  @Prop({ default: now() })
  createdAt: Date;
  @Prop({ default: now() })
  updatedAt: Date;
  @Prop({ required: true })
  address: string;
}

export const JobSchema = SchemaFactory.createForClass(Job);
