import { registerAs } from '@nestjs/config';

const path = process.env.EASEY_SSH_TUNNEL_APP_PATH || 'ssh-tunnel';
const host = process.env.EASEY_SSH_TUNNEL_APP_HOST || 'localhost';
const port = process.env.EASEY_SSH_TUNNEL_APP_PORT || 9000;

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
  enableCors: process.env.EASEY_SSH_TUNNEL_APP_ENABLE_CORS || false,
  enableApiKey: process.env.EASEY_SSH_TUNNEL_APP_ENABLE_API_KEY || false,
  enableAuthToken: process.env.EASEY_SSH_TUNNEL_APP_ENABLE_AUTH_TOKEN || false,
  enableGlobalValidationPipes: process.env.EASEY_SSH_TUNNEL_APP_ENABLE_GLOBAL_VALIDATION_PIPE || false,
  version: process.env.EASEY_SSH_TUNNEL_APP_VERSION || 'v0.0.0',
  published: process.env.EASEY_SSH_TUNNEL_APP_PUBLISHED || 'local',
}));
