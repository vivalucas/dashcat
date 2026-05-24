  1→# DashCat 评审记录
  2→
  3→---
  4→

> 说明：本文件是按时间累积的评审与复核记录，不是当前规格说明。早期评审中关于部署目标、源码行数、文件数量的判断可能已被后续版本推翻；遇到冲突时，以较新的复核结论、`spec.md` 和 `principles.md` 为准。错误但有复盘价值的判断会保留，并在后续复核中标明不成立，避免以后重复采纳。


## 2026-05-12 综合模式 C/M 标签回归复核

**评审员**：Codex
**评审范围**：`AppDelegate.swift` 中 `makeStackedTitle()`、`applyMetricDisplay()`、`updateStatusItemLength()` 与 `v1.1.0` 的综合模式显示路径对比。

### 结论

1. `v1.1.0` 中综合模式 + 数值与动画显示正常，下方 `C` / `M` 标签没有丢失；其 `makeStackedTitle()` 与当前实现基本一致，因此富文本构造不是根因。
2. 当前回归来自 `双数值` 引入后新增的手动 `statusItem.length` 计算。该计算对普通单行和自绘双数值可控，但不适合综合模式的双行 `NSAttributedString`，容易让 `NSStatusBarButton` 在图文混排时裁切下方标签。
3. `1.3.3` 对非 `双数值` 的综合模式恢复 `NSStatusItem.variableLength`，让 AppKit 按 `v1.1.0` 的方式处理双行 attributed title；`双数值` 仍保留自绘和手动紧凑长度。

### 残余说明

本轮没有再调整 `makeStackedTitle()` 的 baseline offset。该路径在 `v1.1.0` 已验证稳定，后续若再优化菜单栏宽度，应避免把综合双行 title 纳入通用 `attributedTitle.size().width` 手动长度计算。

---

## 2026-05-11 Solo 评审综合判断与 1.3.2 处理记录

**评审员**：Codex
**评审范围**：Solo 关于菜单栏显示对齐、剪贴板性能、面板定位和辅助功能权限交互的两份专项评审。

### 采纳项

1. 菜单栏显示路径混用导致模式切换时可能出现像素级跳动：判断成立。本轮不做全 attributed title 或全自绘的大改，而是将菜单栏数值布局参数集中到 `StatusMetricLayout`，把单行 baseline offset 从 `-0.8` 收敛为 `-0.5`，并移除 `StatusDualMetricView` 的额外 `verticalOffset = 1.0`，让双数值自绘文本回到基于内容高度的居中计算。
2. 辅助功能权限交互偏弱：判断成立。用户主动开启反转鼠标滚轮且权限不足时，调用 `AXIsProcessTrustedWithOptions` 触发系统授权提示；菜单中的权限提示和系统设置入口继续保留。
3. 剪贴板面板定位存在边界隐患：判断成立。本轮在按钮锚定路径和 fallback 路径都对最终 frame 做 `visibleFrame` 边界 clamp，降低多屏上下拼接、菜单栏位置异常或特殊安全区下的面板溢出风险。

### 暂缓项

1. 大图片剪贴板处理在主线程可能造成 UI 卡顿：方向成立，但本轮暂缓。当前代码所有 SQLite 操作都在主线程，直接把 `checkPasteboard()` 扔到后台会引入同一个 SQLite 连接跨线程读写的风险。后续如果处理，应同时设计数据库串行队列或读写连接隔离策略，而不是只移动图片压缩。
2. 全面统一菜单栏渲染路径：暂缓。全 attributed title 曾在综合双行标签上出现裁切回归；全自绘资源开销不大，但会明显增加菜单栏图片、文字、长度和系统交互的维护复杂度。`1.3.2` 先选择最小对齐修正。

### 结论

`1.3.2` 采纳 Solo 评审中收益明确且风险低的修复：菜单栏对齐参数收敛、辅助功能授权 prompt、多屏面板边界 clamp。涉及并发和架构切换的建议保留为后续专项，不混入本次小版本。

