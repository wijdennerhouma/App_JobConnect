import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Delete,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JobService } from './job.service';
import Job from '../schemas/job.schema';
import { AuthGuard } from '@nestjs/passport';

@Controller('job')
export class JobController {
  constructor(private jobService: JobService) { }
  @Get()
  @UseGuards(AuthGuard())
  async getAllJobs(): Promise<Job[]> {
    return this.jobService.findAll();
  }
  @Get('byCity')
  @UseGuards(AuthGuard())
  async getJobsByCity(@Query('city') city: string): Promise<Job[]> {
    return this.jobService.findByCity(city);
  }
  @Get('/byStartDate')
  @UseGuards(AuthGuard())
  async getJobsByStartDate(
    @Query('startDate') startDate: Date,
  ): Promise<Job[]> {
    return this.jobService.findByStartDate(startDate);
  }
  @Get('/byPriceAndType')
  @UseGuards(AuthGuard())
  async getJobsByPriceAndType(
    @Query('minPrice') minPrice: number,
    @Query('maxPrice') maxPrice: number,
    @Query('pricingType') pricingType: string,
  ): Promise<Job[]> {
    return this.jobService.findByPriceAndType(minPrice, maxPrice, pricingType);
  }
  @Get('by-user')
  @UseGuards(AuthGuard())
  async getJobsByUserID(@Query('userID') userID: string) {
    try {
      const jobs = await this.jobService.findJobsByUserID(userID);
      return jobs;
    } catch (error) {
      throw new Error('Failed to fetch jobs by user ID');
    }
  }
  @Get('byDateRange')
  @UseGuards(AuthGuard())
  async getJobsByDateRange(
    @Param('startDate') startDate: string,
    @Param('endDate') endDate: string,
  ) {
    const parsedStartDate = new Date(startDate);
    const parsedEndDate = new Date(endDate);
    return this.jobService.findByDateRange(parsedStartDate, parsedEndDate);
  }
  @Get(':id')
  @UseGuards(AuthGuard())
  async getJobById(@Param('id') id: string): Promise<Job | null> {
    return this.jobService.findById(id);
  }
  @Post('create')
  @UseGuards(AuthGuard())
  async createJob(@Body() jobData: Job, @Request() req): Promise<Job> {
    const entreprise_id = req.user.id;
    jobData.entreprise_id = entreprise_id;
    return this.jobService.createJob(jobData);
  }

  @Delete(':id')
  @UseGuards(AuthGuard())
  async deleteJob(@Param('id') id: string) {
    return this.jobService.deleteJob(id);
  }
}
