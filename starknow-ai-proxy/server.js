/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const readline = require('readline');
const crypto = require('crypto');
const tencentcloud = require('tencentcloud-sdk-nodejs');
const http = require('http');
const { WebSocketServer } = require('ws');

const HunyuanClient = tencentcloud.hunyuan.v20230901.Client;
const PORT = process.env.PORT ? Number(process.env.PORT) : 3001;
const REGION = process.env.TENCENT_REGION || 'ap-guangzhou';

// ---------- 认证与用户（内存存储，Demo 用） ----------
const CODE_TTL_MS = 5 * 60 * 1000; // 5 分钟
const codes = new Map(); // phone -> { code, expiresAt }
const tokens = new Map(); // token -> { phone, createdAt }
const users = new Map(); // phone -> { phoneNumber, name, avatarIndex, avatarBase64 }

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
  const secretId = process.env.TENCENT_SECRET_ID;
  const secretKey = process.env.TENCENT_SECRET_KEY;
  if (!secretId || !secretKey) {
    return null;
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

function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  const token = auth && auth.startsWith('Bearer ') ? auth.slice(7).trim() : null;
  if (!token || !tokens.has(token)) {
    return res.status(401).json({ error: 'unauthorized', message: '请先登录' });
  }
  req.auth = tokens.get(token);
  next();
}