---
  5→## 2026-05-11 双数值采样与综合标签回归复核
  6→
  7→**评审员**：Codex
  8→**评审范围**：`AppDelegate.swift` 中 `updateMetric()`、`applyMetricDisplay()`、`makeStackedTitle()`、`StatusDualMetricView` 的菜单栏显示路径。
  9→
 10→### 结论
 11→
 12→1. `双数值` CPU 显示 `0%` 的根因是 CPU 使用率读取依赖两次采样之间的 delta。`1.3.0` 的实现会先按当前 Monitor 模式采样一次，再在 `双数值` 分支第二次采样 CPU，第二次 delta 过短，容易得到接近 `0%` 的结果。
 13→2. `综合` + `数值与动画` 丢失下方 `C` / `M` 标签的根因是 `makeStackedTitle()` 中额外设置 baseline offset 后，双行 attributed title 在 `NSStatusBarButton` 内被裁切。
 14→3. `1.3.1` 已将 `双数值` 路径改为一次性读取 CPU 和内存，并移除 `makeStackedTitle()` 的 baseline offset。两处修复都保持现有菜单结构和用户偏好键不变。
 15→
 16→### 残余风险
 17→
 18→当前仍然存在两套菜单栏文字渲染路径：普通/综合模式使用 `NSStatusBarButton.attributedTitle`，`双数值` 使用 `StatusDualMetricView` 自绘。这是为了换取更紧凑的双行宽度和更可控的菜单栏占位。后续如果继续追求模式切换时的绝对一致性，应优先考虑统一渲染路径，而不是继续增加独立偏移参数。
 19→
 20→---
 21→
  5→## 2026-05-11 菜单栏显示与对齐专项评审
  6→
  7→**评审员**：SOLO
  8→**评审范围**：`AppDelegate.swift` 中的 `StatusDualMetricView` 及 `applyMetricDisplay` / `makeStackedTitle` 渲染逻辑。
  9→**评审方法**：从 UI 表现、渲染引擎一致性、原生 API 推荐用法等维度进行源码审查，分析其是否为最佳实践，并指出当前潜在的跳动与对齐问题。
 10→
 11→### 发现的问题与现象
 12→
 13→目前项目中存在两种不同的渲染路径：
 14→1. **单行模式（综合、CPU、内存）**：通过直接设置 `NSStatusBarButton` 的 `attributedTitle` 实现。为了让单行文本在视觉上居中，代码硬编码了 `.baselineOffset: -0.8`。
 15→2. **双行紧凑模式（CPU + 内存）**：由于原生 `attributedTitle` 无法完美支持极其紧凑且行高一致的双行排版，代码中引入了一个自定义的 `StatusDualMetricView` 盖在 Button 上，内部使用 `draw(_ dirtyRect:)` 自己计算 Y 轴位置，硬编码了 `verticalOffset = 1.0`。
 16→
 17→**用户体验问题（"不同模式切换的时候又有点奇怪"）**：
 18→当用户在“单行模式”和“双行模式”之间切换时，渲染引擎发生了从“AppKit 原生 Title”到“自定义 View draw()”的突变。由于两边的基线微调硬编码值（`-0.8` 和 `1.0`）没有经过统一的基线对齐测算，文字的绝对物理基准线发生了像素级的上下跳动，造成了视觉上的“不稳”或“奇怪”。
 19→
 20→### 当前方案是否为最佳实践？
 21→
 22→**结论：这是一个“聪明且务实的 Hack 方案”，但不是“纯正的最佳实践”。**
 23→
 24→*   **为什么说它聪明？**
 25→    在 macOS 较新版本中（Big Sur 之后），Apple 强烈推荐使用 `NSStatusItem.button`，直接替换 `statusItem.view` 的做法已被废弃（会导致丢失原生点击高亮、按住 Cmd 拖拽图标等系统特性）。当前代码保留了原生的 Button，仅仅在需要时 `addSubview`，完美保留了系统级交互，且内存占用极低。
 26→*   **为什么不是最佳实践？**
 27→    最佳实践应当保证**状态单一、渲染机制统一**。混合的渲染机制是 UI 抖动和维护成本高的根源。
 28→
 29→### 优化建议与解决办法
 30→
 31→为了消除模式切换时的跳动感，建议统一渲染路径。有两个方向的解决方案：
 32→
 33→#### 方案 A：彻底拥抱纯富文本（首选推荐，最符合“极简”原则）
 34→**思路**：完全废弃 `StatusDualMetricView`。双行显示也通过构造带有换行符 `\n` 的 `NSAttributedString`，配合 `NSMutableParagraphStyle`（设置极小的 `lineSpacing` 或甚至负值的 `maximumLineHeight`）来实现，直接赋值给 `statusItem.button?.attributedTitle`。
 35→**优点**：所有的渲染全部交回给系统的 `NSStatusBarButton`，切换模式仅仅是字符串替换，彻底杜绝渲染引擎切换带来的像素跳动。
 36→**可行性**：原有的 `makeStackedTitle` 方法其实已经部分证明了这种思路的可行性，只需进一步微调段落属性和字号即可。
 37→
 38→#### 方案 B：统一接管渲染（高度定制）
 39→**思路**：不管是单行还是双行，甚至包括猫咪的动画图片，**全部**放到你的自定义 View 中绘制。然后把这个 View 盖在空的 Button 上。
 40→**优点**：拥有 100% 的像素级控制权，所有的基线对齐、图片和文字的间距全部由 `draw` 函数计算，切换模式绝对平滑。
 41→**缺点**：实现稍微重了一些，需要自己处理图文混排的宽度计算。
 42→
 43→#### 临时微调方案（如果不打算大改架构）
 44→如果决定保留当前的混合方案，必须重新标定微调参数：
 45→1.  将单行模式的 `.baselineOffset: -0.8` 微调为 `-0.5`（更符合系统默认基线）。
 46→2.  在 `applyDualMetricDisplay()` 的 AutoLayout 中，对 `topAnchor` 施加微小的 `constant` 偏移，或者在 `StatusDualMetricView` 中将 `verticalOffset` 归零，通过 `draw` 内部重新计算 `(bounds.height - textSize.height) / 2`，使其与单行模式的绝对基线对齐。
 47→3.  对 `makeStackedTitle` 中的双行拼接，使用 `.baselineOffset: -1.0`（上行）和 `.baselineOffset: 1.0`（下行）来保证对称性。
 48→
 49→### 评审汇总
 50→
 51→| 类别 | 严重度 | 描述 | 建议 |
 52→|------|------|------|------|
 53→| UI 体验 | 中等 | 单行/双行模式切换时基线跳动 | 统一渲染路径（方案 A）或重新标定硬编码偏移量 |
 54→| 架构设计 | 轻微 | 混合渲染机制不是最佳实践 | 废弃 `StatusDualMetricView`，纯用 `NSAttributedString` 解决排版 |
 55→
 56→---
 57→
 58→## 2026-05-07 独立复核与本轮修复
 59→
 60→**评审员**：Codex
 61→**评审范围**：`AppDelegate.swift`、`ClipboardManager.swift`、`ClipboardPanel.swift`、Xcode 工程版本配置、GitHub Actions 发布流程
 62→**评审方法**：从当前代码独立判断，参考历史 review 和 git commit 记录，但不直接沿用旧结论。
 63→
 64→### 独立判断
 65→
 66→#### 1. 开机启动状态处理：确定是问题，已修复
 67→
 68→当前实现先更新菜单勾选和 `UserDefaults`，再用 `try?` 静默调用 `SMAppService.mainApp.register()` / `unregister()`。如果系统注册失败，UI 和偏好设置会显示成功，但真实系统状态失败。
 69→
 70→本轮修复：
 71→
 72→- 改为先调用 `SMAppService`，捕获错误并记录日志。
 73→- 注册/注销后统一读取 `SMAppService.mainApp.status == .enabled` 作为真实状态源。
 74→- 打开右键菜单前也刷新一次状态，避免菜单显示过期状态。
 75→- `DashCatLaunchAtLogin` 只作为状态缓存，不再作为唯一真相来源。
 76→
 77→#### 2. 历史保留天数变更后不立即清理：轻量行为问题，已修复
 78→
 79→`cleanupExpired()` 原本只在 `ClipboardManager` 初始化时执行。用户把保留期从 90 天改成 7 天后，旧记录会继续显示到下次启动。严格说这不是数据损坏，也不会破坏数据库；但从“历史保留时间可自定义”的产品语义看，设置后立即生效更符合用户预期。
 80→
 81→本轮修复：
 82→
 83→- 选择预设天数后调用 `ClipboardManager.shared.cleanupExpired()`。
 84→- 选择自定义天数后同样立即清理。
 85→- 如果剪贴板面板正在显示，清理后刷新列表。
 86→
 87→#### 3. 剪贴板面板定位：不是确定 bug，作为稳健性优化处理
 88→
 89→旧实现用 `statusItem.button?.window?.frame` 定位面板。它在很多系统环境下可能正常工作，因此不应被定性为确定 bug；但从语义上看，面板应该锚定状态栏按钮本身，而不是承载按钮的窗口。
 90→
 91→本轮修复：
 92→
 93→- 改为先将按钮 `bounds` 转到窗口坐标，再用 `button.window.convertToScreen(...)` 获取按钮的真实屏幕坐标。
 94→- 保留原有无按钮时的 fallback 逻辑。
 95→
 96→#### 4. 版本号：`0.0.0` 占位方案不够好，已改为 build setting 驱动
 97→
 98→历史提交 `274507f` 明确说明：本地版本号 `0.0.0` 是占位，CI 从 git tag 提取版本，并通过 `xcodebuild` 参数注入 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`。这个目标是合理的：发布产物应由 tag 决定版本，避免手工改多个地方。
 99→
100→但源码里长期保留 `0.0.0` 占位不够好：
101→
102→- 本地自行构建会显示 `0.0.0`，检查更新逻辑也可能拿 `0.0.0` 做比较。
103→- 如果 `Info.plist` 写死版本号，CI 传入 `MARKETING_VERSION` 不一定能影响最终 `CFBundleShortVersionString`。
104→- 版本真相分散在 `Info.plist`、工程 build settings、tag、CI 参数之间，容易产生误判。
105→
106→本轮修复：
107→
108→- `Info.plist` 改为 `<string>$(MARKETING_VERSION)</string>` 和 `<string>$(CURRENT_PROJECT_VERSION)</string>`。
109→- 工程 Debug/Release 默认版本改为当前源码版本：`MARKETING_VERSION = 0.0.7`、`CURRENT_PROJECT_VERSION = 7`。
110→- CI 仍可继续通过 `xcodebuild MARKETING_VERSION=... CURRENT_PROJECT_VERSION=...` 从 tag 覆盖版本。
111→
112→这样本地构建有合理版本号，发布构建仍由 tag 自动注入，`AppDelegate.bundleVersion` 也会读取最终展开后的真实版本。
113→
114→### 本轮修改文件
115→
116→| 文件 | 改动摘要 |
117→|------|----------|
118→| `DashCat/AppDelegate.swift` | 历史保留期变更后立即清理；开机启动以 `SMAppService` 真实状态为准；菜单打开前刷新开机启动状态 |
119→| `DashCat/ClipboardPanel.swift` | 面板定位改为使用状态栏按钮自身的屏幕坐标 |
120→| `DashCat/Info.plist` | 版本号改为引用 `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` |
121→| `DashCat.xcodeproj/project.pbxproj` | 本地默认版本改为 `0.0.7` / `7` |
122→| `project-log/review.md` | 记录本轮独立复核结论、修复范围和版本号判断 |
123→
124→---
125→
126→## 第一轮评审
127→
128→**时间**：2026-05-04 19:45
129→**评审员**：GLM-5.1
130→**评审范围**：全部 5 个源文件（1480 行），以及 project-log 下的所有设计文档
131→**评审方法**：逐文件通读源码，对照 spec 和 principles 进行交叉验证
132→
133→---
134→
135→### 一、Bug
136→
137→#### BUG-1：点击剪贴板面板条目会产生重复记录 [严重]
138→
139→**位置**：`ClipboardPanel.swift:273-289` + `ClipboardManager.swift:96-119`
140→
141→**描述**：
142→
143→用户在面板中点击某条历史记录后，`tableViewSelectionDidChange` 将内容写入 `NSPasteboard.general`，然后关闭面板。1 秒后，`ClipboardManager` 的轮询定时器检测到 `changeCount` 变化，调用 `checkPasteboard()` 读取剪贴板内容并插入数据库。
144→
145→现有的重复检测逻辑（`ClipboardManager.swift:106`）只与"最新一条"比对：
146→
147→```swift
148→if let last = fetchLatest(), !last.isImage, last.content == string { return }
149→```
150→
151→但如果你点击的是一条旧记录（非最新条目），`fetchLatest()` 返回的是数据库中按时间排序的最新条目，与当前写入剪贴板的内容不同，重复检测失败，同一条内容被再次插入。
152→
153→**复现路径**：
154→
155→1. 历史中有条目 A（时间较早）和条目 B（时间最新）
156→2. 用户点击条目 A → A 的内容写入剪贴板 → 面板关闭
157→3. 轮询检测到 `changeCount` 变化 → `fetchLatest()` 返回 B
158→4. A 的内容 ≠ B 的内容 → 重复检测失败 → A 被再次插入数据库
159→
160→**修复建议**：
161→
162→在面板点击复制时，同步更新 `ClipboardManager` 的 `changeCount`，使轮询跳过自身触发的剪贴板变化。例如：
163→
164→```swift
165→// ClipboardPanel.tableViewSelectionDidChange 中复制后
166→ClipboardManager.shared.syncChangeCount()
167→```
168→
169→```swift
170→// ClipboardManager 新增方法
171→func syncChangeCount() {
172→    changeCount = NSPasteboard.general.changeCount
173→}
174→```
175→
176→---
177→
178→#### BUG-2：自定义天数不会正确恢复 [中等]
179→
180→**位置**：`AppDelegate.swift:223-227` + `AppDelegate.swift:502-521`
181→
182→**描述**：
183→
184→用户选择自定义天数（例如 45 天），值通过 `UserDefaults.standard.set(days, forKey: "DashCatHistoryDays")` 存入。但下次启动时，`historyDays` 属性通过以下逻辑初始化：
185→
186→```swift
187→private var historyDays: HistoryDays = {
188→    let saved = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
189→    if saved == 0 { return .thirty }
190→    return HistoryDays(rawValue: saved) ?? .thirty
191→}()
192→```
193→
194→`HistoryDays(rawValue: 45)` 返回 `nil`（45 不在枚举定义中），回退为 `.thirty`。UI 上"30 Days"被选中，但 UserDefaults 仍为 45。`cleanupExpired()` 直接读取 UserDefaults 计算天数，实际清理行为是 45 天，造成 **UI 显示与实际行为不一致**。
195→
196→**修复建议**：
197→
198→增加一个 `customHistoryDays: Int?` 属性来存储自定义值，或者在 `historyDays` 的恢复逻辑中检查是否匹配任何预设值，不匹配时在 UI 上反映出自定义状态。
199→
200→---
201→
202→#### BUG-3：首次 CPU 读数不准确 [轻微]
203→
204→**位置**：`SystemMonitor.swift:13-14` + `SystemMonitor.swift:31-53`
205→
206→**描述**：
207→
208→`previousLoad` 初始化为零值结构体 `host_cpu_load_info()`，所有 tick 字段为 0。第一次调用 `cpuUsage()` 时，`delta`（`curr - prev`）是从系统启动到当前的累计 tick 值，而不是两次采样之间的增量，会显示一个极高的不真实数值（通常 90%+）。5 秒后第二次采样才恢复正常。
209→
210→**修复建议**：
211→
212→在 `init()` 中先采样一次作为基准，丢弃首次结果：
213→
214→```swift
215→init() {
216→    // ...existing code...
217→    // 采样一次作为基准，避免首次读数不准
218→    var info = host_cpu_load_info()
219→    var count = cpuInfoCount
220→    withUnsafeMutablePointer(to: &info) {
221→        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
222→            _ = host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count)
223→        }
224→    }
225→    previousLoad = info
226→}
227→```
228→
229→---
230→
231→#### BUG-4：`cleanupExpired()` 启动时被调用两次 [轻微]
232→
233→**位置**：`AppDelegate.swift:242` + `ClipboardManager.swift:46`
234→
235→**描述**：
236→
237→`ClipboardManager.init()` 在第 46 行调用了 `cleanupExpired()`，而 `applicationDidFinishLaunching` 在第 242 行又显式调了一次 `ClipboardManager.shared.cleanupExpired()`。启动时执行了两次完全相同的清理操作，浪费启动时间，且如果清理逻辑有副作用可能导致异常。
238→
239→**修复建议**：
240→
241→删除 `AppDelegate.swift:242` 的显式调用，仅保留 `init()` 中的那一次。
242→
243→---
244→
245→#### BUG-5：`enforceMaxStorage` 会删除已固定项的图片 [严重]
246→
247→**位置**：`ClipboardManager.swift:325-366`
248→
249→**描述**：
250→
251→当图片存储超过 500MB 时，`enforceMaxStorage()` 按文件修改时间从老到新删除图片文件，并删除对应的数据库记录。但删除逻辑完全没有检查对应记录的 `is_pinned` 字段。用户精心固定的条目可能因为存储上限被静默删除，既违背用户预期，也违反了 Pin 功能"固定保留"的语义。
252→
253→**修复建议**：
254→
255→在 `enforceMaxStorage()` 的删除逻辑中，先查询记录的 `is_pinned` 状态，跳过固定项：
256→
257→```swift
258→// 删除前先检查是否固定
259→var checkStmt: OpaquePointer?
260→let checkSql = "SELECT is_pinned FROM clipboard_history WHERE image_path = ?"
261→if sqlite3_prepare_v2(db, checkSql, -1, &checkStmt, nil) == SQLITE_OK {
262→    defer { sqlite3_finalize(checkStmt) }
263→    sqlite3_bind_text(checkStmt, 1, path, -1, SQLITE_TRANSIENT)
264→    if sqlite3_step(checkStmt) == SQLITE_ROW, sqlite3_column_int(checkStmt, 0) != 0 {
265→        continue // 跳过固定项
266→    }
267→}
268→```
269→
270→---
271→
272→#### BUG-6：`selectCustomDays` 不更新 `historyDays` 属性 [中等]
273→
274→**位置**：`AppDelegate.swift:502-521`
275→
276→**描述**：
277→
278→选择自定义天数时，只将值写入了 UserDefaults，没有更新 `AppDelegate` 的 `historyDays` 属性。也没有在 `historyDaysItems` 上正确反映自定义状态——所有预设选项都被设为 `.off`，但没有任何标识表明自定义值已生效。
279→
280→用户在菜单中看到的画面是：History 子菜单中没有任何一项被勾选，不知道当前实际设置是多少天。
281→
282→**修复建议**：
283→
284→1. 在 `selectCustomDays` 中更新 `historyDays` 属性（或在恢复时正确处理自定义值）
285→2. 在 `customDaysItem` 上显示当前自定义天数，如 "Custom (45)..."
286→3. 或在 customDaysItem 旁显示勾选标记
287→
288→---
289→
290→#### BUG-7：`Option + Enter` 复制纯文本功能未实现 [中等]
291→
292→**位置**：README.md:18、spec.md:38-39 与实际代码不符
293→
294→**描述**：
295→
296→README 明确写了"Option + Enter 复制纯文本（去除格式）"，spec 中也明确标注了"Option+Enter → 复制纯文本到剪贴板，关闭弹窗"。但代码中完全没有实现键盘事件处理：
297→
298→- `ClipboardPanel` 没有实现 `keyDown` 方法
299→- `NSTableView` 的选择回调 `tableViewSelectionDidChange` 只处理鼠标点击
300→- 没有任何修饰键检测逻辑
301→
302→这是一个**承诺了但未实现的功能**，属于功能缺失。
303→
304→**修复建议**：
305→
306→1. 让 `ClipboardPanel` 或 `NSTableView` 成为 first responder
307→2. 捕获 Enter 键事件，检测 `NSEvent.modifierFlags` 是否包含 `.option`
308→3. Option+Enter 时，将 `.string` 类型（纯文本）而非富文本写入剪贴板
309→
310→---
311→
312→### 二、逻辑缺陷与健壮性问题
313→
314→#### ISSUE-1：剪贴板面板打开期间不刷新数据 [中等]
315→
316→**位置**：`ClipboardPanel.swift` 全文
317→
318→**描述**：
319→
320→用户在面板打开时复制了新内容，面板不会自动更新。`ClipboardPanel` 与 `ClipboardManager` 之间没有数据变更通知机制。必须关闭面板再重新打开才能看到新条目。
321→
322→对于一个高频使用的剪贴板管理器，这是一个明显体验问题。用户可能习惯性地打开面板后去别处复制内容，再回来查找，却发现列表没有更新。
323→
324→**修复建议**：
325→
326→使用 `NotificationCenter` 在 `ClipboardManager.insert()` 后发送通知，面板监听后自动 `reloadData()`：
327→
328→```swift
329→// ClipboardManager.insert() 末尾
330→NotificationCenter.default.post(name: .DashCatClipboardDidChange, object: nil)
331→
332→// ClipboardPanel.init() 中
333→NotificationCenter.default.addObserver(self,
334→    selector: #selector(reloadData),
335→    name: .DashCatClipboardDidChange, object: nil)
336→```
337→
338→---
339→
340→#### ISSUE-2：`resignKey` 过于激进 [中等]
341→
342→**位置**：`ClipboardPanel.swift:47-50`
343→
344→**描述**：
345→
346→当前实现在面板失去 key status 时立即关闭面板（`resignKey` → `close()`）。但任何系统弹窗、通知横幅、输入法候选框、甚至某些快捷键触发都可能导致面板短暂失去 key status，面板会意外关闭。
347→
348→用户体验上，正在浏览剪贴板历史时面板突然消失，需要重新点击打开，打断工作流。
349→
350→**修复建议**：
351→
352→1. 监听 `NSApplication.didResignActiveNotification`（应用级别失焦）而非窗口级别
353→2. 或增加短延迟（0.3-0.5秒），在延迟后检查是否仍是 non-key 状态再关闭
354→3. 或仅在用户点击面板外区域时关闭（全局监听鼠标点击事件）
355→
356→---
357→
358→#### ISSUE-3：SQLite 错误全部静默吞掉 [中等]
359→
360→**位置**：`ClipboardManager.swift` 全文，涉及所有数据库操作
361→
362→**描述**：
363→
364→所有 SQLite 操作的返回值都不检查：
365→
366→- `sqlite3_open()` 失败后 `db = nil`，后续所有操作在 `guard db != nil else { return }` 处静默退出
367→- `sqlite3_prepare_v2()` 失败直接 `return`，不输出任何错误信息
368→- `sqlite3_step()` 的返回值从不检查（只判断 `== SQLITE_ROW`，不判断错误）
369→- `sqlite3_exec()` 的错误参数传了 `nil`
370→
371→如果数据库文件损坏、磁盘满、权限异常，用户完全无感知——剪贴板功能静默失效，无法排查。
372→
373→**修复建议**：
374→
375→1. 至少在 `openDatabase()` 和 `createTable()` 失败时输出 `NSLog` 或 `os_log`
376→2. 关键操作（`insert`、`deleteItem`、`togglePin`）检查 `sqlite3_step()` 返回 `SQLITE_DONE`
377→3. 考虑在数据库完全不可用时通过面板或菜单提示用户
378→
379→---
380→
381→#### ISSUE-4：文本内容无长度限制 [轻微]
382→
383→**位置**：`ClipboardManager.swift:104-108`
384→
385→**描述**：
386→
387→用户复制超大文本（如整个源码文件、日志文件），会原封不动存入 SQLite 的 `content` 字段。没有截断或大小限制。极端情况下，单条记录可能达到数 MB，导致：
388→
389→- 数据库文件快速膨胀
390→- `fetchAll()` 和 `search()` 查询变慢
391→- 面板渲染卡顿
392→
393→**修复建议**：
394→
395→对 `content` 做长度限制，例如截断到前 10000 字符，超长部分丢弃。在面板显示中已经只展示前 80 字符（`ClipboardPanel.swift:264`），存储全量文本的意义不大。
396→
397→---
398→
399→#### ISSUE-5：缩略图路径替换逻辑脆弱 [轻微]
400→
401→**位置**：`ClipboardManager.swift:261, 318`
402→
403→**描述**：
404→
405→多处使用 `path.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")` 来推算缩略图路径。这个逻辑假设：
406→
407→1. 所有图片路径都以 `.jpg` 结尾
408→2. 路径中不会出现其他 `.jpg` 子串
409→
410→如果未来支持其他格式（如 `.png`），或文件路径中包含 `.jpg`（如 `/path/to/my.jpg_backup/image.jpg`），替换结果会错误。
411→
412→**修复建议**：
413→
414→使用 `URL` 或 `NSString.pathExtension` 来操作路径扩展名：
415→
416→```swift
417→let url = URL(fileURLWithPath: path)
418→let thumbPath = url.deletingPathExtension()
419→    .appendingPathExtension("jpg")
420→    .path
421→    .replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
422→```
423→
424→或在数据库中增加 `thumbnail_path` 字段，同时记录缩略图路径。
425→
426→---
427→
428→#### ISSUE-6：`clearAll()` 删除 Images 目录下所有文件 [轻微]
429→
430→**位置**：`ClipboardManager.swift:274-283`
431→
432→**描述**：
433→
434→`clearAll()` 不加判断地删除 `imagesDir` 下所有文件。如果有非预期文件（如 `.DS_Store`、临时写入的文件、其他程序的残留），也会被一并删除。虽然这个目录由 DashCat 独占，风险较低，但不够严谨。
435→
436→---
437→
438→### 三、代码质量问题
439→
440→#### QUALITY-1：不必要的 `#available` 检查
441→
442→**位置**：`AppDelegate.swift:540`
443→
444→历史判断：当时误以为项目只面向最新系统，因此认为 `if #available(macOS 13.0, *)` 是死代码。后续复核已确认工程实际部署目标为 macOS 13+，类似可用性检查需要结合真实 deployment target 判断，不能只按早期设想处理。
445→
446→---
447→
448→#### QUALITY-2：硬编码英文字符串未本地化
449→
450→**位置**：多处
451→
452→以下字符串硬编码为英文，与项目 7 语言本地化的目标不一致：
453→
454→| 位置 | 字符串 |
455→|------|--------|
456→| `ClipboardPanel.swift:67` | 搜索框占位符 `"Search..."` |
457→| `ClipboardPanel.swift:254` | 图片标签 `"Image"` |
458→| `ClipboardPanel.swift:268` | Pin 标识 `"pin"` |
459→| `ClipboardPanel.swift:301-307` | 右键菜单 `"Pin"` / `"Unpin"` / `"Delete"` |
460→| `AppDelegate.swift:505` | 自定义天数对话框 `"Enter number of days (1-365):"` |
461→| `AppDelegate.swift:421` | Language 菜单标题硬编码为 `"Language"` |
462→
463→建议将这些字符串加入 `Language.table` 字典，通过 `language.str()` 获取本地化文本。
464→
465→---
466→
467→#### QUALITY-3：`sqlite3_bind_text` 使用 `unsafeBitCast(-1, ...)` 的模式
468→
469→**位置**：`ClipboardManager.swift:185, 190, 194, 233, 315, 358`
470→
471→多处使用 `unsafeBitCast(-1, to: sqlite3_destructor_type.self)` 传递 `SQLITE_TRANSIENT` 语义。虽然功能正确，但 `unsafeBitCast` 语义不清晰，且如果误用可能导致未定义行为。
472→
473→建议在文件顶部定义常量：
474→
475→```swift
476→private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
477→```
478→
479→然后所有调用点使用 `SQLITE_TRANSIENT` 替代。
480→
481→---
482→
483→#### QUALITY-4：`cleanupOrphanedImages` 存在 N+1 查询问题
484→
485→**位置**：`ClipboardManager.swift:307-323`
486→
487→对每个图片文件执行一次 `SELECT COUNT(*) FROM clipboard_history WHERE image_path = ?` 查询。当图片文件较多时（数百张），会产生数百次数据库查询。
488→
489→**修复建议**：
490→
491→一次性查询所有存在的 `image_path`，构建 Set 后与文件系统对比：
492→
493→```swift
494→private func cleanupOrphanedImages() {
495→    // 一次性查询所有数据库中存在的图片路径
496→    var dbPaths = Set<String>()
497→    var stmt: OpaquePointer?
498→    let sql = "SELECT image_path FROM clipboard_history WHERE image_path IS NOT NULL"
499→    if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
500→        defer { sqlite3_finalize(stmt) }
501→        while sqlite3_step(stmt) == SQLITE_ROW {
502→            if let cStr = sqlite3_column_text(stmt, 0) {
503→                dbPaths.insert(String(cString: cStr))
504→            }
505→        }
506→    }
507→
508→    guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDir) else { return }
509→    for file in files where !file.hasSuffix("_thumb.jpg") {
510→        let path = (imagesDir as NSString).appendingPathComponent(file)
511→        if !dbPaths.contains(path) {
512→            try? FileManager.default.removeItem(atPath: path)
513→            let thumbPath = path.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
514→            try? FileManager.default.removeItem(atPath: thumbPath)
515→        }
516→    }
517→}
518→```
519→
520→---
521→
522→#### QUALITY-5：`updateMetric` 每次重建 `runnerTimer`
523→
524→**位置**：`AppDelegate.swift:589-616`
525→
526→每 5 秒调用 `updateMetric()` 时都会 `invalidate` 旧 `runnerTimer` 并创建新的 `Timer` 对象。频繁创建/销毁 Timer 有不必要的开销。
527→
528→**修复建议**：
529→
530→- 如果帧率变化不大（差异 < 0.5fps），跳过 Timer 重建
531→- 或使用固定帧率（如 12fps），仅通过是否渲染来控制视觉速度
532→
533→---
534→
535→### 四、架构与设计优化建议
536→
537→#### OPT-1：增加数据变更通知机制
538→
539→当前 `ClipboardManager` 和 `ClipboardPanel` 之间没有松耦合的通信机制。`AppDelegate` 直接调用 `clipboardPanel?.reloadData()`。建议用 `NotificationCenter` 发送剪贴板数据变更通知，让面板自动刷新，也方便未来扩展。
540→
541→---
542→
543→#### OPT-2：SQLite 启用 WAL 模式
544→
545→默认的 DELETE journal 模式在读写并发时性能较差。WAL（Write-Ahead Logging）模式更适合频繁写入的场景，且读取不会被写入阻塞。一行代码即可启用：
546→
547→```swift
548→sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)
549→```
550→
551→---
552→
553→#### OPT-3：考虑 SQLite 数据库 VACUUM
554→
555→长时间使用后，大量 `DELETE` 操作会留下空闲页，数据库文件不会自动缩小。可在 `clearAll()` 后执行 `VACUUM` 回收空间：
556→
557→```swift
558→sqlite3_exec(db, "VACUUM", nil, nil, nil)
559→```
560→
561→---
562→
563→#### OPT-4：图片保存时添加单张大小限制
564→
565→spec 中提到"单张上限 500KB"但代码未实现。应在 `saveImage()` 中检查 `jpegData.count`，超限时提高压缩率或缩小尺寸后重试。
566→
567→---
568→
569→#### OPT-5：`ClipboardItem` 改为 struct
570→
571→`ClipboardItem` 目前是 `final class`，但它只是纯数据载体，没有引用语义的需求。改为 `struct` 更符合 Swift 惯例，也更安全（值语义避免意外共享修改）。
572→
573→---
574→
575→### 五、评审汇总
576→
577→| 类别 | 数量 | 严重 | 中等 | 轻微 |
578→|------|------|------|------|------|
579→| Bug | 7 | 2 | 2 | 3 |
580→| 逻辑缺陷 | 6 | 0 | 3 | 3 |
581→| 代码质量 | 5 | - | - | 5 |
582→| 优化建议 | 5 | - | - | 5 |
583→
584→**最高优先级修复项**：
585→
586→1. **BUG-1**（点击条目产生重复记录）— 影响核心功能体验，每次使用都会遇到
587→2. **BUG-5**（固定项图片被静默删除）— 违反 Pin 功能的语义承诺
588→3. **BUG-7**（Option+Enter 未实现）— 与 README 和 spec 的明确承诺不符
589→4. **ISSUE-1**（面板不自动刷新）— 高频使用的剪贴板管理器的核心体验问题
590→
591→---
592→
593→*评审时间：2026-05-04 19:45*
594→*评审员：GLM-5.1*
595→
596→---
597→
598→## 第一轮评审修复响应
599→
600→**修复时间**：2026-05-05
601→**修复人**：Claude (Opus 4.6)
602→
603→逐条过了一遍评审意见，以下是每条的处理结果和思考。
604→
605→---
606→
607→### Bug 修复
608→
609→**BUG-1（点击条目产生重复记录）** — 已修复
610→
611→在 `ClipboardManager` 新增 `syncChangeCount()` 方法，将内部 `changeCount` 同步为当前 `NSPasteboard.general.changeCount`，使轮询跳过自身触发的变化。在 `ClipboardPanel.tableViewSelectionDidChange` 和新增的 `keyDown` 处理中，复制后立即调用此方法。
612→
613→评审建议的方案准确且最小侵入，直接采纳。
614→
615→**BUG-2（自定义天数不正确恢复）** — 已修复
616→
617→新增 `customHistoryDays: Int?` 属性。启动时若 UserDefaults 中的值不匹配任何 `HistoryDays` 枚举项，则存入 `customHistoryDays`。菜单中 `customDaysItem` 显示为"Custom... (45)"格式，让用户明确知道当前自定义值是多少。
618→
619→`selectHistoryDays` 选择预设值时会清空 `customHistoryDays` 并恢复菜单标题。
620→
621→**BUG-3（首次 CPU 读数不准确）** — 已修复
622→
623→在 `SystemMonitor.init()` 末尾增加一次采样，将结果写入 `previousLoad` 作为基准，丢弃首次结果。后续 `cpuUsage()` 的第一次调用即可获得正确的增量数据。
624→
625→**BUG-4（`cleanupExpired` 被调用两次）** — 已修复
626→
627→删除了 `AppDelegate.applicationDidFinishLaunching` 中显式的 `ClipboardManager.shared.cleanupExpired()` 调用，仅保留 `ClipboardManager.init()` 中的那一次。
628→
629→**BUG-5（`enforceMaxStorage` 会删除已固定项的图片）** — 已修复
630→
631→在 `enforceMaxStorage()` 的删除循环中，先查询 `is_pinned` 字段，跳过固定项。固定条目的图片不受存储上限清理影响。
632→
633→**BUG-6（`selectCustomDays` 不更新状态）** — 已修复
634→
635→随 BUG-2 一起解决。`selectCustomDays` 现在会设置 `customHistoryDays`、更新 UserDefaults、清空预设勾选、并在菜单标题中显示自定义天数。
636→
637→**BUG-7（`Option + Enter` 未实现）** — 已修复
638→
639→在 `ClipboardPanel` 中重写 `keyDown(with:)` 方法。Enter 键（keyCode 36）被拦截：
640→- 普通 Enter：正常复制（图片或文本）
641→- Option+Enter：仅复制纯文本（`.string` 类型），即使条目是富文本
642→
643→复制后同步 `changeCount`、关闭面板、触发回调，与鼠标点击行为一致。
644→
645→---
646→
647→### 逻辑缺陷修复
648→
649→**ISSUE-1（面板打开期间不刷新数据）** — 已修复
650→
651→在 `ClipboardManager.insert()` 末尾发送 `NSNotification.Name.DashCatClipboardDidChange` 通知。`ClipboardPanel` 在 `init` 中注册监听，收到通知后仅在面板可见时调用 `reloadData()`。
652→
653→同时解决了 OPT-1（增加数据变更通知机制）。
654→
655→**ISSUE-2（`resignKey` 过于激进）** — 已修复
656→
657→将 `resignKey` 的 `close()` 改为延迟 0.3 秒执行。延迟后再次检查面板是否仍然可见且非 key window，避免系统弹窗、输入法候选框等导致的意外关闭。
658→
659→**ISSUE-3（SQLite 错误静默吞掉）** — 已修复
660→
661→引入 `os.log.Logger`（subsystem: `com.dashcat.app`），在以下关键位置添加错误日志：
662→- `openDatabase` 失败
663→- `createTable` 失败
664→- `insert` 的 `sqlite3_step` 返回非 `SQLITE_DONE`
665→- `togglePin` 的 prepare 或 step 失败
666→- `deleteItem` 的 prepare 或 step 失败
667→
668→不在 UI 层面弹出错误（避免打扰用户），但问题可在 Console.app 中排查。
669→
670→**ISSUE-4（文本内容无长度限制）** — 已修复
671→
672→新增 `maxTextLength = 10000` 常量。`checkPasteboard` 中在重复检测前先截断超长文本。面板显示层已只展示前 80 字符，存储全量文本意义不大。
673→
674→**ISSUE-5（缩略图路径替换逻辑脆弱）** — 已修复
675→
676→新增 `thumbnailPath(for:)` 方法，使用 `URL(fileURLWithPath:)` 的 `deletingPathExtension` + `lastPathComponent` 来安全构建缩略图路径，先检查扩展名是否为 `jpg`。所有需要推算缩略图路径的地方统一使用此方法。
677→
678→`ClipboardPanel` 中的缩略图加载也改为 URL API 方式。
679→
680→**ISSUE-6（`clearAll` 删除目录下所有文件）** — 未修改
681→
682→评审自身也指出"风险较低"。此目录由 DashCat 独占管理，不会出现非预期文件。加过滤反而增加复杂度，收益不大。
683→
684→---
685→
686→### 代码质量改进
687→
688→**QUALITY-1（不必要的 `#available` 检查）** — 已修复
689→
690→历史处理记录：当时按“只面向最新系统”的错误前提移除了 `if #available(macOS 13.0, *)` 包装。后续版本已把当前基线明确为 macOS 13+；未来处理可用性分支时，应先核对 Xcode 工程里的实际 deployment target。
691→
692→**QUALITY-2（硬编码英文字符串未本地化）** — 已修复
693→
694→在 `Language.table` 中新增以下键：`search`、`image`、`pin`、`unpin`、`delete`、`language`、`customDaysPrompt`、`ok`、`cancel`，覆盖 7 种语言。
695→
696→`ClipboardPanel` 中通过文件级 `localized()` 辅助函数读取当前语言并查找翻译。`AppDelegate` 中 `languageMenuItem.title` 和自定义天数对话框的按钮/提示文字也改为本地化调用。
697→
698→**QUALITY-3（`unsafeBitCast` 模式）** — 已修复
699→
700→在 `ClipboardManager.swift` 顶部定义 `private let SQLITE_TRANSIENT`，所有调用点统一使用此常量。
701→
702→**QUALITY-4（`cleanupOrphanedImages` 的 N+1 查询）** — 已修复
703→
704→改为一次查询所有 `image_path IS NOT NULL` 的记录，构建 `Set<String>`，然后与文件系统对比。将 N 次数据库查询降为 1 次。
705→
706→---
707→
708→### 优化实施
709→
710→**OPT-2（SQLite WAL 模式）** — 已实施
711→
712→在 `openDatabase()` 中 `sqlite3_open` 成功后执行 `PRAGMA journal_mode=WAL`。WAL 模式下读写不互相阻塞，适合轮询+写入的场景。
713→
714→**OPT-3（VACUUM）** — 已实施
715→
716→在 `clearAll()` 末尾执行 `VACUUM`，回收 DELETE 操作留下的空闲页。
717→
718→**OPT-4（单张图片大小限制）** — 已实施
719→
720→`saveImage()` 中采用渐进式压缩：先尝试 0.6 压缩因子，若超过 500KB 则依次尝试 0.4、0.25，直到满足限制。spec 中要求的"单张上限 500KB"现在有了实际保障。
721→
722→**OPT-5（`ClipboardItem` 改为 struct）** — 已实施
723→
724→`ClipboardItem` 从 `final class` 改为 `struct`。它只是纯数据载体，值语义更安全，也更符合 Swift 惯例。
725→
726→---
727→
728→### 未采纳项
729→
730→| 编号 | 原因 |
731→|------|------|
732→| ISSUE-6 | 评审自身标注"风险较低"，收益不足以证明增加复杂度合理 |
733→
734→---
735→
736→### 修改文件清单
737→
738→| 文件 | 改动摘要 |
739→|------|----------|
740→| `SystemMonitor.swift` | init 中增加 CPU 基准采样（BUG-3） |
741→| `ClipboardManager.swift` | 新增 syncChangeCount、thumbnailPath、Logger；WAL 模式；SQLITE_TRANSIENT 常量；文本截断；通知发送；is_pinned 保护；VACUUM；渐进式压缩；N+1 修复；struct 替代 class |
742→| `ClipboardPanel.swift` | 新增 keyDown（Option+Enter）、延迟 resignKey、自动刷新通知、本地化字符串、URL 方式构建缩略图路径 |
743→| `AppDelegate.swift` | 移除重复 cleanupExpired；移除 #available；新增 customHistoryDays 属性；本地化菜单和对话框；新增 9 个本地化键 |
744→
745→---
746→
747→*修复时间：2026-05-05*
748→*修复人：Claude (Opus 4.6)*
749→
750→---
751→
752→## 第二轮自检
753→
754→**时间**：2026-05-05
755→**检查人**：Claude (Opus 4.6)
756→**范围**：全部 4 个源文件逐行通读，重点关注第一轮修复引入的新代码、边界条件、cell 复用、状态一致性
757→**方法**：逐函数走读，模拟用户操作路径和极端输入
758→
759→---
760→
761→### 发现项
762→
763→#### BUG-A：`enforceMaxStorage` 枚举了非图片文件 [轻微]
764→
765→**位置**：`ClipboardManager.swift` `enforceMaxStorage()`
766→
767→**描述**：
768→
769→`FileManager.default.enumerator(atPath:)` 递归枚举 `imagesDir` 下所有文件，包括 `.DS_Store`、临时文件等非图片文件。这些文件的大小被计入 `totalSize`，导致 500MB 上限的触发阈值不准确——可能提前触发清理，也可能漏算实际图片大小。
770→
771→此外，枚举结果包含 `_thumb.jpg` 缩略图文件。缩略图与其原图在同一次清理中都会被删除（先删原图，再删缩略图），但缩略图的大小也被计入总量，使计算略微膨胀。
772→
773→**修复**：
774→
775→改用 `contentsOfDirectory(atPath:)` 替代 `enumerator`，仅收集以 `.jpg` 结尾且不以 `_thumb.jpg` 结尾的文件：
776→
777→```swift
778→guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDir) else { return }
779→for file in files where file.hasSuffix(".jpg") && !file.hasSuffix("_thumb.jpg") {
780→    // ...
781→}
782→```
783→
784→同时解决了 `.DS_Store` 和缩略图重复计算两个问题。
785→
786→---
787→
788→#### BUG-B：切换语言后搜索框占位符不更新 [轻微]
789→
790→**位置**：`ClipboardPanel.swift:121` + `AppDelegate.swift` `selectLanguage()`
791→
792→**描述**：
793→
794→`searchField.placeholderString` 在 `ClipboardPanel.init()` 中通过 `localized("search")` 设置一次。之后用户切换语言时，`AppDelegate.selectLanguage` 更新菜单文本、调用 `applyLanguage()`，但不会通知 ClipboardPanel 更新搜索框占位符。
795→
796→由于 `showPanel()` 不重建 UI（只清空搜索并 reloadData），面板重新打开时占位符仍是旧语言文本。
797→
798→**修复**：
799→
800→在 `ClipboardPanel` 中新增 `refreshLocale()` 方法，更新占位符并（若面板可见）刷新数据：
801→
802→```swift
803→func refreshLocale() {
804→    searchField.placeholderString = localized("search")
805→    if isVisible { reloadData() }
806→}
807→```
808→
809→在 `AppDelegate.selectLanguage()` 末尾调用 `clipboardPanel?.refreshLocale()`。
810→
811→---
812→
813→#### BUG-C：`historyDays` 属性在选择自定义天数后变为脏数据 [轻微]
814→
815→**位置**：`AppDelegate.swift` `selectCustomDays()` + `historyDays` 属性
816→
817→**描述**：
818→
819→`selectCustomDays` 将自定义值写入 `customHistoryDays` 和 UserDefaults，但未更新 `historyDays` 属性。`historyDays` 保留为用户之前选择的预设值（例如 `.thirty`）。
820→
821→实际影响有限——`cleanupExpired()` 直接从 UserDefaults 读取天数，不依赖 `historyDays` 属性。但 `historyDays` 在 `setupMenu()` 中用于初始化 `historyDaysItems` 的勾选状态（`if days == historyDays { item.state = .on }`），如果将来有代码依赖此属性做判断，会产生误导。
822→
823→**修复**：
824→
825→在 `selectCustomDays` 的成功分支中，将 `historyDays` 重置为一个有效预设值（`.thirty`），使属性不会保留过时的自定义值：
826→
827→```swift
828→customHistoryDays = days
829→historyDays = .thirty // Reset; actual value is in UserDefaults
830→UserDefaults.standard.set(days, forKey: "DashCatHistoryDays")
831→```
832→
833→---
834→
835→#### OPT-A：`enforceMaxStorage` 的 is_pinned 查询是 N+1 [轻微]
836→
837→**位置**：`ClipboardManager.swift` `enforceMaxStorage()`
838→
839→**描述**：
840→
841→第一轮评审修复（BUG-5）在 `enforceMaxStorage` 的删除循环中为每个文件执行一次 `SELECT is_pinned FROM clipboard_history WHERE image_path = ?` 查询。当图片文件较多时（数百张），产生数百次数据库查询。第一轮评审中 `cleanupOrphanedImages` 的同类 N+1 问题已修复（QUALITY-4），但 `enforceMaxStorage` 的修复遗漏了这一点。
842→
843→**修复**：
844→
845→在删除循环之前，一次性查询所有 `is_pinned = 1` 的 `image_path`，构建 `Set<String>`：
846→
847→```swift
848→var pinnedPaths = Set<String>()
849→var pinStmt: OpaquePointer?
850→let pinSql = "SELECT image_path FROM clipboard_history WHERE is_pinned = 1 AND image_path IS NOT NULL"
851→if sqlite3_prepare_v2(db, pinSql, -1, &pinStmt, nil) == SQLITE_OK {
852→    defer { sqlite3_finalize(pinStmt) }
853→    while sqlite3_step(pinStmt) == SQLITE_ROW {
854→        if let cStr = sqlite3_column_text(pinStmt, 0) {
855→            pinnedPaths.insert(String(cString: cStr))
856→        }
857→    }
858→}
859→```
860→
861→循环内改为 `if pinnedPaths.contains(path) { continue }`，将 N 次查询降为 1 次。
862→
863→---
864→
865→### 第二轮未修改项
866→
867→以下项经审查后确认无需修改：
868→
869→| 项目 | 原因 |
870→|------|------|
871→| 表格 cell 复用 | 逐路径验证后确认所有分支（sourceApp 有/无、isImage true/false）均正确设置 `iconView.image`，无残留 |
872→| `updateMetric` 每次重建 Timer | 已审查——`runnerTimer` 间隔随系统负载动态变化（1~12fps），每次重建是正确行为，非浪费 |
873→| `clearAll` 中 VACUUM 阻塞 | 用户主动触发清除历史的低频操作，且执行 VACUUM 前已删除全部数据，数据库极小，耗时可忽略 |
874→| Escape 键未处理 | `super.keyDown` 会传递事件，NSPanel 默认行为已处理 Escape 关闭 |
875→| `cleanupExpired` 仅启动时运行 | 设计决策，非 bug。每秒轮询已由 `insert` 中的 60 秒节流 `enforceMaxStorage` 覆盖 |
876→| 自定义天数对话框输入验证 | `max(1, min(365, Int(...) ?? 30))` 已处理非法输入和越界，行为合理 |
877→
878→---
879→
880→### 修改文件清单
881→
882→| 文件 | 改动摘要 |
883→|------|----------|
884→| `ClipboardManager.swift` | `enforceMaxStorage` 改用 `contentsOfDirectory` 过滤 jpg；批量查询 pinned 路径替代 N+1 |
885→| `ClipboardPanel.swift` | 新增 `refreshLocale()` 方法 |
886→| `AppDelegate.swift` | `selectLanguage` 调用 `refreshLocale()`；`selectCustomDays` 重置 `historyDays` |
887→
888→---
889→
890→*检查时间：2026-05-05*
891→*检查人：Claude (Opus 4.6)*
892→
893→---
894→
895→## 第二轮评审（复核）
896→
897→**时间**：2026-05-05 19:57
898→**评审员**：GLM-5.1
899→**评审范围**：同事（Claude Opus 4.6）根据第一轮评审修复后的全部 4 个源文件，以及其自检记录
900→**评审方法**：逐文件通读修改后的代码，对照第一轮评审意见逐条验证修复质量，并查找修复引入的新问题
901→
902→---
903→
904→### 对前次修复的评价
905→
906→同事的修复工作整体质量较高，7 个 Bug 全部处理、6 个逻辑缺陷中 5 个修复、5 个代码质量问题全部改进、5 个优化建议中 4 个实施。自检记录也发现了 4 个额外问题（BUG-A/B/C、OPT-A）并给出了修复方案。以下是逐条复核结果：
907→
908→**BUG-1（重复记录）** — 修复正确。`syncChangeCount()` 在面板复制后同步 `changeCount`，轮询不再重复插入。
909→
910→**BUG-2（自定义天数恢复）** — 修复方向正确，但实现存在状态不一致问题，详见下方 FIX-2。
911→
912→**BUG-3（首次 CPU 读数）** — 修复正确。`init()` 中采样一次作为基准。
913→
914→**BUG-4（cleanupExpired 两次）** — 修复正确。移除了 AppDelegate 中的重复调用。
915→
916→**BUG-5（固定项图片删除）** — 修复正确。批量查询 `pinnedPaths` 替代 N+1，循环中跳过固定项。
917→
918→**BUG-6（selectCustomDays 不更新状态）** — 与 BUG-2 一起处理，但存在遗留问题，见 FIX-2。
919→
920→**BUG-7（Option+Enter）** — 修复存在缺陷，见 FIX-1。
921→
922→**ISSUE-1（面板不刷新）** — 修复正确。`NotificationCenter` 通知机制工作正常。
923→
924→**ISSUE-2（resignKey 过于激进）** — 修复方向合理，0.3 秒延迟 + 二次检查。存在轻微竞态风险（快速点击面板外再点回），但实际场景中几乎不会遇到，可接受。
925→
926→**ISSUE-3（SQLite 错误静默）** — 修复正确。关键路径添加了 `Logger` 输出。
927→
928→**ISSUE-4（文本长度限制）** — 修复正确。`maxTextLength = 10000` 截断超长文本。
929→
930→**ISSUE-5（缩略图路径）** — 修复正确。新增 `thumbnailPath(for:)` 使用 URL API 安全构建路径。
931→
932→**QUALITY-1~5、OPT-2~5** — 全部修复正确。
933→
934→**自检项 BUG-A（enforceMaxStorage 枚举非图片文件）** — 修复方案合理，已在代码中实施。
935→
936→**自检项 BUG-B（切换语言后搜索框不更新）** — 修复方案合理，已在代码中实施。
937→
938→**自检项 BUG-C（historyDays 脏数据）** — 修复方案有误，详见 FIX-2。
939→
940→**自检项 OPT-A（enforceMaxStorage N+1）** — 修复方案合理，已在代码中实施。
941→
942→---
943→
944→### 发现的新问题及修复
945→
946→#### FIX-1：Option+Enter 对图片条目什么都不复制 [Bug]
947→
948→**位置**：`ClipboardPanel.swift:83-89`（修复后代码）
949→
950→**问题**：
951→
952→同事的修复中，Option+Enter 的处理逻辑为：
953→
954→```swift
955→if event.modifierFlags.contains(.option) {
956→    if let content = item.content {
957→        pb.setString(content, forType: .string)
958→    }
959→}
960→```
961→
962→对于图片条目，`item.content` 为 `nil`（数据库中 `content` 字段为空），所以 Option+Enter 对图片条目**什么都不复制**就关闭了面板。而 `pb.clearContents()` 已经执行，剪贴板被清空——用户以为复制了图片，实际上剪贴板变空了。
963→
964→**修复**：
965→
966→对于图片条目，Option+Enter 应该回退到正常复制图片（因为图片没有"纯文本"版本可以提取）：
967→
968→```swift
969→if event.modifierFlags.contains(.option) {
970→    if let content = item.content {
971→        pb.setString(content, forType: .string)
972→    } else if item.isImage, let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
973→        pb.writeObjects([image])
974→    }
975→}
976→```
977→
978→**状态**：已修复
979→
980→---
981→
982→#### FIX-2：自定义天数启动时菜单勾选状态与实际行为不一致 [Bug]
983→
984→**位置**：`AppDelegate.swift:232-252`（修复后代码）+ 自检 BUG-C 修复方案
985→
986→**问题**：
987→
988→同事将 `historyDays` 和 `customHistoryDays` 都改为了存储属性（初始化时从 UserDefaults 读取一次），然后在 `selectCustomDays` 中设置 `historyDays = .thirty`。这导致：
989→
990→1. **启动时不一致**：用户之前设了 45 天，`historyDays` 被初始化为 `.thirty`（45 不匹配枚举），`setupMenu()` 中 `if days == historyDays` 让 "30 Days" 被勾选。但实际清理行为读 UserDefaults 是 45 天。UI 显示 30 天被选中，实际按 45 天清理。
991→
992→2. **自检 BUG-C 的修复方案加剧了问题**：设置 `historyDays = .thirty` 明确让属性持有一个与 UserDefaults 不同的值，造成两个真相源（`historyDays` 属性 vs UserDefaults）的永久分裂。
993→
994→**根本原因**：`historyDays` 和 `customHistoryDays` 作为存储属性缓存了 UserDefaults 的值，但两者可能不一致。
995→
996→**修复**：
997→
998→将 `historyDays` 和 `customHistoryDays` 都改为计算属性，直接从 UserDefaults 实时读取，消除缓存不一致的可能：
999→
1000→```swift
1001→private var historyDays: HistoryDays {
1002→    get {
1003→        let saved = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
1004→        if saved == 0 { return .thirty }
1005→        return HistoryDays(rawValue: saved) ?? .thirty
1006→    }
1007→    set { /* only set via selectHistoryDays/selectCustomDays */ }
1008→}
1009→
1010→private var customHistoryDays: Int? {
1011→    get {
1012→        let saved = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
1013→        if saved == 0 { return nil }
1014→        return HistoryDays(rawValue: saved) == nil ? saved : nil
1015→    }
1016→    set {
1017→        if let newValue = newValue {
1018→            UserDefaults.standard.set(newValue, forKey: "DashCatHistoryDays")
1019→        }
1020→    }
1021→}
1022→```
1023→
1024→同时在 `setupMenu()` 中，仅当 `customHistoryDays == nil` 时才勾选预设项：
1025→
1026→```swift
1027→if customHistoryDays == nil && days == historyDays { item.state = .on }
1028→```
1029→
1030→在 `restoreState()` 中恢复自定义天数的 customDaysItem 标题和预设项勾选：
1031→
1032→```swift
1033→if let custom = customHistoryDays {
1034→    historyDaysItems.forEach { $0.state = .off }
1035→    customDaysItem.title = "\(language.str("customDays")) (\(custom))"
1036→}
1037→```
1038→
1039→`selectCustomDays` 中移除冗余的 `historyDays = .thirty` 和 `customHistoryDays = days` 调用，改为直接写 UserDefaults：
1040→
1041→```swift
1042→UserDefaults.standard.set(days, forKey: "DashCatHistoryDays")
1043→```
1044→
1045→**状态**：已修复
1046→
1047→---
1048→
1049→### 修改文件清单
1050→
1051→| 文件 | 改动摘要 |
1052→|------|----------|
1053→| `ClipboardPanel.swift` | Option+Enter 对图片条目回退到正常复制 |
1054→| `AppDelegate.swift` | `historyDays`/`customHistoryDays` 改为计算属性；`setupMenu` 仅在无自定义值时勾选预设；`selectCustomDays` 移除冗余赋值；`restoreState` 恢复自定义天数显示 |
1055→
1056→---
1057→
1058→*评审时间：2026-05-05 19:57*
1059→*评审员：GLM-5.1*
1060→
1061→---
1062→
1063→## 第三方评审分析与修复
1064→
1065→**时间**：2026-05-05
1066→**分析人**：Claude (Opus 4.6)
1067→**评审来源**：外部同行对全部源文件的 22 条分析意见
1068→**方法**：逐条对照当前源码验证，确认存在则修复，不存在则说明
1069→
1070→---
1071→
1072→### 一、确认存在并已修复的问题（5 项）
1073→
1074→#### #6：panel 在动画过程中调整大小 [已修复]
1075→
1076→**位置**：`ClipboardPanel.swift` `resizeToFitContent()`
1077→
1078→**分析**：确认存在。`reloadDataFromNotification` 在面板可见时调用 `reloadData()` → `resizeToFitContent()` → `setFrame(animate: isVisible)`。如果前一次 resize 动画尚未结束，新的 `setFrame` 会嵌套动画，导致视觉闪烁。
1079→
1080→**修复**：新增 `hasAppeared` 标志位。`showPanel()` 中先置为 `false`，`reloadData()` 完成后置为 `true`。`resizeToFitContent` 中 `animate` 条件改为 `isVisible && !hasAppeared`，仅在首次打开时动画，后续 resize 不动画。
1081→
1082→---
1083→
1084→#### #14：图片压缩循环硬编码因子，无降采样回退 [已修复]
1085→
1086→**位置**：`ClipboardManager.swift` `saveImage()`
1087→
1088→**分析**：确认存在。压缩因子 `[0.6, 0.4, 0.25]` 依次尝试，如果 0.25 仍超过 500KB，代码直接保存超限文件（`break` 跳出循环后使用最后一次的 `jpegData`）。实际上循环中 `break` 只在满足条件时触发，但如果所有因子都不满足，`jpegData` 保存的是 0.25 的结果，可能仍然超限。
1089→
1090→**修复**：在压缩循环之后增加降采样回退——如果所有压缩因子均超限，将图片尺寸减半后以 0.25 压缩因子重试。
1091→
1092→---
1093→
1094→#### #18：resizeToFitContent 在多显示器下使用 NSScreen.main [已修复]
1095→
1096→**位置**：`ClipboardPanel.swift` `resizeToFitContent()`
1097→
1098→**分析**：确认存在。`NSScreen.main` 返回的是主显示器（有菜单栏的屏幕），但 macOS 的菜单栏在所有显示器上都可见（Big Sur 起）。如果状态栏图标在副显示器上，panel 会定位到主显示器而非副显示器。
1099→
1100→**修复**：改用 `NSScreen.screens.first { $0.frame.contains(buttonFrame.midX) }` 查找包含状态栏按钮的屏幕，fallback 到 `NSScreen.main`。
1101→
1102→---
1103→
1104→#### #19：checkPasteboard 只检测 TIFF，忽略 PNG [已修复]
1105→
1106→**位置**：`ClipboardManager.swift` `checkPasteboard()`
1107→
1108→**分析**：确认存在。macOS 的截图工具（Cmd+Shift+3/4）默认写入 PNG 格式到剪贴板。代码只检查 `.tiff`，导致截图不会被记录为图片。
1109→
1110→**修复**：图片检测改为 `pb.data(forType: .tiff) ?? pb.data(forType: .png)`，优先 TIFF，fallback 到 PNG。
1111→
1112→---
1113→
1114→#### #21：isNewerVersion 不支持 prerelease 标签 [已修复]
1115→
1116→**位置**：`AppDelegate.swift` `isNewerVersion()`
1117→
1118→**分析**：确认存在。`"1.0.0-beta".split(separator: ".")` 得到 `["1", "0", "0-beta"]`，`Int("0-beta")` 返回 `nil`，`compactMap` 过滤后只剩 `[1, 0, 0]`。虽然在多数场景下结果碰巧正确（因为 GitHub `/releases/latest` 默认不返回 prerelease），但语义上不严谨。
1119→
1120→**修复**：解析版本号时只取数字前缀：`Int($0.prefix(while: { $0.isNumber }))`。`"0-beta"` → `0`，语义正确。
1121→
1122→---
1123→
1124→### 二、经分析不存在的问题（17 项）
1125→
1126→| # | 问题描述 | 分析结论 |
1127→|---|---------|---------|
1128→| 1 | 重复触发复制逻辑 | **已修复**。第一轮评审已添加 `syncChangeCount()`，`keyDown` 和 `tableViewSelectionDidChange` 复制后均调用。两条路径不会同时触发——`keyDown` 处理 Enter 键并 `close()`，鼠标点击走 `tableViewSelectionDidChange`。 |
1129→| 2 | CPU 第一次读数不准确 | **已修复**。`SystemMonitor.init()` 末尾已有基准采样（第 28-36 行），`previousLoad` 在构造时就被设为真实值。 |
1130→| 3 | 内存压力监控初始化顺序 | **不存在**。`init()` 中的操作是顺序执行的：先 `host_statistics` 采样到局部变量 `info`，再赋值给 `previousLoad`。没有并发，不存在数据竞争。 |
1131→| 4 | SQLite 未处理 SQLITE_BUSY | **可接受风险**。WAL 模式下读写不互阻，且所有写操作都在主线程串行执行（Timer 回调），不存在并发写入。SQLITE_BUSY 在此场景下极不可能出现。 |
1132→| 5 | VACUUM 在写操作后立即执行 | **可接受**。`clearAll()` 由用户主动触发（菜单 → 清除历史），是低频操作。DELETE 后数据库极小，VACUUM 耗时可忽略。 |
1133→| 7 | 混合模式显示格式不一致 | **不存在**。`makeStackedTitle` 第 662 行对 value 做了 `trimmingCharacters(in: .whitespaces)`，末尾空格被正确去除。 |
1134→| 8 | Option+Enter 在图片项时行为不对称 | **已修复**。第二轮评审已修复——Option+Enter 对图片条目回退到正常复制（`else if item.isImage` 分支）。 |
1135→| 9 | historyDays setter 为空 | **设计决策**。`historyDays` 是计算属性，setter 为空是有意为之——所有持久化通过 `selectHistoryDays`/`selectCustomDays` 直接写 UserDefaults，避免属性与 UserDefaults 不同步。 |
1136→| 10 | selectCustomDays 取消时未恢复 UI | **不存在**。取消时 `alert.runModal()` 返回 `.alertSecondButtonReturn`，不执行任何状态修改。UI 保持原样，无需恢复。 |
1137→| 11 | syncChangeCount 时序问题 | **理论竞态，实际可忽略**。`syncChangeCount` 后立即 `close()`，窗口极小（微秒级）。且即使漏捕获，下次轮询（1 秒后）仍会检测到变化。 |
1138→| 12 | willSleepNotification 未释放 sleepAssertion | **不存在问题**。系统睡眠时 IOPMA assertion 自动失效。唤醒后 assertion 句柄虽然保留，但 `applyCaffeineMode` 切换时会先 release 旧 assertion，`applicationTerminate` 也会释放。不存在状态不一致。 |
1139→| 13 | 数据库路径构造方式 | **风格建议，非 bug**。`NSSearchPathForDirectoriesInDomains` 功能正确，含空格路径也能正常工作（NSString 拼接不涉及 shell 解析）。 |
1140→| 15 | fetchLatest 查询未使用 LIMIT | **已使用 LIMIT**。当前代码第 446 行已有 `LIMIT 1`。 |
1141→| 16 | CPU 计算使用 min(99.9, ...) | **正确行为**。多核 Mac 的 CPU% 是所有核的平均值，99.9% 上限合理。`user + sys > total` 理论上不会发生（tick 计数器单调递增），`min` 是防御性保护。 |
1142→| 17 | makeFrames 中 tint 使用 sourceOver + sourceAtop | **正确**。先 `sourceOver` 绘制源图，再 `sourceAtop` 填色——`sourceAtop` 只在源图已绘制的不透明区域着色，不影响透明度。对于不透明的 cat 帧图效果正确。 |
1143→| 20 | cleanupExpired 未删除过期图片文件 | **不存在**。`cleanupExpired()` 先删除数据库记录，再调用 `cleanupOrphanedImages()` 清理无引用的图片文件。两步协作确保文件被正确清理。 |
1144→| 22 | 右键菜单回收 cells 时未重置状态 | **不存在**。`tableView(_:viewFor:row:)` 中所有分支都完整设置 `iconView.image`、`label.stringValue`、`label.textColor`、`pinIndicator.stringValue`。无论新旧 item 类型如何组合，回收 cell 的所有属性都会被覆盖。 |
1145→
1146→---
1147→
1148→### 三、修改文件清单
1149→
1150→| 文件 | 改动摘要 |
1151→|------|----------|
1152→| `ClipboardPanel.swift` | 新增 `hasAppeared` 标志位防止动画嵌套（#6）；`resizeToFitContent` 改用 `NSScreen.screens` 定位多显示器（#18） |
1153→| `ClipboardManager.swift` | `checkPasteboard` 新增 PNG 格式检测（#19）；`saveImage` 新增降采样回退（#14） |
1154→| `AppDelegate.swift` | `isNewerVersion` 支持 prerelease 标签解析（#21） |
1155→
1156→---
1157→
1158→*分析时间：2026-05-05*
1159→*分析人：Claude (Opus 4.6)*
1160→
1161→---
1162→
1163→## 第四轮独立审查
1164→
1165→**时间**：2026-05-05
1166→**审查人**：Claude (Opus 4.6)
1167→**范围**：全部 5 个源文件逐行通读，以全新视角独立审查，不依赖前三轮的结论
1168→**方法**：逐函数走读，关注废弃 API、键盘交互完整性、主线程阻射、每秒轮询的数据库开销
1169→
1170→---
1171→
1172→### 发现并修复的问题
1173→
1174→#### FIX-A：`lockFocus`/`unlockFocus` 已废弃 [已修复]
1175→
1176→**位置**：`ClipboardManager.swift` `saveImage()` 中 3 处
1177→
1178→**描述**：`lockFocus()` 在 macOS 10.14+ 标记为 deprecated，在某些图形上下文（后台线程、无窗口环境）中行为不稳定。`saveImage` 被 `checkPasteboard` 在 Timer 回调中调用，当前在主线程运行，但如果未来移到后台队列会立即崩溃。
1179→
1180→**修复**：全部替换为 `NSImage(size:flipped:drawingHandler:)` 闭包式绘图，这是 Apple 推荐的现代 API。
1181→
1182→---
1183→
1184→#### FIX-B：Escape 键无响应 [已修复]
1185→
1186→**位置**：`ClipboardPanel.swift` `keyDown(with:)`
1187→
1188→**描述**：`keyDown` 只拦截 Enter（keyCode 36），其他键走 `super.keyDown`。由于 `resignKey` 有 0.3 秒延迟，用户按 Escape 后面板不会立即关闭，体验不一致。
1189→
1190→**修复**：在 `keyDown` 中增加 Escape（keyCode 53）的显式处理，直接调用 `close()`。
1191→
1192→---
1193→
1194→#### FIX-C：`fetchLatest()` 每秒查询数据库 [已修复]
1195→
1196→**位置**：`ClipboardManager.swift` `fetchLatest()` + `checkPasteboard()`
1197→
1198→**描述**：`checkPasteboard` 每秒调用一次，每次都执行 `SELECT ... ORDER BY created_at DESC LIMIT 1` 查询数据库做去重检查。虽然单次查询很快，但完全可以用内存缓存替代。
1199→
1200→**修复**：新增 `latestCache` 属性。`insert` 成功后更新缓存；`fetchLatest` 优先读缓存；`togglePin`/`deleteItem`/`clearAll` 时清空缓存。将每秒一次的数据库查询降为 0 次（命中缓存时）。
1201→
1202→---
1203→
1204→### 未修改项
1205→
1206→| 项目 | 原因 |
1207→|------|------|
1208→| `clearAll()` 中 VACUUM 阻塞主线程 | `auto_vacuum = INCREMENTAL` 对已有数据库需完整 VACUUM 后才生效，引入额外复杂度。`clearAll` 是用户主动触发的低频操作，DELETE 后数据库极小，VACUUM 耗时可忽略。保持原方案。 |
1209→| `saveImage` 在主线程做图片处理 | 当前所有 Timer 回调都在主线程，移到后台需要处理 SQLite 线程安全问题。改动风险大于收益，暂不处理。 |
1210→| `mach_host_self()` 线程安全 | `hostPort` 在 init 时创建一次，后续只读使用，不存在并发问题。 |
1211→
1212→---
1213→
1214→### 修改文件清单
1215→
1216→| 文件 | 改动摘要 |
1217→|------|----------|
1218→| `ClipboardManager.swift` | `saveImage` 替换 lockFocus 为现代 API（FIX-A）；新增 `latestCache` 缓存（FIX-C）；insert/togglePin/deleteItem/clearAll 同步维护缓存 |
1219→| `ClipboardPanel.swift` | `keyDown` 新增 Escape 键处理（FIX-B） |
1220→
1221→---
1222→
1223→*审查时间：2026-05-05*
1224→*审查人：Claude (Opus 4.6)*
1225→
1226→---
1227→
1228→## 第五轮评审
1229→
1230→**时间**：2026-05-09
1231→**评审员**：Claude (glm-5)
1232→**评审范围**：全部 5 个源文件 + ScrollManager.swift + project-log 下所有设计文档
1233→**评审方法**：逐文件通读，以全新视角独立审查，关注 Timer 生命周期、代码重复、边缘条件
1234→
1235→---
1236→
1237→### 发现的问题
1238→
1239→#### BUG-D：ClipboardPanel 关闭时 searchTimer 未清理 [轻微]
1240→
1241→**位置**：`ClipboardPanel.swift:139-145` + `close()` / `keyDown`
1242→
1243→**描述**：
1244→
1245→用户在搜索框输入后，`searchChanged` 启动 0.2 秒延迟的 timer：
1246→```swift
1247→searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
1248→    self?.searchQuery = sender.stringValue
1249→    self?.reloadData()
1250→}
1251→```
1252→
1253→如果用户在 0.2 秒内按 Escape 或点击关闭面板，`keyDown` 直接调用 `close()`，但没有清理 `searchTimer`。Timer 在 0.2 秒后仍会触发，执行不必要的数据库查询和 `tableView.reloadData()`。
1254→
1255→由于 `clipboardPanel` 属性一直持有面板实例（直到应用退出），`self` 不是 nil，reload 操作会执行但面板已关闭，属于资源浪费。
1256→
1257→**影响**：轻微资源浪费，不影响用户体验和数据正确性。
1258→
1259→**修复建议**：在 `close()` 中调用 `searchTimer?.invalidate()`。
1260→
1261→---
1262→
1263→### 代码质量问题
1264→
1265→#### QUALITY-D：`activateAppForModal()` 存在冗余 `#available` 检查 [死代码]
1266→
1267→**位置**：`AppDelegate.swift:942-948`
1268→
1269→**描述**：
1270→
1271→```swift
1272→private func activateAppForModal() {
1273→    if #available(macOS 14.0, *) {
1274→        NSApp.activate()
1275→    } else {
1276→        NSApp.activate(ignoringOtherApps: true)
1277→    }
1278→}
1279→```
1280→
1281→历史判断：这里再次沿用了“只面向最新系统”的错误前提。紧随其后的第五轮复核已确认该判断不成立，`#available(macOS 14.0, *)` 分支对 macOS 13 兼容是必要的。
1282→
1283→**修复建议**：删除条件分支，直接调用 `NSApp.activate()`。
1284→
1285→---
1286→
1287→#### QUALITY-E：缩略图路径构建逻辑重复 [维护风险]
1288→
1289→**位置**：`ClipboardPanel.swift:339` vs `ClipboardManager.swift:348-354`
1290→
1291→**描述**：
1292→
1293→两处代码构建缩略图路径：
1294→
1295→`ClipboardPanel.swift:339`：
1296→```swift
1297→let thumbPath = url.deletingPathExtension().path + "_thumb.jpg"
1298→```
1299→
1300→`ClipboardManager.swift` 有专门的 `thumbnailPath(for:)` 方法：
1301→```swift
1302→private func thumbnailPath(for path: String) -> String? {
1303→    let url = URL(fileURLWithPath: path)
1304→    guard url.pathExtension.lowercased() == "jpg" else { return nil }
1305→    let stem = url.deletingPathExtension().lastPathComponent
1306→    let dir = url.deletingLastPathComponent().path
1307→    return (dir as NSString).appendingPathComponent("\(stem)_thumb.jpg")
1308→}
1309→```
1310→
1311→逻辑相同但分散维护。ClipboardPanel 的实现更简单（直接拼接），ClipboardManager 的实现更严谨（检查扩展名、使用 URL API）。未来修改一处可能遗漏另一处。
1312→
1313→**修复建议**：将 `ClipboardManager.thumbnailPath(for:)` 改为 `public` 或 `internal`，ClipboardPanel 直接调用，统一维护。
1314→
1315→---
1316→
1317→### 优化建议
1318→
1319→#### OPT-D：iconCache 无大小上限 [潜在内存增长]
1320→
1321→**位置**：`ClipboardPanel.swift:19`
1322→
1323→**描述**：
1324→
1325→```swift
1326→private var iconCache: [String: NSImage] = [:]
1327→```
1328→
1329→如果用户复制了来自大量不同应用的内容，iconCache 会持续增长。每个缓存项约 1KB（16×16 图像），100 个应用约 100KB，影响很小，但无上限设计不够严谨。
1330→
1331→**建议**：设置上限（如 50-100），超过后清理最旧的；或改用 `NSCache` 自动管理。
1332→
1333→---
1334→
1335→### 未确认问题
1336→
1337→以下问题经分析后确认不需要修复：
1338→
1339→| 项目 | 原因 |
1340→|------|------|
1341→| 零尺寸图片未检查 | `saveImage` 对零尺寸图片会返回 nil（`resized.tiffRepresentation` 为 nil），不会插入数据库，行为合理 |
1342→| eventTap 超时后当前事件未处理 | 设计权衡：重新启用 tap 比处理单次事件更重要，用户感知不到单次事件丢失 |
1343→| Language.systemDefault() 对葡萄牙语判断宽泛 | **设计决策**：只支持巴西葡萄牙语，用户选择葡萄牙语即显示该版本，无需在前端标注"巴西" |
1344→
1345→---
1346→
1347→### 评审汇总
1348→
1349→| 类别 | 数量 | 严重 | 中等 | 轻微 |
1350→|------|------|------|------|------|
1351→| Bug | 1 | 0 | 0 | 1 |
1352→| 代码质量 | 2 | - | - | 2 |
1353→| 优化建议 | 1 | - | - | 1 |
1354→
1355→**最高优先级处理项**：
1356→
1357→1. **BUG-D**（searchTimer 未清理）— 简单修复，避免不必要资源消耗
1358→2. **QUALITY-D**（冗余 #available）— 清理死代码
1359→3. **QUALITY-E**（缩略图路径重复）— 统一维护，降低风险
1360→
1361→---
1362→
1363→### 整体评价
1364→
1365→代码经过四轮评审后质量已相当高。本轮仅发现 1 个轻微 bug（Timer 未清理）和 2 个代码质量问题，都是边缘情况或代码整洁度问题，不影响核心功能。
1366→
1367→项目整体设计遵循当时 spec 和 principles 要求：零依赖、代码精简、功能明确。后续新增功能后不再以 `~1500 行` 作为硬指标，当前更看重少依赖、低常驻开销和清晰边界。
1368→
1369→---
1370→
1371→*评审时间：2026-05-09*
1372→*评审员：Claude (glm-5)*
1373→
1374→---
1375→
1376→## 第五轮评审复核与修复
1377→
1378→**时间**：2026-05-09
1379→**复核人**：Codex
1380→**范围**：第五轮评审新增问题、当前源码、滚轮反转新增实现
1381→**方法**：逐条独立判断，不直接沿用评审结论；确认存在则修复，影响很小但低成本的优化一并处理。
1382→
1383→---
1384→
1385→### 逐条判断
1386→
1387→#### BUG-D：ClipboardPanel 关闭时 searchTimer 未清理 [确认存在，已修复]
1388→
1389→判断：成立。`searchTimer` 使用 0.2 秒防抖，面板关闭后如果 timer 尚未触发，会继续执行 `reloadData()`。虽然不会造成数据错误，但会做一次无意义查询和表格刷新。
1390→
1391→修复：
1392→
1393→- 在 `ClipboardPanel.close()` 中统一 `invalidate` 并清空 `searchTimer`。
1394→- Escape、点击条目复制、失焦延迟关闭等路径最终都走 `close()`，因此不用在各调用点重复清理。
1395→
1396→#### QUALITY-D：`activateAppForModal()` 存在冗余 `#available` 检查 [不成立，未修改]
1397→
1398→判断：不成立。工程实际部署目标是 macOS 13.0，而 `NSApp.activate()` 只在 macOS 14.0+ 可用。直接删除 `#available` 分支会导致 Release 构建失败：
1399→
1400→```text
1401→error: 'activate()' is only available in macOS 14.0 or newer
1402→```
1403→
1404→结论：
1405→
1406→- 保留 `if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }`。
1407→- 该分支不是死代码，而是 macOS 13 兼容所必需。
1408→
1409→#### QUALITY-E：缩略图路径构建逻辑重复 [确认存在，已修复]
1410→
1411→判断：成立。`ClipboardPanel` 和 `ClipboardManager` 分别构造缩略图路径，虽然当前结果一致，但确实会增加未来维护风险。
1412→
1413→修复：
1414→
1415→- 将 `ClipboardManager.thumbnailPath(for:)` 从 `private` 改为内部方法。
1416→- `ClipboardPanel` 加载图片缩略图时直接调用 `ClipboardManager.shared.thumbnailPath(for:)`。
1417→
1418→#### OPT-D：iconCache 无大小上限 [轻微优化，已修复]
1419→
1420→判断：问题真实但影响很小。普通用户不会复制来自大量不同应用的内容，且图标尺寸很小。不过用 `NSCache` 替代字典成本低，符合“省资源”原则。
1421→
1422→修复：
1423→
1424→- `ClipboardPanel.iconCache` 从 `[String: NSImage]` 改为 `NSCache<NSString, NSImage>`。
1425→- 设置 `countLimit = 100`，由系统自动管理缓存淘汰。
1426→
1427→---
1428→
1429→### 修改文件清单
1430→
1431→| 文件 | 改动摘要 |
1432→|------|----------|
1433→| `ClipboardPanel.swift` | 关闭面板时清理 `searchTimer`；图标缓存改为 `NSCache`；缩略图路径调用 `ClipboardManager` |
1434→| `ClipboardManager.swift` | `thumbnailPath(for:)` 改为内部方法，供面板复用 |
1435→
1436→---
1437→
1438→*复核时间：2026-05-09*
1439→*复核人：Codex*

