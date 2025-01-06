// The Swift Programming Language
// https://docs.swift.org/swift-book

protocol MySpecialProtocol { 
    var name: String { get }
}

struct FirstConformingType: MySpecialProtocol { 
    let name = "First Type"
}

struct SecondConformingType: MySpecialProtocol { 
    let name = "Second Type"
}

struct ThirdConformingType: MySpecialProtocol { 
    let name = "Third Type"
}

class MyBaseClass {
    var name: String = "Base Class"
}

class FirstSubClass: MyBaseClass {
    override init() {
        super.init()
        self.name = "First Sub Class"
    }
}
