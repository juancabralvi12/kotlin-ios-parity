import SwiftUI
import Foundation

@MainActor
final class ListViewModel: ObservableObject {
    @Published private(set) var items: [FeedItem] = []
    private let loader = RemoteFeedLoader(url: URL(string: "http://localhost:8080/v1/items")!, client: URLSessionHTTPClient(session: URLSession.shared))

    func load() async {
        do {
            items = try await loader.load()
        } catch {
            print("Failed to load feed items: \(error)")
        }
    }
}

struct ListView: View {
    @StateObject private var vm = ListViewModel()

   var body: some View {
    ScrollView {
        VStack {
            ForEach(vm.items) { item in
                Text("Item \(item.title)")
                    .font(.system(size: 24, weight: .bold))
                    .padding()
            } 
        }
    }.task {
        await vm.load()
    }

   }
}

struct HomeView : View {
    var body: some View {
        ListView()
    }
}
