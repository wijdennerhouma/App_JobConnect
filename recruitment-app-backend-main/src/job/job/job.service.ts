import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import Job from '../schemas/job.schema';
import * as mongoose from 'mongoose';
import * as moment from 'moment';

@Injectable()
export class JobService {
  constructor(
    @InjectModel(Job.name)
    private jobModel: mongoose.Model<Job>,
  ) { }
  async findJobsByUserID(userID: string): Promise<Job[]> {
    try {

      const jobs = await this.jobModel
        .find({ applicants_ids: { $all: [userID] } })
        .exec();
      return jobs;
    } catch (error) {

      throw new Error('Failed to fetch jobs by user ID');
    }
  }
  async findAll(): Promise<Job[]> {
    const jobs = await this.jobModel.find().exec();
    return jobs;
  }
  async createJob(job: Job): Promise<Job> {
    const res = await this.jobModel.create(job);
    return res;
  }
  async findById(id: string): Promise<Job | null> {
    return this.jobModel.findById(id).exec();
  }
  async findByCity(city: string): Promise<Job[]> {
    return this.jobModel
      .find({ address: { $regex: city, $options: 'i' } })
      .exec();
  }
  async findByStartDate(startDate: Date): Promise<Job[]> {
    return this.jobModel.find({ startDate: startDate }).exec();
  }
  async findByPriceAndType(
    minPrice: number,
    maxPrice: number,
    pricingType: string,
  ): Promise<Job[]> {
    return this.jobModel
      .find({
        price: { $gte: minPrice, $lte: maxPrice },
        pricing_type: pricingType,
      })
      .exec();
  }
  async findByDateRange(startDate: Date, endDate: Date) {
    return this.jobModel
      .find({
        startDate: {
          $gte: moment(startDate).format(),
        },
        endDate: {
          $lte: moment(endDate).format(),
        },
      })
      .exec();
  }
  async deleteJob(id: string): Promise<Job | null> {
    return this.jobModel.findByIdAndDelete(id).exec();
  }
}
