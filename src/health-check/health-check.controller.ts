import {
  ApiTags,
  ApiOkResponse,
} from '@nestjs/swagger';

import {
  Get,
  Controller,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Controller()
@ApiTags('Health Check')
export class HealthCheckController {
  constructor(private readonly config: ConfigService) {}

  @Get()
  @ApiOkResponse({
    description: 'SSH Tunnel Application Helath Check',
  })
  ping(): string {
    return "SSH tunnel application for cloud.gov database connections. Dummy application bound to database services that provide a dedicated connection to the EASEY Database.";
  }

  @Get('/env-test')
  @ApiOkResponse({
    description: 'Testing .env file',
  })
  getEnvVar(): string {
    return this.config.get<string>("app.test");
  }
}
