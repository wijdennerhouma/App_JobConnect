import { Module } from '@nestjs/common';
import { ResumeService } from './resume/resume.service';
import { MongooseModule } from '@nestjs/mongoose';
import { Resume, ResumeSchema } from './schemas/resume.schema';
import { Education, EducationSchema } from './schemas/education.schema';
import {
  WorkExperience,
  WorkExperienceSchema,
} from './schemas/workexperience.schema';
import { Language, LanguageSchema } from './schemas/language.schema';
import { Skills, SkillsSchema } from './schemas/skill.schema';
import {
  Certification,
  CertificationSchema,
} from './schemas/certification.schema';
import { ResumeController } from './resume/resume.controller';
import { PassportModule } from '@nestjs/passport';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    MongooseModule.forFeature([
      { name: Resume.name, schema: ResumeSchema },
      { name: Education.name, schema: EducationSchema },
      { name: Language.name, schema: LanguageSchema },
      { name: Skills.name, schema: SkillsSchema },
      { name: WorkExperience.name, schema: WorkExperienceSchema },
      { name: Certification.name, schema: CertificationSchema },
    ]),
  ],
  providers: [ResumeService],
  controllers: [ResumeController],
  exports: [ResumeService],
})
export class ResumeModule {}
