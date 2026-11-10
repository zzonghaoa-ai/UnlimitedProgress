import SwiftUI
import AppKit
import UniformTypeIdentifiers
import CoreImage

struct ContentView: View {
    @State private var selectedURLs: [URL] = []
    @State private var statusMessage: String = "选择图片后点击处理"
    @State private var isProcessing = false
    
    // 模块
    @State private var selectedModule: Module = .hd
    
    // 调整尺寸
    @State private var targetWidth: CGFloat = 800
    @State private var targetHeight: CGFloat = 0
    
    // 图片高清
    @State private var upscaleFactor: Double = 2.0
    
    // 水印
    @State private var watermarkURL: URL?
    @State private var watermarkScale: Double = 0.25
    @State private var watermarkOpacity: Double = 0.8
    @State private var watermarkOffsetX: CGFloat = 0.75   // 相对位置 0~1
    @State private var watermarkOffsetY: CGFloat = 0.75
    
    // 导出格式
    @State private var exportFormat: ExportFormat = .jpeg
    
    enum Module: String, CaseIterable {
        case hd = "图片高清"
        case resize = "调整尺寸"
        case watermark = "添加水印"
    }
    
    enum ExportFormat: String, CaseIterable {
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"
        case tiff = "TIFF"
        case webp = "WebP"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("無限進步")
                    .font(.title)
                    .fontWeight(.semibold)
                
                // 模块切换
                Picker("功能模块", selection: $selectedModule) {
                    ForEach(Module.allCases, id: \.self) { module in
                        Text(module.rawValue).tag(module)
                    }
                }
                .pickerStyle(.segmented)
                
                // 拖拽区域（所有模块共用）
                dropZone
                
                // 根据模块显示不同内容
                Group {
                    switch selectedModule {
                    case .resize:
                        resizeModule
                    case .hd:
                        hdModule
                    case .watermark:
                        watermarkModule
                    }
                }
                
                // 导出格式（共用）
                HStack {
                    Text("导出格式:")
                    Picker("", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                if !selectedURLs.isEmpty {
                    Text("已选择 \(selectedURLs.count) 张图片")
                        .font(.callout)
                        .foregroundColor(.blue)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(selectedURLs, id: \.self) { url in
                                Text(url.lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 70)
                    .border(Color.gray.opacity(0.3))
                    
                    Button(isProcessing ? "处理中..." : "开始处理并导出") {
                        processImages(keepForNext: false, targetModule: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                    
                    // 处理后转到其他板块
                    if selectedModule != .hd {
                        Button("处理后转到「图片高清」") {
                            processImages(keepForNext: true, targetModule: .hd)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isProcessing || selectedURLs.isEmpty)
                    }
                    if selectedModule != .resize {
                        Button("处理后转到「调整尺寸」") {
                            processImages(keepForNext: true, targetModule: .resize)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isProcessing || selectedURLs.isEmpty)
                    }
                    if selectedModule != .watermark {
                        Button("处理后转到「添加水印」") {
                            processImages(keepForNext: true, targetModule: .watermark)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isProcessing || selectedURLs.isEmpty)
                    }
                }
                
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)
            }
            .padding(20)
        }
        .frame(width: 480, height: 680)
    }
    
    // MARK: - 拖拽 + 点击区域
    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(.blue.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                )
            
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("拖拽图片到这里")
                    .font(.headline)
                Text("或点击此区域选择图片")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(height: 110)
        .contentShape(Rectangle())
        .onTapGesture {
            selectImages()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - 调整尺寸模块
    private var resizeModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("调整尺寸").font(.headline)
            
            HStack {
                Text("目标宽度:")
                TextField("0=不指定", value: $targetWidth, format: .number)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text("px")
            }
            
            HStack {
                Text("目标高度:")
                TextField("0=不指定", value: $targetHeight, format: .number)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text("px")
            }
            
            Text("只填一个会自动按比例缩放；两个都填则按指定尺寸")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 图片高清模块
    private var hdModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("图片高清").font(.headline)
            
            HStack {
                Text("放大倍数:")
                Picker("", selection: $upscaleFactor) {
                    Text("2x").tag(2.0)
                    Text("4x").tag(4.0)
                    Text("8x").tag(8.0)
                    Text("16x").tag(16.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            
            Text("使用高质量 Lanczos 算法进行放大")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 添加水印模块（自由拖拽）
    private var watermarkModule: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加水印").font(.headline)
            
            HStack {
                Button(watermarkURL == nil ? "导入水印图片" : "更换水印") {
                    selectWatermark()
                }
                
                if let url = watermarkURL {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    Button("清除") {
                        watermarkURL = nil
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            if watermarkURL != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("水印大小:")
                        Slider(value: $watermarkScale, in: 0.05...0.6)
                        Text("\(Int(watermarkScale * 100))%")
                            .frame(width: 45)
                    }
                    
                    HStack {
                        Text("透明度:")
                        Slider(value: $watermarkOpacity, in: 0.1...1.0)
                        Text("\(Int(watermarkOpacity * 100))%")
                            .frame(width: 45)
                    }
                    
                    Text("在下方预览区域拖拽水印调整位置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 预览 + 拖拽区域
                    watermarkPreview
                }
            }
        }
    }
    
    // 水印预览（可拖拽）
    private var watermarkPreview: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Text("预览区域（拖拽水印）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
                
                if let wmURL = watermarkURL,
                   let nsImage = NSImage(contentsOf: wmURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * watermarkScale)
                        .opacity(watermarkOpacity)
                        .position(
                            x: geo.size.width * watermarkOffsetX,
                            y: geo.size.height * watermarkOffsetY
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newX = max(0, min(1, value.location.x / geo.size.width))
                                    let newY = max(0, min(1, value.location.y / geo.size.height))
                                    watermarkOffsetX = newX
                                    watermarkOffsetY = newY
                                }
                        )
                }
            }
        }
        .frame(height: 180)
        .border(Color.gray.opacity(0.3), width: 1)
        .cornerRadius(8)
    }
    
