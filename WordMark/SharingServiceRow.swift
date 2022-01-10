//
//  SharingServiceRow.swift
//  WordMark
//
//  Created by Hao Liu on 1/5/22.
//

import SwiftUI

struct SharingServiceRow: View {
  // The data of service to show.
  var data: SharingService
  
  var body: some View {
    if let provider = SharingProvider(rawValue: data.provider) {
      HStack {
        Image(provider.imageName)
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 24.0, height: 24.0)
        
        switch provider  {
        case .github:
          Text("\(data.repository ?? "Unknown repository")")
            .lineLimit(1)
        case .medium:
          Text("\(data.name ?? "Unknown user")")
            .lineLimit(1)
        }
      }
    } else {
      EmptyView()
    }
  }
}