---

## 2026-05-11 性能与健壮性专项复核审查

**评审员**：SOLO
**评审范围**：`ClipboardManager.swift`、`ClipboardPanel.swift`、`ScrollManager.swift`
**评审方法**：针对前置沟通中提出的几项遗留建议，从主线程阻塞、SQLite 线程安全、UI边界处理、权限交互等维度进行彻底的源码二次验证，判断其是否为Bug并提供最优解。

### 一、发现的问题与判定

#### 1. ClipboardManager 主线程阻塞问题
*   **相关代码**：`startPolling()` 中设置的 `Timer` 运行在 `RunLoop.main`。当 `checkPasteboard()` 命中大图片时，`saveImage()` 的图像缩放、多轮 JPEG 压缩降采样（耗 CPU）以及随后的 SQLite `insert` 写入操作都在主线程同步执行。
*   **性质判定**：**严重性能优化点 / 体验 Bug**。由于该 App 包含菜单栏最高 12fps 的猫咪动画，当用户频繁复制大图时，主线程阻塞会导致动画卡顿、甚至整个应用在短暂时间内无响应（菊花）。
*   **最优解决办法**：将 `checkPasteboard()` 内的处理逻辑分发到自定义的串行后台队列（Serial `DispatchQueue`）。将 CPU 密集型的图片处理和 IO 密集型的数据库写入从主线程剥离，仅在需要通知 UI 刷新时再 dispatch 回主线程。

