import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { HealthCheckController } from './health-check.controller';
import { Logger, LoggerModule } from '@us-epa-camd/easey-common/logger';

@Module({
  imports: [],
  controllers: [HealthCheckController],
  providers: [],
})
export class HealthCheckModule {}
