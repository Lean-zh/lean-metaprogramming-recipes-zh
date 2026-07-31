# 翻译进度

状态含义：未翻译、初译、校对、完成。只有通过全文英文残留检查、Lean/Verso 构建、干净渲染与站点链接检查后，才标为“完成”。

| 部分 | 状态 |
|---|---|
| 首页与总入口 | 完成 |
| 概览 | 完成 |
| 信息视图 | 完成 |
| 语法与宏 | 完成 |
| 表达式 | 完成 |
| 精译 | 完成 |
| 策略 | 完成 |
| 状态维护 | 完成 |
| I/O 与进程 | 完成 |
| 文件系统 | 完成 |
| 数据结构 | 完成 |
| 索引 | 完成 |
| 配方编写指南 | 完成 |
| 贡献者页 | 完成 |
| 仓库外围文档与模板 | 完成 |

## 验收结果

- [x] 71 个发布文档源中的可见英文正文已全部翻译
- [x] README、CONTRIBUTING、COOKBOOK_GUIDELINES、CODE_OF_CONDUCT、PR 模板与 TemplateRecipe 已处理
- [x] 前端可见文案已本地化
- [x] 术语与 GLOSSARY.md 一致
- [x] `lake build lean-cookbook` 通过，共 440 个构建任务
- [x] 清空 `_out` 后，`lake exe lean-cookbook` 通过
- [x] 90 个生成页面均有稳定且互不碰撞的 ASCII 路径
- [x] 90 个页面的标题、站内链接与 Lean 高亮代码块已由 `scripts/check_generated_site.py` 检查
- [ ] GitHub Pages 最新部署成功并从公开 URL 验证

## 维护说明

Verso 4.28 默认把中文标题转写为下划线。同级且长度相同的标题可能静默写入同一路径，造成页面丢失。本仓库为文档 part 写入显式 `file := "..."` 元数据，并用 `scripts/add_stable_page_files.py` 维护稳定文件名。新增章节或配方后，应重新运行该脚本，再执行完整构建和站点检查。
