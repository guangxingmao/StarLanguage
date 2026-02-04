-- 知识擂台·按社群扩充题库
-- 参考：backend/sql/010_communities_seed.sql（共 50 个社群，id + name）
-- topic 字段与 010 中 communities.name 严格一致，便于按社群筛选题目。
-- 020 已覆盖：历史、计算机、篮球、动物、科学、地理；本文件覆盖其余社群。
-- 依赖：019_arena_questions_schema.sql、020_arena_questions_seed_100.sql 已执行

INSERT INTO arena_questions (id, topic, subtopic, title, options, answer, created_at) VALUES
-- 数学（010: math）
('q101', '数学', '趣味数学', '一周有几天？', '["A. 5 天", "B. 6 天", "C. 7 天", "D. 8 天"]', 'C', extract(epoch from now())::bigint),
('q102', '数学', '趣味数学', '一个三角形有几个角？', '["A. 2 个", "B. 3 个", "C. 4 个", "D. 5 个"]', 'B', extract(epoch from now())::bigint),
('q103', '数学', '思维训练', '10 减去 3 等于？', '["A. 5", "B. 6", "C. 7", "D. 8"]', 'C', extract(epoch from now())::bigint),
-- 美术（010: art）
('q104', '美术', '艺术创作', '三原色不包括？', '["A. 红", "B. 黄", "C. 蓝", "D. 绿"]', 'D', extract(epoch from now())::bigint),
('q105', '美术', '艺术创作', '蒙娜丽莎是谁画的？', '["A. 梵高", "B. 达·芬奇", "C. 毕加索", "D. 莫奈"]', 'B', extract(epoch from now())::bigint),
-- 音乐（010: music）
('q106', '音乐', '乐器', '钢琴有多少个键（标准）？', '["A. 66", "B. 88", "C. 99", "D. 108"]', 'B', extract(epoch from now())::bigint),
('q107', '音乐', '音乐欣赏', '《欢乐颂》的作曲家是？', '["A. 莫扎特", "B. 贝多芬", "C. 巴赫", "D. 肖邦"]', 'B', extract(epoch from now())::bigint),
-- 阅读（010: reading）
('q108', '阅读', '好书分享', '《西游记》里唐僧有几个徒弟？', '["A. 2 个", "B. 3 个", "C. 4 个", "D. 5 个"]', 'B', extract(epoch from now())::bigint),
('q109', '阅读', '阅读打卡', '《小红帽》里大灰狼假扮的是谁？', '["A. 妈妈", "B. 奶奶", "C. 猎人", "D. 爸爸"]', 'B', extract(epoch from now())::bigint),
-- 太空（010: space）
('q110', '太空', '宇宙探索', '太阳系中离太阳最近的行星是？', '["A. 金星", "B. 水星", "C. 地球", "D. 火星"]', 'B', extract(epoch from now())::bigint),
('q111', '太空', '航天', '中国第一颗人造卫星叫什么？', '["A. 嫦娥一号", "B. 东方红一号", "C. 神舟一号", "D. 天宫一号"]', 'B', extract(epoch from now())::bigint),
('q112', '太空', '宇宙探索', '火星在太阳系中排第几颗行星？', '["A. 第二", "B. 第三", "C. 第四", "D. 第五"]', 'C', extract(epoch from now())::bigint),
-- 机器人（010: robot）
('q113', '机器人', '编程与创客', '机器人三大定律是谁提出的？', '["A. 爱因斯坦", "B. 阿西莫夫", "C. 霍金", "D. 图灵"]', 'B', extract(epoch from now())::bigint),
('q114', '机器人', '拼装', '扫地机器人主要靠什么感知障碍？', '["A. 摄像头和传感器", "B. 只有声音", "C. 只有轮子", "D. 遥控"]', 'A', extract(epoch from now())::bigint),
-- 游戏（010: game）
('q115', '游戏', '益智游戏', '俄罗斯方块由几种不同形状的方块组成？', '["A. 5 种", "B. 6 种", "C. 7 种", "D. 8 种"]', 'C', extract(epoch from now())::bigint),
('q116', '游戏', '策略', '围棋棋盘上一共有多少个交叉点？', '["A. 361", "B. 360", "C. 400", "D. 324"]', 'A', extract(epoch from now())::bigint),
-- 美食（010: cook）
('q117', '美食', '简单料理', '做蛋糕通常需要加入什么让面团膨胀？', '["A. 盐", "B. 酵母或泡打粉", "C. 醋", "D. 酱油"]', 'B', extract(epoch from now())::bigint),
('q118', '美食', '美食分享', '中国八大菜系不包括？', '["A. 川菜", "B. 粤菜", "C. 东北菜", "D. 鲁菜"]', 'C', extract(epoch from now())::bigint),
-- 旅行（010: travel）
('q119', '旅行', '各地风土', '中国的首都北京在哪个方位？', '["A. 华南", "B. 华北", "C. 西北", "D. 西南"]', 'B', extract(epoch from now())::bigint),
('q120', '旅行', '游记', '长城主要位于中国哪个区域？', '["A. 南方", "B. 北方", "C. 西部", "D. 东部沿海"]', 'B', extract(epoch from now())::bigint),
-- 摄影（010: photo）
('q121', '摄影', '拍照技巧', '相机「快门」的主要作用是？', '["A. 对焦", "B. 控制进光时间", "C. 变焦", "D. 闪光"]', 'B', extract(epoch from now())::bigint),
('q122', '摄影', '作品', '「自拍」通常用相机什么功能？', '["A. 后置镜头", "B. 前置镜头", "C. 只有录像", "D. 只有连拍"]', 'B', extract(epoch from now())::bigint),
-- 电影（010: movie）
('q123', '电影', '电影推荐', '《狮子王》里小狮子叫什么名字？', '["A. 辛巴", "B. 木法沙", "C. 刀疤", "D. 丁满"]', 'A', extract(epoch from now())::bigint),
('q124', '电影', '观后感', '动画电影《寻梦环游记》主要讲的是哪个国家的节日？', '["A. 中国", "B. 墨西哥", "C. 日本", "D. 美国"]', 'B', extract(epoch from now())::bigint),
-- 动漫（010: cartoon）
('q125', '动漫', '动漫角色', '《龙猫》是哪个国家的工作室制作的？', '["A. 美国", "B. 中国", "C. 日本", "D. 法国"]', 'C', extract(epoch from now())::bigint),
('q126', '动漫', '剧情', '《千与千寻》里千寻为了救谁进入神隐世界？', '["A. 妹妹", "B. 爸爸妈妈", "C. 朋友", "D. 老师"]', 'B', extract(epoch from now())::bigint),
-- 益智（010: puzzle）
('q127', '益智', '谜题', '数独每一行、每一列都要填满 1～9 且？', '["A. 可以重复", "B. 不能重复", "C. 只填奇数", "D. 只填偶数"]', 'B', extract(epoch from now())::bigint),
('q128', '益智', '逻辑', '「如果下雨就带伞」和「没带伞」，能推出？', '["A. 一定下雨", "B. 一定没下雨", "C. 可能下雨可能没下", "D. 不能确定"]', 'B', extract(epoch from now())::bigint),
-- 英语（010: english）
('q129', '英语', '英语学习', '「苹果」的英文是？', '["A. banana", "B. apple", "C. orange", "D. grape"]', 'B', extract(epoch from now())::bigint),
('q130', '英语', '交流', '「Hello」的意思是？', '["A. 再见", "B. 谢谢", "C. 你好", "D. 对不起"]', 'C', extract(epoch from now())::bigint),
-- 语文（010: chinese）
('q131', '语文', '古诗文', '「床前明月光」的下一句是？', '["A. 低头思故乡", "B. 疑是地上霜", "C. 举头望明月", "D. 明月几时有"]', 'B', extract(epoch from now())::bigint),
('q132', '语文', '阅读写作', '《静夜思》的作者是？', '["A. 杜甫", "B. 李白", "C. 白居易", "D. 王维"]', 'B', extract(epoch from now())::bigint),
-- 物理（010: physics）
('q133', '物理', '生活物理', '冬天摸金属比摸木头更凉，主要是因为？', '["A. 金属更重", "B. 金属导热快", "C. 金属更硬", "D. 金属更亮"]', 'B', extract(epoch from now())::bigint),
('q134', '物理', '物理现象', '声音在真空中能传播吗？', '["A. 能", "B. 不能", "C. 有时能", "D. 只有大声才能"]', 'B', extract(epoch from now())::bigint),
-- 化学（010: chemistry）
('q135', '化学', '趣味化学', '水的化学式是？', '["A. CO2", "B. H2O", "C. O2", "D. NaCl"]', 'B', extract(epoch from now())::bigint),
('q136', '化学', '小实验', '铁生锈主要和什么气体有关？', '["A. 氢气", "B. 氧气", "C. 氮气", "D. 二氧化碳"]', 'B', extract(epoch from now())::bigint),
-- 生物（010: bio）
('q137', '生物', '人体奥秘', '人体消化食物主要在哪一器官？', '["A. 心脏", "B. 胃", "C. 肺", "D. 肾"]', 'B', extract(epoch from now())::bigint),
('q138', '生物', '动植物', '植物通过什么器官吸收土壤里的水分？', '["A. 叶子", "B. 根", "C. 花", "D. 果实"]', 'B', extract(epoch from now())::bigint),
-- 足球（010: football）
('q139', '足球', '规则', '足球比赛每队上场几人？', '["A. 9 人", "B. 10 人", "C. 11 人", "D. 12 人"]', 'C', extract(epoch from now())::bigint),
('q140', '足球', '赛事', '世界杯足球赛每几年举办一届？', '["A. 2 年", "B. 3 年", "C. 4 年", "D. 5 年"]', 'C', extract(epoch from now())::bigint),
-- 游泳（010: swim）
('q141', '游泳', '水上安全', '游泳时抽筋应该？', '["A. 用力蹬腿", "B. 尽量放松并呼救", "C. 憋气下沉", "D. 继续游"]', 'B', extract(epoch from now())::bigint),
('q142', '游泳', '游泳', '自由泳时主要靠哪里划水？', '["A. 腿", "B. 手臂", "C. 手臂和腿配合", "D. 只用腰"]', 'C', extract(epoch from now())::bigint),
-- 跑步（010: run）
('q143', '跑步', '健康', '跑步前为什么要热身？', '["A. 为了好看", "B. 减少受伤、让身体适应", "C. 为了减肥", "D. 没有原因"]', 'B', extract(epoch from now())::bigint),
('q144', '跑步', '跑步打卡', '马拉松全程大约多少公里？', '["A. 约 21 公里", "B. 约 42 公里", "C. 约 10 公里", "D. 约 50 公里"]', 'B', extract(epoch from now())::bigint),
-- 绘画（010: draw）
('q145', '绘画', '素描', '素描常用哪种笔？', '["A. 圆珠笔", "B. 铅笔", "C. 毛笔", "D. 马克笔"]', 'B', extract(epoch from now())::bigint),
('q146', '绘画', '水彩', '水彩画需要用水调和什么？', '["A. 墨水", "B. 颜料", "C. 胶水", "D. 油"]', 'B', extract(epoch from now())::bigint),
-- 舞蹈（010: dance）
('q147', '舞蹈', '律动', '芭蕾舞起源于哪个国家？', '["A. 中国", "B. 美国", "C. 意大利/法国", "D. 日本"]', 'C', extract(epoch from now())::bigint),
('q148', '舞蹈', '街舞', '「Breaking」属于哪种舞蹈？', '["A. 民族舞", "B. 街舞", "C. 芭蕾", "D. 拉丁舞"]', 'B', extract(epoch from now())::bigint),
-- 植物（010: plant）
('q149', '植物', '植物观察', '仙人掌的刺是由什么变成的？', '["A. 根", "B. 叶子", "C. 茎", "D. 花"]', 'B', extract(epoch from now())::bigint),
('q150', '植物', '养花种菜', '植物生长需要的光合作用原料不包括？', '["A. 阳光", "B. 水", "C. 二氧化碳", "D. 土壤"]', 'D', extract(epoch from now())::bigint),
-- 天文（010: star）
('q151', '天文', '观星', '北斗七星属于哪个星座？', '["A. 大熊座", "B. 小熊座", "C. 猎户座", "D. 天鹅座"]', 'A', extract(epoch from now())::bigint),
('q152', '天文', '星座', '牛郎星和织女星分别在哪个星座？', '["A. 天鹰座和天琴座", "B. 大熊座和小熊座", "C. 猎户座和狮子座", "D. 双子座和处女座"]', 'A', extract(epoch from now())::bigint),
-- 海洋（010: ocean）
('q153', '海洋', '海洋生物', '鲸鱼是鱼吗？', '["A. 是", "B. 不是，是哺乳动物", "C. 是两栖动物", "D. 是爬行动物"]', 'B', extract(epoch from now())::bigint),
('q154', '海洋', '环保', '海洋污染对谁危害大？', '["A. 只对鱼", "B. 对海洋生物和人类都有害", "C. 只对人类", "D. 没有危害"]', 'B', extract(epoch from now())::bigint),
-- 恐龙（010: dinosaur）
('q155', '恐龙', '恐龙种类', '霸王龙主要生活在什么时代？', '["A. 三叠纪", "B. 侏罗纪", "C. 白垩纪", "D. 新生代"]', 'C', extract(epoch from now())::bigint),
('q156', '恐龙', '化石', '恐龙化石主要保存在什么类型的岩石里？', '["A. 岩浆岩", "B. 沉积岩", "C. 变质岩", "D. 只有泥土"]', 'B', extract(epoch from now())::bigint),
-- 发明（010: invent）
('q157', '发明', '小发明', '指南针最早用于？', '["A. 打仗", "B. 看风水/航海", "C. 玩游戏", "D. 做饭"]', 'B', extract(epoch from now())::bigint),
('q158', '发明', '创意设计', '电灯是谁发明的？', '["A. 牛顿", "B. 爱迪生", "C. 爱因斯坦", "D. 瓦特"]', 'B', extract(epoch from now())::bigint),
-- 故事（010: story）
('q159', '故事', '讲故事', '《三只小猪》里第三只小猪用啥盖房？', '["A. 稻草", "B. 木头", "C. 砖头", "D. 石头"]', 'C', extract(epoch from now())::bigint),
('q160', '故事', '编故事', '《丑小鸭》最后变成了什么？', '["A. 鸭子", "B. 天鹅", "C. 鸡", "D. 鹅"]', 'B', extract(epoch from now())::bigint),
-- 诗歌（010: poem）
('q161', '诗歌', '古诗', '「春眠不觉晓」的下一句是？', '["A. 处处闻啼鸟", "B. 夜来风雨声", "C. 花落知多少", "D. 明月几时有"]', 'A', extract(epoch from now())::bigint),
('q162', '诗歌', '现代诗', '诗歌常用来表达？', '["A. 只有开心", "B. 情感和想象", "C. 只有悲伤", "D. 只有风景"]', 'B', extract(epoch from now())::bigint),
-- 手工（010: handwork）
('q163', '手工', '折纸', '折纸起源于哪个国家？', '["A. 美国", "B. 中国/日本", "C. 英国", "D. 法国"]', 'B', extract(epoch from now())::bigint),
('q164', '手工', '手作', '做黏土作品时，黏土变硬是因为？', '["A. 加热", "B. 水分蒸发或烘干", "C. 冷冻", "D. 压扁"]', 'B', extract(epoch from now())::bigint),
-- 魔术（010: magic）
('q165', '魔术', '科学魔术', '魔术「变没」东西通常是利用了？', '["A. 真正的魔法", "B. 手法、道具和视觉错觉", "C. 只有道具", "D. 只有手法"]', 'B', extract(epoch from now())::bigint),
-- 棋类（010: chess）
('q166', '棋类', '象棋', '中国象棋里「将」和「帅」能见面吗？', '["A. 能", "B. 不能", "C. 只有将能", "D. 只有帅能"]', 'B', extract(epoch from now())::bigint),
('q167', '棋类', '围棋', '围棋中「气」指的是？', '["A. 棋子的呼吸", "B. 与棋子相邻的空交叉点", "C. 棋子的颜色", "D. 下棋的速度"]', 'B', extract(epoch from now())::bigint),
-- 宠物（010: pet）
('q168', '宠物', '养宠日常', '狗摇尾巴通常表示？', '["A. 生气", "B. 高兴或兴奋", "C. 害怕", "D. 困了"]', 'B', extract(epoch from now())::bigint),
('q169', '宠物', '萌宠', '猫的胡须主要用来？', '["A. 好看", "B. 感知空间和平衡", "C. 闻气味", "D. 打架"]', 'B', extract(epoch from now())::bigint),
-- 环保（010: env）
('q170', '环保', '垃圾分类', '废电池应该扔进哪个垃圾桶？', '["A. 厨余", "B. 有害垃圾", "C. 可回收", "D. 其他"]', 'B', extract(epoch from now())::bigint),
('q171', '环保', '绿色生活', '「低碳」是指？', '["A. 少吃碳", "B. 减少二氧化碳等温室气体排放", "C. 少用碳笔", "D. 少烧炭"]', 'B', extract(epoch from now())::bigint),
-- 健康（010: health）
('q172', '健康', '饮食', '每天喝足够的水有助于？', '["A. 只解渴", "B. 新陈代谢和身体机能", "C. 只减肥", "D. 只美容"]', 'B', extract(epoch from now())::bigint),
('q173', '健康', '作息', '小学生一般每天需要睡几小时？', '["A. 5～6 小时", "B. 8～10 小时", "C. 12 小时", "D. 3～4 小时"]', 'B', extract(epoch from now())::bigint),
-- 考古（010: archaeo）
('q174', '考古', '考古发现', '甲骨文是在哪里被发现的？', '["A. 西安", "B. 河南安阳等地", "C. 北京", "D. 南京"]', 'B', extract(epoch from now())::bigint),
('q175', '考古', '古文明', '兵马俑在哪个城市？', '["A. 北京", "B. 西安", "C. 洛阳", "D. 南京"]', 'B', extract(epoch from now())::bigint),
-- 民俗（010: folk）
('q176', '民俗', '传统节日', '端午节人们常吃什么？', '["A. 月饼", "B. 粽子", "C. 汤圆", "D. 饺子"]', 'B', extract(epoch from now())::bigint),
('q177', '民俗', '民间文化', '「年兽」的传说与哪个节日有关？', '["A. 端午", "B. 春节", "C. 中秋", "D. 清明"]', 'B', extract(epoch from now())::bigint),
-- 羽毛球（010: badminton）
('q178', '羽毛球', '技巧', '羽毛球单打场地是几对几？', '["A. 1 对 1", "B. 2 对 2", "C. 3 对 3", "D. 都可以"]', 'A', extract(epoch from now())::bigint),
('q179', '羽毛球', '锻炼', '打羽毛球主要锻炼身体的？', '["A. 只练手", "B. 手眼协调和全身", "C. 只练腿", "D. 只练腰"]', 'B', extract(epoch from now())::bigint),
-- 瑜伽（010: yoga）
('q180', '瑜伽', '放松', '练瑜伽时强调什么？', '["A. 只比谁柔韧", "B. 呼吸与身体配合、量力而行", "C. 只做高难度", "D. 只练力量"]', 'B', extract(epoch from now())::bigint),
-- 编程（010: coding）
('q181', '编程', '算法', '编程里「循环」的作用是？', '["A. 只跑一次", "B. 重复执行一段代码", "C. 只用来画画", "D. 只用来听音乐"]', 'B', extract(epoch from now())::bigint),
('q182', '编程', 'Scratch', 'Scratch 是什么？', '["A. 一种游戏", "B. 图形化编程工具", "C. 一种语言", "D. 一种动物"]', 'B', extract(epoch from now())::bigint),
-- 人工智能（010: ai）
('q183', '人工智能', 'AI 科普', 'AI 是哪个英文的缩写？', '["A. Automatic Input", "B. Artificial Intelligence", "C. Advanced Internet", "D. Apple Inc."]', 'B', extract(epoch from now())::bigint),
('q184', '人工智能', '趣味应用', '语音助手（如 Siri）主要用到了？', '["A. 只有录音", "B. 语音识别和自然语言处理", "C. 只有打字", "D. 只有网络"]', 'B', extract(epoch from now())::bigint),
-- 其他（010: other）
('q185', '其他', '综合知识', '一年中白天最长的是哪一天？', '["A. 春分", "B. 夏至", "C. 秋分", "D. 冬至"]', 'B', extract(epoch from now())::bigint),
('q186', '其他', '综合知识', '地球自转一圈大约是？', '["A. 12 小时", "B. 24 小时", "C. 一周", "D. 一个月"]', 'B', extract(epoch from now())::bigint)
ON CONFLICT (id) DO NOTHING;
