# 请假模拟器 · iOS 版（LeaveSim）

纯本地 SwiftUI 工程：没有网络、没有后端、没有第三方依赖，用来复刻 Android 版「请假」小程序的
**六个页面**（列表 / 详情 / 承诺书 / 申请表 / 记录 / 筛选），所有页面上的文字都能点开改、
改完立刻写进 `UserDefaults`，杀掉 App 重启仍在。

Android 版在 `D:\dsh\work\leave-app`（Kotlin/Java + XML 布局）。本工程是它的 iOS 对等版本：
字段、文案、配色、行高、标签列宽、下划线尺寸都照搬 Android 版。

> ⚠️ 本工程是在 Windows 上写的，**没有用 Xcode 编译过、也没有在模拟器 / 真机上跑过**。
> 代码只用了公开 API、iOS 16.0 部署目标、Swift 5.9 语法，但首次打开时仍可能需要修掉
> 一两个编译期小问题（见文末「最可能编译失败的点」）。

---

## 一、目录结构

```
leave-ios/
├── LeaveSim.xcodeproj/
│   ├── project.pbxproj                     # 手写工程文件，objectVersion 56，单 target
│   ├── project.xcworkspace/
│   │   └── contents.xcworkspacedata
│   └── xcshareddata/xcschemes/
│       └── LeaveSim.xcscheme               # 共享 scheme，双击工程即可 Run
├── LeaveSim/
│   ├── LeaveSimApp.swift                   # @main 入口 + RootView（导航栈 + 全局编辑浮层）
│   ├── Models.swift                        # TextStore（全部可改字段 + UserDefaults 持久化）、图片、相册写入
│   ├── Theme.swift                         # 配色 / 尺寸 / 字号、EditableText、Card、NavHeader 等原子组件
│   ├── EditSheet.swift                     # 编辑浮层 + KeyboardMonitor（键盘避让）
│   ├── Shot.swift                          # ImageRenderer 整页截图 + 存相册 / 分享
│   ├── HomeView.swift                      # 请假列表（首页）
│   ├── DetailView.swift                    # 请假详情 / 续假详情
│   ├── FormView.swift                      # 请假申请表单
│   ├── RecordsView.swift                   # 请假记录 + 筛选底部弹层
│   ├── PromiseView.swift                   # 请假安全承诺书
│   ├── Wheels.swift                        # 日期 / 时间三列滚轮
│   └── Assets.xcassets/                    # AppIcon（1024 图标）+ AccentColor + 8 个矢量图 imageset
│       ├── AppIcon.appiconset/             # 1024（蓝色「今日校园」底图）
│       ├── TabLeaveActive.imageset/        # 底部 tab·请假·选中（蓝）
│       ├── TabLeaveInactive.imageset/      # 底部 tab·请假·未选（灰）
│       ├── TabRecordActive.imageset/       # 底部 tab·记录·选中（蓝）
│       ├── TabRecordInactive.imageset/     # 底部 tab·记录·未选（灰）
│       ├── IconFilterActive.imageset/      # 筛选·已生效（蓝漏斗）
│       ├── IconFilterInactive.imageset/    # 筛选·未生效（灰漏斗）
│       ├── IconMore.imageset/              # 详情页「更多」（三道横杠）
│       └── IconJoin.imageset/              # 发起卡蓝圈人形（115×115 原图，唯一彩色位图）
├── tools/make_icon.py                      # 生成 1024 AppIcon 的脚本（已跑过，图标已生成）
├── tools/make_assets.py                    # 把 Android 的 SVG / PNG 烤成上面那 8 个 imageset
├── tools/check_project.py                  # 静态自检：括号配对 / key 覆盖 / 图标 / pbxproj
└── README.md
```

## 二、用 Xcode 打开

1. 把整个 `leave-ios` 目录拷到 macOS 上（U 盘 / 网盘 / git 都行）。
2. 双击 `LeaveSim.xcodeproj`（或 `File → Open…` 选它）。
3. 左上角 scheme 选 **LeaveSim**，目标设备选一台模拟器（iPhone 15 / iOS 17 之类），按 `⌘R`。

模拟器不需要签名，直接能跑。

## 二·五、没有 Mac 也能装到 iPhone（Windows 全流程）

