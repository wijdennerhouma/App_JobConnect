import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Resume, ResumeDocument } from '../schemas/resume.schema';
import { Model } from 'mongoose';
import { Education } from '../schemas/education.schema';
import { WorkExperience } from '../schemas/workexperience.schema';
import { Language } from '../schemas/language.schema';
import { Skills } from '../schemas/skill.schema';
import { Certification } from '../schemas/certification.schema';
import { PopulatedResume } from '../schemas/populated-resume.interface'; // Adjust the path as needed

@Injectable()
export class ResumeService {
  constructor(
    @InjectModel(Resume.name)
    private readonly resumeModel: Model<ResumeDocument>,
    @InjectModel(Education.name)
    private readonly educationModel: Model<Education>,
    @InjectModel(WorkExperience.name)
    private readonly workExperienceModel: Model<WorkExperience>,
    @InjectModel(Language.name) private readonly languageModel: Model<Language>,
    @InjectModel(Skills.name) private readonly skillsModel: Model<Skills>,
    @InjectModel(Certification.name)
    private readonly certificationModel: Model<Certification>,
    @InjectModel(Language.name)
    private readonly langModel: Model<Language>,
  ) {}
  async createResume(data: any): Promise<Resume> {
    try {
      // Ensure arrays exist and are iterable
      const education = Array.isArray(data.education) ? data.education : [];
      const workExperience = Array.isArray(data.workExperience)
        ? data.workExperience
        : [];
      const skills = Array.isArray(data.skills) ? data.skills : [];
      const certifications = Array.isArray(data.certifications)
        ? data.certifications
        : [];
      const languages = Array.isArray(data.languages) ? data.languages : [];

      const hasData =
        education.length > 0 ||
        workExperience.length > 0 ||
        skills.length > 0 ||
        certifications.length > 0 ||
        languages.length > 0;

      if (!hasData && !data.file) {
        // Create empty resume
        return await this.resumeModel.create(data);
      }

      const educationIds: string[] = [];
      const workIds: string[] = [];
      const skillIds: string[] = [];
      const certifIds: string[] = [];
      const languageIds: string[] = [];

      for (const ed of education) {
        const newEd = await this.educationModel.create(ed);
        educationIds.push(newEd._id.toString());
      }

      for (const work of workExperience) {
        const newWork = await this.workExperienceModel.create(work);
        workIds.push(newWork._id.toString());
      }

      for (const skill of skills) {
        const newSkill = await this.skillsModel.create(skill);
        skillIds.push(newSkill._id.toString());
      }

      for (const cert of certifications) {
        const newCert = await this.certificationModel.create(cert);
        certifIds.push(newCert._id.toString());
      }

      for (const lang of languages) {
        const newLang = await this.languageModel.create(lang);
        languageIds.push(newLang._id.toString());
      }

      // Create resume with IDs
      const resumeData = {
        ...data,
        education: educationIds,
        workExperience: workIds,
        skills: skillIds,
        certifications: certifIds,
        languages: languageIds,
      };

      return await this.resumeModel.create(resumeData);
    } catch (error) {
      console.error('Error creating resume:', error);
      throw error;
    }
  }

  async getResumesByUserId(userId: string): Promise<PopulatedResume | null> {
    try {
      const resume = await this.resumeModel.findOne({ userId }).exec();
      if (!resume) {
        return null;
      }

      const resumeObj = resume.toObject();

      // Helper function to safely fetch related documents
      const safeFind = async (model: any, ids: any[]) => {
        if (!Array.isArray(ids) || ids.length === 0) {
          return [];
        }
        try {
          // Filter out invalid IDs and convert strings to ObjectIds
          const validIds = ids
            .filter((id) => id && (typeof id === 'string' || id._id))
            .map((id) => (typeof id === 'string' ? id : id._id));

          if (validIds.length === 0) return [];
          return await model.find({ _id: { $in: validIds } }).exec();
        } catch (e) {
          console.warn('Error fetching related documents:', e);
          return [];
        }
      };

      // Fetch the associated subdocuments
      const education = await safeFind(
        this.educationModel,
        resumeObj.education,
      );
      const workExperience = await safeFind(
        this.workExperienceModel,
        resumeObj.workExperience,
      );
      const skills = await safeFind(this.skillsModel, resumeObj.skills);
      const certifications = await safeFind(
        this.certificationModel,
        resumeObj.certifications,
      );
      const languages = await safeFind(this.langModel, resumeObj.languages);

      return {
        ...resumeObj,
        education,
        workExperience,
        skills,
        certifications,
        languages,
      };
    } catch (error) {
      console.error('Error fetching resume:', error);
      throw error;
    }
  }

