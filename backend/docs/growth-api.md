# 成长页接口设计

成长页数据：每日提醒、成长统计、每日任务、今日学习、双卡。以下接口均需登录（`Authorization: Bearer <token>`）。

---

## 1. GET /growth — 成长页整页数据

**说明**：一次返回整页所需数据，便于前端一屏渲染。

**响应体**（与前端 `GrowthPageData` 一致）：

| 字段 | 类型 | 说明 |
|------|------|------|
| reminder | object | 每日提醒：reminderTime、message、progress（0～1）、remainingCount（可选） |
| stats | object | 成长统计：streakDays、accuracyPercent、badgeCount |
| dailyTasks | array | 每日任务列表，每项含 id、iconKey、label、completed |
| todayLearning | object | 今日学习推荐：title、contentId、summary（可选） |
| growthCards | array | 双卡列表，每项含 title、value、colorHex |

**数据来源**：

- **reminder**：用户设置（reminderTime、message）+ 当日任务完成数计算 progress、remainingCount、message 文案。
- **stats**：用户成长统计（可被擂台/学习等流程更新），无则默认 0。
- **dailyTasks**：固定模板 + 用户当日完成状态（PATCH /growth/daily-tasks 写入）。
- **todayLearning**：推荐列表按「用户 + 日期」取一条，同一天同用户不变。
- **growthCards**：由 stats 计算（如「连续学习」= streakDays + " 天"，「本周挑战」= weeklyDone + " / " + weeklyTotal）。

---

## 2. PATCH /growth/reminder — 更新每日提醒设置（含修改提醒时间）

**Body**：

```json
{
  "reminderTime": "20:00",
  "message": "今天还差 4 项打卡，加油！"
}
```

- `reminderTime`：提醒时间，格式 `"HH:mm"`（如 "20:00"）。前端时间选择器选好后传此字段即可。
- `message`：可选，自定义提示文案；不传则保留原值，GET /growth 时也可根据任务完成数生成默认文案。

**响应**：`{ "ok": true, "reminderTime": "20:00", "message": "..." }`。

---

## 3. PATCH /growth/stats — 更新成长统计

**说明**：可由擂台结算、学习完成等流程调用，或设置页/调试用。

**Body**：

```json
{
  "streakDays": 7,
  "accuracyPercent": 86,
  "badgeCount": 9,
  "weeklyDone": 3,
  "weeklyTotal": 5
}
```

- 全部可选；只传需要更新的字段。
- `weeklyDone` / `weeklyTotal`：用于双卡「本周挑战」展示（如 "3 / 5"）。

**响应**：`{ "ok": true }` 或 200。

---

## 4. PATCH /growth/daily-tasks — 更新某项每日任务完成状态

**Body**：

```json
{
  "taskId": "school",
  "completed": true
}
```

- `taskId`：与 GET /growth 返回的 dailyTasks[].id 一致（如 school、video、arena、forum）。
- `completed`：是否已完成。

**响应**：`{ "ok": true, "taskId": "school", "completed": true }`。

---

## 5. 今日学习与双卡

- **今日学习**：不单独提供接口；GET /growth 时后端从推荐列表按用户+日期选一条返回。
- **双卡**：不单独提供接口；GET /growth 时由 stats（含 weeklyDone/weeklyTotal）计算 growthCards。

---

## 6. 按日重置每日任务

- 每日任务完成状态按 **日期** 存储：key = `phone:YYYY-MM-DD`，每天零点后自然「重置」为未完成（新一天没有记录即视为未完成）。
- PATCH /growth/daily-tasks 写入当日日期；GET /growth 只读当日完成状态。

## 7. 后续可迁 DB 的存储

| 数据 | 当前 | 表结构 |
|------|------|--------|
| 提醒设置 | 内存 Map | `sql/002_growth_schema.sql` → growth_reminder |
| 成长统计 | 内存 Map | growth_stats |
| 每日任务完成 | 内存 Map（key: phone:date） | growth_daily_completion(phone, date, task_id, completed) |
| 今日学习推荐列表 | 内存数组 | 可迁表 content / recommendation |

建表脚本：在 starknow 库中执行 `backend/sql/002_growth_schema.sql`，再将 growth.js 改为从 pg 读写上述表即可。
