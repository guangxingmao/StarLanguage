/* eslint-disable no-console */
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const readline = require('readline');
const tencentcloud = require('tencentcloud-sdk-nodejs');
const http = require('http');
const { WebSocketServer } = require('ws');

const HunyuanClient = tencentcloud.hunyuan.v20230901.Client;
const PORT = process.env.PORT ? Number(process.env.PORT) : 3001;
const REGION = process.env.TENCENT_REGION || 'ap-guangzhou';

function promptSecret(label) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(`${label}: `, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function initClient() {
  const secretId = process.env.TENCENT_SECRET_ID || await promptSecret('SecretId');
  const secretKey = process.env.TENCENT_SECRET_KEY || await promptSecret('SecretKey');
  if (!secretId || !secretKey) {
    throw new Error('SecretId/SecretKey is required.');
  }
  return new HunyuanClient({
    credential: { secretId, secretKey },
    region: REGION,
    profile: {
      httpProfile: {
        endpoint: 'hunyuan.tencentcloudapi.com',
      },
    },
  });
}

function normalizeMessages(messages) {
  if (!Array.isArray(messages)) return [];
  return messages
    .filter((m) => m && typeof m.content === 'string')
    .map((m) => ({
      Role: m.role || 'user',
      Content: m.content,
    }));
}

function buildVisionMessage({ question, imageBase64, imageMime }) {
  const mime = imageMime || 'image/jpeg';
  const url = imageBase64.startsWith('data:')
    ? imageBase64
    : `data:${mime};base64,${imageBase64}`;
  return [
    {
      Role: 'user',
      Contents: [
        {
          Type: 'text',
          Text: question || '请描述图片内容，并用儿童易懂的方式解释。',
        },
        {
          Type: 'image_url',
          ImageUrl: {
            Url: url,
          },
        },
      ],
    },
  ];
}

async function main() {
  const client = await initClient();

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '2mb' }));
  app.use(morgan('dev'));

  app.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'starknow-ai-proxy' });
  });

  app.post('/chat', async (req, res) => {
    try {
      const {
        messages,
        model = 'hunyuan-turbos-latest',
        temperature = 0.6,
        topP = 1.0,
        stream = false,
        imageBase64,
        imageMime,
        question,
      } = req.body || {};

      if (stream) {
        return res.status(400).json({
          error: 'streaming_not_supported',
          message: 'Streaming is not enabled in local proxy yet.',
        });
      }

      const isVision = typeof imageBase64 === 'string' && imageBase64.length > 0;
      const normalized = isVision ? buildVisionMessage({ question, imageBase64, imageMime }) : normalizeMessages(messages);
      if (!normalized.length) {
        return res.status(400).json({ error: 'missing_messages' });
      }

      const params = {
        Model: isVision ? 'hunyuan-vision' : model,
        Messages: normalized,
        Temperature: temperature,
        TopP: topP,
        Stream: false,
      };

      const result = await client.ChatCompletions(params);
      const reply = result?.Choices?.[0]?.Message?.Content || '';
      res.json({
        reply,
        model: result?.Model,
        usage: result?.Usage,
        raw: result,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({
        error: 'proxy_error',
        message: err?.message || 'Unknown error',
      });
    }
  });

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
      if (!room || !rooms.has(room)) {
        return;
      }
      const entry = rooms.get(room);
      const target = ws === entry.host ? entry.guest : entry.host;
      if (target) {
        target.send(JSON.stringify(payload));
      }
    });

    ws.on('close', () => {
      for (const [room, entry] of rooms.entries()) {
        if (entry.host === ws || entry.guest === ws) {
          rooms.delete(room);
          const target = entry.host === ws ? entry.guest : entry.host;
          if (target) {
            target.send(JSON.stringify({ type: 'peer_left' }));
          }
        }
      }
    });
  });

  server.listen(PORT, () => {
    console.log(`StarKnow AI proxy running on http://localhost:${PORT}`);
    console.log(`LAN relay available on ws://localhost:${PORT}/duel`);
  });
}

main().catch((err) => {
  console.error('Failed to start proxy:', err.message);
  process.exit(1);
});