  async getResumeById(id: string): Promise<any> {
    try {
      const resume = await this.resumeModel.findById(id).exec();
      if (!resume) {
        return null;
      }

      const resumeObj = resume.toObject();

      // Helper function to safely fetch related documents
      const safeFind = async (model: any, ids: any[]) => {
        if (!Array.isArray(ids) || ids.length === 0) {
          return [];
        }
        try {
          const validIds = ids
            .filter((id) => id && (typeof id === 'string' || id._id))
            .map((id) => (typeof id === 'string' ? id : id._id));

          if (validIds.length === 0) return [];
          return await model.find({ _id: { $in: validIds } }).exec();
        } catch (e) {
          console.warn('Error fetching related documents:', e);
          return [];
        }
      };

      // Fetch the associated subdocuments
      const education = await safeFind(
        this.educationModel,
        resumeObj.education,
      );
      const workExperience = await safeFind(
        this.workExperienceModel,
        resumeObj.workExperience,
      );
      const skills = await safeFind(this.skillsModel, resumeObj.skills);
      const certifications = await safeFind(
        this.certificationModel,
        resumeObj.certifications,
      );
      const languages = await safeFind(this.langModel, resumeObj.languages);

      return {
        ...resumeObj,
        education,
        workExperience,
        skills,
        certifications,
        languages,
      };
    } catch (error) {
      console.error('Error fetching resume by id:', error);
      throw error;
    }
  }

  async updateResume(id: string, updateData: any): Promise<any> {
    try {
      // Ensure arrays exist and are iterable
      const education = Array.isArray(updateData.education)
        ? updateData.education
        : [];
      const workExperience = Array.isArray(updateData.workExperience)
        ? updateData.workExperience
        : [];
      const skills = Array.isArray(updateData.skills) ? updateData.skills : [];
      const certifications = Array.isArray(updateData.certifications)
        ? updateData.certifications
        : [];
      const languages = Array.isArray(updateData.languages)
        ? updateData.languages
        : [];

      // Get existing resume
      const existingResume = await this.resumeModel.findById(id).exec();
      if (!existingResume) {
        throw new Error('Resume not found');
      }

      // Convert new objects (without _id) to documents
      const educationIds: string[] = [];
      const workIds: string[] = [];
      const skillIds: string[] = [];
      const certifIds: string[] = [];
      const languageIds: string[] = [];

      // Process education
      for (const ed of education) {
        if (typeof ed === 'object' && ed._id) {
          // Existing document, keep the ID
          educationIds.push(ed._id.toString());
        } else if (typeof ed === 'object') {
          // New document, create it
          const newEd = await this.educationModel.create(ed);
          educationIds.push(newEd._id.toString());
        } else if (typeof ed === 'string') {
          // Already an ID
          educationIds.push(ed);
        }
      }

      // Process workExperience
      for (const work of workExperience) {
        if (typeof work === 'object' && work._id) {
          workIds.push(work._id.toString());
        } else if (typeof work === 'object') {
          const newWork = await this.workExperienceModel.create(work);
          workIds.push(newWork._id.toString());
        } else if (typeof work === 'string') {
          workIds.push(work);
        }
      }

      // Process skills
      for (const skill of skills) {
        if (typeof skill === 'object' && skill._id) {
          skillIds.push(skill._id.toString());
        } else if (typeof skill === 'object') {
          const newSkill = await this.skillsModel.create(skill);
          skillIds.push(newSkill._id.toString());
        } else if (typeof skill === 'string') {
          skillIds.push(skill);
        }
      }

      // Process certifications
      for (const cert of certifications) {
        if (typeof cert === 'object' && cert._id) {
          certifIds.push(cert._id.toString());
        } else if (typeof cert === 'object') {
          const newCert = await this.certificationModel.create(cert);
          certifIds.push(newCert._id.toString());
        } else if (typeof cert === 'string') {
          certifIds.push(cert);
        }
      }

      // Process languages
      for (const lang of languages) {
        if (typeof lang === 'object' && lang._id) {
          languageIds.push(lang._id.toString());
        } else if (typeof lang === 'object') {
          const newLang = await this.langModel.create(lang);
          languageIds.push(newLang._id.toString());
        } else if (typeof lang === 'string') {
          languageIds.push(lang);
        }
      }

      // Update resume with new IDs
      const updatePayload = {
        ...updateData,
        education: educationIds,
        workExperience: workIds,
        skills: skillIds,
        certifications: certifIds,
        languages: languageIds,
      };

      const updatedResume = await this.resumeModel
        .findByIdAndUpdate(id, updatePayload, { new: true })
        .exec();

      // Return populated data
      return this.getResumesByUserId(updatedResume.userId.toString());
    } catch (error) {
      console.error('Error updating resume:', error);
      throw error;
    }
  }

  async deleteResume(id: string): Promise<Resume | null> {
    return this.resumeModel.findByIdAndDelete(id).exec();
  }
}
