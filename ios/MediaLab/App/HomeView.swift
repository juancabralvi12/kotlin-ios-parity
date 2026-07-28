import SwiftUI
import Foundation

@MainActor
final class ListViewModel: ObservableObject {
    @Published private(set) var items: [FeedItem] = []
    private let loader = RemoteFeedLoader(url: URL(string: "http://localhost:8080/v1/items")!, client: URLSessionHTTPClient(session: URLSession.shared))

    func load() {
        loader.load { [weak self] result in
            switch result {
            case let .success(items):
                self?.items = items
            case let .failure(error):
                print("Failed to load feed items: \(error)")
            }
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
        vm.load()
    }

   }
}

struct HomeView : View {
    var body: some View {
        ListView()
    }
}
