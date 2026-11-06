import ExpoModulesCore
import UIKit

/** A transparent measuring surface. It never moves native navigation or
 * intercepts a touch; its rectangles are local to the page content wrapper. */
public final class ReservedRegionObserverView: ExpoView {
  let onReservedRegionsChange = EventDispatcher()
  private var measuredBounds = CGRect.zero
  private var lastPayload: NSDictionary?

  public required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    isUserInteractionEnabled = false
    isAccessibilityElement = false
  }

  public override class var requiresConstraintBasedLayout: Bool { true }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    lastPayload = nil
    setNeedsUpdateConstraints()
  }

  public override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsUpdateConstraints()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    if measuredBounds != bounds {
      measuredBounds = bounds
      setNeedsUpdateConstraints()
    }
  }

  public override func updateConstraints() {
    // UIKit tracks reserved-region reads during this method and invalidates
    // constraints when a fold/camera region changes, including without rotation.
    publishRegions()
    super.updateConstraints()
  }

  private func publishRegions() {
    guard window != nil, bounds.width > 0, bounds.height > 0 else { return }
    var regions: [[String: Any]] = []
    #if canImport(UIKit, _version: 9127.0.85)
    if #available(iOS 27.1, *) {
      for (kind, name) in [(UIView.ReservedRegion.Kind.division, "division"), (.occlusion, "occlusion")] {
        for region in reservedRegions(kind: kind) where region.isActive {
          let raw = region.frame
          // A division may be a zero-width/height line. CGRect.intersection
          // treats some such boundary intersections as empty, so clip manually.
          let left = max(bounds.minX, raw.minX)
          let top = max(bounds.minY, raw.minY)
          let right = min(bounds.maxX, raw.maxX)
          let bottom = min(bounds.maxY, raw.maxY)
          guard right >= left, bottom >= top else { continue }
          let frame = CGRect(x: left, y: top, width: right - left, height: bottom - top)
          guard name == "division" ? (frame.width > 0 || frame.height > 0) : (frame.width > 0 && frame.height > 0) else { continue }
          // Apple's frame already includes the region's interactive margins.
          regions.append([
            "kind": name,
            "x": frame.minX,
            "y": frame.minY,
            "width": frame.width,
            "height": frame.height,
          ])
        }
      }
    }
    #endif
    let payload: [String: Any] = [
      "width": bounds.width,
      "height": bounds.height,
      "safeArea": [
        "top": safeAreaInsets.top,
        "right": safeAreaInsets.right,
        "bottom": safeAreaInsets.bottom,
        "left": safeAreaInsets.left,
      ],
      "regions": regions,
    ]
    let next = payload as NSDictionary
    guard lastPayload?.isEqual(next) != true else { return }
    lastPayload = next
    onReservedRegionsChange(payload)
  }
}
