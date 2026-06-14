import Flutter
import Combine
import SwiftUI
import UIKit

final class LiquidGlassPlugin: NSObject {
  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      LiquidGlassBarFactory(messenger: registrar.messenger()),
      withId: "clashking/liquid_glass_bar"
    )
    registrar.register(
      LiquidGlassTabBarFactory(messenger: registrar.messenger()),
      withId: "clashking/liquid_glass_tab_bar"
    )
  }
}

private final class LiquidGlassBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassBarPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
  }
}

private final class LiquidGlassBarPlatformView: NSObject, FlutterPlatformView {
  private let container: LiquidGlassHostView
  private let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let params = args as? [String: Any]
    let cornerRadius = CGFloat(codecValue: params?["cornerRadius"]) ?? 28
    let opacity = CGFloat(codecValue: params?["opacity"]) ?? 0.74
    let borderColor = UIColor(argbValue: params?["borderColor"]) ?? UIColor.separator
    let borderOpacity = CGFloat(codecValue: params?["borderOpacity"]) ?? 0.28
    let shadowOpacity = CGFloat(codecValue: params?["shadowOpacity"]) ?? 0.16
    let interactive = params?["interactive"] as? Bool ?? false
    let selected = params?["selected"] as? Bool ?? false
    let isDark = params?["isDark"] as? Bool ?? (UITraitCollection.current.userInterfaceStyle == .dark)
    container = LiquidGlassHostView(
      cornerRadius: cornerRadius,
      opacity: opacity,
      borderColor: borderColor,
      borderOpacity: borderOpacity,
      shadowOpacity: shadowOpacity,
      interactive: interactive,
      selected: selected,
      isDark: isDark
    )
    channel = FlutterMethodChannel(
      name: "clashking/liquid_glass_bar_\(viewId)",
      binaryMessenger: messenger
    )
    container.frame = frame
    super.init()
    channel.setMethodCallHandler { [weak container] call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let params = call.arguments as? [String: Any]
      DispatchQueue.main.async {
        container?.update(params)
        result(nil)
      }
    }
  }

  func view() -> UIView {
    container
  }
}

private final class LiquidGlassTabBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassTabBarPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
  }
}

private final class LiquidGlassTabBarPlatformView: NSObject, FlutterPlatformView {
  private let container: LiquidGlassTabBarHostView
  private let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let params = args as? [String: Any]
    container = LiquidGlassTabBarHostView(params: params)
    channel = FlutterMethodChannel(
      name: "clashking/liquid_glass_tab_bar_\(viewId)",
      binaryMessenger: messenger
    )
    container.frame = frame
    super.init()
    channel.setMethodCallHandler { [weak container] call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let params = call.arguments as? [String: Any]
      DispatchQueue.main.async {
        container?.update(params)
        result(nil)
      }
    }
  }

  func view() -> UIView {
    container
  }
}

@MainActor
private final class LiquidGlassBarModel: ObservableObject {
  @Published var cornerRadius: CGFloat
  @Published var opacity: CGFloat
  @Published var borderColor: UIColor
  @Published var borderOpacity: CGFloat
  @Published var shadowOpacity: CGFloat
  @Published var interactive: Bool
  @Published var selected: Bool
  @Published var isDark: Bool

  init(
    cornerRadius: CGFloat,
    opacity: CGFloat,
    borderColor: UIColor,
    borderOpacity: CGFloat,
    shadowOpacity: CGFloat,
    interactive: Bool,
    selected: Bool,
    isDark: Bool
  ) {
    self.cornerRadius = cornerRadius
    self.opacity = opacity
    self.borderColor = borderColor
    self.borderOpacity = borderOpacity
    self.shadowOpacity = shadowOpacity
    self.interactive = interactive
    self.selected = selected
    self.isDark = isDark
  }

  func update(_ params: [String: Any]?) {
    cornerRadius = CGFloat(codecValue: params?["cornerRadius"]) ?? cornerRadius
    opacity = CGFloat(codecValue: params?["opacity"]) ?? opacity
    borderColor = UIColor(argbValue: params?["borderColor"]) ?? borderColor
    borderOpacity = CGFloat(codecValue: params?["borderOpacity"]) ?? borderOpacity
    shadowOpacity = CGFloat(codecValue: params?["shadowOpacity"]) ?? shadowOpacity
    interactive = params?["interactive"] as? Bool ?? interactive
    selected = params?["selected"] as? Bool ?? selected
    isDark = params?["isDark"] as? Bool ?? isDark
  }
}

private final class LiquidGlassHostView: UIView {
  private let model: LiquidGlassBarModel
  private var hostedController: UIHostingController<AnyView>?

