# Inspector

游戏对象调试工具集。通过可视化界面显示对象的类名、血量等元信息，支持选中追踪、实例统计。

## 安装

在plugins（或plugin，看你用哪个版本）目录下
```shell
git clone https://github.com/Airofact/LuaSTG_Inspector.git
```
即可

## 架构

```
Inspector（门面单例）
├── config       → InspectorConfiguration  持久配置
├── object_meta_info → ObjectMetaInfoRenderer  类名标签渲染（DirectWrite）
├── instance_info    → InstanceInfoRenderer    HP 渲染
├── indicator        → IndicatorRenderer       十字标 / 包围盒
├── selected_units / selected_class / owned_indicators  运行时选中状态
└── 协调：选中自动管理 indicator 生命周期
```

## 模块一览

| 模块 | 类型 | 职责 |
|---|---|---|
| `Inspector` | 单例 | 门面，持有所有子模块 + 选中协调 |
| `InspectorConfiguration` | 单例 | 持久配置，预留 load/save |
| `ObjectMetaInfoRenderer` | 单例 | 类名标签渲染（DirectWrite 合批） |
| `InstanceInfoRenderer` | 单例 | HP 及护盾文字渲染 |
| `IndicatorRenderer` | 单例 | 十字标 / 包围盒指示器 |
| `DirectWriteLabelCache` | 类构造器 | 文本→精灵纹理缓存 |
| `ClassMetaInfo` | 普通模块 | 类元数据扫描与管理 |
| `InstanceQuery` | 普通模块 | 按类标识符统计实例数量 |
| `EvilNameStealer` | 普通模块 | 反解本地 Class() 的变量名 |

## UI Tab

| Tab | 文件 | 功能 |
|---|---|---|
| Config | `Tab/ConfigTab.lua` | 类名/HP/指示器/Group 显示开关 |
| Statistics | `Tab/StatisticsTab.lua` | 按类统计实例数量，点击跳转实例列表 |
| Instances | `Tab/InstancesTab.lua` | 实例列表，支持多选（按住 Ctrl） |
| Inspector | `Tab/InspectorTab.lua` | 选中对象的属性浏览器 |

## 显示含义

| 颜色 | 定义类型 |
|---|---|
| 绿色 | editor — `_editor_class` 中定义 |
| 黄色 | global — `_G` 中定义 |
| 青色 | local — `Class()` 本地定义 |
| 红色 | invalid — 无法识别 |

## 配置项

### object_meta_info（类名标签）
- `show` — 显示类名
- `show_invalid` — 显示无效类
- `show_group_id` — 显示 Group ID
- `show_editor` / `show_global` / `show_local` — 类型过滤
- `font_scale` — 字体缩放

### instance_info（HP）
- `show` — 显示血量
- `show_protect` — 护盾蓝色标识
- `font_scale` — 字体缩放

### indicator（指示器）
- `show` — 显示指示器
- `size` — 十字标尺寸
- `thickness` — 线条粗细

### enabled_groups
按 Group ID 过滤渲染范围。

## 加载流程

1. `beforeTHlib` → `Hook/Class.lua` 拦截 `Class()` 调用
2. `afterTHlib` → `InspectorView` 注册调试窗口 + `Hook/Render.lua` 注入 `AfterRender`

## 依赖

- imgui（调试 UI）
- DirectWrite（字体渲染）
- LuaSTG 调试库
