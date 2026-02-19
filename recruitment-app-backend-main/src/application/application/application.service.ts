import { Injectable, NotFoundException } from '@nestjs/common';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';
import { Application } from '../schemas/application.schema';
import Job from 'src/job/schemas/job.schema';
import { ApplicationWithJobUser } from '../schemas/fullapp.schema';
import { User } from 'src/auth/schemas/user.schema';

import { NotificationService } from 'src/notification/notification.service';

@Injectable()
export class ApplicationService {
  constructor(
    @InjectModel(Application.name)
    private readonly applicationModel: Model<Application>,
    @InjectModel(Job.name)
    private readonly jobModel: Model<Job>,
    @InjectModel(User.name)
    private readonly userModel,
    private readonly notificationService: NotificationService,
  ) { }

  async getAllApplications(): Promise<ApplicationWithJobUser[]> {
    const applications = await this.applicationModel.find().exec();

    const applicationData: ApplicationWithJobUser[] = [];

    for (const application of applications) {
      const job = await this.jobModel.findById(application.job_id).exec();
      const applicant = await this.userModel
        .findById(application.user_id)
        .exec();
      const publisher = await this.userModel
        .findById(application.entreprise_id)
        .exec();

      if (job && applicant && publisher) {
        const applicationWithJobUser: ApplicationWithJobUser = {
          id: application._id,
          application: application,
          job: job,
          applicant: applicant,
          publisher: publisher,
        };

        applicationData.push(applicationWithJobUser);
      }
    }

    return applicationData;
  }

  async getApplicationsByApplicantId(
    applicantId: string,
  ): Promise<ApplicationWithJobUser[]> {
    const applications = await this.applicationModel
      .find({ user_id: applicantId })
      .exec();

    const applicationData: ApplicationWithJobUser[] = [];

    for (const application of applications) {
      const job = await this.jobModel.findById(application.job_id).exec();
      const applicant = await this.userModel
        .findById(application.user_id)
        .exec();
      const publisher = await this.userModel
        .findById(application.entreprise_id)
        .exec();

      if (job && applicant && publisher) {
        const applicationWithJobUser: ApplicationWithJobUser = {
          id: application._id,
          application: application,
          job: job,
          applicant: applicant,
          publisher: publisher,
        };

        applicationData.push(applicationWithJobUser);
      }
    }

    return applicationData;
  }
  async getApplicationsByEntrepriseId(
    entrepriseId: string,
  ): Promise<ApplicationWithJobUser[]> {
    const applications = await this.applicationModel
      .find({ entreprise_id: entrepriseId })
      .exec();

    const applicationData: ApplicationWithJobUser[] = [];

    for (const application of applications) {
      const job = await this.jobModel.findById(application.job_id).exec();
      const applicant = await this.userModel
        .findById(application.user_id)
        .exec();
      const publisher = await this.userModel
        .findById(application.entreprise_id)
        .exec();

      if (job && applicant && publisher) {
        const applicationWithJobUser: ApplicationWithJobUser = {
          id: application._id,
          application: application,
          job: job,
          applicant: applicant,
          publisher: publisher,
        };

        applicationData.push(applicationWithJobUser);
      }
    }

    return applicationData;
  }
  async getApplicationById(
    applicationId: string,
  ): Promise<ApplicationWithJobUser | null> {
    const application = await this.applicationModel
      .findById(applicationId)
      .exec();

    if (!application) {
      throw new NotFoundException('Application not found');
    }

    const job = await this.jobModel.findById(application.job_id).exec();
    const applicant = await this.userModel.findById(application.user_id).exec();
    const publisher = await this.userModel
      .findById(application.entreprise_id)
      .exec();

    if (!job || !applicant || !publisher) {
      throw new NotFoundException('Related data not found');
    }

    return {
      id: application._id,
      application: application,
      job: job,
      applicant: applicant,
      publisher: publisher,
    };
  }

