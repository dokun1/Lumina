import SwiftUI

public struct Lumina: View {
  var cameraPosition: Lumina.CameraPosition = .back
  var customFrame: CGRect = UIScreen.main.bounds
  
  public init() {}
  
  public var body: some View {
    Lumina.CameraView(cameraPosition: cameraPosition, customFrame: customFrame)
      .edgesIgnoringSafeArea(.all)
  }
}

extension Lumina {
  public func cameraPosition(_ position: Lumina.CameraPosition) -> Lumina {
    var result = self
    result.cameraPosition = position
    return result
  }
  
  public func customFrame(_ frame: CGRect) -> Lumina {
    var result = self
    result.customFrame = frame
    return result
  }
}

struct Lumina_Previews: PreviewProvider {
  static var previews: some View {
    Lumina()
  }
}
