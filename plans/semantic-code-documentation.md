# MoonBit 语义化代码文档实施计划

状态：In progress（当前里程碑采用 local-first semantic scope）

范围：`next/` Sphinx 文档站点、`next/sources/` 中的 MoonBit 示例，以及它们解析后的 MoonBit 依赖闭包

当前目标功能：local/standalone 代码 Hover、从 local/standalone occurrence 出发的 Go to definition、覆盖完整 local/dependency/stdlib corpus 的 Hackage 风格冻结源码页

长期目标功能：把 occurrence analysis 扩展到 dependency 和 stdlib 源码页，使完整 corpus 都具有 Hover 与 Go to definition

## 1. 结论与不可变约束

本方案采用“构建期语义分析、静态快照、Sphinx 渲染”的两阶段架构。

核心结论如下：

1. MoonBit 工具链在 Sphinx HTML 构建之前完成语义分析；浏览器和 Sphinx 都不实时调用 LSP。
2. 分析结果持久化为项目自有、版本化、自包含的 semantic source snapshot。Snapshot 同时保存语义区间和分析时使用的精确源码字节。
3. Sphinx 扩展可以进行侵入式改造，包括覆盖 `literalinclude`、注册 domain 和自定义 node、接管 HTML code renderer、添加模板和静态资源、生成额外页面。
4. 现有文档 Markdown 及其引用的 MoonBit 源文件不得为了语义功能而增加标记、ID、front matter 或特殊 directive，也不得改写其内容。
5. 每个进入 semantic snapshot 的 local、dependency 和 stdlib source 都必须生成一个 canonical source page；不允许用外部仓库链接代替已解析依赖或标准库源码页。页面是否被任何文档引用，不影响它是否生成。
6. Go to definition 的规范目标是源码页上的定义锚点，而不是某个偶然展示该定义的文档代码块。
7. 文档中的代码块只是源码区间的投影视图；它与完整源码页共享同一份 occurrence、hover 和 definition 数据。
8. 纯源码文件（如 `.mbt`）使用 Hackage 风格的 code-only source page；`.mbt.md` 是文学编程文档，必须保留并渲染 Markdown prose，同时只在其中的 MoonBit code blocks 叠加语义信息。
9. 没有语义信息的代码仍按现有方式显示和高亮；不得制造猜测性的 Hover 或无效 Definition 链接。
10. Markdown、gettext、LaTeX/PDF、EPUB、linkcheck 等非目标 builder 必须保持原有行为。

这里的“非侵入”只约束文档内容与被引用源码，不约束扩展实现和构建流水线。

### 1.1 当前里程碑：完整页面 corpus，local-first 语义

为先得到可用且 clean build 足够快的产品，本计划把“源码是否进入 snapshot/page corpus”和“源码是否作为 LSP occurrence analysis 的起点”明确分离：

| Origin | 冻结 blob 与 canonical source page | 作为 LSP occurrence analysis 起点 | 页面语义 overlay |
|---|---|---|---|
| local/workspace required source | 是 | 是 | Hover + Definition |
| standalone required `.mbt.md` | 是 | 是 | MoonBit code blocks 中的 Hover + Definition |
| resolved dependency（含 `.mooncakes`、path dependency） | 是，完整 resolution-locked corpus | 否 | 不扫描自身 occurrence；允许为 local 入站 target 合成定义落点 |
| pinned stdlib/core | 是，完整 toolchain-locked corpus | 否 | 不扫描自身 occurrence；允许为 local 入站 target 合成定义落点 |
| expected-failure / 无可靠 context | 是 | 否 | 暂无；只显示冻结代码 |

这里的“不分析 dependency/stdlib”表示不为这些 origin 启动独立 LSP analysis session、不枚举其中 token，也不为其中 occurrence 发起 Hover/Definition 请求。Local/standalone 文件中的 occurrence 仍由其 required consumer context 分析；当 LSP 返回的 Definition target 位于 dependency 或 stdlib 时，索引器保留该 verified location，并把链接解析到对应的冻结本站源码页。目标页至少提供文件行锚点，也可以低成本地为这个已验证入站 target 合成 definition occurrence/精确锚点；这种合成不包含目标文件自身 Hover 或引用图，不会触发对目标文件的递归语义扫描。

这一收缩不改变 snapshot schema、source identity、Definition edge、Sphinx domain、source-page route 或 renderer 数据流。未来恢复全量语义时，只扩大 `analysis_origin` allowlist，把 dependency/stdlib 的 required contexts 放回 occurrence analysis 输入；页面 corpus、冻结 blob 和现有 local-to-dependency/stdlib 链接无需重做。

除明确标注“当前里程碑”的范围外，本文对 dependency/stdlib 完整语义的描述均是长期目标和后续验收门槛，不是当前发布的阻塞条件。

## 2. 目标体验

### 2.1 文档页面中的代码块

对于能够映射到 semantic snapshot 的 MoonBit token：

- 鼠标悬停、键盘聚焦或触摸点击时显示签名、类型和文档；
- 标识符使用普通 `href` 指向定义，禁用 JavaScript 后仍可跳转；
- 复制、选择、换行、caption、Pygments 样式和现有 copybutton 行为不变。

只有文学编程 source 或 `literalinclude` 等具有可验证 source provenance 的代码块才叠加语义。普通 Markdown 中直接书写、没有文学编程 source identity 的 MoonBit fence 按设计保持现有词法高亮，不属于语义覆盖缺口。Source hash 不匹配时，原本具有 provenance 的代码块也必须 fail closed，退化为普通高亮。

### 2.2 Hackage 风格源码页

纯源码文件的源码页主体只展示代码，不承载 API 正文或教程内容。可以保留极简的文件路径、package/version、license attribution 和返回文档的导航。

`.mbt.md` 使用单独的 literate source page：Markdown prose、标题、列表、链接和其他文档结构按 MyST/Sphinx 规则渲染，MoonBit fence 渲染为带语义信息的代码块。它不是 raw Markdown dump，也不是删除 prose 的代码投影；front matter 作为页面元数据处理，fence delimiter 不作为可见正文。

| Source kind / origin | Canonical page | 当前里程碑的 semantic behavior |
|---|---|---|
| local/workspace required `.mbt` | Hackage 风格 code-only page | 完整 Hover/Definition |
| local/standalone required `.mbt.md` | 保留 Markdown prose 的 literate page | 在可分析 MoonBit code blocks 中提供 Hover/Definition |
| dependency/stdlib recognized source | 对应类型的冻结 code-only/literate page | 不扫描自身 occurrence；可作为 local Definition 的入站目标并合成 definition anchor |
| `.mbti` | code-only page | 仅当属于允许的 local provider/context 时分析，否则 display-only |
| `.mbtp` | code-only page | 仅当属于允许的 local proof provider/context 时分析，否则 display-only |
| generated pure source | code-only page | local 且 provider/context 可靠时分析，否则 display-only |
| virtual inline unit | code-only synthetic page | 仅在 Phase 4 context 可确定时生成 |

每个源码页必须具有：

- canonical、可预测、包含依赖版本身份的 URL；
- 每个展示代码行对应的原始文件行锚点；
- 当前被分析 source 中全局定义和局部 binding 的唯一锚点；display-only target 至少具有稳定行锚点，并可具有由入站 Definition location 建立的精确 target anchor；
- 当前被分析 occurrence 到定义的真实 `href`；
- 对拥有 semantic overlay 的页面，与文档代码块一致的 Hover；
- 同一符号引用的可选联动高亮；
- 没有语义数据时仍完整可读的词法高亮代码。

源码页不是 `literalinclude` 的兜底。它是 definition navigation 的主要目的地，也是当前仓库完全缺失的新输出类型。当前里程碑中 dependency/stdlib 页面虽然没有自身 occurrence 的 Hover/Definition overlay，仍是一等、冻结且可离线重建的导航目标。

## 3. 当前系统与缺口

当前文档数据流可概括为：

```text
next/sources 下的 MoonBit 工程
  ├─ scripts/check-document.py / next/check_error_docs.py 独立校验
  └─ Markdown 通过 include / literalinclude 引用
                         ↓
MyST + Sphinx read phase
  ├─ include 展开 Markdown
  ├─ literalinclude 读取、切片、dedent、prepend/append
  └─ 生成 literal_block
                         ↓
Pygments 词法着色 + sphinx_book_theme
                         ↓
普通静态 HTML / Markdown / PDF / gettext 等输出
```

仓库中的关键事实：

- [`next/conf.py`](../next/conf.py) 已把 `.mbt.md` 注册为 Markdown source，并将 `next/sources/` 排除在 Sphinx source discovery 之外。
- 当前 [`next/_ext/lexer.py`](../next/_ext/lexer.py) 只是正则 Pygments lexer，没有 package、source path 或 symbol context。
- 当前 [`next/_ext/check.py`](../next/_ext/check.py) 仅对少量带 class 的 block 做 parser-only 检查，不提供 package 级语义信息。
- [`scripts/check-document.py`](../scripts/check-document.py) 和 [`next/check_error_docs.py`](../next/check_error_docs.py) 负责示例正确性，但它们的输出没有进入文档 HTML。
- 页面与源码之间没有中央映射表；关系分散在约 984 个 `literalinclude` 和若干 `include` 中。
- `literalinclude` 广泛使用 `start-after`、`end-before`、`dedent`、`prepend`、`append`、`start-at` 和 `end-at`。现有 doctree node 已经丢失足够的逐字符 provenance，不能在 HTML 阶段可靠反推。
- 当前 checkout 在 `next/sources/` 下有 704 个 `.mbt`、21 个 `.mbti`、3 个 `.mbtp` 和 3 个 `.mbt.md`；其中大量文件属于 error-code 示例，很多源码定义从未被任何文档代码块完整展示。
- Read the Docs 和 linkcheck 当前并不安装 MoonBit，因此不能把语义分析悄悄塞进常规 Sphinx 进程。

目前缺少的不是一个前端 tooltip，而是以下四层完整基础设施：

1. 全源码和依赖的可复现语义 corpus；
2. 源码区间到页面展示区间的 provenance；
3. 每个源码文件的 canonical HTML 页面和定义锚点；
4. 让普通文档页面、源码页和跨 package 链接共享同一 symbol graph 的 Sphinx 扩展。

## 4. 总体数据流

```mermaid
flowchart LR
  A["仓库源码与 Moon 配置"] --> B["root 与 pre-check source inventory"]
  B --> C["固化输入 digest 与 moon check barrier"]
  C --> E["package metadata adapter 与 resolution lock"]
  D[".mooncakes resolved dependencies 与 pinned stdlib"] --> E
  E --> Q["完整 local / dependency / stdlib page corpus"]
  B --> Q
  Q --> R["冻结全部 source blob 与 route identity"]
  Q --> S["analysis-origin filter"]
  S -->|"当前：local / standalone required"| F["token candidate collector"]
  S -.->|"后续：放回 dependency / stdlib"| F
  F --> G["长期运行的 moon-lsp sessions"]
  G --> H["规范化 local occurrence / hover / definition"]
  H --> T["解析 target source；允许 dependency / stdlib"]
  T --> I["自包含 semantic source snapshot"]
  R --> I

  J["现有 Markdown"] --> K["MyST / Sphinx read phase"]
  L["include 与 literalinclude"] --> K
  I --> M["MoonBit Sphinx domain 与 renderer"]
  K --> M
  M --> N["普通文档中的语义代码块"]
  M --> O["全部 canonical source pages"]
  M --> P["按页分片的 hover payload"]
```

这条数据流有三个需要显式区分的清单：

- pre-check source inventory：来自受控 root、Moon 配置、error-code inventory 和受控文件发现，保证故意失败的源码也能固化 blob 并生成源码页；
- semantic source inventory：来自成功检查后的 resolved package graph，建立可分析 source/context 的全集，并补入 dependency、stdlib 和生成源码；当前里程碑再由 `analysis_origin` 策略从中只选择 local/standalone required contexts；
- documentation occurrence inventory：来自最终 Sphinx doctree，决定哪些源码区间被显示在某个文档页面中。

