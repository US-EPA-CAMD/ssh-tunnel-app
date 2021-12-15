import {
  ApiTags,
  ApiOkResponse,
} from '@nestjs/swagger';

import {
  Get,
  Controller,
} from '@nestjs/common';

@Controller()
@ApiTags('Health Check')
export class HealthCheckController {

  @Get()
  @ApiOkResponse({
    description: 'SSH Tunnel Application Helath Check',
  })
  ping(): string {
    return "SSH tunnel application for cloud.gov database connections. Dummy application bound to database services that provide a dedicated connection to the EASEY Database.";
  }
}
