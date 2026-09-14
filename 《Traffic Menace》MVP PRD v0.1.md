# 《Traffic Menace》MVP PRD

**类型：** 俯视角驾驶 + Traffic Manipulation + Roguelite  
**首发目标：** CrazyGames / PC Web  
**技术栈：** Godot 4 + GDScript  
**美术：** Modern Pixel Art 2D  
**单局目标时长：** 8 分钟  
**MVP 核心目标：** 验证“堵别人 + 搞笑道具 + 连锁交通灾难”是否具有持续重玩价值。

> **版本说明（2026-09-12）：** 本文件是早期设计基线。当前可运行灰盒已经升级为 3 个永久混合道具槽、23 个开放道具、`?` 自动拾取、1/2/3 直接使用和常驻左右支路汇入；试玩操作与实现细节请以 [《Traffic Menace》产品需求文档 PRD v0.3](</Users/lvfushun/dev/Traffic Menace/《Traffic Menace》产品需求文档 PRD v0.3.md>) 及 [灰盒 README](</Users/lvfushun/dev/Traffic Menace/prototypes/traffic-menace-graybox/README.md>) 为准。

---

# 1. 一句话玩法

> **Drive slow. Block lanes. Get ridiculous tools. Ruin everyone’s commute.**

玩家驾驶一辆自动前进的小破车，通过横向卡位、有限速度控制和越来越荒谬的交通道具，阻止 NPC 超车，并制造堵塞、追尾和连锁事故。

普通赛车：

> 比别人更快。

本作：

> **让所有人都比你更慢。**

最终玩家幻想：

> **“我只开了一辆破车，但整条路都因为我瘫痪了。”**

---

# 2. MVP 三个核心支柱

## 2.1 Traffic Blocking Skill

玩家需要观察 NPC 的超车意图，通过：

- 横向卡位；
- 压线；
- 30–50 km/h 速度调整；
- 预判 NPC 换道；
- 超车瞬间回切；

阻止 NPC 超过自己。

核心不是单纯蛇形驾驶，而是：

> **看出它准备怎么超我，然后把路堵死。**

---

## 2.2 Comedic Chaos Discovery

玩家需要持续获得新的、荒谬的交通道具和车辆改装。

每局都应该产生：

> “这次又会拿到什么鬼东西？”

的期待。

升级应优先改变交通行为，而不是单纯增加数值。

避免：

> +10% Damage  
> -15% Cooldown

优先：

> 漏油、掉沙发、滚轮胎、拖车、黑烟、假转向灯、掉床垫、施工牌。

---

## 2.3 Emergent Chain Reaction

道具本身不应该直接等于“伤害”。

理想因果：

> 玩家制造交通压力  
> → NPC 刹车 / 换道 / 绕行  
> → 玩家继续卡位  
> → NPC 决策进一步恶化  
> → 追尾 / 堵塞 / 大型车辆横路  
> → 连锁事故

核心原则：

> **Item creates pressure. Player positioning converts pressure into chaos.**

不能让最优玩法退化成：

> 等 CD → 扔东西 → 看爆炸。

---

# 3. 核心循环

**自动前进**

↓

**观察 NPC 超车意图**

↓

**横向卡位 / BRAKE / BOOST**

↓

**迫使 NPC 刹车、换道或等待**

↓

**阻止超车 / 制造拥堵**

↓

**使用搞笑道具扩大交通问题**

↓

**产生 Chaos Score / Combo / Chain Reaction**

↓

**达到 Chaos 阈值 → 三选一 Roguelite Upgrade**

↓

**道路上偶尔出现 Mystery Pickup**

↓

**获得道具并放入三个永久槽位**

↓

**交通密度和超车压力提高**

↓

**撑过 8 分钟 / 耐久归零失败**

↓

**Restart**

---

# 4. 玩家车辆

玩家车辆自动巡航。

基础目标速度：

> **40 km/h**

