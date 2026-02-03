-- 社群种子数据（兴趣社群列表，共 50 个）
-- 执行顺序：008_communities_schema → 本脚本
--
-- 若执行后 communities 表没有新增行：多半是「第二条 INSERT 失败导致整段事务回滚」。
-- 解决办法：先只执行下面「Part 1」这一段（从 INSERT INTO communities 到 ON CONFLICT 那一行），
-- 执行完后查 SELECT COUNT(*) FROM communities 应有 50 行；再单独执行「Part 2」。

-- ========== Part 1：插入 50 个社群（先单独执行并提交） ==========
INSERT INTO communities (id, name, description, cover_url, sort_order, created_at)
VALUES
  ('hist', '历史', '一起聊聊历史人物与故事', '', 1, extract(epoch from now())::bigint * 1000),
  ('comp', '计算机', '编程与科技爱好者', '', 2, extract(epoch from now())::bigint * 1000),
  ('sport', '篮球', '篮球招式与赛事', '', 3, extract(epoch from now())::bigint * 1000),
  ('animal', '动物', '小动物的温暖秘密', '', 4, extract(epoch from now())::bigint * 1000),
  ('science', '科学', '科学实验与发现', '', 5, extract(epoch from now())::bigint * 1000),
  ('math', '数学', '趣味数学与思维训练', '', 6, extract(epoch from now())::bigint * 1000),
  ('art', '美术', '绘画与艺术创作', '', 7, extract(epoch from now())::bigint * 1000),
  ('music', '音乐', '乐器、唱歌与音乐欣赏', '', 8, extract(epoch from now())::bigint * 1000),
  ('reading', '阅读', '好书分享与阅读打卡', '', 9, extract(epoch from now())::bigint * 1000),
  ('nature', '自然', '探索大自然与户外', '', 10, extract(epoch from now())::bigint * 1000),
  ('space', '太空', '宇宙、星球与航天', '', 11, extract(epoch from now())::bigint * 1000),
  ('robot', '机器人', '拼装、编程与创客', '', 12, extract(epoch from now())::bigint * 1000),
  ('game', '游戏', '益智游戏与策略', '', 13, extract(epoch from now())::bigint * 1000),
  ('cook', '美食', '简单料理与美食分享', '', 14, extract(epoch from now())::bigint * 1000),
  ('travel', '旅行', '游记与各地风土', '', 15, extract(epoch from now())::bigint * 1000),
  ('photo', '摄影', '拍照技巧与作品', '', 16, extract(epoch from now())::bigint * 1000),
  ('movie', '电影', '电影推荐与观后感', '', 17, extract(epoch from now())::bigint * 1000),
  ('cartoon', '动漫', '动漫角色与剧情', '', 18, extract(epoch from now())::bigint * 1000),
  ('puzzle', '益智', '谜题、数独与逻辑', '', 19, extract(epoch from now())::bigint * 1000),
  ('english', '英语', '英语学习与交流', '', 20, extract(epoch from now())::bigint * 1000),
  ('chinese', '语文', '阅读写作与古诗文', '', 21, extract(epoch from now())::bigint * 1000),
  ('physics', '物理', '生活中的物理现象', '', 22, extract(epoch from now())::bigint * 1000),
  ('chemistry', '化学', '趣味化学小实验', '', 23, extract(epoch from now())::bigint * 1000),
  ('bio', '生物', '动植物与人体奥秘', '', 24, extract(epoch from now())::bigint * 1000),
  ('geo', '地理', '山川河流与世界地理', '', 25, extract(epoch from now())::bigint * 1000),
  ('football', '足球', '足球技巧与赛事', '', 26, extract(epoch from now())::bigint * 1000),
  ('swim', '游泳', '游泳与水上安全', '', 27, extract(epoch from now())::bigint * 1000),
  ('run', '跑步', '跑步打卡与健康', '', 28, extract(epoch from now())::bigint * 1000),
  ('draw', '绘画', '素描、水彩与涂鸦', '', 29, extract(epoch from now())::bigint * 1000),
  ('dance', '舞蹈', '街舞、民族舞与律动', '', 30, extract(epoch from now())::bigint * 1000),
  ('plant', '植物', '养花种菜与植物观察', '', 31, extract(epoch from now())::bigint * 1000),
  ('star', '天文', '星座、望远镜与观星', '', 32, extract(epoch from now())::bigint * 1000),
  ('ocean', '海洋', '海洋生物与环保', '', 33, extract(epoch from now())::bigint * 1000),
  ('dinosaur', '恐龙', '恐龙种类与化石', '', 34, extract(epoch from now())::bigint * 1000),
  ('invent', '发明', '小发明与创意设计', '', 35, extract(epoch from now())::bigint * 1000),
  ('story', '故事', '编故事与讲故事', '', 36, extract(epoch from now())::bigint * 1000),
  ('poem', '诗歌', '古诗与现代诗', '', 37, extract(epoch from now())::bigint * 1000),
  ('handwork', '手工', '折纸、黏土与手作', '', 38, extract(epoch from now())::bigint * 1000),
  ('magic', '魔术', '小魔术与科学魔术', '', 39, extract(epoch from now())::bigint * 1000),
  ('chess', '棋类', '围棋、象棋与五子棋', '', 40, extract(epoch from now())::bigint * 1000),
  ('pet', '宠物', '养宠日常与萌宠', '', 41, extract(epoch from now())::bigint * 1000),
  ('env', '环保', '垃圾分类与绿色生活', '', 42, extract(epoch from now())::bigint * 1000),
  ('health', '健康', '作息、运动与饮食', '', 43, extract(epoch from now())::bigint * 1000),
  ('archaeo', '考古', '考古发现与古文明', '', 44, extract(epoch from now())::bigint * 1000),
  ('folk', '民俗', '传统节日与民间文化', '', 45, extract(epoch from now())::bigint * 1000),
  ('badminton', '羽毛球', '羽毛球技巧与锻炼', '', 46, extract(epoch from now())::bigint * 1000),
  ('yoga', '瑜伽', '儿童瑜伽与放松', '', 47, extract(epoch from now())::bigint * 1000),
  ('coding', '编程', 'Scratch、Python 与算法', '', 48, extract(epoch from now())::bigint * 1000),
  ('ai', '人工智能', 'AI 科普与趣味应用', '', 49, extract(epoch from now())::bigint * 1000),
  ('other', '其他', '其他兴趣话题', '', 99, extract(epoch from now())::bigint * 1000)
ON CONFLICT (id) DO NOTHING;
-- 执行完 Part 1 后请先 COMMIT（或确认已提交），再执行 Part 2。

-- ========== Part 2：演示用户默认加入 5 个社群（可选，失败不影响 Part 1） ==========
INSERT INTO user_communities (phone, community_id, joined_at)
SELECT '13800138000', id, extract(epoch from now())::bigint * 1000
FROM communities
WHERE id IN ('animal', 'hist', 'science', 'comp', 'sport')
ON CONFLICT (phone, community_id) DO NOTHING;
