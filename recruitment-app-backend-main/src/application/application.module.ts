import { Module } from '@nestjs/common';
import { ApplicationService } from './application/application.service';
import { ApplicationController } from './application/application.controller';
import { PassportModule } from '@nestjs/passport';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from 'src/auth/auth.module';
import { ApplicationSchema } from './schemas/application.schema';
import { JobModule } from 'src/job/job.module';
import { JobSchema } from 'src/job/schemas/job.schema';
import { UserSchema } from 'src/auth/schemas/user.schema';
import { NotificationModule } from 'src/notification/notification.module';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    AuthModule,
    JobModule,
    NotificationModule,
    MongooseModule.forFeature([
      { name: 'Application', schema: ApplicationSchema },
      { name: 'Job', schema: JobSchema },
      { name: 'User', schema: UserSchema },
    ]),
  ],
  providers: [ApplicationService],
  controllers: [ApplicationController],
})
export class ApplicationModule {}