玩家只能有限调整：

**BRAKE：30 km/h**

让后方车辆快速接近，制造堵塞机会，但更容易被包围。

**默认：40 km/h**

标准卡位速度。

**BOOST：50 km/h**

重新定位、抢占另一车道、躲避侧撞。

玩家不能：

- 完全停车；
- 倒车；
- 长时间原地卡死道路。

横向移动采用连续转向，不使用瞬移换车道。

---

# 5. Desktop 操作

当前灰盒使用方向键和数字键：

**← / →**

横向移动。

**↓**

BRAKE，目标速度降至 30 km/h。

**↑**

BOOST，目标速度升至 50 km/h。

**1 / 2 / 3**

选中并直接使用对应道具槽中的主动道具；被动道具进入槽位后立即生效。

**Esc / R**

暂停 / 继续；重新开始本局。

满槽替换和三选一奖励也按 1/2/3 选择。当前灰盒不使用 Space、WASD 或 ZXC。

松开 BOOST / BRAKE 后，逐渐回到 40 km/h。

MVP 暂时只开发：

> **PC Keyboard**

Mobile、Tilt、Touch Steering 不进入第一版 MVP。

---

# 6. NPC Traffic AI

MVP 不追求真实驾驶模拟。

NPC 只需要做到：

> **行为清晰、意图可读、能够被玩家操纵。**

基础状态：

**Cruise**

正常驾驶。

**Follow**

跟随前车。

**Brake**

因为前方受阻而减速。

**Prepare Overtake**

准备超过玩家。

必须给出明显提示：

- 转向灯；
- 鸣笛；
- 车辆横向偏移；
- 必要时路线提示。

**Lane Change**

执行换道。

**Pass Player**

成功超过玩家。

**Crash**

发生碰撞后滑行、旋转并最终成为道路障碍。

MVP 只需要：

> Normal + Aggressive

两种驾驶倾向。

Aggressive 更容易贴车、更快尝试超车，因此也更容易制造事故。

---

# 7. 生存规则

玩家拥有车辆耐久。

MVP 初始测试值：

> **10 Durability**

NPC 完整超过玩家并稳定进入玩家前方：

> **-1 Durability**

玩家主动横向撞击 NPC：

> **-2 Durability**

NPC 不主动选择撞玩家。

多个 NPC 同时超车时必须存在伤害间隔，避免瞬间雪崩死亡。

耐久归零：

> Game Over。

撑过 8 分钟：

> Run Complete。

“超车扣耐久”属于重点验证规则。如果测试玩家普遍认为不合理，再考虑替换为 Road Control / Menace Meter，但 MVP 首版先保留现有规则。

---

# 8. Chaos 与计分

MVP 只需要三个核心数据：

**CHAOS SCORE**

整局成绩。

**COMBO**

连续制造交通事件时提高。

**CHAIN REACTION**

显示一次连锁事故规模。

高价值事件：

- 阻止 NPC 超车；
- 迫使 NPC 急刹；
- NPC 因玩家行为发生碰撞；
- 无接触事故；
- 多车连锁事故；
- 大型堵塞。

玩家直接侧撞 NPC：

> 低奖励。

NPC 因为玩家卡位或道具自行发生事故：

> 高奖励。

---

# 9. MVP Chaos Attribution

不开发完整多层交通责任系统。

使用简单规则：

NPC 在最近约 **3 秒** 内因为玩家：

- 急刹；
- 换道；
- 绕行；
- 打滑；

并随后发生碰撞，则该事故归因给玩家。

如果继续产生连续事故，则维持同一 Chain Reaction。

目标不是模拟交通责任：

> **目标是让玩家明显感觉“这是我害的”。**

---

# 10. Roguelite Upgrade

通过 Chaos Score 达到阈值触发：

> **三选一。**

选择时暂停游戏。

完整 8 分钟 Run：

> 约 5–7 次升级。