前两者合并为 snapshot source corpus；它与 documentation occurrence inventory 只在渲染时通过 `source_id + context_id + source range + blob digest` 连接。源码页永远不能由文档 occurrence inventory 反推，否则未被 `literalinclude` 的文件和定义会再次丢失。

当前里程碑的关键单向边界是：dependency/stdlib 可以出现在 Definition target closure 中，但不会因此反向进入 token candidate collector。换言之，target resolution 只补充导航边和 target anchor，不递归触发目标文件的 Hover/Definition 请求。

## 5. 阶段 A：建立 semantic source snapshot

### 5.1 发现语义 root

索引器按以下优先级发现分析单元：

1. `moon.work` workspace；
2. `moon.mod.json` 或 `moon.mod` module；
3. 可以由工具链单独检查的 standalone `.mbt.md`。

Root 发现不依赖 Sphinx `env.found_docs`，因为 `next/sources/` 被 Sphinx 排除。

在执行任何检查之前，索引器先建立 pre-check source inventory 并固化 first-party blob。它综合 Moon 配置、error-code inventory、standalone 清单和受控 root 内的文件发现，因此 `_error` 工程即使不能生成完整 IDE metadata，也不会从源码页全集中消失。

Source kind 由 provider capability registry 决定，而不是只硬编码 `.mbt` 和 `.mbt.md`。当前至少显式处理：

- `.mbt`：Moon LSP semantic provider；
- `.mbt.md`：完整 literate document + Moon LSP semantic provider；
- `.mbti`：在当前 toolchain/provider 支持时分析，否则生成 display-only source page；
- `.mbtp`：在 proof/verification provider 支持时分析，否则生成 display-only source page；
- package metadata 报告的 generated source：按其真实 source kind 处理；
- 未知或内部构建产物：不自动接纳。

所有进入 inventory 的 recognized source 都有源码页；provider capability 只决定 `analysis_status`，不决定页面是否存在。

### 5.2 完成检查 barrier

对每个健康 root 先完整执行相应的 `moon check`。这是 LSP 可用 IDE metadata 的硬 barrier，不依赖语言服务器后台检查的时序。Expected-failure root 仍执行其既有 diagnostic 检查，但源码页 inventory 不以它成功生成 `packages.json` 为前提。

- workspace/module 使用生成的 `_build/packages.json`；
- standalone `.mbt.md` 使用其对应的 `_build/<filename>.packages.json`；
- 初次解析依赖可以正常下载；可复现 CI 在依赖准备完成后使用 frozen 模式；
- backend、target 和 toolchain build ID 是 semantic fingerprint 的一部分。

`packages.json` 是 Moon 工具链与 IDE 共享的 metadata，但当前属于 legacy interface。必须用 adapter 隔离其 schema，snapshot 不直接暴露该文件的字段结构。

整个 `capture -> check -> metadata -> LSP` 必须在不可变 checkout/copy 中执行；若本地 watch 模式不能提供不可变目录，则在 check 前、metadata 读取后和所有 LSP 请求完成后重复验证 source/config/package-metadata digest，任何变化都中止并重试。`didOpen.text` 必须直接来自已经 hash 并写入临时 snapshot 的 blob，不能再次从活动工作树读取。Manifest 记录 check-barrier input digest，避免发布“旧 `.mi` + 新源码”的混合结果。

`--frozen` 只阻止解析过程修改依赖，不能代替 dependency lock。索引器必须持久化并验证自己的 resolution lock，包括 module、resolved version/revision、registry checksum、source tree digest 和 package set；stdlib 同时记录 toolchain ID 和 core tree digest。Production 中相同 module/version 解析到不同字节时必须失败。

### 5.3 确定源码全集

第一版把“全部源码”严格定义为 pre-check inventory 与 resolved semantic closure 的并集：

1. pre-check inventory 中所有 first-party recognized source，包括 `.mbt`、`.mbt.md`、`.mbti`、`.mbtp` 和 expected-failure 文件；
2. 所有 local/workspace/standalone package metadata 列出的 normal/test/white-box/literate/generated source；
3. 当前 resolution lock 中全部 dependency module root（包括 `.mooncakes` registry dependency 和 path dependency）的 provider-recognized source；
4. pinned toolchain 的完整 stdlib/core tree 中全部 provider-recognized source；
5. LSP Definition 返回但尚未进入集合、且通过安全策略的目标，递归加入 definition closure。

每个已经进入 resolution lock 的 dependency module 都扫描其 allowed module root 下的全部 provider-recognized source，包括 `.mooncakes` registry module、path dependency 及该 module 自带的其他 package/example source；但不越过 module root 收集相邻 cache/workspace，也不包含 `_build` 下的 `.ast`、`.typechecked`、`.mi` 等内部产物。

Definition closure 扩张必须在写入 blob 前执行 realpath/source-kind/license policy，并限制 allowed roots、symlink escape、visited set、递归深度、文件数量和总字节。未知构建机路径不得因为“可读”就进入 snapshot。Resolved `.mooncakes` 和 pinned stdlib root 是明确允许的 source roots；除此之外的未知目标在 strict mode 中报告并失败，不能静默复制或伪造链接。

通过发布策略后，验收恒等式为：

```text
生成的源码文件页面集合 == snapshot.sources
```

而不是：

```text
生成的源码文件页面集合 == 文档中被 literalinclude 的文件集合
```

这里还必须区分：

- page corpus：上述全部 recognized source，必须 100% 有页面；
- semantic-capable corpus：拥有成功、可复现 analysis context 的 source/context 全集；
- active analysis corpus：本次构建策略允许作为 occurrence analysis 起点的 source/context，必须完成 candidate request ledger 并获得可用语义。

当前里程碑的 active analysis corpus 只包含 local/workspace/standalone 的 required contexts。Dependency 和 stdlib 即使拥有健康 context，也以 `analysis_status = deferred-by-origin-policy` 进入 page corpus，不建立 candidate ledger；它们不应被误报为分析失败。对于 resolved dependency module 自带但不在 consumer graph 中的 package/example，当前只需固化源码、身份和页面，不解析其额外 dev/test context。长期全量模式恢复时，再从其自身 workspace/module manifest 解析独立 context，并锁定额外的 dev/test dependency。

确实无法形成健康 context 的 local 文件仍在 page corpus 中，但标记为 `display-only-with-reason`；不能把“有词法页面”计入 semantic complete。Coverage report 分别给出 `page_corpus_count`、`active_analysis_source_count`、`semantic_complete_count`、`deferred_by_origin_count`、`expected_failure_count` 和 `display_only_count`。

### 5.4 采集 Hover 和 Definition

推荐 provider 组合：

- `moon-lsp`：Hover 和 Definition 的唯一权威来源；
- `mooninfo -dump-tokens`：候选 token 枚举器；
- `moon ide gen-symbols`：全局声明、名称和 anchor 的补充信息；
- package metadata adapter：source identity、package、依赖版本和 backend 路由。

每个 active required context 使用长期运行的 `moon-lsp --stdio` session。对 active analysis source 发送 `didOpen`，然后对候选 token 请求：

- `textDocument/hover`；
- `textDocument/definition`。

当前 `analysis_origin` allowlist 为 local/workspace/standalone，dependency 和 stdlib 文件不进入候选枚举、不发送 `didOpen`、不产生自己的 Hover/Definition request ledger。Local occurrence 的 Definition 响应仍可以指向 dependency/stdlib：索引器将返回 URI 规范化为已经冻结的 `source_id`，校验 target range 落在对应 blob 内，并保存导航 edge。该 edge 的渲染目标优先使用由 verified `targetSelectionRange` 建立的稳定 target anchor；若 provider 只返回普通 `Location`，至少使用可信行锚点。索引器不得因为发现这个 target 而分析目标文件中的其他 occurrence。

恢复长期全量模式时，此处的 provider、请求、range normalization 和 ledger 规则全部不变；只将 dependency/stdlib contexts 加入 `analysis_origin` allowlist，并为它们建立 candidate ledger。

普通 `.mbt` 使用 MoonBit language ID；`.mbt.md` 以原始 Markdown 内容和 Markdown language ID 打开，使 LSP range 直接落在原文件坐标。`mooninfo` 不能直接把 `.mbt.md` prose 当可靠 MoonBit token：候选枚举器需要把非代码区域替换为空白并保留换行/偏移，或先按 projection range 过滤 raw token。候选 token 只决定“向哪里提问”，最终 occurrence range 以 LSP response 或经过验证的原 token span 为准。

必须完整支持 LSP 返回 union，包括多个 Definition target 和 `LocationLink`；后者使用 `targetSelectionRange` 定位定义 token，并保留 `targetRange` 供导航高亮。Semantic Tokens 当前不足以覆盖类型、变量、字段、variant 等全部 occurrence，不能作为唯一枚举来源。

位置处理必须显式区分：

- LSP 的 0-based UTF-16；
- `mooninfo` 的行列格式；
- UTF-8 byte offset；
- Python code point index；
- HTML escaped text offset。

Snapshot 的规范渲染坐标使用原始 blob 上的 UTF-8 byte range，同时保存原始 LSP range 用于审计和回归。所有转换都通过一个共享 range library，源码页和文档代码块不得各自实现一套。

### 5.5 Source identity 与 semantic context

物理 `source_id` 与一次语义分析的 `context_id` 必须分离。同一文件可能作为普通 package file、test、white-box test 或不同 backend 的输入，解析到的依赖和可见性不一定相同。

`context_id` 至少包含 root、package、file role、backend 和 resolved package-graph fingerprint。Occurrence 按 `source_id + context_id` 存储；文档 block 根据 provenance 选择对应 context。源码页采用确定性的 canonical context：

1. 普通 package 文件优先 normal package context；
2. test/wbtest 专用文件使用自身 file-role context；
3. `.mooncakes` dependency 在长期全量模式中优先其 resolved module/package 自身的可复现 context，consumer root context 作为 variant；当前里程碑没有 occurrence overlay；
4. stdlib 在长期全量模式中优先 pinned toolchain 的独立 core semantic context；当前里程碑没有 occurrence overlay；
5. 第一版使用项目配置的 preferred backend；
6. 同一源码在多个 context 得到不同结果时全部保存在 snapshot，并在覆盖报告中列出；未实现 context selector 前，页面只展示 canonical context，不做无规则合并。

Definition anchor 由 target source identity 和 definition identity 决定，不因引用方 context 改变。Source page 对所有已验证入站 target 和已分析 context 的 definition anchors 取并集，确保任一合法引用都有落点；target-only anchor 只是导航落点，不赋予 display-only 页面 Hover/reference overlay。拥有语义数据的页面使用 canonical context 展示 overlay，避免把相互冲突的类型信息合并。未来的多 backend UI 可以切换 overlay，但不能改变同一个定义的 canonical source URL。

### 5.6 Symbol identity

Snapshot 中不能用机器绝对路径或裸 identifier 作为 symbol identity。

- 导航用 `symbol_id` 统一由 `target_source_id + target_selection_range + definition kind` 生成，避免同一声明先得到 location-based provisional ID、随后又被 `gen-symbols` 改名并产生两个 anchor；
- qualified module/package/name/kind 另存为 `logical_symbol_key`，用于搜索、展示和跨版本关联，不替换导航 identity；
- 如果未来 compiler 提供真正稳定的 symbol ID，把它登记为 alias，不迁移现有 occurrence identity；
- `moon ide gen-symbols` 只补充名称、kind、visibility 和 doc 属性，不能在没有 LSP/编译器验证位置时单独制造 Definition edge；
- 同名 shadowing 必须得到不同 ID；
- symbol URL 的生成属于 Sphinx 路由层，不写死在 occurrence 中。

### 5.7 自包含 artifact

建议的第一版布局：