#### 2. SQLite 并发与线程安全
*   **相关代码**：目前所有的数据库操作都在主线程。虽然因为单线程不会触发多线程写冲突，但如果实施了上述的主线程剥离优化，读取（面板展示）和写入（后台检测）就会发生跨线程并发访问。
*   **性质判定**：**潜在的 Crash Bug**（目前被单线程掩盖）。
*   **最优解决办法**：鉴于目前已开启 WAL 模式（Write-Ahead Logging），读写已可以不互阻。为确保绝对的指针访问安全，建议：1) 开启 SQLite 的 `SQLITE_CONFIG_SERIALIZED` 模式；或 2) 让所有的读写操作都通过同一个自定义串行队列（例如 `dbQueue.sync` 和 `dbQueue.async`）来进行统一管理，这是最无缝且最安全的现代 Swift 实践。

#### 3. 剪贴板面板定位边界与逻辑隐患
*   **相关代码**：`ClipboardPanel.swift` 的 `resizeToFitContent()` 中，通过绝对坐标计算 `panelY = buttonFrame.minY - finalHeight - 4`。
*   **性质判定**：**边界逻辑隐患（Edge Case Issue）**。在一些极限多屏场景（主副屏上下拼接、主屏在下）或者含有特殊异形安全区的设备上，绝对坐标计算如果不和所有 `NSScreen` 的完整 `frame` 严谨求交，可能导致面板底部溢出甚至不可见。
*   **最优解决办法**：使用 `NSRect.intersection`，将最后算出的 `newFrame` 强制与目标屏幕的 `screen.visibleFrame` 求交集，保证 `panel` 绝不溢出屏幕物理边界；或者在架构上，彻底抛弃绝对坐标的手工计算，改用 `NSPopover` 挂载 `NSViewController` 的方案，`NSPopover` 具有系统级的防溢出和自适应屏幕边界重定位能力。