MVP 目标：

> **12–15 张 Upgrade Cards。**

但这些卡牌必须围绕约 **8–10 个真正不同的 Chaos Mechanic** 制作。

卡牌数量不是核心。

核心是：

> **不同交通行为数量。**

---

# 11. MVP Chaos Mechanics

第一批至少实现以下类型：

### Oil Leak

车辆留下油污。

NPC 压到后打滑并产生横向失控。

---

### Loose Cargo

BRAKE 时有机会从车后掉落纸箱或家具。

形成临时实体障碍。

---

### Sofa Drop

掉落大型沙发。

车辆必须换道绕行。

---

### Rolling Tire

掉落一个持续滚动的轮胎。

可以跨车道移动，制造动态避让。

---

### Smoke Exhaust

产生黑烟。

附近 NPC 提前减速或尝试换道。

---

### Fake Indicator

玩家显示错误转向信号。

NPC 对玩家路线产生错误预测。

---

### Wide Load

车辆临时获得超宽货物或后视镜。

更容易同时覆盖两个车道。

---

### Trailer

玩家后方出现短拖车。

提高封堵能力，同时降低横向机动性。

---

### Road Junk

随机掉落垃圾袋、纸箱、小型障碍。

主要制造交通扰动。

---

### Large Mystery Object

低概率出现明显夸张的大型物体。

例如：

> 床垫 / 大型充气物 / 巨型纸箱。

作为喜剧高光事件。

---

# 12. Upgrade 设计原则

Upgrade 应该强化或改变 Chaos Mechanic。

例如：

**Loose Cargo**

BRAKE 时掉货。

↓

**Moving Day**

更容易掉家具。

↓

**Overloaded**

一次掉两个。

↓

**Fragile Furniture**

家具被撞后分裂成更多障碍。

因此：

> **10 个基础系统，可以衍生出几十张升级卡。**

MVP 不追求大量卡牌数量。

MVP 要验证：

> 玩家是否期待下一次升级出现没见过的搞笑效果。

---

# 13. Mystery Pickup

道路上少量生成：

> **? Mystery Pickup**

当前灰盒一局最多生成 3 个，接触后自动拾取，不需要按键确认。

拾取规则：

- 有空槽时，道具自动放入第一个空槽并自动选中；
- 三个槽位都已有道具时，交通暂停并显示替换界面，必须按 1/2/3 选择要替换的槽位；
- 道具在本局内永久保留，使用不会消失；
- 主动道具共用 3 秒冷却，被动道具拾取后立即生效且不占用冷却；
- 被替换的被动效果立即失效，已经生成的障碍物继续存在到自身结束。

当前灰盒直接开放全部 23 个道具，环境拾取和 Chaos 三选一卡池共用这套道具池。

目的：

> **让玩家在密集车流中承担路线选择，同时快速看到道具造成的交通后果。**

三选一升级负责：

> **Build Strategy + Slot Replacement**

道路 Mystery Pickup 负责：

> **Immediate Surprise + Automatic Pickup**

---

# 14. 道路

MVP 不做开放世界。

使用持续向前生成的城市道路。

初始：

> **3 Lane Main Road**

MVP 只需要少量道路变化：

### Merge

左右支路常驻产生车辆并横向进入主路；目标车道不可用时，车辆在入口等待，主干道出现空位后继续汇入。道路事件“支路合流”期间进一步缩短入口间隔。

### Lane Closure

前方减少一条可通行车道。

### Narrow Section

道路短暂变窄，提高堵塞机会。

### Breakdown

一辆抛锚 NPC 成为天然障碍。

道路本身必须能够：

> **制造 Chaos Opportunity。**

---

# 15. 一局节奏

## 0–2 分钟

3 车道。

NPC 较少。

教玩家：

> 卡位、BRAKE、BOOST、阻止超车。

尽快给出第一次 Chaos Upgrade。

---

## 2–5 分钟

