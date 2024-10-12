import Foundation


// MARK: - Task 1: Break the retain cycle
class Apartment {
    let number: Int
    weak var tenant: Person?  // <- use `weak` here
    
    init(number: Int) {
        self.number = number
    }
    
    func getInfo() {
        print("Apartment \(number) hosting \(tenant?.name.description ?? "empty")")
    }
    
    deinit {
        print("Apartment deinitialized")
    }
}

class Person {
    let name: String
    var apartment: Apartment?
    
    init(name: String) {
        self.name = name
    }
    
    func setupApartment(_ apartment: Apartment) {
        self.apartment = apartment
    }
    
    func getInfo() {
        print("Person \(name) is in Apartment \(apartment?.number.description ?? "empty")")
    }
    
    deinit {
        print("Person deinitialized")
    }
}

var person: Person? = Person(name: "Kira")

person?.setupApartment(Apartment(number: 42))

person?.apartment?.tenant = person
person?.getInfo()
person?.apartment?.getInfo()

person = nil

// Ref to appartment in a Person can't be neither weak nor unowned: ARC count = 0 => apartment is deinitialized right after the initialization.
// Weak and unowned ref to tenant in a Apartment both break the retain cycle.
// Weak ref can hold nil => objects lifetimes doesn't interfere.
// Unowned ref presumes a Person is valid from the onset and will outlive an Apartment.



// MARK: - Task 2: Weak Nodes

class Node {
    var value : Int
    var children : [Node]
    var neighbors: [weakNode]
    
    init(value: Int) {
        self.value = value
        self.children = []
        self.neighbors = []
    }
    
    deinit {
        print("Node \(value) deinitialized")
    }
    
    func addNeighbor(_ neighbor: Node) {
        neighbors.append(weakNode(from: neighbor))
    }
}

struct weakNode {
    weak var node: Node?
    
    init(from node: Node) {
        self.node = node
    }
}

var node1 = Node(value: 1)
var node2 = Node(value: 2)
var node3 = Node(value: 3)

node1.addNeighbor(node2)
node2.addNeighbor(node3)
node3.addNeighbor(node1)

if isKnownUniquelyReferenced(&node1) && isKnownUniquelyReferenced(&node2) && isKnownUniquelyReferenced(&node3) {
    print("\nReference counts aren't affected by neighbors.\n")
} else {
    print("\nThere're other strong references to the nodes!\n")
}



// MARK: - Task 3: Custom copy on write

class IntArray {  // wrapper class to ensure array is ref type
    var array: [Int]
    
    init(array: [Int]) {
        self.array = array
    }
}

struct MyData {  // value type to disable auto CoW
    private var data: IntArray

    init(data: [Int] = []) {
        self.data = IntArray(array: data)
    }
    
    private mutating func copyOnWrite() {
        print("Is the Int array uniquely referenced: \(isKnownUniquelyReferenced(&data))")
        if !isKnownUniquelyReferenced(&data) {
            data = IntArray(array: data.array)
        }
    }
    
    subscript(index: Int) -> Int {
        get { return data.array[index] }
        set {
            copyOnWrite()
            data.array[index] = newValue
        }
    }
    
    mutating func append(_ element: Int) {
        copyOnWrite()
        data.array.append(element)
        print("Is the Int array uniquely referenced after mutating: \(isKnownUniquelyReferenced(&data))")
    }
    
    mutating func remove(at index: Int) {
        copyOnWrite()
        data.array.remove(at: index)
        print("Is the Int array uniquely referenced after mutating: \(isKnownUniquelyReferenced(&data))")
    }
    
    func count() -> Int {
        return data.array.count
    }
    
    func printArray() {
        print(data.array)
    }
}

var numbers = MyData(data: [1, 2, 3])
var numbers2 = numbers
print("Initial array: ")
numbers.printArray()

numbers.append(4)
print("Mutated array: ")
numbers.printArray()
print("Unchanged array: ")
numbers2.printArray()
print()