#### 4. ScrollManager 辅助功能权限交互体验
*   **相关代码**：在 `ScrollManager.start()` 中仅调用了 `AXIsProcessTrusted()`，如果不受信任则静默返回 `false`。然后在 `AppDelegate` 的菜单项里增加了一条静态提示文字让用户去点击。
*   **性质判定**：**非 Bug，但属于不良交互设计**。
*   **最优解决办法**：当用户主动在菜单栏点击勾选“Reverse Mouse Scroll”这一动作发生时，如果权限不足，应直接调用 `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)`。这样会直接唤起 macOS 系统的标准化权限请求弹窗，引导用户一键跳入系统设置，而不是仅仅在菜单栏显示一行干瘪的提示。

### 评审汇总

| 类别 | 严重度 | 描述 | 最优建议 |
|------|------|------|------|
| 性能 | 高 | 主线程轮询大图压缩导致UI/动画卡顿 | 引入后台串行队列处理 `checkPasteboard`，剥离图片压缩与IO |
| 架构 | 高 | SQLite 线程安全设计缺失 | 配合后台队列优化，将所有数据库读写统一通过串行队列保护 |
| UI逻辑 | 低 | `ClipboardPanel` 绝对坐标定位可能溢出 | 强制与 `visibleFrame` 求交集，或重构使用 `NSPopover` |
| 交互体验 | 中 | 辅助功能权限静默失败体验不佳 | 主动调用带 Prompt 参数的 AX API，唤起系统设置弹窗 |