```text
semantic-snapshot/
├── manifest.json
├── resolution-lock.json
├── analysis-inputs.jsonl
├── sources.jsonl
├── assets.jsonl
├── contexts.jsonl
├── symbols.jsonl
├── occurrences/
│   └── <context-id>/<source-id>.json
├── requests/
│   └── <context-id>/<source-id>.json
├── hovers/
│   └── <shard>.json
├── diagnostics.jsonl
└── blobs/
    └── sha256/<content-digest>
```

各部分职责：

- `manifest.json`：schema、analyzer revision、toolchain、corpus digest、root、显式 `analysis_origin` policy 和全部 shard digest；
- `resolution-lock.json`：local/path/registry dependency 和 stdlib 的 version/revision/tree digest/package set；
- `analysis-inputs.jsonl`：`moon.work`、`moon.mod*`、`moon.pkg*`、原始及规范化 package metadata、provider config 等精确输入的 logical identity/blob digest；
- `sources.jsonl`：canonical source identity、origin、module/version/package/path、aliases、blob digest、analysis status、literate structure 和 source-page route key；local、resolved `.mooncakes` dependency 与 pinned stdlib 都在此表中；
- `assets.jsonl`：literate page 递归引用的 Markdown include、图片和允许的静态资源 identity/MIME/blob digest；
- `contexts.jsonl`：root、package、file role、backend、package graph digest、toolchain digest、是否 active/deferred、LSP initialize params、negotiated position encoding，以及精确 `input_source_ids + blob digests`/`context_input_digest`；deferred context 不伪造 LSP 初始化信息；
- `symbols.jsonl`：navigation symbol ID、logical symbol key、definition source/selection range、kind、visibility、qualified name、hover ID；
- `occurrences`：按 context 隔离的 definition/reference range、hover ID 和完整 target location/link；
- `requests`：每个 candidate 的 hover/definition 完成状态、重试和错误 ledger；
- `hovers`：去重后的受限 Markdown payload；
- `diagnostics`：required、expected-failure、display-only 状态及原因；
- `blobs`：分析时实际使用的原始 UTF-8 字节，按 SHA-256 去重。

一个 occurrence 的概念结构如下：

```json
{
  "source_id": "local:next/sources/sudoku/src/index.mbt.md",
  "context_id": "ctx:sudoku:normal:wasm-gc:4d...",
  "request_position_utf16": [263, 20],
  "candidate_range_utf8": [8124, 8145],
  "hover_range_utf8": [8124, 8145],
  "effective_range_utf8": [8124, 8145],
  "hover_id": "sha256:8b...",
  "definitions": [
    {
      "response_kind": "location-link",
      "origin_selection_range_utf8": [8124, 8145],
      "target_source_id": "stdlib:moonbitlang/core@0.10.2+1bb3e16cf:immut/sorted_set/types.mbt",
      "target_range_utf8": [380, 445],
      "target_selection_range_utf8": [412, 421]
    }
  ]
}
```

所有 byte range 都是原始 blob 上的半开区间 `[start, end)`。普通 `Location` 把 target range 和 target selection range 规范化为同一 verified identifier range；`LocationLink` 的四个 range 全部保留。Hover 同时保存请求位置、candidate range、可选的 `Hover.range` 和最终采用的 effective range，避免 qualifier、method 或 field 被绑定到错误 span。

Active required context 只有在所有 candidate 都进入 `complete`、`valid-no-result` 或 `skipped-with-reason` 状态时才能发布。任何未分类请求、JSON-RPC error、timeout、LSP crash 或未完成文件都会使该 context 失败；不得用 occurrence 数量看起来“差不多”来判断完成。`deferred-by-origin-policy` source 不建立空 ledger 冒充 complete，而是由 manifest policy 和 coverage report 单独审计。

Sphinx 只能从 snapshot blob 生成源码页，不能在渲染阶段重新读取 `.mooncakes`、`$MOON_HOME` 或依赖 checkout。Snapshot 对渲染和分析输入审计是 self-contained；重新执行语义分析仍需要 manifest 指定的 pinned toolchain/provider。这一边界保证分析字节与展示字节一致，也使不安装 MoonBit 的文档环境能够生成完整页面。

Artifact 写入必须是原子的：先写临时目录、校验 blob 和所有 target，再切换 manifest。失败的分析不得把新旧 shard 混合，也不得继续发布旧 occurrence 冒充最新结果。

Snapshot 的确定性规范同时固定 canonical JSON 编码、JSONL 排序键、Definition target 排序、hover shard 分配、Unicode/path normalization 和 digest 算法。Wall-clock timestamp、绝对 checkout path 和非确定性请求完成顺序不进入内容身份。Manifest corpus digest 覆盖 resolution lock、analysis inputs、sources、assets、contexts、symbols、occurrences、requests、hovers、diagnostics、routes 和每个 blob；同一输入在两个不同绝对路径的 clean checkout 中必须生成 byte-for-byte 相同的 public snapshot。

### 5.8 Canonical source identity 与路由输入

逻辑 source identity 与最终 Sphinx pagename 分离。建议 source identity 形式：

```text
local:<repo-relative-path>
workspace:<module>@<revision>:<module-relative-path>
dependency:<module>@<resolved-version>:<module-relative-path>
stdlib:<core>@<toolchain-id>:<core-relative-path>
generated:<root-id>:<package>:<logical-path>
standalone:<repo-relative-path>
virtual:<docname>:<stable-block-id>
```

Path dependency 没有发布版本时使用 commit ID；仍不可得时使用 module tree digest。所有绝对路径只存在于索引器进程内，published snapshot 和 HTML 中不得出现 `file://`、本地用户名或 cache 路径。

Indexer 内部维护 `canonicalized file URI -> source_id` 映射，并在 `sources.jsonl` 只保存可移植 alias，例如 repo-relative path、module-relative path、`.mooncakes` module-relative path 和 stdlib-relative path。Canonicalization 必须处理 symlink/realpath、`..`、URI percent decoding、Unicode normalization、大小写碰撞和同一文件被多个 root 发现。

Origin 优先级固定为：repo-local > workspace path dependency > resolved `.mooncakes` dependency > stdlib > generated。相同物理文件不能因不同拼写产生两个 source page；同一 source 在不同 root/backend 中的差异由 `context_id` 表达，而不是复制 `source_id`。

## 6. 阶段 B：Sphinx 扩展架构

建议新增一个独立扩展包，例如：

```text
next/_ext/moonbit_semantic/
├── __init__.py
├── config.py
├── domain.py
├── snapshot.py
├── ranges.py
├── directives.py
├── provenance.py
├── nodes.py
├── render.py
├── source_pages.py
├── templates/moonbit-source.html
└── static/
    ├── moonbit-semantic.css
    └── moonbit-semantic.js
```

构建输出另包含 `_static/moonbit-semantic/hovers.<payload-digest>.js` 和兼容回退 `hovers.json`；前者由 snapshot 生成，不是扩展包中的手写静态文件。

扩展可以侵入 Sphinx pipeline，但不能要求修改任何现有 `.md` 或 `.mbt` 文件。

### 6.1 Sphinx domain

注册 `MoonBitSemanticDomain`，负责：

- `symbol_id -> source pagename + definition anchor`；
- module、package、file、type、trait、function、method、value、field、constructor 等对象；
- `resolve_xref` 和跨 package URL 解析；
- `objects.inv` 导出；
- module/package/symbol/source index；
- 文档 occurrence 到源码的 backlink；
- `env_version`、`env-purge-doc` 和并行构建时的 `env-merge-info`。

所有 definition target 在 `builder-inited` 加载 snapshot 时注册，不等待某个文档页引用它。

### 6.2 生命周期挂载点

| 挂载点 | 职责 |
|---|---|
| `setup()` | 注册配置、domain、node、post-transform、directive override、template 和事件；不无条件注入 JS/CSS |
| `config-inited` | 固化 snapshot 路径、URL prefix、支持的 builder 和 strictness；声明扩展自带 template path |
| `builder-inited` | 仅在 `html/dirhtml` 一次加载并验证 snapshot、注册 CSS/JS、向 domain 注册全部 source/symbol；其他 builder 进入轻量 no-op |
| `env-get-outdated` | 细粒度标记受影响文档；若 corpus/source-page/renderer digest 改变，或 expected output manifest 中任一 page/target-set/hover/CSS/JS 文件缺失，即使源码未变、文件从未被文档引用，也至少返回 `root_doc` 作为 write sentinel |
| `env-before-read-docs` | 为每个 `.mbt.md` 以稳定 virtual docname、snapshot source URI 和独立 settings 调用 MyST；运行允许的 read transforms，将可 pickle doctree 存入 environment |
| 自定义 `literalinclude` | 保留 target、全部 slice options 和 displayed-to-source 分段映射 |
| `source-read` / `include-read` | 记录整篇 `.mbt.md` include 的来源上下文；不为普通 Markdown fence 合成 source identity |
| `doctree-read` | 在 include 与 i18n 后为现有 `literal_block` 附加轻量 semantic annotation；不替换 node |
| `env-purge-doc` / `env-merge-info` | 维护 usage/backlink，支持增量构建和 `-j` |
| `env-updated` | 校验 snapshot graph、计划 route、definition closure，完成 backlink 汇总 |
| `env-check-consistency` | 检查计划 page/route 唯一性、blob hash 和 symbol target；此时不声称实际 HTML 已写出 |
| `SphinxPostTransform` | 仅在目标 HTML builder 中把已注解 block 换成 semantic node |
| `write-started` | clone literate doctree，运行 reference resolution、semantic post-transforms 和独立 HTML writer，准备不可变 body/context |
| `html-collect-pages` | 只 yield 已准备好的纯源码 body、literate body、target-set page 和 module/package/source index；开始时验证计划页数量，不再修改 environment |
| `html-page-context` | 提供 breadcrumb、locale UI 文本和 hover asset URL；不正则改写 HTML body |
| `build-finished` copy handler | 仅在无 build exception 时从扩展 package/snapshot asset manifest 复制 CSS、runtime JS、经典脚本形式的 hover payload、兼容回退 JSON 和 literate static assets 到 `_static/moonbit-semantic/` |
| `build-finished` validation handler | 在 copy 后验证实际文件、hover shard、anchor manifest 和 page count；成功后只清理扩展 namespace 中的 stale page/asset |

现有 `check.py` 已在 `doctree-read` 遍历 literal block。Semantic handler 必须晚于它运行，且此阶段只增加可 pickle attribute；真正 node replacement 推迟到 post-transform。

### 6.3 覆盖 `literalinclude` 并保留 provenance

只在 `doctree-read` 观察 `literal_block` 不足以恢复 `literalinclude` 的 target、options 和逐行映射。扩展应覆盖同名 directive，但委托或严格复刻当前 Sphinx `LiteralIncludeReader` 的显示语义。

自定义 directive 除生成原有 node 外，还保存：

- resolved `source_id`；
- directive 所在文档和行；
- 原始 options；
- displayed byte range 到 original source byte range 的分段 map；
- `dedent` 对每行列的影响；
- `prepend`/`append` 等 synthetic segment，并明确标记为无源；
- 最终 display text hash。

必须用 golden tests 覆盖当前所有 option 组合。扩展升级 Sphinx 时，该 directive compatibility suite 是强制 gate。

这属于允许的扩展侵入，不需要也不允许修改现有 984 个 directive。

### 6.4 普通 fence 与 `{include}`

- 完整 `.mbt.md` 被 `{include}` 后，内部 code block 保留原 `.mbt.md` source 和行号，扩展据此映射到 snapshot；
- 普通 Markdown 中直接书写、没有文学编程 source provenance 的 MoonBit fence 始终保持词法高亮；不推断 package context，也不生成 virtual source unit；
- `{literalinclude}`、整篇 `.mbt.md` include 以及 canonical `.mbt.md` literate page 使用 verified source/range map 获得语义；
- 以 `language: markdown` 原样展示 `.mbt.md` 文件时，不把 fence 文本误当成当前代码块中的 MoonBit token。

