import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class EntrepriseGuard implements CanActivate {
  private readonly logger = new Logger(EntrepriseGuard.name);
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization;

    try {
      const decoded = this.jwtService.verify(token);
      this.logger.debug(`Decoded JWT payload: ${JSON.stringify(decoded)}`);
      if (decoded && decoded.type === 'entreprise') {
        return true;
      }
      throw new ForbiddenException('Access denied. User is not an entreprise.');
    } catch (error) {
      throw new ForbiddenException('Access denied. Invalid or missing token.');
    }
  }
}