---

## 2026-05-24 全项目评审与优化计划

**评审员**：Codex
**评审范围**：`project-log`、README、Xcode 工程配置、`AppDelegate.swift`、`ClipboardManager.swift`、`ClipboardPanel.swift`、`SystemMonitor.swift`、`ScrollManager.swift`
**评审方法**：先阅读项目记录，确认当前有效规范以 `spec.md` / `principles.md` / README 为准；再逐文件审查功能、稳定性、性能和用户交互风险，并用 Debug 构建验证工程当前可编译。

### 项目理解

DashCat 是一个纯 AppKit、低依赖、低常驻开销的 macOS 菜单栏工具。当前核心边界是将剪贴板历史、系统监控、防休眠、鼠标滚轮反转、极简电量和 Finder 新建文件集中在一个菜单栏应用内，数据本地保存，不引入重量级依赖或长期后台扫描。

### 已确认问题

1. **剪贴板维护任务存在主线程阻塞风险**
   - `ClipboardManager` 初始化会同步执行过期清理；清空历史会同步 `DELETE`、`VACUUM` 和删除图片目录；图片存储上限回收会扫描目录、查询数据库并删除文件。
   - 这些路径可能在启动、菜单操作或剪贴板写入后阻塞主线程，影响菜单栏动画和面板响应。
   - 优化方向：用专用串行维护队列执行清理、清空和图片回收；UI 刷新通知回到主线程派发。