这一边界使语义始终来自仓库中真实、可复现的文学编程/源码单元，不对教学片段、残缺代码或包含 `...` 的普通 fence 伪造语义。

### 6.5 文档代码块渲染

共享的 `SemanticCodeRenderer` 接收：

1. 最终 display text；
2. Pygments lexical ranges；
3. displayed-to-source provenance；
4. snapshot semantic ranges；
5. domain 解析后的 definition URL。

Renderer 在 lexical 和 semantic range 的边界并集上切分文本，直接构造合法嵌套 HTML，禁止在 Pygments HTML 上用正则插入 `<a>`。

生成结构必须继续保留：

```html
<div class="highlight-moonbit notranslate">
  <div class="highlight">
    <pre>...</pre>
  </div>
</div>
```

语义 wrapper 不能改变 `<pre>.textContent`。行号、tooltip 和辅助内容应通过 CSS pseudo-element、`aria-describedby` 或 `<pre>` 外部容器实现，不能污染复制文本。

## 7. 阶段 C：Hackage 风格纯源码页与 literate source pages

### 7.1 页面生成机制

使用与 `sphinx.ext.viewcode` 类似的 `html-collect-pages` 架构，但有三个重要差异：

1. 从 `snapshot.sources` eager 生成全集，而不是由文档引用 lazy 触发；
2. 使用共享 semantic renderer，生成 token hover、definition anchor、reference link 和 line anchor；
3. 同时生成 source root、module、package、file index，并把 symbols 注册到 MoonBit domain。

当前里程碑中，第 2 点只对 active local/standalone source 渲染完整 occurrence overlay。Dependency/stdlib 页面使用同一 lexical renderer 和 canonical route，但不渲染自身扫描得到的 Hover、引用链接或文件内部 occurrence；它们仍渲染行锚点，并允许为 local Definition edge 实际命中的 target 合成 definition occurrence/anchor。未来放开 origin policy 后，同一页面模板直接叠加其完整 occurrence overlay，不改变 URL。

推荐 namespace：

```text
_moonbit-source/index
_moonbit-source/local/<repo-relative-path>
_moonbit-source/workspace/<module>/<revision>/<path>
_moonbit-source/pkg/<module>/<version>/<path>
_moonbit-source/stdlib/<toolchain-id>/<path>
_moonbit-source/generated/<root-id>/<package>/<path>
_moonbit-source/virtual/<docname>/<stable-block-id>
_moonbit-source/_targets/<definition-set-digest>
```

最终 URI 必须通过 `builder.get_relative_uri()` 生成，以兼容 `html` 和 `dirhtml`；不能在 renderer 中手拼 `.html`。路径编码必须处理 `/`、Unicode、保留字符、大小写不敏感文件系统碰撞、同名 module 和 dependency version。

### 7.2 Anchor contract

每个源码页同时提供两类 anchor：

- 行锚点：`#L42`，永远表示原始文件的一基第 42 行；
- 定义锚点：`#mb-def-<stable-symbol-id>`，附着在精确的 definition token 上。

Reference 的默认 `href` 指向定义锚点；如果只有可信 location 而没有完整 symbol identity，则至少指向对应行锚点。这一规则同样适用于 display-only dependency/stdlib 目标：目标页无需自己的 semantic overlay，也必须能承接 local occurrence 的入站链接。单个 Definition target 直接链接源码页；多个 target 则生成一个确定性、静态的 target-set page，普通 `href` 指向该页面，页面列出全部候选源码锚点。JavaScript 可以把同一选择器增强为就地 popover，但不能代替静态页面。这样既不静默丢弃 target，也保证禁用 JavaScript 后仍可完成导航。

全局、局部、同名 shadowing 和跨 package symbol 使用同一 contract。Go to definition 不优先选择文档页面 occurrence，从而避免同一源码被多个页面重复 include 时的歧义。

### 7.3 Source page DOM contract

视觉目标参考 Hackage，但不复制其内部 class 名称。概念结构如下：

```html
<span id="L42" class="mbt-source-line" data-source-line="42">
  <span id="mb-def-sym_abc" class="mbt-definition">
    <a href="#mb-def-sym_abc"
       data-mbt-hover="hover_123"
       aria-describedby="mbt-hover-hover_123">answer</a>
  </span>
</span>
```

Hover 内容按 source page 或 module 分片并去重，token 只保存 `hover_id`，避免像早期 Hackage/Koka 页面一样在每个 occurrence 内重复整段签名。

本地静态预览不能依赖 `fetch(file://.../hovers.json)`。构建必须同时输出在 runtime 之前加载的经典脚本 `hovers.<payload-digest>.js`，直接注册同一份确定性 payload；内容寻址文件名同时避免 HTTP/浏览器缓存旧 Hover。`hovers.json` 仅作为 HTTP 部署或旧页面的兼容回退。runtime 的 fetch 回退必须捕获失败，不能产生未处理 rejection。这样直接打开生成的 HTML 与通过 HTTP 服务访问时使用相同的 Hover 数据。

- 普通 `href` 在无 JavaScript 时仍工作；
- JavaScript 只负责 hover/focus/touch、多个 target 选择和同 href 高亮；
- 当前纯文本 Hover 是不参与 hit testing 的被动 tooltip；定位必须做上下碰撞翻转并限制到 viewport，异步 payload 返回前还要校验触发 token 仍处于 active 状态，避免 tooltip 覆盖 token 后形成 `pointerout -> hide -> pointerover -> show` 闪烁循环；
- hover payload 只支持受限 Markdown，HTML 必须 escape/sanitize；
- UI 需支持键盘、触摸、`aria` 和 reduced motion。

### 7.4 `.mbt.md` 的 literate source page

`.mbt.md` 不是纯源码文件。Snapshot 保存完整原始 blob，Sphinx 使用注册的 MyST parser 把它渲染为文学编程页面：

```text
原始 .mbt.md
  ├─ front matter                    → 页面元数据
  ├─ Markdown prose/heading/list     → 正常渲染并保留
  ├─ link/image/directive/include    → 按 Sphinx/MyST 规则解析
  ├─ mbt / mbt check / moonbit check → active origin 中为代码块叠加语义
  ├─ mbt nocheck / moonbit skip      → 代码块，仅词法高亮
  ├─ 普通 moonbit fence              → `.mbt.md` 文学编程代码块；active origin 中叠加语义
  └─ 其他语言 fence                  → 正常文档代码块
```

页面不显示 Markdown fence delimiter，但必须显示其 prose。Definition anchor 位于渲染后的 MoonBit code block 内；code line anchor 继续使用原始 `.mbt.md` 的一基行号，例如原文件第 98 行仍是 `#L98`。标题和 prose 使用正常的文档 anchor，不冒充源码行。

索引阶段仍需持久化每个 MoonBit fence 的精确映射，Sphinx 解析出的 code node 必须通过 source range 和 content digest 与之匹配：

```json
{
  "raw_byte_range": [3012, 3654],
  "raw_line_range": [98, 116],
  "content_digest": "sha256:...",
  "fence_kind": "moonbit-check",
  "semantic_status": "analyzed",
  "range_map": [
    {
      "raw_line": 98,
      "raw_utf8": [3012, 3050],
      "display_utf8": [0, 38],
      "transform_kind": "identity"
    }
  ]
}
```

`range_map` 是双向、分段、半开区间映射。MyST 若因 list/blockquote、tab 展开、CRLF 归一化或非连续 slice 改变文本，使用多个带 `transform_kind` 的 segment 表达；每个语义 span 都必须能从 raw 映射到 display 并 round-trip 回同一 raw span。Sphinx 发现 parser 结果、segment digest 或 source range 不一致时 fail closed，只让该 code block 退化为普通高亮，不能把语义贴到错误 token。

为了让 additional page 拥有完整 Markdown 能力，扩展为每个 `.mbt.md` 建立 extension-owned virtual doctree。`env-before-read-docs` 从 snapshot blob 调用项目当前注册的 MyST parser，运行 section/target、标准 role/reference、受控 directive 和 asset dependency 等明确允许的 read transforms，并把可 pickle doctree 存入 environment；`write-started` clone 它，运行 reference resolution 和 semantic post-transforms，再用独立 HTML writer 预渲染 body；`html-collect-pages` 只 yield 已准备的 body/context/template。Canonical literate page 不运行 gettext locale transform，也不允许 `toctree` 或其他会改写全站 environment 的 directive。这个过程不在工作树中生成或修改 `.md` 文件。

`.mbt.md` virtual parser 覆盖 `{include}` 和 `{literalinclude}` 为 snapshot-backed directive，直接从 `sources.jsonl`/`assets.jsonl`/blob store 读取，不能依赖 filesystem 先打开文件后才触发 `include-read`。相对 Markdown link、image、nested include 和 literalinclude 都以原 source identity 为基准重写；展开节点标记为它自己的 `source_id + range`。禁止渲染阶段绕过 snapshot 去读取一个不同版本的活动文件。

索引阶段递归建立 literate resource closure，把本地 Markdown include、图片和允许的静态资源写入 `assets.jsonl`/blob store。Resolver 限制 allowed roots、include cycle、递归深度、单文件/总大小，并对 dependency/stdlib 中不可信的 raw HTML 和危险 MyST directive 使用 allowlist/sanitizer。Strict build 遇到缺失资源、越界路径或未冻结 include 时失败。

同一 child source 被 include 多次时，展示 occurrence 使用 instance-scoped anchor，例如 `#inc-<instance-id>-L42`，避免重复 DOM ID；该 symbol 的 canonical Definition URL 始终指向 child source 自己的 canonical page/definition anchor，而不是父 literate page 的 include occurrence。

`moonbit check` 是仓库中仍在使用的兼容写法；`moonbit skip` 则是对应的跳过写法。最终是否附加语义仍以 snapshot occurrence 为准，不能只根据 fence 名称猜测。`nocheck`/`skip` 代码正常显示但不能有伪 Hover 或伪 Definition。

### 7.5 Additional page 的“一等”边界

`html-collect-pages` 产生的页面不是普通 source docname，默认不会自动进入 toctree、Sphinx prose search，`hasdoc()` 也不会把它当普通文档。纯源码页直接由 semantic renderer 生成；`.mbt.md` 先生成 extension-owned virtual doctree，再把渲染结果交给 additional-page template。

第一版明确选择 viewcode-style additional pages，并用以下方式补齐一等导航能力：

- MoonBit domain index；
- 全局 Source 入口；
- module/package/file 层级索引；
- `objects.inv`；
- breadcrumb 和 docs backlinks。

不在 source tree 中生成临时 Markdown stub。Phase 1 不承诺把 additional pages 注入原生 Sphinx prose search；Phase 4 再实现独立 symbol search 或显式接入 HTML search index。全局 Source 入口由扩展提供的窄范围 template block override 实现，并用当前 `sphinx_book_theme` 版本做快照测试，不能只在 `html-page-context` 放一个无人消费的变量。

## 8. `.mooncakes`、dependency、stdlib 与发布策略

### 8.1 `.mooncakes` 是第一等 page-corpus 输入

`.mooncakes` 不能被忽略。它是当前工程实际解析出的 registry dependency source tree，也是 cross-package Definition 的主要目标之一。当前里程碑把它作为第一等冻结源码与路由输入，但暂不把其中源码作为 occurrence analysis 起点。

正确边界是：

```text
分析阶段
  packages.json / resolution lock
    → 定位每个 root 的 .mooncakes 中的精确 module/version/package
    → 枚举全部 provider-recognized source
    → 固化 blob、route、版本和 tree digest
    → 解析 local Definition 返回的 dependency target
    → 不枚举 dependency token，不请求其 Hover/Definition

Sphinx 阶段
  只消费上述 snapshot
  不重新读取活动 .mooncakes
```

“Sphinx 不重新读取 `.mooncakes`”不是忽略依赖，而是防止分析后 cache 被升级、清理或换成另一版本。Indexer 必须把 `.mooncakes` 当作显式 allowed root，并完成以下工作：

