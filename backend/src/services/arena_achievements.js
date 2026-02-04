/**
 * 擂台挑战完成后，根据本次会话 + 用户累计统计匹配成就墙（achievements 表），
 * 与 007_achievements_seed.sql 中定义一致。仅评估可由擂台/挑战数据得出的成就。
 */

const ARENA_TOPICS = ['历史', '篮球', '科学', '语文', '数学', '英语', '艺术'];

/**
 * @param {object} ctx
 * @param {object} ctx.stats - user_arena_stats 一行：matches, max_streak, total_score, best_accuracy, topic_best
 * @param {object} ctx.session - 本次挑战：topic, totalQuestions, correctCount, score, maxStreak
 * @param {number} ctx.totalCorrect - 累计答对题数（所有挑战 correct_count 之和）
 * @param {object} ctx.topicSessionCounts - { '历史': 5, '科学': 3, ... } 各分区挑战次数
 * @returns {string[]} 满足条件的成就 id 列表（a01～a100）
 */
function evaluateArenaAchievements(ctx) {
  const { stats = {}, session = {}, totalCorrect = 0, topicSessionCounts = {} } = ctx;
  const topicBest = stats.topic_best && typeof stats.topic_best === 'object' ? stats.topic_best : {};
  const matches = Number(stats.matches) || 0;
  const maxStreak = Number(stats.max_streak) || 0;
  const totalScore = Number(stats.total_score) || 0;
  const bestAccuracy = Number(stats.best_accuracy) || 0;

  const totalQuestions = Number(session.totalQuestions) || 0;
  const correctCount = Number(session.correctCount) || 0;
  const score = Number(session.score) || 0;
  const sessionMaxStreak = Number(session.maxStreak) || 0;
  const topic = (session.topic && String(session.topic).trim()) || '全部';
  const sessionAccuracy = totalQuestions > 0 ? correctCount / totalQuestions : 0;

  const ids = [];

  if (matches >= 1) ids.push('a01'); // 闪亮新星：完成 1 次擂台挑战
  if (maxStreak >= 3) ids.push('a02'); // 连胜三场
  if (totalScore >= 300) ids.push('a03'); // 探索家
  if (sessionAccuracy >= 0.9) ids.push('a04'); // 观察大师：单局准确率 90%
  if (Number(topicBest['历史']) >= 120) ids.push('a05'); // 历史小通
  if (Number(topicBest['篮球']) >= 120) ids.push('a06'); // 篮球达人
  if (totalCorrect >= 10) ids.push('a10'); // 知识新星
  if (correctCount >= 10) ids.push('a11'); // 十题达人
  if (totalCorrect >= 100) ids.push('a12'); // 百题斩
  if (totalCorrect >= 1000) ids.push('a13'); // 千题王
  if (maxStreak >= 5) ids.push('a14'); // 连胜五场
  if (maxStreak >= 10) ids.push('a15'); // 连胜十场
  if (totalQuestions > 0 && correctCount >= totalQuestions) ids.push('a16'); // 全对一局
  if (Number(topicBest['科学']) >= 120) ids.push('a20'); // 科学小达人
  if (Number(topicBest['语文']) >= 120) ids.push('a21'); // 语文小能手
  if (Number(topicBest['数学']) >= 120) ids.push('a22'); // 数学小天才
  if (Number(topicBest['英语']) >= 120) ids.push('a23'); // 英语小达人
  if (Number(topicBest['艺术']) >= 120) ids.push('a24'); // 艺术小星星
  const topicBestOver100 = ARENA_TOPICS.filter((t) => Number(topicBest[t]) >= 100).length;
  if (topicBestOver100 >= 2) ids.push('a18'); // 双科精通
  if (totalScore >= 500) ids.push('a54');
  if (totalScore >= 1000) ids.push('a55');
  if (totalScore >= 2000) ids.push('a56');
  if (totalScore >= 5000) ids.push('a57');
  if (sessionAccuracy >= 0.8) ids.push('a58'); // 准确率 80%
  if (sessionAccuracy >= 0.95) ids.push('a59'); // 准确率 95%
  if (totalQuestions > 0 && correctCount >= totalQuestions) ids.push('a60'); // 准确率 100%
  if ((topicSessionCounts['历史'] || 0) >= 5) ids.push('a61'); // 探索历史
  if ((topicSessionCounts['科学'] || 0) >= 5) ids.push('a62'); // 探索科学
  if ((topicSessionCounts['艺术'] || 0) >= 5) ids.push('a63'); // 探索艺术
  const distinctTopics = Object.keys(topicSessionCounts).filter((t) => t !== '全部' && (topicSessionCounts[t] || 0) > 0).length;
  if (distinctTopics >= 5) ids.push('a64'); // 多面手
  const allTopicsParticipated = ARENA_TOPICS.every((t) => (topicSessionCounts[t] || 0) > 0);
  if (allTopicsParticipated) ids.push('a19'); // 全能王：全部主题均参与过
  const allTopicsOver100 = ARENA_TOPICS.every((t) => Number(topicBest[t]) >= 100);
  if (allTopicsOver100) ids.push('a97'); // 全能学霸

  return [...new Set(ids)];
}

module.exports = { evaluateArenaAchievements, ARENA_TOPICS };