  async applyForJob(applicationData: any): Promise<Application> {
    const application = new this.applicationModel(applicationData);
    const savedApplication = await application.save();


    await this.updateJobApplicants(
      savedApplication.job_id,
      savedApplication.user_id,
    );


    try {
      const job = await this.jobModel.findById(savedApplication.job_id);
      const applicant = await this.userModel.findById(savedApplication.user_id);
      if (job && applicant) {
        await this.notificationService.send(
          job.entreprise_id,
          'Nouvelle candidature',
          `${applicant.name} a postulé pour ${job.title}`,
          savedApplication._id.toString(),
          'application_new',
        );
      }
    } catch (e) {
      console.error('Failed to send notification for new application', e);
    }

    return savedApplication;
  }
  private async updateJobApplicants(
    jobId: string,
    userId: string,
  ): Promise<void> {
    const job = await this.jobModel.findById(jobId).exec();
    if (!job) {
      throw new NotFoundException('Job not found');
    }


    job.applicants_ids.push(userId);
    await job.save();
  }
  async getApplicationsByJobId(
    jobId: string,
  ): Promise<ApplicationWithJobUser[]> {
    const applications = await this.applicationModel
      .find({ job_id: jobId })
      .exec();

    const applicationData: ApplicationWithJobUser[] = [];

    for (const application of applications) {
      const job = await this.jobModel.findById(application.job_id).exec();
      const applicant = await this.userModel
        .findById(application.user_id)
        .exec();
      const publisher = await this.userModel
        .findById(application.entreprise_id)
        .exec();

      if (job && applicant && publisher) {
        const applicationWithJobUser: ApplicationWithJobUser = {
          id: application._id,
          application: application,
          job: job,
          applicant: applicant,
          publisher: publisher,
        };

        applicationData.push(applicationWithJobUser);
      }
    }

    return applicationData;
  }
  async getApplicationsByStatus(
    status: string,
  ): Promise<ApplicationWithJobUser[]> {
    const applications = await this.applicationModel.find({ status }).exec();

    const applicationData: ApplicationWithJobUser[] = [];

    for (const application of applications) {
      const job = await this.jobModel.findById(application.job_id).exec();
      const applicant = await this.userModel
        .findById(application.user_id)
        .exec();
      const publisher = await this.userModel
        .findById(application.entreprise_id)
        .exec();

      if (job && applicant && publisher) {
        const applicationWithJobUser: ApplicationWithJobUser = {
          id: application._id,
          application: application,
          job: job,
          applicant: applicant,
          publisher: publisher,
        };

        applicationData.push(applicationWithJobUser);
      }
    }

    return applicationData;
  }
  async getApplicationsByUserId(userId: string): Promise<Application[]> {
    return this.applicationModel.find({ user_id: userId }).exec();
  }
  async updateStatus(id: string, status: string): Promise<Application> {
    const application = await this.applicationModel.findById(id).exec();
    if (!application) {
      throw new NotFoundException('Application not found');
    }
    application.status = status;
    const savedApp = await application.save();


    try {
      const job = await this.jobModel.findById(application.job_id);
      if (job) {
        let title = 'Mise à jour de candidature';
        let body = `Le statut de votre candidature pour ${job.title} a changé: ${status}`;

        if (status === 'Accepted') {
          title = 'Félicitations !';
          body = `Votre candidature pour ${job.title} a été acceptée.`;
        } else if (status === 'Rejected') {
          title = 'Candidature refusée';
          body = `Votre candidature pour ${job.title} n'a pas été retenue.`;
        }

        await this.notificationService.send(
          application.user_id,
          title,
          body,
          application._id.toString(),
          'application_status',
        );
      }
    } catch (e) {
      console.error('Failed to send notification for status update', e);
    }

    return savedApp;
  }

  async deleteApplication(id: string): Promise<void> {
    const result = await this.applicationModel.deleteOne({ _id: id }).exec();
    if (result.deletedCount === 0) {
      throw new NotFoundException('Application not found');
    }
  }
}