- 从 package metadata 而不是目录名猜测 module/package identity；
- 记录 `.mooncakes` alias、canonical realpath、module、resolved version/revision 和 source tree digest；
- 对 resolution lock 中每个 dependency module 的全部 provider-recognized source 建 page inventory，不只收集恰好被某次 Definition 命中的文件；
- 当前以 `deferred-by-origin-policy` 记录这些文件，不为其建立 occurrence request ledger；
- 把所有 dependency source blob 复制进 content-addressed snapshot；
- 为每个 dependency 文件生成本站版本化 source/literate page；
- 让从 local/standalone occurrence 出发的跨 package Definition 只指向这些本站页面和锚点。

长期全量模式再使用 consumer context 或 dependency 自身可复现的 module context 分析这些文件并持久化 occurrence。这个变化只扩大 analysis origin，不改变依赖发现、blob、source identity、route 或已存在的入站 Definition edge。

不同 root 的 `.mooncakes` 可能包含同一 module/version。Tree digest 相同则共享 blob/page identity；相同 version 但 digest 不同必须视为 resolution conflict 并在 production 中失败。

Path dependency 使用同一规则：从 package metadata/resolution lock 确认 module root，扫描该 root 的全部 provider-recognized source，并用 commit ID 或 module tree digest 固化身份。它不能因为不位于 `.mooncakes` 就只收当前 consumer 恰好编译到的几个文件。

### 8.2 完整 stdlib source corpus，当前 display-only

Stdlib 也不是 Definition 命中时才临时补一个文件。索引器从 pinned MoonBit toolchain 纳入该发行版中全部 provider-recognized source，并为每个文件生成版本化本站页面。当前里程碑不启动独立 stdlib/core LSP occurrence analysis；stdlib 页面是可承接 local Definition 的 display-only 冻结页面。

Snapshot 记录：

- toolchain/core build ID；
- stdlib/core tree digest；
- core bundle/`.mi`/IDE semantic artifacts 的 digest；
- `moon-lsp`、`moonc` 和相关 provider executable digest；
- backend 与 build profile；
- package、相对路径、source kind 和 blob digest；
- 当前分析策略 `deferred-by-origin-policy`；
- local occurrence 返回的入站 Definition target 与 target-only anchor；
- 长期全量模式所需的 canonical analysis context fingerprint。

当前里程碑只要求验证 consumer LSP 使用的 stdlib semantic artifacts 与 pinned toolchain/source identity 一致，并校验每个入站 target 落在冻结 blob 内；不遍历 stdlib token，也不生成 stdlib 内部引用图。长期全量模式在不可变 toolchain snapshot 中重新 bundle/check core，或验证现有 semantic artifacts 明确由相同 core source tree 产生，不能把新 source tree 与旧 `.mi`/bundle 混用。Toolchain 升级会整体失效 stdlib pages 和所有指向它们的 Definition edge；启用全量后也会失效 stdlib Hover/occurrence overlay。

### 8.3 License 是前置 gate，不是外链降级

Dependency 与 stdlib 源码必须进入本站页面，因此 license/attribution policy 在 Phase 0 固定、在写 public snapshot 前执行。若某项许可不允许该发布方式，production full-source build 必须失败并解决许可问题；不能用 GitHub URL 或 `external-only` 标记冒充“已经包括”。

Snapshot 至少记录 module、version/revision、repository、license、normalized path、exact blob digest 和 attribution metadata。分析可以在私有临时目录中进行，但交给 Sphinx 的 public snapshot 只在完整 license gate 通过后产生。

### 8.4 Source-page UI 与 attribution

纯源码页的主内容只展示代码；`.mbt.md` 页面保留 literate prose。依赖的 module/version/license/repository 可以放在紧凑 header 或 footer，不进入 `<pre>`，也不影响复制文本。若 license 要求包含完整文本，则链接到独立 attribution 页面，而不是把许可正文插入每个源码页。

## 9. Error-code、无效源码与降级策略

分析策略显式分为：

```text
required          active local/standalone 健康工程和 *_fixed，完整语义是发布要求
expected-failure  故意触发诊断的 *_error
display-only      deferred dependency/stdlib、nocheck、无法形成可靠 semantic context 的片段
```

第一版策略：

- active `required` root 分析失败时，production semantic build 失败，且不得复用旧 occurrence；deferred origin 不启动分析，也不产生这一失败状态；
- `expected-failure` 仍保存精确 blob、diagnostic 状态并按文件类型生成纯源码页或 literate page；初版不发布未经验证的 recovery semantics；
- `_fixed` 工程按 `required` 完整分析；
- `display-only` 仍生成词法页面或普通代码块，但 occurrence 为空；
- 健康 root 的 Definition 如果指向 expected-failure 文件，仍可跳到该文件的可信行锚点；
- recovery semantics 后续只有在建立独立正确性测试后才逐项启用，绝不将上一次成功构建的语义覆盖到新失败源码。

分类应来自 error-code inventory 或显式索引配置，不依赖临时目录名猜测。Expected-failure 的 source inventory 在 check barrier 之前建立，因此即使失败检查没有生成 `packages.json`，所有 recognized source 仍有 blob 和页面。

Diagnostics 至少保存 code、severity、message、raw/normalized half-open range、toolchain、expected pattern 和 match status，不能只保存一个 failure reason。现有 [`next/check_error_docs.py`](../next/check_error_docs.py) 继续作为 expected diagnostic 的权威校验，语义索引器不取代它。

## 10. Builder、i18n 与现有行为边界

| Builder | 语义扩展行为 |
|---|---|
| `html` | 启用 active 文档语义代码块、全部 source pages、active hover/definition 和 index |
| `dirhtml` | 与 `html` 相同的 active/deferred 范围，所有 URI 经 builder API 计算 |
| `singlehtml` | 初版不支持独立 source topology；退化并给出一次 warning |
| `epub` | 不生成 source pages/JS，保留普通代码块 |
| `latex` / PDF | 保留原 literal block，不输出 HTML-only link |
| `markdown` | 保持原输出；[`next/llm.py`](../next/llm.py) 不受影响 |
| `gettext` | 不收集 generated source pages；保留现有 literal-block gettext 行为 |
| `linkcheck` | 不注入尚未生成的内部 source-page link，保持成功 |
| 其他 builder | 默认原 node fallback |

不能仅判断 `builder.format == "html"`，因为 EPUB 等 builder 也可能属于 HTML family；第一版使用明确白名单 `{"html", "dirhtml"}`。

“非目标 builder 保持等价”的可测试不变量是：literal block 的可见文本、language、caption、现有 link 集合和 gettext msgid 集合不变。Markdown/HTML 使用 normalized golden；PDF/EPUB 验证构建成功并抽取代码文本比较，不要求包含时间戳等环境信息的二进制产物 byte-for-byte 相同。

I18n 规则：

- 文档 code block 继续遵循当前 `gettext_additional_targets = ["literal-block"]`；
- semantic annotation 在 locale transform 后检查最终 display text hash；翻译改变代码时该 block 退化为普通高亮；
- generated source text、identifier、源码注释和原始 hover 不进入 gettext；
- canonical `.mbt.md` literate page 展示文件自身的原始 Markdown prose，不从文档 PO catalog 替换；若未来需要 localized literate pages，使用独立 locale URL，不能覆盖 canonical source coordinates；
- “Source”“Defined at”“Used by”等扩展 UI chrome 使用扩展自身的 locale catalog；
- 各 locale 使用相同 source pagename，文档到源码的链接保持稳定。

## 11. 构建、CI 与持久化交付

常规 Sphinx build 只消费 snapshot。建议新增独立命令和流水线：

```text
semantic-index
  → resolve/check/freeze complete page corpus
  → analyze active local/standalone origins
  → validate/atomically publish semantic-snapshot

docs-html
  → download or locate snapshot for current commit/toolchain/backend
  → Sphinx HTML render
```

本地开发模式：

- snapshot 缺失或过期时默认 warning，并完全退化为当前文档体验；
- 提供显式 `semantic-index` 和 `semantic-watch` recipe；
- `docs-watch` 可选并行启动 snapshot watcher，但 Sphinx 进程本身不启动 LSP；
- snapshot shard 注册为 Sphinx dependency，使索引更新触发相关页面重建。

Production 模式：

- `moonbit_semantic_required = true` 只对 `html/dirhtml` 生效，不能让 Markdown、EPUB、PDF 或 linkcheck 因语义 snapshot 缺失而失败；
- schema、corpus fingerprint、blob、source-page count、definition closure 或 license policy 不满足时失败；
- snapshot artifact 必须与当前 commit、pinned toolchain、backend 匹配；
- RTD 可以下载由专门 CI job 生成并签名/校验 digest 的 artifact；备选方案是在 RTD pre-build 安装 pinned toolchain 并运行同一索引命令（包括 `.mooncakes` 与 stdlib capture），但不能混入 Sphinx read/write phase；
- source artifact 不建议直接提交大量 dependency blob 到 Git，使用 CI artifact/object storage 和 content-addressed cache。

RTD/production 的唯一顺序固定为：

1. 下载或生成并完整校验 snapshot；
2. 运行 [`next/llm.py`](../next/llm.py)，其中 Markdown builder 强制 semantic HTML no-op；
3. 运行 strict `html` build，生成文档页、纯源码页、literate pages 和 hover assets；
4. EPUB/PDF 等后续 builder 继续走原节点 fallback。

现有 [`justfile`](../justfile) 的普通 `docs-html` 保持可用并允许无 snapshot 退化；实施时新增 `just semantic-index`、`just docs-html-semantic` 和 `just semantic-check`，其中 `docs-html-semantic` 是 release/RTD 的 production 入口，但不改写现有文档内容。

### 11.1 当前 clean-build 性能预算

2026-07-11 的首个 strict local-first baseline 实际冻结 2,075 个源码页面，在 279 个 active context 中完成 17,665 个 identifier request；相对原全量约 337,210 个 candidate，逐 occurrence LSP 工作量只剩约 5.2%。Dependency/stdlib 的源码枚举、hash、blob 固化与页面生成仍完整执行，但不再产生自身的逐 occurrence LSP RPC。

当前里程碑的 clean-build 预算如下；它是需要由 CI 报告验证的工程预算，不是以跳过正确性检查换取的软目标：

| 阶段 | 当前预计 | 2026-07-11 strict baseline |
|---|---:|---:|
| local root check、resolved graph 与完整 corpus 固化 | 1–2.5 分钟 | 27.5 秒 |
| active candidate + Hover + Definition capture | 2–3.5 分钟 | 约 176.1 秒 |
| snapshot 校验与原子发布 | 5–20 秒 | 约 5.0 秒 |
| Sphinx HTML（含全部冻结源码页） | 1–2 分钟 | 85.28 秒 |
| semantic snapshot only | 约 3–6 分钟 | 208.6 秒 |
| 完整 clean semantic HTML | 约 4–8 分钟，保守上限 10 分钟 | 293.9 秒（约 4 分 54 秒） |

性能报告必须分别记录 corpus discovery/hash、check barrier、candidate collection、LSP capture、snapshot write/validate 和 Sphinx render，不能只提供总时长。超过 10 分钟时先按 context/source/candidate/request 吞吐定位回归，不通过继续排除 source origin 来掩盖问题。

## 12. 缓存与失效

第一版使用 root-wide semantic fingerprint，正确性稳定后再优化到 package/file shard。Fingerprint 至少包含：

- snapshot schema 和 projection/parser version；
- `moon version --all`、`moon-lsp` 版本以及无独立版本工具的 executable digest；
- selected backend、target 和 opt level；
- `moon.work`、全部 `moon.mod*` 和 `moon.pkg*` 内容；
- 参与分析的 source digest；
- normalized package graph；
- dependency resolved version/revision/tree digest；
- stdlib/toolchain digest；
- `analysis_origin` policy（当前 local/workspace/standalone；长期再加入 dependency/stdlib）；
- expected-failure/display-only policy。

可独立缓存：

