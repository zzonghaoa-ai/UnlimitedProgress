# 無限進步

一个简单的 macOS 应用，用于批量处理图片。

## 功能
- **调整尺寸**：支持自定义宽度和高度
  - 只填宽度：高度自动按比例缩放
  - 只填高度：宽度自动按比例缩放
  - 两个都填：按指定宽高处理（可能改变比例）
  - 填 0 或留空表示不指定该维度
- **高清化**：使用 Lanczos 算法进行高质量 2x / 4x / 8x / 16x 放大
- **添加水印**：
  - 支持导入本地水印图片（建议使用透明 PNG）
  - 可调节水印大小（相对图片宽度的百分比）
  - 可调节透明度
  - 支持多个位置：右下角、左下角、右上角、左上角、居中
- 支持批量选择多张图片
- 处理后的图片保存到原图片所在文件夹（自动添加对应后缀）

## 如何使用

1. 打开 Xcode
2. 创建新项目：
   - 选择 **macOS** → **App**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - 项目名称：`ImageResizer800`
3. 删除 Xcode 自动生成的 `ContentView.swift` 和 `ImageResizer800App.swift`（如果存在）
4. 把本目录下的两个 `.swift` 文件拖入 Xcode 项目中
5. 运行（⌘R）

## 关于「高清化」
当前使用的是 **Lanczos 高质量插值算法**。如需更强的 AI 超分辨率效果，可后续集成 CoreML 模型。

## 打包成可分发的 App
在 Xcode 中：
- Product → Archive
- 然后 Distribute App

## 应用图标
项目中已包含一个简单的应用图标：`assets/AppIcon.png`

在 Xcode 中使用时：
1. 打开 Assets.xcassets
2. 拖入 AppIcon.png 作为 AppIcon

在 GitHub Actions 打包时，也可手动放入 .app/Contents/Resources/ 并在 Info.plist 中引用。
- 需要 macOS 12+ 和 Xcode 14+
- JPEG 默认压缩质量较高（0.92）
- 水印建议使用带透明通道的 PNG 图片
