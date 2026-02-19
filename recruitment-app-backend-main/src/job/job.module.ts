import { Module } from '@nestjs/common';
import { JobService } from './job/job.service';
import { JobController } from './job/job.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { JobSchema } from './schemas/job.schema';
import { AuthModule } from 'src/auth/auth.module';
import { JwtService } from '@nestjs/jwt';
import { EntrepriseGuard } from 'src/auth/auth/entreprise.guard';
import { EmployeeGuard } from 'src/auth/auth/employee.guard';
import { PassportModule } from '@nestjs/passport';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    AuthModule,
    MongooseModule.forFeature([{ name: 'Job', schema: JobSchema }]),
  ],
  providers: [JobService, JwtService, EntrepriseGuard, EmployeeGuard],
  controllers: [JobController],
})
export class JobModule {}