- raw blob：按 SHA-256 长期复用；
- dependency/stdlib bundle：按 module version/toolchain ID 复用；
- lexical source-page base：`blob + projection + lexer + template version`；
- semantic overlay：`root fingerprint + source_id + occurrence digest`；
- hover shard：按 payload digest 去重。

关键失效语义：

- dependency API 或版本变化会失效消费者 occurrence 和 dependency page；当前不会触发 dependency 自身 occurrence 重算，因为它不存在；
- toolchain 变化会失效全部 active semantics 和 stdlib page；
- 扩大 `analysis_origin` 会新增 dependency/stdlib semantic overlay，但不改变内容相同的冻结 blob/page route；
- `.mbt.md` prose 在代码前增加一行会改变原始 line anchor，因此该文件 snapshot 必须失效；
- 只有普通文档 prose 变化且 source 不变时，不重跑 MoonBit 分析；
- 只有 CSS/template 变化时，只重渲染 HTML，不重跑 LSP。

## 13. 实施阶段与交付门槛

### Phase 0：可行性 spike

目标是消除 MoonBit provider 和 range mapping 的主要不确定性。

交付物：

- 一个 root 的 `moon check -> package adapter -> moon-lsp` 原型；
- 普通 `.mbt` 与 Sudoku `.mbt.md` 的 UTF-16/UTF-8 range fixture；
- local、workspace dependency、registry dependency、stdlib 各一个 Definition fixture；
- 一个 snapshot schema fixture；
- 一个纯 `.mbt` 的 Hackage 风格页面原型和一个保留 prose 的 `.mbt.md` literate page 原型。

退出条件：

- 同一输入重复生成相同 source ID、symbol ID 和 occurrence；
- 同一 checkout 位于两个不同绝对路径时生成 byte-for-byte 相同的 public snapshot；
- Unicode/emoji 后的 token range 精确；
- `LocationLink` 的 origin/target/target-selection ranges 能完整 round-trip；
- check 与 LSP 之间修改源码时 digest barrier 能检测并中止；
- Sudoku 的 Markdown prose 正常保留，原始 code position 能映射到渲染后的语义 code block；
- 所有 Definition fixture 均得到可规范化 source identity；
- dependency/stdlib license 与 attribution policy 已固定，不允许 external-only 替代；
- `.mbt/.mbt.md/.mbti/.mbtp` 的 provider/display policy 已固定。

### Phase 1（当前目标）：自包含 snapshot、完整冻结源码页与 local-first 语义

这是首个产品增量，并优先解决当前完全没有覆盖的源码页。

交付物：

- 正式索引 CLI、metadata adapter、snapshot writer/validator；
- local/workspace source、resolution lock 中全部 `.mooncakes` 与 path dependency module roots，以及 pinned toolchain 完整 stdlib/core source bundle；
- Sphinx extension skeleton、MoonBit domain 和 `html-collect-pages`；
- module/package/file index；
- `.mbt/.mbti/.mbtp` 和 generated pure-source kinds 的 code-only source pages，以及 `.mbt.md` 的完整 literate source pages；
- 对 local/workspace/standalone required source 建立 Hover、Definition 和完整 request ledger；
- dependency/stdlib 页面保持 display-only，但具有行锚点和 local Definition 实际命中的 target-only anchor；
- 从 local/standalone occurrence 到 local、dependency 或 stdlib 冻结源码页的跨 package Definition 链接；
- manifest 中显式、可审计的 `analysis_origin` policy 和 `deferred-by-origin-policy` coverage。

退出条件：

- 删除工作树、`.mooncakes` 和 `$MOON_HOME` 后，只从 snapshot 仍能生成全部 source pages；
- generated source pages 与 `snapshot.sources` 一一对应；
- 每个 active local/standalone required context 返回的 `file://` Definition 都解析为本站 snapshot source page，包括 dependency/stdlib target；无文件位置的语言 builtin 必须显式记录 `no_source_definition`；
- 每个 active snapshot Definition 恰好生成一个 definition 或 target-only anchor，每个 Definition edge 命中存在的 page/anchor 或静态 target-set page；
- 每个 active occurrence 引用的 hover ID 都能从声明的 shard 加载，每个 active required request ledger 都是 complete；
- dependency/stdlib 没有 occurrence/request shard，coverage 将其报告为 deferred 而不是 complete 或 error；
- 构建日志与测试证明没有为 dependency/stdlib origin 启动独立 LSP analysis session；
- dependency/stdlib 页面没有自身扫描得到的 `data-mbt-hover` 或引用图；允许 local 入站 Definition 为命中的 target 合成 definition occurrence/anchor；
- 每个 Definition target 的原始行都实际出现在对应纯源码页或 literate code block 中；
- 禁用 JavaScript 后 Definition 仍可用；
- `.mbt.md` 页面保留并正确渲染 prose，front matter 作为元数据处理；active local/standalone MoonBit code block 带原始行锚点和语义信息，deferred origin 只带原始行锚点。

### Phase 2：文档 `literalinclude` 语义增强

交付物：

- 同名 `literalinclude` override；
- 精确 provenance segment map；
- semantic literal node 和共享 renderer；
- 文档 block 中 token 到 canonical source page/anchor 的 Definition link；不增加独立 `View source` 控件；
- copybutton、caption、选区和 textContent 兼容测试。

退出条件：

- 当前所有使用中的 slice/dedent/prepend/append option 有 golden fixture；
- synthetic 行永远不获得伪 source range；
- 同一源码被多页重复 include 时全部指向同一 canonical source page；
- 增强前后每个 block 的可复制文本完全相同。

### Phase 3：`.mbt.md` include、i18n 与全 builder 稳定性

交付物：

- 整篇 literate include 的 block provenance；
- EN、zh_CN、ja HTML 支持；
- Markdown、gettext、PDF/LaTeX、EPUB、linkcheck fallback；
- locale UI catalog；
- `-j` 并行和 incremental rebuild 支持。

退出条件：

- 三个 locale 的 source URL 一致；
- 翻译改变 code block 时只降级对应 block，不错位链接；
- 所有非目标 builder 与扩展关闭时输出等价且成功；
- snapshot shard 变化只重建受影响页面。

### Phase 4：覆盖扩展与错误工程

交付物：

- expected-failure recovery semantics 的独立实验和正确性 gate；
- 多 backend snapshot/merge 策略；
- symbol search、docs backlinks 和同 href 联动高亮。

退出条件：

- 普通 Markdown fence 维持 lexical-only；具有 provenance 的 block 若没有语义增强，则有机器可读 reason；
- recovery semantics 不会在 source 改变后残留；
- 多 backend 冲突有确定的展示和 target 规则；
- local binding shadowing 和多个 Definition target 的端到端测试通过。

### Phase 5：生产发布与性能收敛

交付物：

- 独立 semantic CI job 和 artifact 传递；
- strict production mode；
- content-addressed cache、page/hover shard；
- Phase 0 license policy 的自动执行、attribution page 和审计报告；
- 构建耗时、页面体积和覆盖率 dashboard。

退出条件：

- clean CI 可以稳定复现 snapshot 和 HTML；
- 当前 local-first 完整 clean semantic HTML 满足 4–8 分钟目标，并以 10 分钟为回归 gate；
- snapshot 不完整、悬空 definition、缺 blob、路径泄漏或 page count 不一致会失败；
- source HTML、hover payload 和内部 target URL 通过安全检查；
- 性能预算和 artifact retention policy 已固定。

### Phase 6（长期目标）：恢复 dependency/stdlib occurrence analysis

交付物：

- 将 resolved dependency、path dependency 和 pinned stdlib required contexts 加入 `analysis_origin` allowlist；
- 为这些 context 建立与 local 完全相同的 candidate ledger、Hover、Definition 和 semantic overlay；
- dependency 自身独立 context、额外 dev/test dependency 与 stdlib/core semantic root 的可复现构建；
- 面向全量规模的批量 compiler/provider API 或等价缓存与调度优化。

退出条件：

- 不修改 snapshot schema、source identity、canonical route、Sphinx renderer contract 或现有 local Definition edge，即可为原 display-only 页面叠加语义；
- dependency/stdlib active required ledger 全部 complete，页面中的 Hover/Definition 与 local 页面遵守同一正确性标准；
- 全量语义模式拥有单独测量并固定的性能预算，不能降低 Phase 1 local-first 发布的默认速度；
- stdlib LSP/provider crash、版本不匹配和未完成 request 都 fail closed，不回退到旧 overlay。

## 14. 测试矩阵

### 14.1 Snapshot 与 source pages

- local、workspace、path dependency、完整 `.mooncakes` registry dependency、完整 pinned stdlib、generated source 的 page corpus；
- 当前 origin policy 只为 local/workspace/standalone required source 产生 candidate/request/occurrence，dependency/stdlib source 计入 deferred 且 request 数为零；
- local occurrence 分别 Definition 到 local、`.mooncakes` dependency、path dependency 和 stdlib，所有链接都命中冻结本站页面的精确 target-only anchor 或行锚点；
- dependency/stdlib 页面不存在自身扫描得到的 Hover payload 与引用图，仍保留完整代码、行锚点，并可包含 local 入站 target 合成的 definition occurrence；
- 把 dependency/stdlib 加入测试用 `analysis_origin` 后，同一 fixture 无 schema/route 变化即可获得 overlay；
- `.mbt`、`.mbt.md`、`.mbti`、`.mbtp` 的页面与 provider policy；
- public function/type/trait/method、field/constructor、operator、local binding 和 shadowing；
- 同文件、跨文件、跨 package、跨 module 和多个 Definition target；
- 长期全量模式：同一 dependency 文件从两个 root/file-role/backend 分析，context occurrence 不互相覆盖；
- Unicode identifier、emoji、CRLF、tab；
- `.mbt.md` prose/heading/link/include/image、多 fence、list/blockquote fence、原始行列、`mbt nocheck`、兼容的 `moonbit check/skip`；
- literate include/image/resource closure 离线可重建；缺失、越界、循环 include 和危险 directive 被 strict policy 拒绝；
- dependency version 和 toolchain upgrade 会同时失效冻结 target page 与 active consumer edge；
- 相同 dependency version 但 tree digest 不同；symlink/URI alias 仍解析为同一 source page；
- LSP timeout/crash、未完成 request ledger、check 后源码变化；
- expected-failure 与 fixed pair；
- dependency/stdlib license gate 拒绝与 attribution；
- clean output 中 stale `_moonbit-source` page 清理；
- 修改一个从未被文档引用的 source，incremental build 仍更新其 additional page；
- 手工删除未引用 source page、target-set page、hover preload/JSON 或 semantic CSS/runtime JS 后，incremental build 自动恢复。

### 14.2 文档 projection

- `start-after/end-before`；
- `start-at/end-at`；
- `dedent`；
- `prepend/append`；
- 同一文件多个 slice 和多个页面；
- 完整 Sudoku `.mbt.md` include；
- literate page 保留 prose，include 展开后每个代码块仍指向自己的 source identity；
- 同一 child source include 两次时没有重复 DOM ID，两个 occurrence 使用 scoped anchor，而 canonical Definition URL 不变；
- raw Markdown literalinclude；
- 普通 Markdown fence 保持 lexical-only，`.mbt.md`/`literalinclude` provenance block 才允许语义 overlay；
- translated literal block；
- stale/missing snapshot；
- copybutton 和 `<pre>.textContent` 精确一致。

### 14.3 Builders 与运行时

- `html`、`dirhtml`；
- EN、zh_CN、ja；
- Markdown、gettext、LaTeX/PDF、EPUB、linkcheck；
- clean build、incremental build、parallel build；
- JavaScript disabled；
- JavaScript disabled 时的多个 Definition 静态 target-set page；
- keyboard、touch、screen reader；
- CSP、HTML escaping、hover Markdown sanitization；
- HTML/dirhtml 实际存在并引用 semantic CSS/JS/hover assets，EPUB/PDF 不引用它们；
- 所有内部 Definition URL 和 anchor 的 link audit。