iOS 的编译工具链（Xcode / iOS SDK）只有 macOS 版，Windows 上无法直接编出 `.ipa`。
但整条链路可以拆成「云端编译 + Windows 签名安装」，全程不碰 Mac：

```
GitHub Actions（跑 macOS 虚拟机编译） → LeaveSim-unsigned.ipa → Windows 上 Sideloadly 用免费 Apple ID 签名 → 装进 iPhone
```

### 1. 云端编译（约 5 分钟，免费）

1. 注册 GitHub，新建一个仓库（Private 也可以，私有仓库每月有 2000 分钟免费额度，
   macOS runner 按 10 倍计，一次编译约消耗 40~60 分钟额度，够跑 30 多次）。
2. 把 `leave-ios` 整个目录传上去（网页版仓库页 → `Add file → Upload files` 直接拖文件夹即可）。
   注意 `.github/` 目录要一起传（它是隐藏目录，网页拖拽有时会漏，漏了就用 GitHub Desktop 或 git 命令行）。
3. 仓库页 → `Actions` → 左边选 **build-ios** → 右边 `Run workflow` → 等 4~6 分钟。
4. 点进这次运行，页面最下方 **Artifacts** 里下载 `LeaveSim-unsigned-ipa`，解压得到 `LeaveSim-unsigned.ipa`。

编译脚本 `.github/workflows/ios-build.yml` 已经写好：先试现有的 `LeaveSim.xcodeproj`，
打不开就自动 `brew install xcodegen` 用 `project.yml` 重新生成工程再编 —— 手写工程文件出问题也不会卡死。
产物是**未签名**的 `.ipa`（`Payload/LeaveSim.app`），签名交给下一步。

### 2. 在 Windows 上签名并装进 iPhone

1. 装 **iTunes**（微软商店版即可，提供 Apple 驱动）+ 装 **Sideloadly**（sideloadly.io，免费）。
2. iPhone 用数据线连电脑，手机上点「信任此电脑」。
3. 打开 Sideloadly：`IPA` 选刚下载的 `LeaveSim-unsigned.ipa`，
   `Apple ID` 填你的 Apple ID（免费账号即可，密码只用于本机向 Apple 换取签名证书，不经过第三方服务器），
   `Bundle ID` 随便改一个唯一的，例如 `com.你的名字.LeaveSim`。
4. 点 `Start`，输入 Apple ID 密码（如开了双重认证，用「App 专用密码」）。
5. 手机上 `设置 → 通用 → VPN 与设备管理 → 开发者 App` → 信任你的 Apple ID。
6. iPhone（iOS 16+）需要 `设置 → 隐私与安全性 → 开发者模式` 打开，然后重启手机。

### 3. 7 天过期怎么办

免费 Apple ID 签出来的 App **7 天失效**（打开会闪退报「无法验证 App」）。三条路：

- **手动重签**：7 天后再用 Sideloadly 点一次 Start（一分钟）。
- **自动续签**：电脑装 **AltStore + AltServer**（altstore.io），AltServer 常驻托盘，
  手机和电脑连同一个 WiFi 时会自动后台重签，不用管。
- **付费开发者账号**（$99/年）可以签一年，且不用每 7 天折腾。

> 免费账号限制：最多同时 3 个自签 App、每个 7 天、必须定期联网续签。这是 Apple 的规则，绕不开。

### 4. 其它两条备选路

- **借一台 Mac 十分钟**：Xcode 打开 → 选真机 → `⌘R`，同样用免费 Apple ID，效果和上面一样。
- **iPad + Swift Playgrounds 4**：iPad 上装免费的 Swift Playgrounds，新建 App 项目，
  把 `LeaveSim/*.swift` 粘进去，可以直接在 iPad 上运行（不用签名，但只能在 iPad 上跑）。

---

## 三、真机运行（需要 Apple ID 免费签名，本机有 Mac 时看这节）

1. Xcode → `Settings → Accounts` → 用 Apple ID 登录（免费账号即可）。
2. 工程导航栏选中 `LeaveSim` target → `Signing & Capabilities`：
   - 勾上 **Automatically manage signing**；
   - **Team** 选你的 `xxx (Personal Team)`；
   - **Bundle Identifier** 改成唯一值，例如 `com.你的名字.LeaveSim`
     （`project.pbxproj` 里默认是 `com.example.LeaveSim`，免费的 Personal Team 不允许这个 ID 被占用）。
