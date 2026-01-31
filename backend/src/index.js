/* eslint-disable no-console */
const http = require('http');
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { WebSocketServer } = require('ws');
const tencentcloud = require('tencentcloud-sdk-nodejs');

const config = require('./config');
const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const chatRoutes = require('./routes/chat');

const HunyuanClient = tencentcloud.hunyuan.v20230901.Client;

async function initHunyuanClient() {
  const { secretId, secretKey, region } = config.tencent;
  if (!secretId || !secretKey) return null;
  return new HunyuanClient({
    credential: { secretId, secretKey },
    region,
    profile: {
      httpProfile: { endpoint: 'hunyuan.tencentcloudapi.com' },
    },
  });
}

async function main() {
  const hunyuanClient = await initHunyuanClient();
  if (!hunyuanClient) {
    console.log('Tencent credentials not set: AI chat disabled. Auth and user API only.');
  }

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '2mb' }));
  app.use(morgan('dev'));

  healthRoutes(app);
  authRoutes(app);
  userRoutes(app);
  chatRoutes(app, () => hunyuanClient);

  const server = http.createServer(app);

  const wss = new WebSocketServer({ server, path: '/duel' });
  const rooms = new Map();

  wss.on('connection', (ws) => {
    ws.on('message', (message) => {
      let payload;
      try {
        payload = JSON.parse(message.toString());
      } catch (_) {
        return;
      }
      const type = payload.type;
      const room = payload.room;
      if (type === 'host') {
        if (!room) return;
        rooms.set(room, { host: ws, guest: null });
        ws.send(JSON.stringify({ type: 'hosted', room }));
        return;
      }
      if (type === 'join') {
        if (!room || !rooms.has(room)) {
          ws.send(JSON.stringify({ type: 'room_not_found' }));
          return;
        }
        const entry = rooms.get(room);
        entry.guest = ws;
        if (entry.host) {
          entry.host.send(JSON.stringify({ type: 'join', name: payload.name || '对手', room }));
        }
        ws.send(JSON.stringify({ type: 'waiting' }));
        return;
      }
      if (!room || !rooms.has(room)) return;
      const entry = rooms.get(room);
      const target = ws === entry.host ? entry.guest : entry.host;
      if (target) target.send(JSON.stringify(payload));
    });

    ws.on('close', () => {
      for (const [room, entry] of rooms.entries()) {
        if (entry.host === ws || entry.guest === ws) {
          rooms.delete(room);
          const target = entry.host === ws ? entry.guest : entry.host;
          if (target) target.send(JSON.stringify({ type: 'peer_left' }));
        }
      }
    });
  });

  server.listen(config.port, () => {
    console.log(`starknow-backend running on http://localhost:${config.port}`);
    console.log(`LAN duel relay: ws://localhost:${config.port}/duel`);
  });
}

main().catch((err) => {
  console.error('Failed to start:', err.message);
  process.exit(1);
});
