# 窗口放大后点击偏移（2026-10-09）

## 修复

- 编辑器原先按原生像素合成，却仍在 Step、节点连线拖拽和下拉悬停中使用 device_mouse_*_to_gui。该换算依赖另一套 GUI 尺寸/相机状态，与编辑器的独立 surface 未共用同一矩形。
- 新增 Window_ContentViewport，供编辑器最终绘制和输入共同使用：相同窗口尺寸、边框皮肤留边、纵横留黑、整数取整后的 surface 尺寸。Window_ContentMouse 将客户区鼠标坐标按这个矩形逆变换成 640×480 逻辑坐标。
- 不钳制坐标；画布外拖动仍然允许。Workspace 本身平移/缩放继续在逻辑坐标之上换算。
- 最终光标按窗口像素绘制，不再把逻辑坐标当物理像素。存在最终合成器时关闭较早的重复光标，避免留下受游戏滤镜影响的第二个光标。
- 原像素字体和游戏特效分层不变；未改项目/存档数据。

## 验证

- 隔离 Runner：148 个断言全部通过，退出码 0。
- 坐标往返/画布外坐标/拖动增量：640×480、800×600、960×720、1120×840、1280×960、1920×1080、1001×703，分别启用/禁用边框。
- 真实窗口的五种比例（100/125/150/175/200%）及两种边框状态下，向真实 Step 注入客户区点击坐标，验证脚本顶栏入口、公式打开/收起、新对象分类下拉展开及选项选择。
- 这是 Runner 事件级输入回归，不冒充用户手动鼠标/系统 DPI/全屏切换实测；未移动或点击用户鼠标。完整手动拖动和不同显示器 DPI 仍待用户实测。
- 证据：.codex-build/click-probe-result.txt、click-probe-screen.png、click-probe-compile.log。临时启动和输入注入已全部撤回，存档根恢复为 working_directory/save。

正式 Windows Compile 退出码 0（window-input-fix-compile.log，Igor complete）。已覆盖 C:/D/games/hi175570的神秘模版/data.win，24,418,712 bytes；源目标 SHA-256 均为 491B664B49C36AE78D32A5D3793376A57FBA2E0C07177E667A718BD1ABF7A222。覆盖前备份为 .codex-build/data-before-window-input-fix-20261009.win。用户存档未动，未关闭用户游戏。