    // MARK: - 处理逻辑
    private func handleDrop(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   url.isFileURL {
                    urls.append(url)
                } else if let url = item as? URL {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            let imageURLs = urls.filter { url in
                let ext = url.pathExtension.lowercased()
                return ["jpg", "jpeg", "png", "tiff", "tif", "heic", "gif", "webp"].contains(ext)
            }
            
            if !imageURLs.isEmpty {
                selectedURLs = imageURLs
                statusMessage = "已拖入 \(imageURLs.count) 张图片"
            } else {
                statusMessage = "未识别到有效图片文件"
            }
        }
    }
    
    private func selectImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "选择要处理的图片"
        
        if panel.runModal() == .OK {
            selectedURLs = panel.urls
            statusMessage = "已选择 \(selectedURLs.count) 张图片"
        }
    }
    
    private func selectWatermark() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "选择水印图片（建议透明 PNG）"
        
        if panel.runModal() == .OK, let url = panel.url {
            watermarkURL = url
        }
    }
    
    private func processImages(keepForNext: Bool = false, targetModule: Module? = nil) {
        guard !selectedURLs.isEmpty else { return }
        
        isProcessing = true
        statusMessage = "正在处理..."
        
        let module = selectedModule
        let wURL = watermarkURL
        let scale = watermarkScale
        let opacity = watermarkOpacity
        let offsetX = watermarkOffsetX
        let offsetY = watermarkOffsetY
        let format = exportFormat
        
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            var failed: [String] = []
            var newURLs: [URL] = []
            
            for url in selectedURLs {
                do {
                    var processedImage: NSImage
                    
                    switch module {
                    case .resize:
                        guard let original = NSImage(contentsOf: url) else { throw ImageError.loadFailed }
                        processedImage = original.resized(
                            toWidth: targetWidth > 0 ? targetWidth : nil,
                            height: targetHeight > 0 ? targetHeight : nil
                        )
                    case .hd:
                        guard let original = NSImage(contentsOf: url) else { throw ImageError.loadFailed }
                        processedImage = try original.lanczosUpscale(scale: upscaleFactor)
                    case .watermark:
                        guard let original = NSImage(contentsOf: url) else { throw ImageError.loadFailed }
                        processedImage = original
                    }
                    
                    if module == .watermark, let wmURL = wURL, let watermark = NSImage(contentsOf: wmURL) {
                        processedImage = try processedImage.addWatermark(
                            watermark,
                            scale: scale,
                            opacity: opacity,
                            relativeX: offsetX,
                            relativeY: offsetY
                        )
                    }
                    
                    let suffix = module == .resize ? "_resized" : (module == .hd ? "_hd\(Int(upscaleFactor))x" : "_watermarked")
                    let savedURL = try saveImage(processedImage, originalURL: url, suffix: suffix, format: format)
                    newURLs.append(savedURL)
                    successCount += 1
                } catch {
                    failed.append(url.lastPathComponent)
                }
            }
            
            DispatchQueue.main.async {
                isProcessing = false
                if keepForNext && !newURLs.isEmpty {
                    selectedURLs = newURLs
                    if let target = targetModule {
                        selectedModule = target
                        statusMessage = "已处理 \(successCount) 张，已转到「\(target.rawValue)」，可继续处理"
                    } else {
                        statusMessage = "已处理 \(successCount) 张，可继续选择其他板块处理"
                    }
                } else if failed.isEmpty {
                    statusMessage = "成功处理 \(successCount) 张图片！\n已保存到原图片所在文件夹"
                } else {
                    statusMessage = "成功 \(successCount) 张，失败 \(failed.count) 张"
                }
            }
        }
    }
    
    private func saveImage(_ image: NSImage, originalURL: URL, suffix: String, format: ExportFormat) throws -> URL {
        let originalName = originalURL.deletingPathExtension().lastPathComponent
        let ext: String
        let fileType: NSBitmapImageRep.FileType
        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
        
        switch format {
        case .jpeg:
            ext = "jpg"
            fileType = .jpeg
            properties = [.compressionFactor: 0.92]
        case .png:
            ext = "png"
            fileType = .png
        case .heic:
            ext = "heic"
            fileType = .jpeg  // 简化处理，实际 HEIC 需要额外处理
            properties = [.compressionFactor: 0.9]
        case .tiff:
            ext = "tiff"
            fileType = .tiff
        case .webp:
            ext = "webp"
            fileType = .jpeg  // WebP 在纯 AppKit 中支持有限，降级为 JPEG
            properties = [.compressionFactor: 0.9]
        }
        
        let newName = "\(originalName)\(suffix).\(ext)"
        let saveURL = originalURL.deletingLastPathComponent().appendingPathComponent(newName)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ImageError.encodeFailed
        }
        
        guard let data = bitmap.representation(using: fileType, properties: properties) else {
            throw ImageError.encodeFailed
        }
        
        try data.write(to: saveURL)
        return saveURL
    }
}