async function main() {
  const client = await initClient();
  if (!client) {
    console.log('Tencent credentials not set: AI chat disabled. Auth and user API only.');
  }

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '2mb' }));
  app.use(morgan('dev'));

  app.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'starknow-ai-proxy', aiEnabled: !!client });
  });

  // ---------- 认证 API ----------
  app.post('/auth/send-code', (req, res) => {
    const phone = (req.body && req.body.phone) ? String(req.body.phone).trim() : '';
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      return res.status(400).json({ error: 'invalid_phone', message: '请输入正确的11位手机号' });
    }
    const code = '666666';
    codes.set(phone, { code, expiresAt: Date.now() + CODE_TTL_MS });
    console.log(`[auth] send-code ${phone} -> ${code} (demo)`);
    res.json({ ok: true, demoCode: code });
  });

  app.post('/auth/verify', (req, res) => {
    const phone = (req.body && req.body.phone) ? String(req.body.phone).trim() : '';
    const code = (req.body && req.body.code) ? String(req.body.code).trim() : '';
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      return res.status(400).json({ error: 'invalid_phone', message: '请输入正确的11位手机号' });
    }
    if (!/^\d{6}$/.test(code)) {
      return res.status(400).json({ error: 'invalid_code', message: '请输入6位数字验证码' });
    }
    if (code !== '666666') {
      const entry = codes.get(phone);
      if (!entry || entry.expiresAt < Date.now()) {
        return res.status(400).json({ error: 'code_expired', message: '验证码已过期，请重新获取' });
      }
      if (entry.code !== code) {
        return res.status(400).json({ error: 'invalid_code', message: '验证码错误' });
      }
      codes.delete(phone);
    }

    let user = users.get(phone);
    if (!user) {
      user = {
        phoneNumber: phone,
        name: '星知小探险家',
        avatarIndex: 0,
        avatarBase64: null,
      };
      users.set(phone, user);
    }

    const token = crypto.randomBytes(32).toString('hex');
    tokens.set(token, { phone, createdAt: Date.now() });
    console.log(`[auth] verify ok ${phone}`);
    res.json({
      ok: true,
      token,
      user: {
        phoneNumber: user.phoneNumber,
        name: user.name,
        avatarIndex: user.avatarIndex,
        avatarBase64: user.avatarBase64,
      },
    });
  });

  // ---------- 用户 API ----------
  app.get('/user/me', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const user = users.get(phone);
    if (!user) {
      return res.status(404).json({ error: 'user_not_found' });
    }
    res.json({
      phoneNumber: user.phoneNumber,
      name: user.name,
      avatarIndex: user.avatarIndex,
      avatarBase64: user.avatarBase64,
    });
  });

  app.patch('/user/me', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const user = users.get(phone);
    if (!user) {
      return res.status(404).json({ error: 'user_not_found' });
    }
    const body = req.body || {};
    if (body.name !== undefined) user.name = String(body.name);
    if (body.avatarIndex !== undefined) user.avatarIndex = Number(body.avatarIndex) || 0;
    if (body.avatarBase64 !== undefined) user.avatarBase64 = body.avatarBase64 === null ? null : String(body.avatarBase64);
    if (body.phoneNumber !== undefined) user.phoneNumber = String(body.phoneNumber);
    res.json({
      phoneNumber: user.phoneNumber,
      name: user.name,
      avatarIndex: user.avatarIndex,
      avatarBase64: user.avatarBase64,
    });
  });

  // ---------- 成长页 API（内存，与 backend 同结构，便于 3001/3002 通用） ----------
  const growthReminder = new Map();
  const growthStats = new Map();
  const growthDailyCompletion = new Map();
  const GROWTH_TASKS = [
    { id: 'school', iconKey: 'school', label: '学习一个新知识点', completed: false },
    { id: 'video', iconKey: 'video', label: '观看一个视频或图文', completed: false },
    { id: 'arena', iconKey: 'arena', label: '参与一次擂台', completed: false },
    { id: 'forum', iconKey: 'forum', label: '参与一次社群讨论', completed: false },
  ];
  const TODAY_LEARNING = [
    { title: '为什么天空是蓝色的？', contentId: 'sky-blue', summary: '光的散射' },
    { title: '恐龙为什么会灭绝？', contentId: 'dinosaur', summary: '小行星与气候' },
    { title: '还没有学习内容', contentId: null, summary: null },
  ];

  function growthTodayKey() {
    return new Date().toISOString().slice(0, 10);
  }

  app.get('/growth', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const reminderSetting = growthReminder.get(phone) || { reminderTime: '20:00', message: '' };
    const stats = growthStats.get(phone) || { streakDays: 0, accuracyPercent: 0, badgeCount: 0, weeklyDone: 0, weeklyTotal: 5 };
    const key = `${phone}:${growthTodayKey()}`;
    const completed = growthDailyCompletion.get(key) || {};
    const dailyTasks = GROWTH_TASKS.map((t) => ({ ...t, completed: completed[t.id] !== undefined ? completed[t.id] : t.completed }));
    const completedCount = dailyTasks.filter((t) => t.completed).length;
    const total = dailyTasks.length;
    const progress = total === 0 ? 0 : Math.min(1, completedCount / total);
    const remainingCount = Math.max(0, total - completedCount);
    const reminder = {
      reminderTime: reminderSetting.reminderTime || '20:00',
      message: reminderSetting.message || (remainingCount > 0 ? `今天还差 ${remainingCount} 项打卡，加油！` : '今日打卡已完成，真棒！'),
      progress,
      remainingCount,
    };
    const seed = (phone + growthTodayKey()).split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
    const todayLearning = TODAY_LEARNING[Math.abs(seed) % TODAY_LEARNING.length];
    const growthCards = [
      { title: '连续学习', value: `${stats.streakDays} 天`, colorHex: '#FFD166' },
      { title: '本周挑战', value: `${stats.weeklyDone} / ${stats.weeklyTotal}`, colorHex: '#B8F1E0' },
    ];
    res.json({
      reminder,
      stats: { streakDays: stats.streakDays, accuracyPercent: stats.accuracyPercent, badgeCount: stats.badgeCount },
      dailyTasks,
      todayLearning: { ...todayLearning },
      growthCards,
    });
  });

  app.patch('/growth/reminder', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const { reminderTime, message } = req.body || {};
    const cur = growthReminder.get(phone) || {};
    const next = {
      reminderTime: reminderTime !== undefined ? String(reminderTime) : cur.reminderTime,
      message: message !== undefined ? String(message) : cur.message,
    };
    growthReminder.set(phone, next);
    res.json({ ok: true, reminderTime: next.reminderTime, message: next.message });
  });

  app.patch('/growth/stats', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const cur = growthStats.get(phone) || { streakDays: 0, accuracyPercent: 0, badgeCount: 0, weeklyDone: 0, weeklyTotal: 5 };
    const body = req.body || {};
    if (body.streakDays !== undefined) cur.streakDays = Number(body.streakDays) || 0;
    if (body.accuracyPercent !== undefined) cur.accuracyPercent = Math.min(100, Math.max(0, Number(body.accuracyPercent) || 0));
    if (body.badgeCount !== undefined) cur.badgeCount = Math.max(0, Number(body.badgeCount) || 0);
    if (body.weeklyDone !== undefined) cur.weeklyDone = Math.max(0, Number(body.weeklyDone) || 0);
    if (body.weeklyTotal !== undefined) cur.weeklyTotal = Math.max(1, Number(body.weeklyTotal) || 1);
    growthStats.set(phone, cur);
    res.json({ ok: true, stats: cur });
  });

  app.patch('/growth/daily-tasks', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const { taskId, completed } = req.body || {};
    if (!taskId || typeof completed !== 'boolean') {
      return res.status(400).json({ error: 'invalid_body', message: '需要 taskId 与 completed (boolean)' });
    }
    const key = `${phone}:${growthTodayKey()}`;
    if (!growthDailyCompletion.has(key)) growthDailyCompletion.set(key, Object.create(null));
    growthDailyCompletion.get(key)[taskId] = completed;
    res.json({ ok: true, taskId, completed, date: growthTodayKey() });
  });

  app.post('/chat', async (req, res) => {
    if (!client) {
      return res.status(503).json({
        error: 'ai_disabled',
        message: '未配置腾讯云密钥，AI 对话不可用。请设置 TENCENT_SECRET_ID / TENCENT_SECRET_KEY 或启动时输入。',
      });
    }
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