NPC 数量增加。

Aggressive Driver 比例提高。

开始出现：

- Merge；
- Mystery Pickup；
- 更多大型车辆。

---

## 5–8 分钟

高交通密度。

频繁超车。

道路瓶颈增多。

玩家 Build 应已经明显改变车辆行为。

画面进入：

> **Toy Car Traffic Disaster**

状态。

---

# 16. 视觉反馈

玩家必须能立刻看懂：

> 谁想超我？

> 谁因为我刹车？

> 谁因为我撞了？

必须重点制作：

- 刹车灯；
- 转向灯；
- 鸣笛；
- 急刹 skid；
- 车辆旋转；
- 横滑；
- 漫画震动；
- 火花；
- 愤怒符号；
- Combo；
- Chain Reaction 数字。

重要反馈：

> OVERTAKEN -1

> BLOCKED!

> INDIRECT CRASH

> CHAIN REACTION ×8

> PERFECT MENACE

---

# 17. MVP 内容量

正式 MVP 控制在：

**玩家车**

1 台。

**NPC**

4 类左右：

- Sedan；
- SUV；
- Van；
- Truck / Bus。

**司机行为**

2 类：

- Normal；
- Aggressive。

**Chaos Mechanics**

8–10 个。

**Upgrade Cards**

12–15 张。

**Mystery Items**

6–8 个。

**道路事件**

3–4 个。

**地图**

1 个城市主题。

**单局**

8 分钟。

**输入**

Keyboard only。

**活跃车辆目标**

正常：

> 20–50 辆。

压力场面：

> 50+。

---

# 18. MVP 不做

暂时不开发：

- Mobile Tilt；
- Mobile Touch；
- 5 车道复杂地图；
- 完整 15–20+ 道具库；
- 数十张升级卡；
- 复杂局外成长；
- Meta Currency；
- Steam 功能；
- 成就；
- 多地图；
- 多玩家车辆；
- 真实车辆物理；
- 复杂 8 层 Attribution；
- Speedster / Taxi 等更多 AI 人格；
- 大量车辆型号；
- 大量剧情；
- 大型设置系统。

只要不能帮助验证核心玩法：

> **暂时不做。**

---

# 19. MVP 最重要的 10 秒

MVP 第一阶段只验证一个问题：

> 新玩家看到一次超车意图后，能否在 5–10 秒内通过减速、横向卡位，或使用一个固定搞笑道具，主动改变 NPC 的行为，并看懂随后发生的急刹、追尾或拥堵是自己造成的；成功后是否想立刻再制造一次。

这里的“10 秒”是最小可重复的爽感单元，不是要求每 10 秒都出现大型连锁事故。基础卡位负责提供可理解的操作判断，道具负责让同一个判断产生不同、意外而且值得期待的结果。

第一阶段测试必须提供：

- 3 条固定车道；
- 1 个 Aggressive Sedan、1 个普通 NPC；
- 1 个起始道具，以及 2–3 个可重复获得的固定代表性道具，例如 Oil Leak、Sofa Drop、Rolling Tire；
- 简单的血条、事件提示和连锁反馈。

不需要完整随机道具池、复杂升级构筑、正式美术或完整道路生成系统，但不能把道具完全拿掉后再判断核心玩法是否成立。

典型场景如下：

> 一辆 Aggressive Sedan 从后方接近并打左转灯，准备超过玩家。

> 玩家先 BRAKE，让 Sedan 进入可控的贴近距离，再向左横向卡位；或者在合适时机使用 Oil Leak / Sofa Drop。

> Sedan 被迫急刹、变道或失去路线；后方 Van 来不及反应，撞上 Sedan 或被道具影响。

> Van 的动作又迫使后方车辆刹车，形成一次可读的二级反应。

屏幕和声音应按顺序反馈：

> **玩家动作 → NPC 反应 → 事故/拥堵结果 → CHAIN REACTION ×N**

