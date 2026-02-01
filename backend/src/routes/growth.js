const { requireAuth } = require('../middleware/auth');
const { pool } = require('../db');

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

// 打卡固定 4 项（与表默认一致）
const DAILY_TASK_TEMPLATE = [
  { id: 'school', iconKey: 'school', label: '学习一个新知识点', completed: false },
  { id: 'video', iconKey: 'video', label: '观看一个视频或者图文', completed: false },
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

async function getReminder(phone) {
  const r = await pool.query(
    'SELECT reminder_time, message FROM growth_reminder WHERE phone = $1',
    [phone]
  );
  if (r.rows.length) {
    return {
      reminderTime: r.rows[0].reminder_time || '20:00',
      message: r.rows[0].message ?? '',
    };
  }
  const now = Date.now();
  await pool.query(
    `INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
     VALUES ($1, '20:00', '今天还差 4 项打卡，加油！', $2)
     ON CONFLICT (phone) DO NOTHING`,
    [phone, now]
  );
  return { reminderTime: '20:00', message: '今天还差 4 项打卡，加油！' };
}

async function getStats(phone) {
  const r = await pool.query(
    'SELECT streak_days, accuracy_percent, badge_count, weekly_done, weekly_total FROM growth_stats WHERE phone = $1',
    [phone]
  );
  if (r.rows.length) {
    const row = r.rows[0];
    return {
      streakDays: row.streak_days ?? 0,
      accuracyPercent: row.accuracy_percent ?? 0,
      badgeCount: row.badge_count ?? 0,
      weeklyDone: row.weekly_done ?? 0,
      weeklyTotal: row.weekly_total ?? 4,
    };
  }
  const now = Date.now();
  await pool.query(
    `INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
     VALUES ($1, 0, 0, 0, 0, 4, $2)
     ON CONFLICT (phone) DO NOTHING`,
    [phone, now]
  );
  return { streakDays: 0, accuracyPercent: 0, badgeCount: 0, weeklyDone: 0, weeklyTotal: 4 };
}

async function getDailyTaskCompletion(phone) {
  const dateStr = todayKey();
  const r = await pool.query(
    'SELECT task_id, completed FROM growth_daily_completion WHERE phone = $1 AND date = $2',
    [phone, dateStr]
  );
  const completed = Object.create(null);
  for (const row of r.rows) {
    completed[row.task_id] = row.completed;
  }
  return completed;
}

function mergeTaskCompletion(completed, tasks) {
  if (!Object.keys(completed).length) return tasks.map((t) => ({ ...t }));
  return tasks.map((t) => ({
    ...t,
    completed: completed[t.id] !== undefined ? completed[t.id] : t.completed,
  }));
}

function pickTodayLearning(phone) {
  const dateStr = todayKey();
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

function buildReminderPayload(reminderSetting, tasksWithCompletion) {
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
  app.get('/growth', requireAuth, async (req, res) => {
    try {
      const { phone } = req.auth;
      const [reminderSetting, stats, completed] = await Promise.all([
        getReminder(phone),
        getStats(phone),
        getDailyTaskCompletion(phone),
      ]);
      const dailyTasks = mergeTaskCompletion(completed, DAILY_TASK_TEMPLATE);
      const reminder = buildReminderPayload(reminderSetting, dailyTasks);
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
    } catch (err) {
      console.error('[growth GET]', err);
      res.status(500).json({ error: 'server_error', message: '获取失败' });
    }
  });

  app.patch('/growth/reminder', requireAuth, async (req, res) => {
    try {
      const { phone } = req.auth;
      const { reminderTime, message } = req.body || {};
      const r = await pool.query(
        'SELECT reminder_time, message FROM growth_reminder WHERE phone = $1',
        [phone]
      );
      const current = r.rows.length
        ? { reminderTime: r.rows[0].reminder_time, message: r.rows[0].message ?? '' }
        : { reminderTime: '20:00', message: '' };
      const nextTime = reminderTime !== undefined ? String(reminderTime) : current.reminderTime;
      const nextMsg = message !== undefined ? String(message) : current.message;
      const now = Date.now();
      await pool.query(
        `INSERT INTO growth_reminder (phone, reminder_time, message, updated_at)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (phone) DO UPDATE SET reminder_time = $2, message = $3, updated_at = $4`,
        [phone, nextTime, nextMsg, now]
      );
      res.json({ ok: true, reminderTime: nextTime, message: nextMsg });
    } catch (err) {
      console.error('[growth PATCH reminder]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });

  app.patch('/growth/stats', requireAuth, async (req, res) => {
    try {
      const { phone } = req.auth;
      const body = req.body || {};
      const r = await pool.query(
        'SELECT streak_days, accuracy_percent, badge_count, weekly_done, weekly_total FROM growth_stats WHERE phone = $1',
        [phone]
      );
      let streak = 0,
        accuracy = 0,
        badge = 0,
        weeklyDone = 0,
        weeklyTotal = 4;
      if (r.rows.length) {
        const row = r.rows[0];
        streak = row.streak_days ?? 0;
        accuracy = row.accuracy_percent ?? 0;
        badge = row.badge_count ?? 0;
        weeklyDone = row.weekly_done ?? 0;
        weeklyTotal = row.weekly_total ?? 4;
      }
      if (body.streakDays !== undefined) streak = Number(body.streakDays) || 0;
      if (body.accuracyPercent !== undefined) accuracy = Math.min(100, Math.max(0, Number(body.accuracyPercent) || 0));
      if (body.badgeCount !== undefined) badge = Math.max(0, Number(body.badgeCount) || 0);
      if (body.weeklyDone !== undefined) weeklyDone = Math.max(0, Number(body.weeklyDone) || 0);
      if (body.weeklyTotal !== undefined) weeklyTotal = Math.max(1, Number(body.weeklyTotal) || 1);
      const now = Date.now();
      await pool.query(
        `INSERT INTO growth_stats (phone, streak_days, accuracy_percent, badge_count, weekly_done, weekly_total, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (phone) DO UPDATE SET
           streak_days = $2, accuracy_percent = $3, badge_count = $4, weekly_done = $5, weekly_total = $6, updated_at = $7`,
        [phone, streak, accuracy, badge, weeklyDone, weeklyTotal, now]
      );
      res.json({ ok: true, stats: { streakDays: streak, accuracyPercent: accuracy, badgeCount: badge, weeklyDone, weeklyTotal } });
    } catch (err) {
      console.error('[growth PATCH stats]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });

  app.patch('/growth/daily-tasks', requireAuth, async (req, res) => {
    try {
      const { phone } = req.auth;
      const { taskId, completed } = req.body || {};
      if (!taskId || typeof completed !== 'boolean') {
        return res.status(400).json({
          error: 'invalid_body',
          message: '需要 taskId 与 completed (boolean)',
        });
      }
      const dateStr = todayKey();
      const now = Date.now();
      await pool.query(
        `INSERT INTO growth_daily_completion (phone, date, task_id, completed, updated_at)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (phone, date, task_id) DO UPDATE SET completed = $4, updated_at = $5`,
        [phone, dateStr, taskId, completed, now]
      );
      res.json({ ok: true, taskId, completed, date: dateStr });
    } catch (err) {
      console.error('[growth PATCH daily-tasks]', err);
      res.status(500).json({ error: 'server_error', message: '更新失败' });
    }
  });
}

module.exports = routes;