2. **剪贴板面板图片缩略图反复从磁盘读取**
   - `ClipboardPanel.tableView(_:viewFor:row:)` 每次渲染图片条目时都从缩略图路径创建 `NSImage`。
   - 图片历史较多或滚动列表时会产生重复磁盘读取和解码。
   - 优化方向：增加缩略图 `NSCache`，与现有应用图标缓存保持同类轻量策略。

3. **鼠标滚轮反转授权后不会立即自动重试**
   - 未授权时开启 `Reverse Mouse Wheel` 会弹出系统授权提示，但代码没有在授权成功后自动再次启动 event tap。
   - 用户通常需要重新打开菜单或再次切换开关，才会真正生效。
   - 优化方向：请求授权后短时间轮询信任状态；一旦授权成功立即 `start()` 并刷新菜单提示。

### 待确认问题

1. **系统设置 deep link 的跨版本稳定性**
   - `x-apple.systempreferences:com.apple.Battery-Settings.extension` 和辅助功能设置链接需要在目标 macOS 13+ 环境实机确认。
   - 当前不作为确定 bug 处理。

### 本轮拟修改文件

| 文件 | 改动摘要 |
|------|----------|
| `ClipboardManager.swift` | 后台化剪贴板维护任务；确保通知回主线程派发；降低清理和回收对 UI 的影响 |
| `ClipboardPanel.swift` | 增加图片缩略图缓存，避免列表滚动反复读盘 |
| `AppDelegate.swift` | 授权提示后自动重试启动鼠标滚轮 event tap |
| `project-log/review.md` | 记录本轮评审结论和实施口径 |