enum ImageError: Error {
    case loadFailed
    case encodeFailed
}

extension NSImage {
    func resized(toWidth width: CGFloat?, height: CGFloat?) -> NSImage {
        let originalSize = self.size
        var newWidth = originalSize.width
        var newHeight = originalSize.height
        
        if let w = width, w > 0, let h = height, h > 0 {
            newWidth = w
            newHeight = h
        } else if let w = width, w > 0 {
            let ratio = w / originalSize.width
            newWidth = w
            newHeight = originalSize.height * ratio
        } else if let h = height, h > 0 {
            let ratio = h / originalSize.height
            newHeight = h
            newWidth = originalSize.width * ratio
        }
        
        let newSize = NSSize(width: newWidth, height: newHeight)
        
        let newImage = NSImage(size: newSize, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            self.draw(in: rect, from: NSRect(origin: .zero, size: originalSize), operation: .copy, fraction: 1.0)
            return true
        }
        return newImage
    }
    
    func lanczosUpscale(scale: Double) throws -> NSImage {
        guard let tiffData = self.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            throw ImageError.loadFailed
        }
        
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            throw ImageError.loadFailed
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let outputImage = filter.outputImage else {
            throw ImageError.loadFailed
        }
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageError.loadFailed
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    func addWatermark(
        _ watermark: NSImage,
        scale: Double,
        opacity: Double,
        relativeX: CGFloat,
        relativeY: CGFloat
    ) throws -> NSImage {
        let targetWidth = self.size.width * scale
        let ratio = targetWidth / watermark.size.width
        let targetHeight = watermark.size.height * ratio
        let wmSize = NSSize(width: targetWidth, height: targetHeight)
        
        let origin = NSPoint(
            x: self.size.width * relativeX - wmSize.width / 2,
            y: self.size.height * (1 - relativeY) - wmSize.height / 2
        )
        
        let result = NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
            watermark.draw(
                in: NSRect(origin: origin, size: wmSize),
                from: NSRect(origin: .zero, size: watermark.size),
                operation: .sourceOver,
                fraction: opacity
            )
            return true
        }
        return result
    }
}
