require('dotenv').config();
import { registerAs } from '@nestjs/config';
import { parseBool } from '@us-epa-camd/easey-common/utilities';

const path = process.env.EASEY_SSH_TUNNEL_APP_PATH || 'ssh-tunnel';
const host = process.env.EASEY_SSH_TUNNEL_APP_HOST || 'localhost';
const port = +process.env.EASEY_SSH_TUNNEL_APP_PORT || 9000;

let uri = `https://${host}/${path}`;

if (host == 'localhost') {
  uri = `http://localhost:${port}/${path}`;
}

export default registerAs('app', () => ({
  name: 'ssh-tunnel',
  title: process.env.EASEY_SSH_TUNNEL_APP_TITLE || 'SSH Tunnel Application',
  path,
  host,
  apiHost: process.env.EASEY_API_GATEWAY_HOST || 'api.epa.gov/easey/dev',
  port,
  uri,
  env: process.env.EASEY_SSH_TUNNEL_APP_ENV || 'local-dev',
  enableCors: parseBool(process.env.EASEY_FACILITIES_API_ENABLE_CORS, true),
  enableApiKey: parseBool(
    process.env.EASEY_FACILITIES_API_ENABLE_API_KEY,
    true,
  ),
  enableAuthToken: parseBool(
    process.env.EASEY_FACILITIES_API_ENABLE_AUTH_TOKEN,
  ),
  enableGlobalValidationPipes: parseBool(
    process.env.EASEY_FACILITIES_API_ENABLE_GLOBAL_VALIDATION_PIPE,
    true,
  ),
  version: process.env.EASEY_SSH_TUNNEL_APP_VERSION || 'v0.0.0',
  published: process.env.EASEY_SSH_TUNNEL_APP_PUBLISHED || 'local',
}));
