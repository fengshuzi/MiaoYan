import Cocoa

class MainWindow: NSWindow {
    private var trackingArea: NSTrackingArea?
    private var isMouseInTitleBar = false
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // 设置窗口位置（仅首次启动）
        if UserDefaults.standard.object(forKey: "NSWindow Frame myMainWindow") == nil {
            Task { @MainActor in
                if let screenHeight = NSScreen.main?.frame.height, let screenWidth = NSScreen.main?.frame.width {
                    let x = (screenWidth - self.frame.width) / 2
                    let y = (screenHeight - self.frame.height) / 2
                    let rect = NSRect(x: x, y: y, width: self.frame.width, height: 680)
                    self.setFrame(rect, display: true)
                }
            }
        }
        
        // 延迟初始化按钮追踪，确保窗口完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.setupWindowButtonTracking()
        }
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        // 窗口显示时也尝试设置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.trackingArea == nil {
                self.setupWindowButtonTracking()
            }
        }
    }
    
    private func setupWindowButtonTracking() {
        // 初始隐藏窗口控制按钮
        hideWindowButtons(animated: false)
        
        // 设置鼠标追踪
        acceptsMouseMovedEvents = true
        
        // 创建追踪区域
        if let contentView = contentView {
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeAlways
            ]
            trackingArea = NSTrackingArea(
                rect: contentView.bounds,
                options: options,
                owner: self,
                userInfo: nil
            )
            contentView.addTrackingArea(trackingArea!)
        }
    }
    
    private func hideWindowButtons(animated: Bool = true) {
        guard let closeButton = standardWindowButton(.closeButton),
              let miniaturizeButton = standardWindowButton(.miniaturizeButton),
              let zoomButton = standardWindowButton(.zoomButton) else {
            return
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                closeButton.animator().alphaValue = 0
                miniaturizeButton.animator().alphaValue = 0
                zoomButton.animator().alphaValue = 0
            })
        } else {
            closeButton.alphaValue = 0
            miniaturizeButton.alphaValue = 0
            zoomButton.alphaValue = 0
        }
    }
    
    private func showWindowButtons() {
        guard let closeButton = standardWindowButton(.closeButton),
              let miniaturizeButton = standardWindowButton(.miniaturizeButton),
              let zoomButton = standardWindowButton(.zoomButton) else {
            return
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            closeButton.animator().alphaValue = 1
            miniaturizeButton.animator().alphaValue = 1
            zoomButton.animator().alphaValue = 1
        })
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        let location = event.locationInWindow
        let inTitleBar = isPointInTitleBar(point: location)
        
        // 只在状态改变时更新按钮
        if inTitleBar != isMouseInTitleBar {
            isMouseInTitleBar = inTitleBar
            if inTitleBar {
                showWindowButtons()
            } else {
                hideWindowButtons()
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isMouseInTitleBar = false
        hideWindowButtons()
    }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount >= 2, isPointInTitleBar(point: event.locationInWindow) {
            performZoom(nil)
        }
        super.mouseUp(with: event)
    }

    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let windowFrame = contentView?.frame {
            let titleBarRect = NSRect(x: contentLayoutRect.origin.x, y: contentLayoutRect.origin.y + contentLayoutRect.height, width: contentLayoutRect.width, height: windowFrame.height - contentLayoutRect.height)
            return titleBarRect.contains(point)
        }
        return false
    }
}