判定标准：

- 新玩家在约 30 秒内，未经逐步讲解就能主动完成一次卡位或道具干预；
- 玩家能在约 3 秒内看见 NPC 的直接反应，并在约 10 秒内理解因果关系；
- 完成一次成功循环后，玩家会主动寻找下一辆车或尝试另一个道具；
- 若基础卡位成立但道具让结果缺少差异，优先调道具效果；若只有解释道具规则后才觉得有趣，则不算验证通过。

只要这个“观察意图 → 做出干预 → 看见意外结果 → 想再来一次”的循环成立，才值得继续扩充道具池、升级卡和 8 分钟流程。

---

# 20. MVP 成功标准

优先观察以下结果。

### Goal Understanding

新玩家 30 秒左右能理解：

> “我要堵别人，不让它们超过我。”

### Blocking Intent

玩家会主动根据 NPC 超车方向改变横向位置。

不是随机蛇形驾驶。

### Speed Intent

玩家会主动使用：

> 30 / 40 / 50 km/h

解决不同情况。

### Causality

发生事故以后玩家能理解：

> “刚才是因为我它才撞的。”

### Item Curiosity

出现升级或 Mystery Pickup 时：

> 玩家明显想知道下一次会出现什么。

### Emergent Story

玩家能够主动描述：

> “刚才那个沙发害 Bus 横过来了，然后后面全撞了。”

### Replay Desire

Run 结束后：

> 玩家主动重新开始。

这个指标优先级极高。

---

# 21. Kill Conditions

如果基础灰盒测试中长期出现以下情况，应暂停内容扩张：

### 卡位不好玩

玩家觉得只是：

> 左右蛇形移动。

### NPC 不可读

玩家不知道：

> NPC 为什么刹车、为什么超车、为什么撞。

### BRAKE / BOOST 没有策略意义

30 / 40 / 50 km/h 实际体验差异很小。

### 道具取代驾驶

最优打法变成：

> 等共享冷却 → 按数字键扔东西。

### Chaos 不可归因

画面虽然很乱，但玩家不知道：

> “这是不是我造成的。”

如果这些问题存在：

> **不要继续增加道具数量。**

先修核心交通玩法。

---

# 22. 开发优先级

开发严格按照以下顺序：

**1. 玩家自动驾驶 + 横向控制**

↓

**2. NPC Follow / Brake / Overtake**

↓

**3. 超车预警与阻止超车**

↓

**4. Durability 与失败条件**

↓

**5. NPC-NPC Crash**

↓

**6. 简单 Chaos Attribution**

↓

**7. Chaos Score / Combo / Chain Reaction**

↓

**8. 3 个基础搞笑 Chaos Mechanic**

推荐：

> Oil + Sofa + Rolling Tire

↓

**9. 三选一 Roguelite Upgrade**

↓

**10. Mystery Pickup**

↓

**11. 扩展到 8–10 个 Chaos Mechanic**

↓

**12. Road Events**

↓

**13. 正式 Pixel Art 与音效**

任何阶段只要发现：

> **Block → React → Crash**

这个核心不够好玩，

立即停止继续堆内容。

---

# 23. MVP 最终判断标准

MVP 不需要证明：

> “我们能不能做一个复杂的交通模拟游戏？”

MVP 只需要证明三件事：

### A

> **阻止 NPC 超车是否本身就有操作乐趣？**

### B

> **搞笑随机道具是否让玩家持续期待下一次 Chaos？**

### C

> **AI + 道具 + 道路是否会自然形成值得玩家复述的连锁事故？**

三个同时成立：

> **进入完整版本开发。**

如果只有 B 成立：

> 会退化成道具小游戏。

如果只有 A 成立：

> 内容寿命可能不足。

如果只有 C 成立：

> 玩家可能只是旁观事故。

最终产品必须同时拥有：

> **Skill + Surprise + Emergence。**
