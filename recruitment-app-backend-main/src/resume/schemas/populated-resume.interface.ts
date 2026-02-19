import { Certification } from './certification.schema';
import { Education } from './education.schema';
import { Language } from './language.schema';
import { Skills } from './skill.schema';
import { WorkExperience } from './workexperience.schema';

export interface PopulatedResume {
  _id: string; // You may need to adjust the type for _id based on your schema
  file: string;
  userId: string;
  education: Education[]; // Define the Education type
  workExperience: WorkExperience[]; // Define the WorkExperience type
  skills: Skills[]; // Define the Skills type
  certifications: Certification[]; // Define the Certification type
  languages: Language[]; // Define the Language type
}
