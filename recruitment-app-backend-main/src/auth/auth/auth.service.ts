import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from 'src/auth/schemas/user.schema';
import * as bcrypt from 'bcryptjs';
import { JwtService } from '@nestjs/jwt';
import { ResumeService } from 'src/resume/resume/resume.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name)
    private userModel: Model<User>,
    private jwtService: JwtService,
    private resumeService: ResumeService,
  ) {}

  async signUp(
    user: User,
    resume: any,
  ): Promise<{ token: string; userId: string; type: string }> {
    const existingUser = await this.userModel.findOne({ email: user.email });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Hash the user's password
    const hashedPassword = await bcrypt.hash(user.password, 10);
    user.password = hashedPassword;

    // Create the user
    const createdUser = await this.userModel.create(user);

    if (user.type === 'employee') {
      // Set the user ID in the resume data
      resume.userId = createdUser._id.toString();
      // Create the resume
      const createdResume = await this.resumeService.createResume(resume);
    }

    // Sign a JWT token for the user
    const token = this.jwtService.sign({
      id: createdUser._id,
      type: user.type,
    });

    return {
      token,
      userId: createdUser._id.toString(),
      type: createdUser.type,
    };
  }
  async login(email, password) {
    try {
      // Find the user by email
      const user = await this.userModel.findOne({ email });

      if (!user) {
        throw new NotFoundException("Le compte avec cet email n'existe pas.");
      }

      // Check if the provided password matches the stored hashed password
      const passwordMatch = await bcrypt.compare(password, user.password);

      if (!passwordMatch) {
        // throw a 401 Unauthorized error for incorrect password
        throw new Error('Incorrect password');
      }

      // If email and password are valid, generate a JWT token
      const token = this.jwtService.sign({ id: user._id, type: user.type });

      return {
        token,
        userId: user._id.toString(),
        type: user.type,
        isTwoFactorEnabled: user.isTwoFactorEnabled || false,
      };
    } catch (error) {
      // Handle errors and throw the appropriate status code
      if (error.message === 'User not found') {
        throw new NotFoundException('User not found');
      } else if (error.message === 'Incorrect password') {
        throw new UnauthorizedException('Incorrect password');
      } else {
        // Handle other errors as needed
        throw new InternalServerErrorException('Internal server error');
      }
    }
  }
  async getUserById(id: string): Promise<User | null> {
    return this.userModel.findById(id).exec();
  }

  async updateAvatar(userId: string, avatarPath: string): Promise<User | null> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    user.avatar = avatarPath;
    await user.save();

    return user;
  }

  async updateUserProfile(
    userId: string,
    updateData: Partial<User>,
  ): Promise<User | null> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    Object.assign(user, updateData);
    await user.save();

    return user;
  }
  async getSavedJobs(userId: string): Promise<any[]> {
    const user = await this.userModel
      .findById(userId)
      .populate('savedJobs')
      .exec();
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }
    return user.savedJobs;
  }

  async toggleSavedJob(
    userId: string,
    jobId: string,
  ): Promise<{ saved: boolean; savedJobs: any[] }> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    if (!user.savedJobs) {
      user.savedJobs = [];
    }

    // Convert savedJobs to strings for comparison
    const savedJobIndex = user.savedJobs.findIndex(
      (id) => id.toString() === jobId,
    );
    let saved = false;

    if (savedJobIndex > -1) {
      // Remove
      user.savedJobs.splice(savedJobIndex, 1);
      saved = false;
    } else {
      // Add
      // @ts-ignore
      user.savedJobs.push(jobId);
      saved = true;
    }

    await user.save();
    return { saved, savedJobs: user.savedJobs }; // Return updated list/status
  }

  async deleteUser(userId: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(userId);
    if (!result) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }
  }

  async searchUsers(query: string): Promise<User[]> {
    return this.userModel
      .find({
        name: { $regex: query, $options: 'i' },
        isPublicProfile: true, // Only search public profiles
      })
      .select('-password')
      .exec();
  }

  async changePassword(
    userId: string,
    currentPass: string,
    newPass: string,
  ): Promise<void> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isMatch = await bcrypt.compare(currentPass, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const hashedNewPass = await bcrypt.hash(newPass, 10);
    user.password = hashedNewPass;
    await user.save();
  }

  async toggleTwoFactor(userId: string, enable: boolean): Promise<User> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    user.isTwoFactorEnabled = enable;
    return user.save();
  }
}
