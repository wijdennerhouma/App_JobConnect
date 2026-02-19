// application.controller.ts
import {
  Controller,
  Post,
  Body,
  UseGuards,
  Param,
  Get,
  Patch,
  Delete,
} from '@nestjs/common';
import { ApplicationService } from './application.service';
import { AuthGuard } from '@nestjs/passport';
import { ApplicationWithJobUser } from '../schemas/fullapp.schema';

@Controller('applications')
export class ApplicationController {
  constructor(private readonly applicationService: ApplicationService) {}

  @Get()
  @UseGuards(AuthGuard())
  async getAllApplications(): Promise<ApplicationWithJobUser[]> {
    return this.applicationService.getAllApplications();
  }
  @Get('status/:status')
  @UseGuards(AuthGuard())
  async getApplicationsByStatus(
    @Param('status') status: string,
  ): Promise<ApplicationWithJobUser[]> {
    return this.applicationService.getApplicationsByStatus(status);
  }

  @Post()
  @UseGuards(AuthGuard())
  async applyForJob(@Body() applicationData: any) {
    return this.applicationService.applyForJob(applicationData);
  }

  @Get('job/:jobId')
  @UseGuards(AuthGuard())
  async getApplicationsByJobId(
    @Param('jobId') jobId: string,
  ): Promise<ApplicationWithJobUser[]> {
    return this.applicationService.getApplicationsByJobId(jobId);
  }
  @Get('byApplicant/:applicantId')
  @UseGuards(AuthGuard())
  async getApplicationsByApplicantId(
    @Param('applicantId') applicantId: string,
  ): Promise<ApplicationWithJobUser[]> {
    return this.applicationService.getApplicationsByApplicantId(applicantId);
  }

  @Get('byEntreprise/:entrepriseId')
  @UseGuards(AuthGuard())
  async getApplicationsByEntrepriseId(
    @Param('entrepriseId') entrepriseId: string,
  ): Promise<ApplicationWithJobUser[]> {
    return this.applicationService.getApplicationsByEntrepriseId(entrepriseId);
  }

  @Get(':id')
  @UseGuards(AuthGuard())
  async getApplicationWithJobUser(
    @Param('id') applicationId: string,
  ): Promise<ApplicationWithJobUser | null> {
    return this.applicationService.getApplicationById(applicationId);
  }
  @Patch(':id/status')
  @UseGuards(AuthGuard())
  async updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.applicationService.updateStatus(id, status);
  }

  @Delete(':id')
  @UseGuards(AuthGuard())
  async deleteApplication(@Param('id') id: string) {
    return this.applicationService.deleteApplication(id);
  }
}
