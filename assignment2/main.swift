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



// MARK: - Task 4 (optional): JSON Parsing. JSON strikes back

extension Student {
    func printInfo() {
        print("""
        ID: \(id). Name: \(name). Age: \(age). Address: \(address.street), \(address.city), \(address.postalCode).
        \(scores.map { "\($0.key): \($0.value.map(String.init) ?? "N/A")" }.joined(separator: ", ")).
        Has Scholarship: \(hasScholarship ? "Yes" : "No"). Graduation Year: \(graduationYear)\n
        """)
    }
}

enum ModelParserError: Error {
    case parsingFailed(String)
}

class ModelParser {
    private let url: URL
    private var jsonData: Data = Data()
    var students: [Student] = []
    
    init(from filename: String) {
        url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent(filename)
    }
    
    func parseJSON() throws -> [Student] {
        guard let inputStream = InputStream(url: url) else {
            throw ModelParserError.parsingFailed("Failed to open input stream from \(url).")
        }
        
        inputStream.open()
        defer { inputStream.close() }
        var buffer = [UInt8](repeating: 0, count: 2048)
        
        var isFirstChunk = true
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead < 0 {
                throw ModelParserError.parsingFailed("Error reading from input stream")
            }
            
            jsonData.append(buffer, count: bytesRead)
            try processChunk(isFirstChunk)
            isFirstChunk = false
        }
            
        return students
    }
    
    private func processChunk(_ isFirstChunk: Bool) throws {
        let decoder = JSONDecoder()
        if var chunk = String(data: jsonData, encoding: .utf8) {
            if isFirstChunk, let arrayRange = chunk.range(of: "[{") {  // discard `{ "students": [`
                chunk = "{" + String(chunk[arrayRange.upperBound...])
            }
            
            while let studentRange = chunk.range(of: "},{") {  // read student by student
                let studentChunk = Data((chunk[..<studentRange.lowerBound] + "}").utf8)
                guard let student = try? decoder.decode(Student.self, from: studentChunk) else {
                    throw ModelParserError.parsingFailed("Failed to decode JSON from \(url).")
                }
                
                students.append(student)
                print("Added student \(student.id)")
                chunk = "{" + String(chunk[studentRange.upperBound...])
            }
            
            jsonData = Data(chunk.utf8)
        }
    }
}

let path = "students.json"
do {
    generateStudentsJSON(3 * 1024 * 1024 * 1024)  // 3GB
    let students = try ModelParser(from: path).parseJSON()
    print("There're \(students.count) students.")
} catch {
    print(error)
}