  init(
    cornerRadius: CGFloat,
    opacity: CGFloat,
    borderColor: UIColor,
    borderOpacity: CGFloat,
    shadowOpacity: CGFloat,
    interactive: Bool,
    selected: Bool,
    isDark: Bool
  ) {
    model = LiquidGlassBarModel(
      cornerRadius: cornerRadius,
      opacity: opacity,
      borderColor: borderColor,
      borderOpacity: borderOpacity,
      shadowOpacity: shadowOpacity,
      interactive: interactive,
      selected: selected,
      isDark: isDark
    )
    super.init(frame: .zero)
    backgroundColor = .clear
    isOpaque = false
    isUserInteractionEnabled = false
    setupGlass()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    false
  }

  func update(_ params: [String: Any]?) {
    model.update(params)
    applyInterfaceStyle()
  }

  private func applyInterfaceStyle() {
    let style: UIUserInterfaceStyle = model.isDark ? .dark : .light
    overrideUserInterfaceStyle = style
    hostedController?.overrideUserInterfaceStyle = style
  }

  private func setupGlass() {
    if #available(iOS 26.0, *) {
      let view = AnyView(LiquidGlassBarView(model: model))
      let controller = UIHostingController(rootView: view)
      controller.view.backgroundColor = .clear
      controller.view.isOpaque = false
      controller.view.isUserInteractionEnabled = false
      hostedController = controller
      applyInterfaceStyle()
      addSubview(controller.view)
      controller.view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
        controller.view.trailingAnchor.constraint(equalTo: trailingAnchor),
        controller.view.topAnchor.constraint(equalTo: topAnchor),
        controller.view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
      return
    }

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    blur.alpha = model.opacity
    blur.layer.cornerRadius = model.cornerRadius
    blur.layer.cornerCurve = .continuous
    blur.clipsToBounds = true
    addSubview(blur)
    applyInterfaceStyle()
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: trailingAnchor),
      blur.topAnchor.constraint(equalTo: topAnchor),
      blur.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}

@available(iOS 26.0, *)
private struct LiquidGlassBarView: View {
  @ObservedObject var model: LiquidGlassBarModel

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: model.cornerRadius, style: .continuous)
    let glass = model.interactive ? Glass.regular.interactive() : Glass.regular
    shape
      .fill(model.selected ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.clear))
      .glassEffect(glass, in: shape)
      .overlay {
        shape.stroke(
          Color(uiColor: model.borderColor).opacity(
            model.selected ? max(model.borderOpacity, 0.42) : model.borderOpacity
          ),
          lineWidth: 0.8
        )
      }
      .shadow(
        color: Color.black.opacity(model.selected ? max(model.shadowOpacity, 0.18) : model.shadowOpacity),
        radius: model.selected ? 18 : 22,
        x: 0,
        y: model.selected ? 8 : 12
      )
      .animation(.interactiveSpring(duration: 0.22, extraBounce: 0), value: model.selected)
      .animation(.interactiveSpring(duration: 0.22, extraBounce: 0), value: model.borderOpacity)
      .environment(\.colorScheme, model.isDark ? .dark : .light)
  }
}

@MainActor
private final class LiquidGlassTabBarModel: ObservableObject {
  @Published var itemCount: Int
  @Published var selectedIndex: Int
  @Published var cornerRadius: CGFloat
  @Published var selectedCornerRadius: CGFloat
  @Published var inset: CGFloat
  @Published var borderColor: UIColor
  @Published var borderOpacity: CGFloat
  @Published var shadowOpacity: CGFloat
  @Published var isDark: Bool

  init(params: [String: Any]?) {
    itemCount = max(params?["itemCount"] as? Int ?? 3, 1)
    selectedIndex = params?["selectedIndex"] as? Int ?? 0
    cornerRadius = CGFloat(codecValue: params?["cornerRadius"]) ?? 28
    selectedCornerRadius = CGFloat(codecValue: params?["selectedCornerRadius"]) ?? 20
    inset = CGFloat(codecValue: params?["inset"]) ?? 7
    borderColor = UIColor(argbValue: params?["borderColor"]) ?? UIColor.separator
    borderOpacity = CGFloat(codecValue: params?["borderOpacity"]) ?? 0.28
    shadowOpacity = CGFloat(codecValue: params?["shadowOpacity"]) ?? 0.18
    isDark = params?["isDark"] as? Bool ?? (UITraitCollection.current.userInterfaceStyle == .dark)
  }

  func update(_ params: [String: Any]?) {
    itemCount = max(params?["itemCount"] as? Int ?? itemCount, 1)
    selectedIndex = params?["selectedIndex"] as? Int ?? selectedIndex
    cornerRadius = CGFloat(codecValue: params?["cornerRadius"]) ?? cornerRadius
    selectedCornerRadius = CGFloat(codecValue: params?["selectedCornerRadius"]) ?? selectedCornerRadius
    inset = CGFloat(codecValue: params?["inset"]) ?? inset
    borderColor = UIColor(argbValue: params?["borderColor"]) ?? borderColor
    borderOpacity = CGFloat(codecValue: params?["borderOpacity"]) ?? borderOpacity
    shadowOpacity = CGFloat(codecValue: params?["shadowOpacity"]) ?? shadowOpacity
    isDark = params?["isDark"] as? Bool ?? isDark
  }
}