3. iPhone 用数据线连 Mac，Xcode 顶部设备选这台 iPhone，`⌘R`。
4. 首次运行会报「不受信任的开发者」：手机 `设置 → 通用 → VPN 与设备管理 → 开发者 App`
   → 信任你的 Apple ID。
5. iPhone 需要 `设置 → 隐私与安全性 → 开发者模式` 打开（iOS 16+），然后重启手机。
6. 免费签名有效期 7 天，到期重新 `⌘R` 一次即可。

首次「保存截图到相册」会弹相册写入授权，允许后以后不再问。

## 四、页面与进入方式

| 页面 | 进入方式 | 说明 |
| --- | --- | --- |
| 请假列表（首页） | App 启动 | 导航标题「请假」，底部 tab「我要请假」为选中态 |
| 请假详情 | 点「进行中」白卡，或点底部「我要请假」再提交后…（直接点白卡最快） | 导航标题「请假详情」，顶部「请假 / 续假」两个 tab |
| 请假申请表单 | 底部 tab「我要请假」，或点「发起」区块里任意类型卡 | 导航标题「请假」，右上相机可截图 |
| 请假记录 | 底部 tab「请假记录」 | 导航标题「请假」，右上漏斗开筛选、右上相机截图 |
| 筛选弹层 | 记录页右上漏斗图标 | 底部弹出，「重置 / 确定」关掉 |
| 请假安全承诺书 | 表单页底部「提交」 | 勾选后「同意并继续」回首页 |
| 日期 / 时间滚轮 | 表单页「开始时间」「结束时间」 | 先选年月日点「下一步」，再选时分点「确定」 |

返回：每页左上都有返回箭头，逐级回退（承诺书「不同意」也是回退）。

## 五、功能清单

- **所有文字可点改**：点任意文字 → 底部编辑浮层（遮罩 + 白色圆角面板 +「修改文字」+ 多行输入框 + 取消 / 确定）。
  少数位置是「点一下执行动作、长按才改字」：详情页顶部「请假 / 续假」tab 文案、首页底部两个 tab 文案、
  「更多」按钮、表单「重新定位」「编辑」、筛选里的状态 chip、提交按钮等。
- **持久化**：每个字段一个 `UserDefaults` 键（键名沿用 Android 版的 tag，例如 `q.student`、`d.left`、`a.note`、
  `f.reason`、`rec1.title`、`flt.s3`），`TextStore` 启动时逐键读回；头像 / 证明材料存 JPEG Data。
- **整页截图**：`ImageRenderer`（iOS 16+）渲染「静态版」页面（导航条 + 内容 + 底栏，宽 393pt、3 倍图），
  每页右上角相机图标，或详情页底部「更多 → 保存截图到相册 / 分享截图」。
  存相册用 `PHPhotoLibrary` 写入（Info.plist 由 Xcode 自动生成，已带
  `NSPhotoLibraryAddUsageDescription` / `NSPhotoLibraryUsageDescription`）。
- **恢复默认文字**：详情页「更多 → 恢复默认文字」，清掉所有键回到初始文案并清掉图片。
- **离校 / 不离校切换**：详情页「更多 → 切换离校」或点「是否离校」的值；
  值以 `否 / 不 / no / false / 0` 开头时，后面四行（目的地 / 详细地址 / 紧急联系人 / 联系电话）自动隐藏。
- **换头像**：点详情页顶部头像 → 系统相册选择器（`PhotosPicker`），选完缩到 320px 存 JPEG。
  长按「证明材料」那一行的值也能放一张缩略图。
- **深色模式无关**：根视图强制 `.preferredColorScheme(.light)`，截图不受系统深色影响。
- **没有任何销假模块**（按需求删掉了 Android 版的「销假内容」卡片）。

## 六、与 Android 版的差异

1. **多出来的页面**：Android 版只有首页 + 详情；iOS 版另外做了「请假申请表单」「请假记录 + 筛选弹层」
   「请假安全承诺书」「日期 / 时间滚轮」，这些是 iOS 端新增的完整流程（表单 → 承诺书 → 回首页）。
