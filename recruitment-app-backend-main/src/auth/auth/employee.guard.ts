import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class EmployeeGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization;

    try {
      const decoded = this.jwtService.verify(token);
      if (decoded && decoded.type === 'employee') {
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }
}
