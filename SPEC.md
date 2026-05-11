# HabitFlow - 微习惯App规格

## 1. 项目概述

- **名称**: HabitFlow
- **Bundle ID**: com.habitflow.app
- **Core**: 像多邻国一样有趣的微习惯打卡App
- **目标用户**: 个人使用，习惯养成入门者
- **最低iOS**: 16.0

## 2. UI/UX规格

### 2.1 屏幕结构

| 屏幕 | 说明 |
|---|---|
| HomeView | 主页面：今日习惯列表 + 打卡 |
| AddHabitView | 添加新习惯 |
| HabitDetailView | 单个习惯详情 + Streak历史 |

### 2.2 颜色

| 用途 | 色值 |
|---|---|
| 主色（活力绿） | #34C759 |
| 次色（深灰） | #1C1C1E |
| 强调（橙色streak）| #FF9500 |
| 背景 | System（自动适配深浅） |
| 卡片背景 | #F2F2F7（浅）/ #2C2C2E（深） |
| 完成动画 | #FFD60A（金色） |

### 2.3 字体

- 标题: .largeTitle, bold
- 正文: .body
- 统计数据: .caption, monospaced

### 2.4 间距

- 卡片圆角: 16pt
- 间距: 16pt
- 卡片padding: 16pt

## 3. 功能规格

### 3.1 核心功能

#### 添加习惯
- 输入习惯名称（必填）
- 选择图标（SF Symbols选择）
- 选择颜色（预设5色）
- 选择提醒时间（可选，暂时不做）

#### 每日打卡
- 今日习惯列表
- 点击卡片→完成打卡
- 完成后播放庆祝动画（弹跳+金色闪光）
- 同时更新streak连续天数

#### Streak机制
- 连续打卡天数显示
- 今天未打卡：灰色
- 今天已打卡：绿色+火焰emoji 🔥
- 断了：显示断开的天数

#### 数据存储
- 使用@AppStorage存储习惯列表（简单起见）
- 结构: [Habit] Codable

### 3.2 UserFlow

```
App启动 → HomeView（今日习惯）
  → 点击添加 → AddHabitView → 保存 → 返回Home
  → 点击习惯卡片 → 打卡动画 → 更新streak
  → 长按习惯卡片 → HabitDetailView（历史记录）
```

### 3.3 边界情况

- 无习惯时：显示引导页"添加你的第一个习惯"
- 一天结束自动重置打卡状态

## 4. 技术规格

### 4.1 架构

- SwiftUI + MVVM
- @AppStorage做持久化
- 单文件搞定（避免过度工程）

### 4.2 数据模型

```swift
struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var color: String // hex
    var createdAt: Date
    var streakDays: Int
    var lastCompletedDate: Date?
    var completedToday: Bool
}
```

### 4.3 动画

- 打卡完成：scale弹跳动画 (0.8 → 1.1 → 1.0)
- 持续时间：0.4秒
- 金色粒子效果（用Overlay实现）

## 5. 后续扩展（不包含在MVP）

- [ ] 推送提醒通知
- [ ] 周/月统计图表
- [ ] iCloud同步
- [ ] 主题切换
- [ ] 社交/排行榜
- [ ] Apple Watch版本

## 6. MVP检查清单

- [ ] 添加习惯（名称+图标+颜色）
- [ ] 今日习惯列表
- [ ] 点击打卡+动画
- [ ] Streak连续天数
- [ ] 打卡历史记录查看
- [ ] 数据持久化
- [ ] 无习惯时的空状态