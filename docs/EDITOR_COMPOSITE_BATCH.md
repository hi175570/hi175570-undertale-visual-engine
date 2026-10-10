# 编辑器界面与游戏特效分层（2026-10-09）

- 正常游玩会显示的内容（敌人、弹幕、战斗文本、战斗框、血条等）保持现有滤镜。
- 编辑器专用菜单、文字、Workspace、时间轴、选框/顶点与提示在特效后绘制，不受像素化或其他游戏滤镜影响。
- 编辑器层按窗口实际像素创建，逻辑布局仍为 640×480；不改变游戏相机和点击坐标。
- 按用户最新要求保留原像素字体和原字符回退，不替换系统字体、不添加抗锯齿；只隔离游戏滤镜。已撤销试验性的动态字体加载与测量缓存。
- 共用原 Draw 与数据结构；只拆分游戏内容/工具覆盖层，不新建第二套编辑器运行时。

## 实现

- 原 Draw 仅输出游戏内容；最终合成器在游戏特效之后调用同一个 Draw 的工具界面部分。编辑器自己的透明 surface 随窗口大小变化才重建；清理时释放 surface 和专用 UI camera。
- 像素坐标裁剪随窗口比例转换，恢复 gpu_get_scissor 返回的结构体时不重复缩放。绘制结束恢复相机矩阵、GPU、文字颜色和对齐状态。
- 场景放置中的骨头、GB 等预览仍走游戏 surface；选框顶点及其他编辑工具不走游戏特效。
- 真正播放/敌人回合和打字预览隐藏界面时，直接跳过整个 UI surface 绘制，不额外绘制空覆盖层。

## 已实现并运行验证

- 隔离 Runner 退出码 0；200% 时 UI surface 为 1280×960，150% 为 960×720。通过实际 Draw 截图检查 Workspace、公式说明、对象属性、顶点和隐藏播放状态。
- 同时施加强像素化、反色、波动后，Workspace UI surface 与无效果版本 SHA-256 相同：E8861946B342C8717FB590945CFF3D62575CECCC97973833952AEAB0C3261B5E。
- 场景 UI surface 在开关像素化/反色前后也完全相同：1D0CD466D8045E3351FEC3F3FA41AA1DE80A1D2F81A4753BA04F9F237561493F；底层攻击/敌人/HUD 实际截图改变，确认没有一并禁用游戏滤镜。
- UI 上下文绘制后已清空；恢复像素字体后，冻结输入的简单 Workspace 300 帧耗时 2500.61 ms（约 120 FPS）。这是隔离小场景、含帧率限制的观测，不代表大型存档性能承诺。
- 证据：.codex-build/ui-composite-tests.txt、ui-layer-{clean,effects}.png、ui-scene-layer-{clean,effects}.png、ui-composite-{clean,effects,150}.png、ui-scene-{clean,effects}.png、ui-hidden-playback.png。

## 未运行验证的边界

- 尚未逐项人工操作所有输入框/下拉/拖动，也没有遍历全部全屏分辨率、边框皮肤和大型存档。
- 测试使用专用空白工程及独立测试存档根；未改用户存档。生产源码已撤回测试启动/禁用输入/捕获截图/测试路径注入。

## 最终构建与覆盖

- 撤掉所有临时测试注入后 Windows Compile 退出码 0，日志 .codex-build/editor-composite-compile.log 包含 Igor complete；生产路径恢复为 working_directory/save。未新增存档字段。
- 已覆盖 C:/D/games/hi175570的神秘模版/data.win，24,416,280 bytes；源/目标 SHA-256 均为 27F61F95CF991BC78F92E874D3D25EE12F2A59E9611C8F69F2950B539494E34A。
- 覆盖前旧版单份备份：.codex-build/data-before-editor-composite-20261009.win。没有改动或删除用户存档；没有关闭用户运行的窗口。
- 完成审计：本批功能全部实现；上述分层/缩放/隐藏行为有实际 Runner 证据，完整交互/全屏皮肤组合仍标为未运行验证。最终生产包只完成编译与部署哈希验证，需重开原程序加载。
