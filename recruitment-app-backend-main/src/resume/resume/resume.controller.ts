import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  Put,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { ResumeService } from './resume.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('resumes')
export class ResumeController {
  constructor(private readonly resumeService: ResumeService) {}

  @Post()
  @UseGuards(AuthGuard())
  async createResume(@Body() createResumeDto: any) {
    return this.resumeService.createResume(createResumeDto);
  }

  @Get(':id')
  @UseGuards(AuthGuard())
  async getResumeById(@Param('id') id: string) {
    return this.resumeService.getResumeById(id);
  }

  @Get('user/:userId')
  @UseGuards(AuthGuard())
  async getResumesByUserId(@Param('userId') userId: string) {
    return this.resumeService.getResumesByUserId(userId);
  }

  @Put(':id')
  @UseGuards(AuthGuard())
  async updateResume(@Param('id') id: string, @Body() updateResumeDto: any) {
    return this.resumeService.updateResume(id, updateResumeDto);
  }

  @Delete(':id')
  @UseGuards(AuthGuard())
  async deleteResume(@Param('id') id: string) {
    return this.resumeService.deleteResume(id);
  }
}
