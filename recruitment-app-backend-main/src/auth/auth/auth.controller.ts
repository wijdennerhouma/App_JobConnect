import {
  Controller,
  Post,
  Body,
  UseGuards,
  UseInterceptors,
  Get,
  Param,
  NotFoundException,
  UploadedFile,
  StreamableFile,
  BadRequestException,
  Patch,
  Delete,
  Query,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { User } from 'src/auth/schemas/user.schema';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express/multer';
import { diskStorage } from 'multer';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs';


@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }
  @Post('login')
  async login(@Body() loginData: { email: string; password: string }) {
    try {
      const { email, password } = loginData;
      const result = await this.authService.login(email, password);
      return result;
    } catch (error) {
      throw error;
    }
  }
  @Post('signup')
  async signUp(
    @Body() signUpData,
  ): Promise<{ token: string; userId: string; type: string }> {
    const { user, resume } = signUpData;
    return this.authService.signUp(user, resume);
  }
  @Post('/upload-avatar')
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: diskStorage({
        destination: './uploads/avatars',
        filename: (req, file, cb) => {
          const filename = `${uuidv4()}${file.originalname}`;
          cb(null, filename);
        },
      }),
    }),
  )
  async uploadAvatar(
    @UploadedFile() avatar: Express.Multer.File,
  ): Promise<{ avatarPath: string }> {
    const avatarPath = avatar ? `/uploads/avatars/${avatar.filename}` : null;
    return { avatarPath };
  }

  @Post('/upload-identity-pic')
  @UseInterceptors(
    FileInterceptor('identityPic', {
      storage: diskStorage({
        destination: './uploads/identities',
        filename: (req, file, cb) => {
          const filename = `${uuidv4()}${file.originalname}`;
          cb(null, filename);
        },
      }),
    }),
  )
  async uploadIdentityPic(
    @UploadedFile() identityPic: Express.Multer.File,
  ): Promise<{ identityPicPath: string }> {
    const identityPicPath = identityPic
      ? `/uploads/identities/${identityPic.filename}`
      : null;
    return { identityPicPath };
  }

  @Get('avatar/:path')
  async getAvatarByPath(
    @Param('path') imagePath: string,
  ): Promise<StreamableFile> {
    if (!imagePath) {
      throw new NotFoundException('Image path parameter is missing');
    }
    const fullPath = path.join(process.cwd(), 'uploads/avatars/', imagePath);


    if (!fs.existsSync(fullPath)) {
      throw new NotFoundException(`Image at path ${imagePath} not found`);
    }
    const file = fs.createReadStream(fullPath);
    return new StreamableFile(file);
  }
  @Get('identityPic/:path')
  async getIdentiyPicByPath(
    @Param('path') imagePath: string,
  ): Promise<StreamableFile> {
    if (!imagePath) {
      throw new NotFoundException('Image path parameter is missing');
    }
    const fullPath = path.join(process.cwd(), 'uploads/identities/', imagePath);


    if (!fs.existsSync(fullPath)) {
      throw new NotFoundException(`Image at path ${imagePath} not found`);
    }
    const file = fs.createReadStream(fullPath);
    return new StreamableFile(file);
  }
  @Get('user/:id')
  @UseGuards(AuthGuard())
  async getUserById(@Param('id') id: string): Promise<User> {
    const user = await this.authService.getUserById(id);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    console.log(user);
    return user;
  }

  @Post('user/:id/avatar')
  @UseGuards(AuthGuard())
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads/avatars',
        filename: (req, file, cb) => {
          const uniqueSuffix =
            Date.now() + '-' + Math.round(Math.random() * 1e9);
          cb(null, `${uniqueSuffix}-${file.originalname}`);
        },
      }),
    }),
  )
  async updateAvatar(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<User> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    const user = await this.authService.updateAvatar(id, file.filename);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  @Patch('user/:id')
  @UseGuards(AuthGuard())
  async updateUserProfile(
    @Param('id') id: string,
    @Body() updateData: Partial<User>,
  ): Promise<User> {
    const user = await this.authService.updateUserProfile(id, updateData);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }
  @Get('user/:id/saved-jobs')
  @UseGuards(AuthGuard())
  async getSavedJobs(@Param('id') id: string) {
    return this.authService.getSavedJobs(id);
  }

  @Post('user/:id/saved-jobs/:jobId')
  @UseGuards(AuthGuard())
  async toggleSavedJob(@Param('id') id: string, @Param('jobId') jobId: string) {
    return this.authService.toggleSavedJob(id, jobId);
  }

  @Delete('user/:id')
  @UseGuards(AuthGuard())
  async deleteUser(@Param('id') id: string) {
    return this.authService.deleteUser(id);
  }

  @Get('search')
  @UseGuards(AuthGuard())
  async searchUsers(@Query('q') query: string) {
    if (!query) return [];
    return this.authService.searchUsers(query);
  }

  @Post('user/:id/toggle-2fa')
  @UseGuards(AuthGuard())
  async toggleTwoFactor(
    @Param('id') id: string,
    @Body() body: { enable: boolean },
  ) {
    return this.authService.toggleTwoFactor(id, body.enable);
  }

  @Post('user/:id/change-password')
  @UseGuards(AuthGuard())
  async changePassword(
    @Param('id') id: string,
    @Body() body: { currentPass: string; newPass: string },
  ) {
    if (!body.currentPass || !body.newPass) {
      throw new BadRequestException('Current and new passwords are required');
    }
    return this.authService.changePassword(id, body.currentPass, body.newPass);
  }
}
