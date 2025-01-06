import SwiftUI
import LanguageClient
import LanguageServerProtocol
import JSONRPC

import OSLog

struct ContentView: View {
    @State var viewModel = ViewModel()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Button("Boot up") {
                print("Boot button pressed!")
                viewModel.setup()
            }
        }
        .frame(width: 200, height: 200)
        .padding()
    }
}

#Preview {
    ContentView()
}

extension ContentView {

    @Observable
    class ViewModel {

        private let logger = Logger(subsystem: "com.Expedia.ek.ConformanceFinder", category: "ViewModel")

        func setup() {

            let executionParams = Process.ExecutionParameters(
                path: "/usr/bin/sourcekit-lsp",
                arguments: ["--log-level", "debug"],
                environment: ProcessInfo.processInfo.userEnvironment
            )

            let channel = try! DataChannel.localProcessChannel(
                parameters: executionParams,
                terminationHandler: { print("terminated") }
            )

            let localServer = JSONRPCServerConnection(dataChannel: channel)

            let docURL = URL(fileURLWithPath: "/Users/ekrietsch/dev/SuperSimpleConformancePackage/Sources/SuperSimpleConformancePackage/SuperSimpleConformancePackage.swift")

            let projectURL = URL(fileURLWithPath: "/Users/ekrietsch/dev/SuperSimpleConformancePackage/", isDirectory: true)

            let provider: InitializingServer.InitializeParamsProvider = {
                // you may need to fill in more of the textDocument field for completions
                // to work, depending on your server
                let capabilities = ClientCapabilities(workspace: nil,
                                                      textDocument: nil,
                                                      window: nil,
                                                      general: nil,
                                                      experimental: nil)

                // pay careful attention to rootPath/rootURI/workspaceFolders, as different servers will
                // have different expectations/requirements here
                return InitializeParams(processId: Int(ProcessInfo.processInfo.processIdentifier),
                                        locale: nil,
                                        rootPath: projectURL.path,
                                        rootUri: projectURL.absoluteString,
                                        initializationOptions: nil,
                                        capabilities: capabilities,
                                        trace: nil,
                                        workspaceFolders: [.init(uri: projectURL.absoluteString, name: "SuperSimpleConformancePackage")])
            }

            let server = InitializingServer(server: localServer, initializeParamsProvider: provider)

            Task {
                let logger = Logger(subsystem: "com.Expedia.ek.ConformanceFinder", category: "TypeHierarchyRequests")
                logger.info("Sending type hierarchy requests...")

                let docContent = try String(contentsOf: docURL)

                let doc = TextDocumentItem(
                    uri: docURL.absoluteString,
                    languageId: .swift,
                    version: 1,
                    text: docContent
                )

                let docParams = DidOpenTextDocumentParams(textDocument: doc)

                try await server.textDocumentDidOpen(docParams)

                // make sure to pick a reasonable position within your test document
                let pos = Position(line: 20, character: 10)

                let docIdentifier = TextDocumentIdentifier(uri: docURL.absoluteString)
                let prepareHierarchyParams = TypeHierarchyPrepareParams(textDocument: docIdentifier, position: pos, workDoneToken: nil)
                let prepareResponse = try await server.prepareTypeHeirarchy(prepareHierarchyParams)
                logger.info("Prepare Response: \(prepareResponse.debugDescription)")

                let subtypeItem = prepareResponse?.first ?? heirarchyItem(uri: docURL.absoluteString, pos: pos)

                let subtypeParams = TypeHierarchySubtypesParams(item: subtypeItem)
                let subtypesResponse = try await server.typeHierarchySubtypes(subtypeParams)

                logger.info("Subtype Response: \(subtypesResponse.debugDescription)")

                let supertypeParams = TypeHierarchySupertypesParams(item: subtypeItem)
                let supertypesResponse = try await server.typeHierarchySupertypes(supertypeParams)

                logger.info("Supertype Response: \(supertypesResponse.debugDescription)")
            }

            Task {
                let logger = Logger(subsystem: "com.Expedia.ek.ConformanceFinder", category: "HoverRequests")
                logger.info("Sending hover request...")

                let docContent = try String(contentsOf: docURL)

                let doc = TextDocumentItem(
                    uri: docURL.absoluteString,
                    languageId: .swift,
                    version: 1,
                    text: docContent
                )

                let docParams = DidOpenTextDocumentParams(textDocument: doc)

                try await server.textDocumentDidOpen(docParams)

                // make sure to pick a reasonable position within your test document
                let pos = Position(line: 20, character: 10)

                let docIdentifier = TextDocumentIdentifier(uri: docURL.absoluteString)

                let hoverParams = TextDocumentPositionParams(textDocument: docIdentifier, position: pos)
                let hoverResponse = try! await server.hover(hoverParams)

                logger.info("Hover Response: \(hoverResponse.debugDescription)")
            }


            Task {
                let logger = Logger(subsystem: "com.Expedia.ek.ConformanceFinder", category: "EventSequence")
                logger.info("Waiting for events...")
                for await event in server.eventSequence {
                    logger.info("Received event!")
                    switch event {
                    case .error(let error):
                        logger.info("  event error: \(error)")
                    case .notification(let notification):
                        logger.info("  event notification: \(String(describing: notification))")
                    case .request(id: _, request: let request):
                        logger.info("  event request: \(String(describing: request))")
                    }
                }
            }
        }

        func heirarchyItem(uri: DocumentUri, pos: Position) -> TypeHierarchyItem {
            TypeHierarchyItem(
                name: "SomeName",
                kind: .class,
                tags: nil,
                detail: nil,
                uri: uri,
                range: LSPRange(start: pos, end: pos),
                selectionRange: LSPRange(start: pos, end: pos),
                data: nil
            )

        }
    }
}

