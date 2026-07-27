import SwiftUI

struct ListView: View {
   var body: some View {
    ScrollView {
        VStack {
            ForEach(0..<10) { index in
                Text("Item \(index)")
                    .font(.system(size: 24, weight: .bold))
                    .padding()
            } 
        }
    }

   }
}

struct HomeView : View {
    var body: some View {
        ListView()
    }
}