## 15. 可观测性与覆盖报告

每次 semantic build 生成一份机器可读和人类可读报告，至少包含：

- discovered roots、packages 和 sources；
- 每个 `.mooncakes` module/version/tree digest 的 package/source/page 数，以及 pinned stdlib 的总 package/source/page 数；
- 生效的 `analysis_origin` policy；
- `page_corpus_count`、`active_analysis_source_count`、`semantic_complete_count`、`deferred_by_origin_count`、`expected_failure_count`、`display_only_count`；
- source pages 计划数和实际生成数；
- 按 source origin/context 分组的 analyzed occurrences、hover、definitions，以及 local-to-dependency/stdlib edge 数；
- candidate request ledger 的 complete/no-result/skipped/error 数；
- unresolved/multiple/no-source definitions；
- 文档 code block 总数、成功映射数和降级原因；
- cache hit rate，以及 corpus discovery/hash、check、candidate collection、LSP capture、snapshot validation、Sphinx render 的分阶段耗时；
- active candidate 总数、每 session/context 吞吐、最长 context/source 和 clean 总用时是否超过 10 分钟 gate；
- snapshot 和 HTML payload 大小；
- license gate、绝对路径泄漏和 stale shard 检查。

这份报告使“所有可以被语义分析的代码”成为可衡量的覆盖目标，而不是无法验证的承诺。

## 16. 主要风险与缓解

| 风险 | 缓解 |
|---|---|
| LSP/IDE metadata 快速变化 | provider adapter、自有 schema、版本 fixture、tool executable digest |
| 逐 token LSP 请求过慢 | 当前只分析 local/workspace/standalone origins，并保持完整 target corpus；长期 session、候选过滤、受控并发、root/package cache；恢复全量前推动批量 compiler API |
| stdlib/dependency provider 崩溃拖垮首个可用版本 | 当前不从这些 origin 发起 occurrence 请求；local 入站 target 仍严格校验；Phase 6 单独以 fail-closed fixture 恢复 |
| 依赖源码在 Sphinx 环境消失 | snapshot 携带 content-addressed source blobs |
| 第三方源码再发布限制 | Phase 0 license gate、attribution；不满足时阻止 full-source 发布，不用外链伪装覆盖 |
| `_error` 工程无法完整类型检查 | 页面始终生成；初版 display-only；recovery 单独验证 |
| `literalinclude` provenance 复杂 | directive override 和与 pin Sphinx 行为一致的 golden suite |
| Pygments 与 semantic range 交叉 | 在原文本 range 边界上统一分段，不后处理 HTML |
| Sphinx additional page 不属于普通 toctree | domain/index/search/Source 入口；不生成源 Markdown stub |
| 多 builder 泄漏 custom node | HTML builder 白名单、post-transform、原 node fallback |
| i18n 改写代码导致错位 | 以最终 display text hash 校验并逐块降级 |
| 增量和并行状态不一致 | digest dependency、env purge/merge、可 pickle state、原子 snapshot |
| URL/anchor 漂移 | canonical source identity、版本化 dependency route、稳定 symbol digest |
| Hover 内容或依赖源码注入 HTML | 全量 escape、受限 Markdown sanitizer、URL scheme allowlist |
| 页面和 artifact 体积增长 | 完整收录 resolution lock 中每个 dependency module root 与 pinned stdlib/core root 的 recognized source，只排除相邻未解析 cache/workspace 和内部构建产物；再用 blob 去重、hover/page sharding 控制体积 |

## 17. 需要在 Phase 0 固定的决策

以下决策不阻碍当前架构，但必须在 Phase 0 用 fixture 和测量固定：

1. 首个 production snapshot 的 canonical backend，以及何时引入多 backend；
2. dependency/stdlib license 与 attribution policy；该模式不允许用 `external-only` 替代本站源码页；
3. source URL 是否包含 docs release/corpus digest，还是仅由 module version/toolchain identity 隔离；
4. Hover 允许的 Markdown 子集和最大 payload；
5. 普通 inline fence 不推断 context、不生成 virtual source；语义范围严格限于文学编程/源码 provenance；
6. source symbol 是否注入 Sphinx HTML search，或只进入独立 MoonBit domain search；
7. 当前 local-first clean production build 使用 4–8 分钟目标/10 分钟 gate；Phase 6 全量模式另行测量并固定页面数、artifact 大小和索引时间预算。

## 18. 完成定义

### 18.1 当前 local-first 里程碑

当且仅当下列条件同时满足，才能认为当前里程碑完整交付：

- 现有 Markdown 和被引用 MoonBit 源码没有为了语义文档而发生内容变更；
- snapshot 对分析时的源码、依赖、toolchain 和 backend 是自包含且可复现的；
- resolution lock 中全部 `.mooncakes`/path dependency module roots 的 recognized source 与 pinned toolchain 完整 stdlib/core source 都在 snapshot 中并拥有本站页面；
- 所有 `snapshot.sources` 都有与文件类型匹配的 canonical source/literate page；
- manifest 将 active local/workspace/standalone origin 与 deferred dependency/stdlib origin 明确分开，coverage 数量守恒；
- 所有 active required context 的 candidate request ledger 完整，file-based Definition target 都有有效的本站 source page/anchor；无源码的 builtin 有显式 `no_source_definition`；
- local occurrence 指向 dependency/stdlib 时仍链接到冻结本站源码页的精确 target-only anchor 或行锚点；
- dependency/stdlib 页面完整展示代码，但没有自身 occurrence Hover/Definition overlay，也没有伪造的 complete ledger；
- 对 active occurrence，文档代码块与源码页显示一致 Hover 和 Definition；
- 普通 Markdown 中没有文学编程/源码 provenance 的 code fence 按设计保持词法高亮，不生成 synthetic source 或伪语义；
- `.mbt/.mbti/.mbtp` 等 pure-source page 只显示代码；`.mbt.md` literate page 保留 Markdown prose，并使用原始 Markdown 行号；active origin 的 code block 叠加语义，deferred origin 的 code block 保持词法显示；
- JavaScript 禁用后 Go to definition 仍工作；
- 无语义或故意无效代码不会获得伪语义；
- EN/zh_CN/ja HTML 正常，其他 builder 保持现有行为；
- copybutton、选择文本和 `<pre>.textContent` 与增强前一致；
- 生产构建能够检测 snapshot 不完整、悬空链接、缺 blob、绝对路径泄漏、license gate 违反和 stale pages；
- 当前规模的 clean semantic HTML 在正常 CI 资源上满足 4–8 分钟目标，并以 10 分钟为性能回归 gate。

### 18.2 长期全量语义目标

长期完整交付在当前里程碑全部条件之上，再要求：

- dependency 与 stdlib required contexts 进入 active analysis corpus；
- 它们的 candidate request ledger 与 local 使用相同完整性规则；
- dependency/stdlib 源码页获得自己的 Hover、Definition 和 canonical occurrence overlay；
- 放开 analysis origin 不改变既有 snapshot schema、source/page identity、URL、anchor contract 或 local-to-external Definition edge；
- 全量模式通过独立的 provider 稳定性、可复现性与性能预算 gate。

## 19. 参考实现