2. **删掉的模块**：Android 版详情页有「销假内容」卡片（销假方式 / 提交人 / 提交时间 / 销假材料 / 销假定位），
   iOS 版按需求整块删除，字段也不再出现在可编辑列表里。
3. **编辑方式**：Android 用 `Dialog(SheetDialog)` + 自建 `liftAboveKeyboard` 监听；iOS 不用 sheet，
   直接把浮层画在根 `ZStack` 顶层，键盘高度由 `KeyboardMonitor` 测量后手动加 `padding`（原因见下节）。
4. **截图**：Android 手动 measure/draw 四段视图拼一张位图；iOS 用 `ImageRenderer` 渲染一份
   `interactive = false` 的静态视图（`CaptureHome` / `CaptureDetail` / `CaptureForm` / `CaptureRecords` / `CapturePromise`），
   所以截图里的内容和屏幕上完全同源，不会分叉。
5. **分享**：Android 是 `ACTION_SEND` + `FileProvider`；iOS 是 `UIActivityViewController`（包在 `ShareSheet` 里）。
6. **图片存储**：Android 存 Base64 进 `SharedPreferences`；iOS 存 JPEG `Data` 进 `UserDefaults`。
7. **底部 tab / 导航条**：两边都是自绘（不用系统导航栏），这样标题、tab 文案也能改字并被截进图里。

## 七、关键实现：浮层为什么不会被键盘挡住

- 根视图 `RootView` 里 `NavigationStack` 和浮层是同一个 `ZStack` 的两个兄弟节点；
- 整个 `ZStack` 加 `.ignoresSafeArea(.keyboard, edges: .bottom)`，**键盘不参与任何布局**，
  页面不会被顶起来，浮层也不会被系统「推」到别处；
- `KeyboardMonitor` 监听 `keyboardWillChangeFrameNotification`，用
  `max(0, 屏幕高度 - keyboardFrameEnd.minY)` 算出键盘实际占掉的高度（`keyboardWillHide` 归零）；
- 浮层位置 = `.padding(.bottom, 键盘高度 + 12)`，没键盘时是 26pt 贴底；
  键盘高度变化带 `.animation(.easeOut, value: keyboard.height)` 平滑跟随；
- 输入框用 `TextField(axis: .vertical)` + `lineLimit(2...6)`，浮层随内容长高，
  高度由内容决定、位置由键盘高度决定，因此不会出现输入框被压在键盘下面的情况；
- 之所以不用 `.sheet`：sheet 自己在 iOS 16 上会抢键盘焦点、会和相册 / 分享 sheet 打架，
  且在「sheet 里再弹键盘」这条路径上系统会重排 sheet 位置，很难保证始终在键盘上方。

## 八、关键实现：截图怎么做

```swift
// Shot.swift
@MainActor
enum Shot {
    static func render<V: View>(_ content: V, width: CGFloat = Metrics.captureWidth) -> UIImage? {
        let renderer = ImageRenderer(content: content.frame(width: width))
        renderer.scale = 3            // 393 × 3 = 1179px 宽
        renderer.isOpaque = true      // 不透明，PNG 体积小、没有透明边
        return renderer.uiImage
    }
}
```

每页准备一个 `Capture*` 视图（`CaptureHome` / `CaptureDetail` / `CaptureForm` / `CaptureRecords` / `CapturePromise`），
它们由与真实页面**同一批子视图**组成，只是 `interactive: false`：

- `editTap(_:_:enabled:)` 在 `enabled == false` 时不响应点击；
- `Menu`、`PhotosPicker`、`Button` 换成纯视觉 `Text` + 描边；
- `editorCenter` 环境对象在渲染时退化成默认空实现，所以点不到也不会崩。

流程：点相机 → `ShotExporter.asking = true` → `confirmationDialog` 选「保存到相册 / 分享截图」→
渲染 → 存相册走 `PHPhotoLibrary.performChanges`（`AlbumWriter.save`，`async throws`，失败弹 toast）；
分享走 `ShareSheet`（`UIActivityViewController`）。

## 九、自定义 / 改文案