private final class LiquidGlassTabBarHostView: UIView {
  private let model: LiquidGlassTabBarModel
  private var hostedController: UIHostingController<AnyView>?

  init(params: [String: Any]?) {
    model = LiquidGlassTabBarModel(params: params)
    super.init(frame: .zero)
    backgroundColor = .clear
    isOpaque = false
    isUserInteractionEnabled = false
    setupGlass()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    false
  }

  func update(_ params: [String: Any]?) {
    model.update(params)
    applyInterfaceStyle()
  }

  private func applyInterfaceStyle() {
    let style: UIUserInterfaceStyle = model.isDark ? .dark : .light
    overrideUserInterfaceStyle = style
    hostedController?.overrideUserInterfaceStyle = style
  }

  private func setupGlass() {
    if #available(iOS 26.0, *) {
      let controller = UIHostingController(rootView: AnyView(LiquidGlassTabBarView(model: model)))
      controller.view.backgroundColor = .clear
      controller.view.isOpaque = false
      controller.view.isUserInteractionEnabled = false
      hostedController = controller
      applyInterfaceStyle()
      addSubview(controller.view)
      controller.view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
        controller.view.trailingAnchor.constraint(equalTo: trailingAnchor),
        controller.view.topAnchor.constraint(equalTo: topAnchor),
        controller.view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
      return
    }

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    blur.layer.cornerRadius = model.cornerRadius
    blur.layer.cornerCurve = .continuous
    blur.clipsToBounds = true
    addSubview(blur)
    applyInterfaceStyle()
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: trailingAnchor),
      blur.topAnchor.constraint(equalTo: topAnchor),
      blur.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}

@available(iOS 26.0, *)
private struct LiquidGlassTabBarView: View {
  @ObservedObject var model: LiquidGlassTabBarModel
  @Namespace private var namespace

  var body: some View {
    GeometryReader { proxy in
      let baseShape = RoundedRectangle(cornerRadius: model.cornerRadius, style: .continuous)
      let visible = model.selectedIndex >= 0 && model.selectedIndex < model.itemCount
      let itemWidth = proxy.size.width / CGFloat(max(model.itemCount, 1))
      let selectedWidth = max(itemWidth - model.inset * 2, 1)
      let selectedHeight = max(proxy.size.height - model.inset * 2, 1)
      let selectedShape = RoundedRectangle(cornerRadius: model.selectedCornerRadius, style: .continuous)

      ZStack(alignment: .topLeading) {
        baseShape
          .fill(.clear)
          .glassEffect(.regular, in: baseShape)
          .overlay {
            baseShape.stroke(Color(uiColor: model.borderColor).opacity(model.borderOpacity), lineWidth: 0.8)
          }
          .shadow(color: Color.black.opacity(model.shadowOpacity), radius: 22, x: 0, y: 12)

        if visible {
          selectedShape
            .fill(.regularMaterial)
            .glassEffect(.regular.interactive(), in: selectedShape)
            .glassEffectID("tab-selection", in: namespace)
            .glassEffectTransition(.matchedGeometry)
            .overlay {
              selectedShape.stroke(Color(uiColor: model.borderColor).opacity(max(model.borderOpacity, 0.42)), lineWidth: 0.8)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 14, x: 0, y: 6)
            .frame(width: selectedWidth, height: selectedHeight)
            .offset(
              x: itemWidth * CGFloat(model.selectedIndex) + model.inset,
              y: model.inset
            )
            .animation(.interactiveSpring(duration: 0.26, extraBounce: 0), value: model.selectedIndex)
        }
      }
    }
    .environment(\.colorScheme, model.isDark ? .dark : .light)
  }
}

private extension CGFloat {
  init?(codecValue value: Any?) {
    if let value = value as? CGFloat {
      self = value
    } else if let value = value as? Double {
      self = CGFloat(value)
    } else if let value = value as? Float {
      self = CGFloat(value)
    } else if let value = value as? Int {
      self = CGFloat(value)
    } else {
      return nil
    }
  }
}

private extension UIColor {
  convenience init?(argbValue value: Any?) {
    let rawValue: UInt32
    if let value = value as? Int {
      rawValue = UInt32(truncatingIfNeeded: value)
    } else if let value = value as? Int64 {
      rawValue = UInt32(truncatingIfNeeded: value)
    } else if let value = value as? UInt32 {
      rawValue = value
    } else {
      return nil
    }

    let alpha = CGFloat((rawValue >> 24) & 0xff) / 255.0
    let red = CGFloat((rawValue >> 16) & 0xff) / 255.0
    let green = CGFloat((rawValue >> 8) & 0xff) / 255.0
    let blue = CGFloat(rawValue & 0xff) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}