- [Hackage `Data.List` hyperlinked source page](https://hackage.haskell.org/package/base-4.21.0.0/docs/src/Data.List.html#compareLength)
- [Haddock `--hyperlinked-source`](https://haskell-haddock.readthedocs.io/latest/invoking.html#cmdoption-hyperlinked-source)
- [Haddock hyperlink renderer](https://github.com/haskell/haddock/blob/395f33bfc14b5a28a14705a559f7f86d0599ab8c/haddock-api/src/Haddock/Backends/Hyperlinker/Renderer.hs#L131-L294)
- [Koka semantic `RangeMap`](https://github.com/koka-lang/koka/blob/429f578512ba7229ec86a2389d4d2481100d17bc/src/Syntax/RangeMap.hs#L68-L190)
- [Koka literate range overlay](https://github.com/koka-lang/koka/blob/429f578512ba7229ec86a2389d4d2481100d17bc/src/Syntax/Colorize.hs#L121-L176)
- [Koka popup 与 token 样式](https://github.com/koka-lang/koka/blob/dev/doc/koka.css#L156-L283)
- [Lean Verso](https://reservoir.lean-lang.org/%40leanprover/verso)
- [Verso highlighted code 数据模型](https://github.com/leanprover/verso/blob/main/src/verso/Verso/Code/Highlighted.lean)
- [Verso semantic CSS variables](https://github.com/leanprover/verso/blob/main/static-web/verso-vars.css)
- [Verso Literate source page 样式](https://github.com/leanprover/verso/blob/main/src/verso-literate-html/literate.css)
- [LSP 3.17 Hover](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_hover)
- [LSP 3.17 Definition](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition)

## 20. 展示层计划：只复用现有文档主题与高亮

### 20.1 最终边界

现有 Sphinx 文档站的代码高亮就是本项目唯一的高亮实现。本计划没有、也不预留任何“改进高亮质量”的工作：

- 不修改 MoonBit lexer；
- 不调整 Pygments token 分类或颜色；
- 不新增 token palette；
- 不新增 lexical shard；
- 不请求 semanticTokens/documentSymbol 来改变颜色；
- 不做 function、method、trait、field 等 semantic coloring；
- 不为源码页或 Hover 建立第二套 highlighter。

当前只解决两个展示层集成问题：

1. standalone 源码页已经输出 Pygments class 并加载 pygments.css，但没有满足文档主题的 data-theme 合同，因此同一份颜色规则没有命中；
2. Hover payload 是完整 Markdown，当前 runtime 却用 textContent 把它显示成原始文本，因此段落、列表、分隔线、链接和内部 code fence 都没有被渲染。

这两项都只复用既有 Sphinx/MyST/Pygments 结果，不扩张语义分析输入，不修改 snapshot schema，也不重跑 MoonBit LSP。

### 20.2 唯一高亮合同

普通文档 code fence 当前使用以下合同：

~~~text
MyST Markdown
  → docutils literal_block
  → Sphinx HTML translator/highlighter
  → 当前注册的 MoonBit lexer（moonbit / mbt）
  → Pygments token class
  → highlight-moonbit notranslate > highlight > pre
  → 构建生成的同一个 _static/pygments.css
  → html[data-theme="light|dark"]
~~~

源码页、文档中的 semantic block 和 Hover 内的 code fence 都必须复用这份合同。

| 展示面 | 代码来源 | 允许增加的内容 | 禁止变化 |
|---|---|---|---|
| 普通文档 fence | MyST literal_block | 无 | 现有 HTML、class、颜色和主题行为 |
| semantic document block | 有 provenance 的冻结源码 | Hover/Definition 属性与 href | 词法 class、token 颜色 |
| pure/literate source page | 冻结源码 | 行锚点、定义锚点、Hover/Definition 属性 | lexer、formatter class、token 颜色 |
| Hover Markdown fence | LSP MarkupContent 中的 literal_block | Markdown 容器与 popover shell | 词法 class、token 颜色；不得增加 semantic overlay |

“复用”必须可测试，而不是仅仅肉眼相似：

- 同一 MoonBit fixture 在普通 fence、semantic block、pure source page、literate source page 和 Hover fence 中具有相同的 Pygments class 序列；
- 外层 code wrapper 与普通文档保持相同的 class contract；
- 所有页面引用构建生成的同一个 pygments.css；
- light/dark 由相同的 data-theme 值选择；
- source/semantic/Hover CSS 不包含 .k、.kd、.nf、.nc、.nv、.s、.m 等 token 配色规则。

SemanticCodeRenderer 仍需要在原始文本 range 上插入链接和 Hover 属性，因此不能把已经生成的 Pygments HTML 再用字符串或正则后处理。它的 lexical 层必须直接使用 Sphinx 当前注册的 lexer 与 HtmlFormatter class mapping；semantic 层只把同一个 lexical class 附加到对应的 a/span 上。

### 20.3 Standalone 源码页如何直接复用文档方案

当前源码页已经接近完成复用：

- SemanticCodeRenderer 使用 Sphinx 注册表中的 MoonBit lexer；
- 输出 kd、nf、nc、nv 等与文档 fence 相同的 Pygments class；
- 外层已经是 highlight-moonbit notranslate、highlight、pre；
- 页面已经链接 _static/pygments.css。

缺失的是主题与 Markdown shell，而不是另一个 highlighter。

#### 20.3.1 Theme contract

standalone 页在加载样式前执行与文档站一致的 theme 初始化：

1. 读取文档主题使用的 mode/theme preference；
2. 显式 light/dark 时直接设置 documentElement.dataset.theme；
3. auto、缺失或 file:// 下无法共享 preference 时使用 prefers-color-scheme；
4. 首次绘制前得到有效的 light 或 dark，避免无色首屏和主题闪烁；
5. 后续若支持主题切换，继续使用文档站同一组 storage key 和 data attribute。

源码页继续链接 builder 实际生成的 pygments.css，不复制其中任何颜色。

#### 20.3.2 Theme assets

纯源码页面保持 Hackage 式轻量 DOM，不生成导航栏、侧栏、搜索或 View Source。但它应复用 builder 已解析出的文档主题 CSS 资产，而不是硬编码某个 theme 版本的文件名：

- pygments.css 提供 code fence 的现有 light/dark 高亮；
- builder 当前的 PyData/Sphinx Book Theme CSS 提供 Markdown typography、CSS variables、inline code、list、blockquote、table 和 link 样式；
- standalone source CSS 最后加载，只负责 header、源码宽度、gutter、overflow、anchor、popover positioning、responsive 和 print；
- standalone source CSS 不得定义 Pygments token 色。

这样主题升级后，普通文档、源码页和 Hover 自动获得同一份构建产物，不需要同步第二套颜色或 Markdown 样式。加载相同静态 CSS 不等于生成完整 Sphinx 页面 shell；2,000 多个源码页仍然是当前的轻量 HTML，浏览器只缓存一份共享资产。

#### 20.3.3 页面形态

纯 .mbt/.mbti/.mbtp 页面只展示源码与必要上下文：

- 紧凑 header 展示 path 及可用的 module/version；
- 代码不自动换行，允许水平滚动；
- line-number gutter 不进入 pre.textContent；
- #L42 和 definition anchor 可见且不被 header 遮挡；
- 不显示 View Source；
- Hover/Definition overlay 不覆盖现有词法颜色。

.mbt.md 继续由当前 MyST/Sphinx pipeline 渲染 Markdown prose，内部 code fence 使用同一高亮合同。页面增加 literate variant 只用于 prose width、code overflow 和 metadata 布局。修样式前先消除当前 render_partial(document) 造成的 fragment 双渲染；prose、heading、image 和 code block 必须各出现一次。

### 20.4 Hover 必须作为完整 Markdown 渲染

LSP MarkupContent.kind 为 markdown 时，value 是一个完整 Markdown 文档。实现不能假定它一定是“第一个 MoonBit fence + --- + 说明”，也不能手工拆 signature/documentation。

正确的数据流是：

~~~text
完整 MarkupContent.value
  → extension-owned isolated MyST document
  → 项目当前 MyST/Sphinx settings
  → 标准 docutils/Sphinx document tree
  → 标准 Sphinx HTML translator 递归渲染
  → 构建期生成安全 HTML fragment
  → content-addressed Hover preload
  → runtime 只展示已经构建好的 fragment
~~~

具体要求：

1. 每个不同 Hover payload 只在 Sphinx 构建期解析一次；
2. 使用 app.registry.create_source_parser(app, "markdown")，并继承当前文档的 MyST/Sphinx settings；
3. 完整解析 paragraph、emphasis、strong、inline code、link、list、blockquote、hr、table 和 fenced code；
4. --- 由 Markdown 正常渲染为 hr，不作为私有分隔符处理；
5. MarkupContent.kind 为 plaintext 时只输出 escaped plaintext；
6. 浏览器端不再运行 Markdown parser，也不维护私有 paragraph/list/code AST；
7. rendered fragment 和 renderer contract 一起参与 content hash，继续通过当前 file:// 可用的 preload 交付，不退回页面级 Fetch；
8. raw HTML、include 和可执行 Sphinx directive 在 Hover isolated context 中禁用；这是输入安全边界，不是另一套 Markdown renderer。

#### 20.4.1 任意深度 code fence

Sphinx translator 会递归遍历整棵 document tree。Hover 中位于以下任意位置的 literal_block 都必须走普通文档的现有 highlighter：

- 顶层；
- list item 内；
- blockquote 内；
- container/admonition 内；
- 其他 Markdown block 的任意嵌套深度。

语言选择也与普通文档相同：

- moonbit / mbt 使用当前 MoonBit lexer；
- 项目已支持的其他语言，例如 Python、C、JSON、shell、diff，使用当前 Sphinx lexer registry；
- 未知语言使用普通文档当前的 warning/fallback 行为。

不允许只特殊处理第一个 MoonBit fence，也不允许只处理所谓 signature。Hover 中后续出现的 MoonBit example、其他语言 example 以及多层嵌套 example 都由同一个 translator 处理。

#### 20.4.2 Hover fence 只有词法高亮

Hover virtual document 没有 frozen source identity 或 provenance，因此其中所有 code fence 只获得普通文档词法高亮。isolated render context 必须让 semantic doctree hooks 明确跳过这些节点，不能依赖“刚好匹配不到 occurrence”。

Hover fragment 内禁止生成：

- data-mbt-hover；
- data-mbt-symbol；
- mbt-semantic-token；
- mbt-definition；
- Definition href；
- semantic tabindex。

触发 Hover 的原代码 token 仍保留自己的 Hover/Definition 信息；Hover Markdown 内的普通 Markdown link 是独立链接，不能被当作 Go to definition。

#### 20.4.3 复用文档主题

构建出的 Hover fragment 使用标准 Sphinx HTML class。runtime 只增加一个 popover 外壳和一个明确的 Markdown content wrapper：

~~~html
<div class="mbt-semantic-popover">
  <div class="mbt-hover-markdown bd-content">
    <!-- app.builder.render_partial(...) 生成的 fragment -->
  </div>
</div>
~~~

普通文档页已经加载主题 CSS；standalone 源码页按 20.3 加载同一组 builder theme CSS 和同一个 pygments.css。因此：

- paragraph/list/link/table/inline code 继承文档站 typography 与 theme variables；
- 所有 fenced code 继承文档站现有 Pygments light/dark 颜色；
- Hover 专用 CSS 只约束 popover 的 border、surface、padding、max size、scroll 和定位；
- Hover CSS 不定义任何代码 token 颜色。

### 20.5 Hover 交互

完整 Markdown 可能包含长说明、列表、链接和多个 code fence，所以最终组件是可交互 popover，不是 pointer-events:none 的纯文本 tooltip。

打开条件为：

~~~text
open =
  triggerHovered
  OR triggerFocused
  OR popoverHovered
  OR popoverFocusWithin
  OR pinned
~~~

要求：

- trigger 与 popover 间使用 100–150ms intent delay，鼠标跨越间隙不闪烁；
- popover 上下碰撞定位，窄屏或上下均不足时使用 viewport inset panel；
- 内容可滚动、可选择，Markdown link 可点击；
- touch/click 可 pin，Escape 关闭；
- Definition trigger 的原生 href 与 click/Enter 导航保持不变；
- Definition a 使用原生 Tab；
- hover-only token 必须保留一种明确的键盘可达方案，可保留 focus、使用 roving tabindex 或提供统一 keyboard exploration；不能直接使其不可达；
- ARIA 根据可交互 popover 语义设置，不继续滥用 aria-haspopup 或把可交互内容伪装成纯 tooltip；
- JavaScript 禁用时 Definition href 仍然可用。

### 20.6 最终数据流

~~~mermaid
flowchart LR
  M["普通文档 Markdown"] --> MP["当前 MyST/Sphinx parser"]
  MP --> LB["literal_block"]
  LB --> SH["当前 Sphinx highlighter"]
  SH --> ML["当前 MoonBit/其他语言 lexer"]
  ML --> PC["现有 Pygments class"]
  PC --> PY["同一个 pygments.css"]

  FS["冻结 MoonBit 源码"] --> SR["SemanticCodeRenderer"]
  ML --> SR
  SR --> PC
  SO["Hover/Definition overlay"] --> SR

  HP["完整 LSP MarkupContent"] --> HI["isolated MyST/Sphinx document"]
  HI --> LB
  HI --> HF["标准 Sphinx HTML fragment"]
  HF --> PO["Theme-styled popover"]

  TH["同一 data-theme"] --> PY
  TC["同一 builder theme CSS"] --> PO
  TC --> SP["standalone source shell"]
  PY --> SP
~~~

这条数据流没有新的 MoonBit 分析阶段。高亮只存在一个来源；源码页和 Hover 都是该来源的新消费面。

### 20.7 分 commit 实施顺序

1. **fix(docs): render literate source fragments once**
   - 修复 .mbt.md fragment 双渲染与 front matter 重复；
   - 添加 prose、heading、image、code occurrence 唯一性测试。

2. **fix(docs): reuse document theme on source pages**
   - 隔离 shared semantic CSS 与 standalone layout CSS；
   - 首屏设置与文档一致的 data-theme；
   - 引用 builder 当前主题 CSS 和同一个 pygments.css；
   - 保持普通 fence/source lexical class stream 与 wrapper contract 一致；
   - 添加 light/dark computed-style 与 file:// 测试；
   - 不修改 lexer、token mapping、palette 或 snapshot。

3. **feat(docs): render hover markdown through Sphinx**
   - 完整 MarkupContent 进入 isolated MyST/Sphinx pipeline；
   - 标准 translator 递归渲染所有 literal_block 和所有语言；
   - 禁用 raw HTML/include/executable directive；
   - 构建期生成 content-addressed HTML fragment；
   - Hover fence 明确跳过 semantic annotation；
   - 添加段落、列表、hr、link、inline code、嵌套 MoonBit/Python/C/JSON fence 测试。

4. **fix(docs): preserve rich hover interactions**
   - 实现 trigger/popover/pin 状态机与 intent delay；
   - 完成长内容滚动、viewport collision、touch、keyboard 和 ARIA；
   - 保持 trigger Definition href 的原生导航；
   - 添加 Chromium、Firefox、WebKit，light/dark，375/768/1440px，200% zoom，file:// 与 HTTP 回归测试。

每个 commit 自带相应测试，避免出现只有实现、没有合同验证的中间提交。

### 20.8 完成定义

- 普通文档现有 MoonBit code fence 的 DOM、class、computed color 和主题行为不变；
- 同一 fixture 在普通 fence、semantic block、pure source、literate source 与 Hover fence 中具有相同 lexical class sequence；
- standalone 页只通过同一 builder theme CSS、同一 pygments.css 和同一 data-theme 获得代码颜色；
- source/semantic/Hover CSS 没有 Pygments token 配色规则；
- Hover 把完整 Markdown 渲染为 paragraph、list、blockquote、hr、link、inline code、table 与 code block，不显示原始 Markdown marker；
- Hover 中任意深度、任意受支持语言的 fence 与普通文档使用同一 Sphinx highlighter；
- Hover 内 MoonBit fence 只有词法高亮，没有 Hover、Definition 或 provenance 伪语义；
- Hover 可滚动、选择、点击链接，并且 trigger 与 popover 间移动不闪烁；
- hover-only token 键盘可达；Definition 的原生 href 在 mouse、keyboard 和 JavaScript disabled 下继续工作；
- .mbt.md prose/code/front matter 不重复；
- source pre.textContent、复制结果、行锚点和 definition target 不变；
- CSS/HTML/Hover Markdown 变化不触发 semantic snapshot 重建或 LSP 重跑；
- 本计划中不存在任何 lexer、高亮质量、token palette 或 semantic coloring 的改进任务。