- 想加字段：在 `Models.swift` 的 `TextStore.fields` 里加一条 `("my.key", "默认值")`，
  然后在页面里用 `EditableText(text: store["my.key"])` + `.editTap("my.key", store["my.key"])`。
- 想改默认文案：只改 `fields` 里对应那条的值即可（首次启动 / 恢复默认时生效）。
- 想改配色 / 尺寸：`Theme.swift` 的 `Palette`、`Metrics`、`Typo`。

## 十、已知限制

- **没有编译验证**：这份代码是在 Windows 上敲的，本机没有 Xcode / macOS 工具链，
  所以「能编译」这件事没有实证。语义上是标准 SwiftUI + iOS 16 API，但首次 `⌘R` 需要留意编译报错。
- **截图为「当前页」**：截的是点相机那一刻这一页的静态版；切到「续假」tab 再截会截续假内容。
- **证明材料缩略图默认不显示**：和截图一致（详情页那一行还是「-」）。要显示缩略图就长按那一行的值放图，
  放图后表单页的虚线框和详情页对应位置会带图；这是为了不破坏「8 行」的版式。
- **长文本会撑高行**：字段允许换行（编辑框是多行），特别长的原因 / 地址会把卡片撑高，
  截图里也是撑高后的样子（和真实 App 行为一致，不做省略号截断）。
- **相册权限**：拒绝后「保存到相册」只会弹提示，不写盘；分享不受影响。
- **没有 iCloud / 多设备同步**：`UserDefaults` 是本机沙盒内的，删 App 即清空。

## 十一、最可能编译失败的点（首次打开先看这几处）

1. **`ImageRenderer` / `PhotosPicker` 的可用性**：两者都是 iOS 16+，工程已设
   `IPHONEOS_DEPLOYMENT_TARGET = 16.0`，如果 Xcode 里被改成更低版本会直接报不可用。
2. **Swift 并发注解**：`Shot.render` 与 `ShotExporter` 的 `@MainActor` 标注，
   在 `-strict-concurrency=complete` 下可能多出几条警告/错误；把
   `SWIFT_STRICT_CONCURRENCY` 设成 `minimal`（默认）即可。
3. **`pbxproj` 是手写的**：如果 Xcode 提示工程文件损坏，最稳的做法是新建一个
   `App` 模板工程（名字 LeaveSim），把 `LeaveSim/` 下 11 个 `.swift` 和 `Assets.xcassets` 拖进去，
   在 target 里补 `NSPhotoLibraryAddUsageDescription`、`NSPhotoLibraryUsageDescription` 两个 Info 键即可，
   源码本身不用改。
4. **`INFOPLIST_KEY_*` 生成**：本工程用 `GENERATE_INFOPLIST_FILE = YES`（不落独立 `Info.plist`）。
   若你的 Xcode 版本对 `INFOPLIST_KEY_UIStatusBarStyle` 之类的键不认，删掉对应行即可，不影响功能。
5. **`onChange(of:)` 单参数闭包**：iOS 17 SDK 会提示 deprecated（只是警告），不影响 iOS 16 运行。
6. **`$array[0]` 绑定下标**（`Wheels.swift`）：依赖 SwiftUI `Binding` 对 `MutableCollection` 的下标扩展，
   iOS 16 起可用；若报错，改成三个独立的 `@State var yearIndex/monthIndex/dayIndex` 再传 `Binding`。
7. **中文 `INFOPLIST_KEY_CFBundleDisplayName = "请假模拟器"`**：`pbxproj` 是 UTF-8 的，
   如果 Xcode 编辑后出现乱码，改回英文或用 `InfoPlist.strings` 本地化即可。

---

## 十二、隐私说明

工程里所有姓名、手机号、地址、学校、审批人全部是虚构占位数据：
王小明 / 13800001234 / 13900005678 / 示例省示例市示例区示例路88号 / 示例小区3号楼 /
辅导员 李老师 / 示例大学。不含任何真实个人信息。

---

## 十三、与 Android 版对齐（第 3 轮）

前三轮：**第 1 轮**单页截图版（只有一张请假详情）→ **第 2 轮**六页雏形（页面齐了但跳转顺序、
联动、图标都不对）→ **第 3 轮（本轮）**按 Android 版逐条对齐：六页重排、全文字可编辑、
详情 ↔ 列表双向联动、时长自动重算、状态自动配色、图标全部换成 Android 的原图。

