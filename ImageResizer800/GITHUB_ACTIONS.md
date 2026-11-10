# GitHub Actions 自动打包说明

## 使用步骤

1. 在 GitHub 上新建一个**公开仓库**（Private 仓库免费额度很少）
2. 把整个 `ImageResizer800` 文件夹里的内容上传到仓库根目录
   - 包括 `.github` 文件夹
   - 包括 `ImageResizer800` 源码文件夹
3. 推送代码到 `main` 分支
4. 进入仓库的 **Actions** 页面，等待构建完成
5. 在构建结果里下载 `ImageResizer800-app` 压缩包
6. 解压后得到 `ImageResizer800.app`，直接拖到「应用程序」文件夹即可使用

## 注意事项

- 这个 workflow 使用的是简化编译方式，适合当前这个无复杂依赖的应用
- 如果编译失败，最稳妥的方式还是在本地用 Xcode 打开一次生成项目文件，再提交 `.xcodeproj`
- 公开仓库的 macOS 构建是免费的

## 本地测试（可选）

如果你有 Mac，也可以直接在终端运行：

```bash
cd ImageResizer800
# 需要先有 Xcode 或 Command Line Tools
```
