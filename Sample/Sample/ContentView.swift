//
//  ContentView.swift
//  Sample
//
//  Created by David Okun on 5/24/20.
//  Copyright © 2020 David Okun. All rights reserved.
//

import SwiftUI
import Lumina

struct ContentView: View {
  var body: some View {
    Lumina()
      .cameraPosition(.front)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
