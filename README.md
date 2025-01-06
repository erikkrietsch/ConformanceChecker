# ConformanceChecker

This repo is a combination of two projects: 

- ConformanceFinder
- SuperSimpleConformancePackage

`ConformanceFinder` is a very stupid, very basic macOS SwiftUI app which is 
basically just a way to for me to test out using the interface provided by 
[LanguageClient](https://github.com/ChimeHQ/LanguageClient). My goal with this 
proof-of-concept project is to be able to traverse an Xcode project/Swift 
Package and determine which types conform to a given protocol. Xcode provides 
this information in a search menu, but I would like to be able to access this 
data from the commandline in order to automate via a script. This project 
represents my exploration of this topic, warts and all.

`SuperSimpleConformancePackage` is what I'm using as input for the sourcekit-lsp
integration. As the name suggests, it's dead simple and consists entirely of a 
single source file which contains all the necessary types to showcase the type 
of functionality I'm looking to achieve through sourcekit-lsp. But to break it
down, I've got:

- `MySpecialProtocol` is a protocol with a single property declaration
- `FirstConformingType` is a struct which declares conformance to `MySpecialProtocol`
- `SecondConformingType` follows suit with `FirstConformingType`

- `MyBaseClass` is a base class to illustrate traditional type inheritance
- `FirstSubClass` is a sub class of `MyBaseClass`

That's it. That's all there is to it. My aim is to use the LSP `textDocument/typeHierarchy`
category of requests in order to expose conformance and inheritance given the 
setup provided in the sample Swift Package.
