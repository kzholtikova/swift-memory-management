import Foundation


// MARK: - Task 1: Break the retain cycle (3 points)
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