> ⚠️ **本机无 macOS 未编译验证**：改完只用 `tools/check_project.py` 做了静态自检
> （括号配对 / 文案 key 覆盖 / 图标资源 / pbxproj 结构），没有跑过 `xcodebuild`。
> 首次在 Xcode 里 `⌘R` 仍可能遇到一两条编译期报错，见第十一节的排查清单。

### 1. 六个页面分别在哪

| # | 页面 | 文件 | 入口 / 关键类型 |
|---|---|---|---|
| ① | 请假列表 | `LeaveSim/HomeView.swift` | `HomeView`、`HomeBody`、`HomeTabBar`、`CaptureHome` |
| ② | 请假详情 / 续假 | `LeaveSim/DetailView.swift` | `DetailView`、`DetailTabStrip`、`DetailContent`、`DetailBottomBar`、`RuleStrip` |
| ③ | 请假安全承诺书 | `LeaveSim/PromiseView.swift` | `PromiseView`、`PromiseBody`、`PromiseBottomBar` |
| ④ | 请假申请表 | `LeaveSim/FormView.swift` | `FormView`、`FormBody`、`FormRow`、`FormSubmitBar` |
| ⑤ | 请假记录 | `LeaveSim/RecordsView.swift` | `RecordsView`、`RecordsBody`、`CaptureRecords` |
| ⑥ | 筛选底部弹层 | `LeaveSim/RecordsView.swift` | `FilterPanel`、`FilterSelection` |

六个页面共用 `Theme.swift` 里的原子组件（`Card` / `EditableText` / `InfoRow` / `AvatarView` /
`RuleStrip` / `NavHeader` / `ArtIcon` / `ArtImage`）与 `Models.swift` 里的 `TextStore`。

### 2. 流程顺序（承诺书在表单前面）

```
列表页「发起」三卡（其它 / 事假 / 病假）
   → path.append(.promise)           HomeView.start(_:)
   → 承诺书勾选「同意并继续」
   → path = [.form]                  PromiseView（把栈换成 [.form]，返回键直接回列表）
   → 申请表填完点「提交」
   → store.commitForm() + path.removeAll()
   → 回到列表，进行中卡片就是刚填的内容
```

承诺书没勾选时「同意并继续」是灰底（`Palette.disabled`）且点不动——
`PromiseBottomBar` 里 `background(agreed ? Palette.blue : Palette.disabled)`，
`onTapGesture` 首行 `guard agreed else { return }`，不是靠 `.opacity` 假禁用。

### 3. 全文字可编辑（点一下弹「修改文字」）

- 组件：`LeaveSim/EditSheet.swift` 的 `EditTap` + `EditorCenter` + `EditPanel`；
  任何文字外面套 `.editTap("q.reason", store["q.reason"])` 就变成可点的。
- 浮层：点字 → 底部弹「修改文字」+ 多行 `TextField` + 取消 / 确定 → 确定即调
  `TextStore.set(key, value)` 写进 `UserDefaults`。
- **点字优先**：`EditTap` 用的是 `.highPriorityGesture`，所以在「整卡可点进详情」的
  进行中卡片上，点卡片空白处进详情、点具体那行字是改字，不会互相抢。
- 例外（诚实说明）：筛选弹层里的状态 chip、抄送人 chip、以及「撤销请假」「提交」这类
  按钮，**点 = 触发动作、长按 0.45 秒 = 改字**——chip 的文字几乎占满整个面，
  点字改字会让它没法被选中；`InfoRow` / `FormRow` 给了 `valueAction` 的行同理
  （如「是否离校」点一下是切换 是/否，长按才是改字）。

### 4. 自动保存与 key 对齐

`Models.swift` 的 `TextStore` 是唯一数据源：

- `static let fields` 里 **168 条** `(key, 默认值)`，key 与 Android 版一一对应：
  `q.start/q.end/q.dur/q.course/q.reason/q.student/q.proof/q.place`、
  `d.left/d.dest/d.addr/d.emerg/d.tel`、`a.who/a.res/a.time/a.note`、
  `hd.name/hd.status`、`hm.name/hm.status/hm.v1/hm.v2/hm.v3/hm.who/hm.time`。
