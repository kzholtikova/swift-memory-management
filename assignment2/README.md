# Task 1: Break the retain cycle (3 points)
Here's a setup code:
```
class Apartment {
    let number: Int
    var tenant: Person?
    
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

var person: Person? = Person(name: "/*WRITE YOUR NAME HERE*/")

person?.setupApartment(Apartment(number: 42))

person?.apartment?.tenant = person
person?.getInfo()
person?.apartment?.getInfo()

person = nil
```
## 1 point
Fix the retain cycle in the code above. Please, do not modify existing methods. Make sure that all objects are deallocated when the `person` object is set to `nil`. In other words: `print` inside the all `deinit` methods should be called. 

## 2 points
Try to make references for `Person` and `Apartment` objects weak and unowned. Explain the difference for this code in the comment. If you can't make them weak or unowned, explain why.

# Task 2: Weak Nodes (4 points)
Take the code from a first Homework (HW1, Task 3: Recursive Data Structure).
Let's add a new property to the Node class named `neighbors`. They property should be an array storing a reference to the neighbors nodes. Make sure those reference don't increase a reference count of the nodes. Here's some code to start with:
```
func addNeighbor(_ node: Node) {
...
}

let node1 = Node(value: 1) // values is just an example to show that nodes are different
let node2 = Node(value: 2)
let node3 = Node(value: 3)

node1.addNeighbor(node2)
node2.addNeighbor(node3)
node3.addNeighbor(node1)
```

# Task 3: Custom copy on write (3 points)
## 4 points
Create a `MyData` class that holds an array of integers (or a class wrapper around array) and implements custom Copy-on-Write (CoW) behavior. 
When you copy an instance of MyData, it should share the same underlying data until one of the instances is mutated, at which point it should create its own copy of the data. 
Use Swift's isKnownUniquelyReferenced function to check if the storage is uniquely referenced before mutating.

#Task 4 (optional): JSON Parsing. JSON strikes back (3 points)
In a galaxy not so far away, students once triumphed over the challenge of reading a small JSON file. But peace was short-lived...
Now, a new task emerges from the shadows. The JSON is larger, the stakes higher.
You have a `main.swift` file with an algorithm that generates a large JSON file (3GB) with an array of students info. The structure of the JSON file is the same as in the previous homework. 
You will need to read this file and print information about each student in it. 
Hint: Do not try to read the whole file at once.
