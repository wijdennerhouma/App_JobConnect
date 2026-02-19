import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CertificationDocument = Certification & Document;

@Schema()
export class Certification {
  @Prop()
  name: string;

  @Prop()
  issuer: string;

  @Prop()
  date: Date;

  @Prop()
  credentialsLink: string;
  @Prop({ type: Types.ObjectId, ref: 'Resume' })
  resumeId: string;
}

export const CertificationSchema = SchemaFactory.createForClass(Certification);