- `set(_:_:)` 每次都同时写内存字典与 `UserDefaults`；`init()` 启动时先从
  `UserDefaults` 覆盖默认值（所以杀进程重启还是改过的值），并把缺失的 key 补写回去。
- 「恢复默认文字」= `resetAll()`（只删本工程的 key，不动别的 App）；
  筛选弹层的「重置」= `resetFilterFields()`，只重置 `flt.*`。

### 5. 联动（详情 ↔ 列表 ↔ 表单共用一份 key）

- 详情页改 `q.*` → 列表「进行中」卡片读的是同一批 key（`InfoRow(labelKey:valueKey:)`
  两边都指向 `q.start` / `q.end` / `q.reason` / `q.dur` / `q.student` / `q.submit`），
  所以列表自动跟着变；反过来在列表卡片上改字写的也是这同一批 key，
  不存在「列表改了、下次同步被详情覆盖」的问题——压根没有第二份数据。
- 改起止时间自动重算时长：`TextStore.set` 里 `q.start` / `q.end` /
  `f.start` / `f.end` 会触发 `refreshDuration(prefix:)`，用 `TimeFmt.minutes(from:to:)`
  算分钟差再 `TimeFmt.durationText(_:)` 拼成「X天X时X分」（不足一天时退化成「X时X分」），
  直接覆盖 `q.dur` / `f.dur`。
- 状态自动配色：`Theme.swift` 的 `StatusTone.color(_:)`，
  已通过 / 已完成 / 即将休假 → 绿 `#40C59C`；审批中 / 待审批 → 蓝 `#2561EF`；
  已驳回 / 已撤销 / 逾期 → 灰 `#999999`。凡是显示状态的地方（列表卡、详情头、
  审批流程、记录卡）都过这个函数，改状态文字颜色立刻跟着变。
- 提交后的联动：`commitForm()` 把 `f.*` 写回 `q.*` / `d.*`，把
  `hd.status`、`a.res` 置「审批中」，`q.submit` 写当前时间戳，`hd.name` 改成
  「（提交人）的请假申请」，于是回列表就能看到一张新的进行中卡片。

### 6. 视觉对齐的数值落点（都在 `Theme.swift`）

| 项 | 值 | 落点 |
|---|---|---|
| 页面底色 | `#F3F7FF` | `Palette.pageBg` |
| 卡片 / 主色 / 标签灰 / 错误红 / 输入框底 | `#FFFFFF` / `#2561EF` / `#999999` / `#EE0A24` / `#F7F8FA` | `Palette.white` / `blue` / `textLabel` / `error` / `fieldBg` |
| 状态绿 | `#40C59C` | `Palette.green` |
| 导航高 / 标题 / 返回图标 | 48pt / 19pt 纯黑居中 / 20pt 细 chevron（1.9 描边） | `Metrics.navHeight`、`Typo.navTitle`、`NavHeader` |
| 详情行高 / 标签列 | 35pt / 103pt | `Metrics.rowHeight`、`Metrics.labelWidth`、`InfoRow` |
| 卡片左右 / 卡片间隙 / 圆角 | 22pt / 13pt / 12pt | `Metrics.cardMargin`、`cardSpacing`、`cardRadius` |
| 小节标题 / 正文 | 17pt bold / 13pt | `Typo.sectionTitle`、`Typo.value` |
| 表单行距 / 标签列 | 46pt / 108pt | `Metrics.formRowPitch`、`formLabelWidth`、`FormRow` |
| 必填星号 / 缺项提示 | 红 `#EE0A24`，提示在值下方 11pt 红字 | `FormRow(required:)`、`store.requiredHint(key)` |

### 7. 图标怎么来的

`tools/make_assets.py` 一次性把 Android 版的图标烤进 `Assets.xcassets`：

1. 7 个 SVG（`cpdaily/svg/` 下的 tab ×4、筛选 ×2、更多 ×1）用 **Edge 无头截图**转 PNG
   （本机没有 ImageMagick / cairosvg / resvg；`msedge --headless=new --screenshot` +
   透明背景 + 4× 分辨率），再按 alpha 外接框裁边、留 1px 边距。
