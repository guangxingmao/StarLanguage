const { requireAuth } = require('../middleware/auth');

// 每日任务完成状态：key = `${phone}:${dateStr}` -> { taskId -> completed }，按日重置，后续可迁 DB
const dailyTaskCompletion = new Map();

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}
// 用户提醒设置：phone -> { reminderTime, message }
const userReminder = new Map();
// 用户成长统计：phone -> { streakDays, accuracyPercent, badgeCount, weeklyDone, weeklyTotal }
const userStats = new Map();

const DAILY_TASK_TEMPLATE = [
  { id: 'school', iconKey: 'school', label: '学习一个新知识点', completed: false },
  { id: 'video', iconKey: 'video', label: '观看一个视频或图文', completed: false },
  { id: 'arena', iconKey: 'arena', label: '参与一次擂台', completed: false },
  { id: 'forum', iconKey: 'forum', label: '参与一次社群讨论', completed: false },
];

const TODAY_LEARNING_SUGGESTIONS = [
  { title: '为什么天空是蓝色的？', contentId: 'sky-blue', summary: '光的散射' },
  { title: '恐龙为什么会灭绝？', contentId: 'dinosaur', summary: '小行星与气候' },
  { title: '植物是怎么喝水的？', contentId: 'plant-water', summary: '根与蒸腾' },
  { title: '星星为什么会眨眼？', contentId: 'twinkle', summary: '大气折射' },
  { title: '还没有学习内容', contentId: null, summary: null },
];

const DEFAULT_REMINDER = { reminderTime: '20:00', message: '今天还差 3 项打卡，加油！' };
const DEFAULT_STATS = { streakDays: 0, accuracyPercent: 0, badgeCount: 0, weeklyDone: 0, weeklyTotal: 5 };

function getReminder(phone) {
  return userReminder.get(phone) || { ...DEFAULT_REMINDER };
}

function getStats(phone) {
  const base = { ...DEFAULT_STATS };
  const stored = userStats.get(phone);
  if (stored) {
    if (stored.streakDays !== undefined) base.streakDays = stored.streakDays;
    if (stored.accuracyPercent !== undefined) base.accuracyPercent = stored.accuracyPercent;
    if (stored.badgeCount !== undefined) base.badgeCount = stored.badgeCount;
    if (stored.weeklyDone !== undefined) base.weeklyDone = stored.weeklyDone;
    if (stored.weeklyTotal !== undefined) base.weeklyTotal = stored.weeklyTotal;
  }
  return base;
}

function mergeTaskCompletion(phone, tasks) {
  const key = `${phone}:${todayKey()}`;
  const completed = dailyTaskCompletion.get(key);
  if (!completed) return tasks.map((t) => ({ ...t }));
  return tasks.map((t) => ({
    ...t,
    completed: completed[t.id] !== undefined ? completed[t.id] : t.completed,
  }));
}

function pickTodayLearning(phone) {
  const dateStr = new Date().toISOString().slice(0, 10);
  const seed = (phone + dateStr).split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
  const idx = Math.abs(seed) % TODAY_LEARNING_SUGGESTIONS.length;
  return { ...TODAY_LEARNING_SUGGESTIONS[idx] };
}

function buildGrowthCards(stats) {
  return [
    { title: '连续学习', value: `${stats.streakDays} 天`, colorHex: '#FFD166' },
    { title: '本周挑战', value: `${stats.weeklyDone} / ${stats.weeklyTotal}`, colorHex: '#B8F1E0' },
  ];
}

function buildReminderPayload(phone, reminderSetting, tasksWithCompletion) {
  const completedCount = tasksWithCompletion.filter((t) => t.completed).length;
  const total = tasksWithCompletion.length;
  const progress = total === 0 ? 0 : Math.min(1, completedCount / total);
  const remainingCount = Math.max(0, total - completedCount);
  const message =
    reminderSetting.message && reminderSetting.message.trim()
      ? reminderSetting.message
      : remainingCount > 0
        ? `今天还差 ${remainingCount} 项打卡，加油！`
        : '今日打卡已完成，真棒！';
  return {
    reminderTime: reminderSetting.reminderTime || '20:00',
    message,
    progress,
    remainingCount,
  };
}

function routes(app) {
  app.get('/growth', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const reminderSetting = getReminder(phone);
    const stats = getStats(phone);
    const dailyTasks = mergeTaskCompletion(phone, DAILY_TASK_TEMPLATE);
    const reminder = buildReminderPayload(phone, reminderSetting, dailyTasks);
    const todayLearning = pickTodayLearning(phone);
    const growthCards = buildGrowthCards(stats);

    res.json({
      reminder,
      stats: {
        streakDays: stats.streakDays,
        accuracyPercent: stats.accuracyPercent,
        badgeCount: stats.badgeCount,
      },
      dailyTasks,
      todayLearning,
      growthCards,
    });
  });

  app.patch('/growth/reminder', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const { reminderTime, message } = req.body || {};
    const current = getReminder(phone);
    const next = {
      reminderTime: reminderTime !== undefined ? String(reminderTime) : current.reminderTime,
      message: message !== undefined ? String(message) : current.message,
    };
    userReminder.set(phone, next);
    res.json({ ok: true, reminderTime: next.reminderTime, message: next.message });
  });

  app.patch('/growth/stats', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const body = req.body || {};
    const current = getStats(phone);
    const next = { ...current };
    if (body.streakDays !== undefined) next.streakDays = Number(body.streakDays) || 0;
    if (body.accuracyPercent !== undefined) next.accuracyPercent = Math.min(100, Math.max(0, Number(body.accuracyPercent) || 0));
    if (body.badgeCount !== undefined) next.badgeCount = Math.max(0, Number(body.badgeCount) || 0);
    if (body.weeklyDone !== undefined) next.weeklyDone = Math.max(0, Number(body.weeklyDone) || 0);
    if (body.weeklyTotal !== undefined) next.weeklyTotal = Math.max(1, Number(body.weeklyTotal) || 1);
    userStats.set(phone, next);
    res.json({ ok: true, stats: next });
  });

  app.patch('/growth/daily-tasks', requireAuth, (req, res) => {
    const { phone } = req.auth;
    const { taskId, completed } = req.body || {};
    if (!taskId || typeof completed !== 'boolean') {
      return res.status(400).json({
        error: 'invalid_body',
        message: '需要 taskId 与 completed (boolean)',
      });
    }
    const key = `${phone}:${todayKey()}`;
    if (!dailyTaskCompletion.has(key)) {
      dailyTaskCompletion.set(key, Object.create(null));
    }
    dailyTaskCompletion.get(key)[taskId] = completed;
    res.json({ ok: true, taskId, completed, date: todayKey() });
  });
}

module.exports = routes;
