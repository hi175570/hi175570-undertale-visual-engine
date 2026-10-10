# 首次构建：本机字体准备

公开仓库与作者本机工程的区别：datafiles/editor_fonts 中有些原始 TTF/OTF 字体没有附明确再分发许可，因此只在本机保留，不通过 Git 上传。Noto Emoji 及对应许可、生成的 Emoji 图集仍在仓库中。

GameMaker 工程的 IncludedFiles 保留了现有字体文件名。首次克隆后，打开/构建前需要从自己获准使用的来源补齐这些文件；缺文件时不能把克隆直接当作已验证的完整发布包。不要将 Windows 已安装字体视为自动获得随软件再分发的许可。

本机版使用的未公开字体文件名（目录均为 datafiles/editor_fonts）：

- Comic Sans MS.ttf
- Papyrus.ttf
- Segoe UI Emoji.ttf
- Wingdings.ttf
- 方正少儿简体.ttf
- 方正卡通简体.ttf
- 方正基础像素体.ttf
- 方正像素12.ttf
- sanschinese.ttf
- papychinese.ttf
- Determination Mono.otf
- Hachicro.ttf
- Mars Needs Cunnilingus.ttf
- Monster Friend Back.otf
- Monster Friend Fore.otf

取得适用授权后按原文件名放入即可；.gitignore 会防止误提交。若要公开发行自己的修改版，需使用具有适用许可的字体并相应调整字体注册/回退与 IncludedFiles，而不是简单重命名替换字体；这不属于本次仓库上传对本机运行版做过的修改。

仓库仍保留原像素字体资源与字体回退代码，本次发布没有更改用户本机的画面、字体或存档。