2. `leave-app/res/drawable-nodpi/ic_join.png` 原样拷进 `IconJoin.imageset`（唯一彩色位图）。
3. `cpdaily/asset_icon640.png`（192×192）用 LANCZOS 放大到 1024 写进 `AppIcon.appiconset`。

生成的 imageset：`TabLeaveActive/TabLeaveInactive/TabRecordActive/TabRecordInactive/
IconFilterActive/IconFilterInactive/IconMore/IconJoin`，每个都是 single-scale +
`"template-rendering-intent": "template"`（`IconJoin` 除外，它是彩色位图）。
颜色一律由代码给（`ArtIcon(name:tint:)` 走 `.renderingMode(.template)`），
所以选中 / 未选只换 tint，不用维护两套颜色。

### 8. 本轮改动文件

`LeaveSim/Theme.swift`、`LeaveSim/Models.swift`、`LeaveSim/HomeView.swift`、
`LeaveSim/DetailView.swift`、`LeaveSim/FormView.swift`、`LeaveSim/PromiseView.swift`、
`LeaveSim/RecordsView.swift`（七个文件整体重写）、`LeaveSim/EditSheet.swift`（EditTap 改高优先级手势）、
`LeaveSim/Assets.xcassets`（新增 8 个 imageset + 替换 AppIcon 1024）、
`tools/make_assets.py`、`tools/check_project.py`、`README.md`。
`LeaveSimApp.swift`、`Wheels.swift`、`Shot.swift`、`project.pbxproj` 没有改动——
新图标都是 asset catalog 内部文件，pbxproj 里 `Assets.xcassets` 本来就整体挂在 Resources，
不需要新增 `PBXFileReference`。

### 9. 本轮仍然没做到的（诚实清单）

- **没有编译验证**：本机没有 macOS / Xcode，`xcodebuild` 一次都没跑过，Swift 代码**一行都没被编译器看过**。
  只做了静态检查：11 个文件的括号配对、168 条文案 key 的引用覆盖（`store["key"]` / `editTap("key")` /
  `labelKey` / `valueKey` 字面量都在 `fields` 里登记；另有 46 个 key 是通过变量或字符串拼接引用的，
  如 `f.cc.\(index)`、`flt.d1.s`、`rec\(i).name`，静态扫描看不到，个别可能确实没用到）、
  8 个 imageset 与 Contents.json、pbxproj 的括号 / 分号配对与文件存在性。语义上都是 iOS 16 API，
  但首次编译仍可能要修（见第十一节的清单）。
- **图标是位图不是矢量**：SVG 转成了 4× PNG，没有用 `"preserves-vector-representation": true`
  ——因为「SVG 进 asset catalog」这条路在没有 Xcode 的情况下无法验证，
  万一 Xcode 版本不认会直接丢图。位图在 1x/2x/3x 下都够清晰（4 倍分辨率），
  但放大到很大尺寸会糊。
- **px 级近似**：详情页行高 35 / 标签列 103、表单行距 46 / 标签列 108 都是按 Android 的
  dp 直接当 pt 用，文字基线、行间距这类没有逐像素比对过；承诺书四段的行距是 6pt。
- **滚动位置 / 弹层动画**：只做了 `.move(edge: .bottom)` + 0.22s 的近似，没对齐具体的
  缓动曲线与遮罩透明度曲线（遮罩用的是 0.35 黑）。
- **chips / 按钮改为长按改字**（见第 3 节的例外说明），没有真正做到「所有文字都是点一下」。
- **筛选只是视觉筛选**：`FilterSelection` 只改统计条上的计数文案，`rec1..3` 三张卡片的
  内容不会被真的过滤掉（本来就是三条静态占位数据）。
- **「撤销请假」只改 `hd.status` / `a.res`**（列表进行中卡片与详情页同步变灰），
  请假记录页那三张 `rec1..3` 卡片是独立字段，不会跟着变。
- **`project.yml`（XcodeGen 备用）没动但也不需要动**：它用 `sources: - path: LeaveSim`
  整目录纳入编译，图标又在 asset catalog 内部，所以两条工程描述都还是完整的；
  真正列文件的是手写的 `project.pbxproj`，本轮没新增 `.swift` 文件正是为了不动它。