---

## 2026-05-24 二次核实与修复结果

### 已确认并修复

1. `clearAll()` 的异步化会导致调用方立即刷新面板时看到旧列表。已改为 `clearAll(completion:)`，在维护队列执行完成后再回到主线程刷新 UI。
2. 后台图片保存仍使用 AppKit 绘图路径，存在线程边界风险。已改为基于 `CGImageSource` / `CGContext` / `CGImageDestination` 的 CoreGraphics / ImageIO 流程，避免后台线程触碰 `NSImage` 和 `NSGraphicsContext`。

### 验证

1. `xcodebuild -project DashCat.xcodeproj -scheme DashCat -configuration Debug CODE_SIGNING_ALLOWED=NO build` 通过。

---

## 2026-05-24 发布前复核与版本推进

**复核结论**：再次检查当前修改后，未发现新增的已确认 bug。当前保留的几项边界问题已明确记录，但按用户决定暂不修复。

### 已记录但暂不修复

1. 清空历史后，当前剪贴板内容在轮询窗口内可能被重新写回历史。
2. 少数非常规图片格式在 `ImageIO` 转换时可能失败，导致不入库或缩略图缺失。
3. 过滤词编辑弹窗在极端大字号或特殊本地化长度下可能偏紧。

### 版本推进

- 工程默认版本从 `2.3.6` 推进到 `2.3.7`。
- 后续通过 `v2.3.7` tag 触发 GitHub Actions 构建与打包。
