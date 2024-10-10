import Foundation

struct Address: Codable {
    let street: String
    let city: String
    let postalCode: String
}

struct Student: Codable {
    let id: Int
    let name: String
    let age: Int
    let subjects: [String]
    let address: Address
    let scores: [String: Int?]
    let hasScholarship: Bool
    let graduationYear: Int
}

// Function to write Data to OutputStream
func writeData(_ data: Data, to outputStream: OutputStream) -> Int {
    var totalBytesWritten = 0
    data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
        guard let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self).baseAddress else {
            return
        }
        var bytesRemaining = data.count
        while bytesRemaining > 0 {
            let bytesWritten = outputStream.write(bufferPointer.advanced(by: totalBytesWritten), maxLength: bytesRemaining)
            if bytesWritten <= 0 {
                fatalError("Failed to write to output stream")
            }
            bytesRemaining -= bytesWritten
            totalBytesWritten += bytesWritten
        }
    }
    return totalBytesWritten
}

// Function to generate a random student
func generateStudent(id: Int) -> Student {
    let names = ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Hannah", "Isaac", "Jack", "Karen"]
    let streets = ["123 Main St", "456 Elm St", "789 Maple Ave", "101 Pine Rd", "202 Oak Dr"]
    let cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix"]
    let postalCodes = ["10001", "90001", "60601", "77001", "85001"]
    let subjectsList = ["Math", "Physics", "Chemistry", "Biology", "History", "English", "Computer Science"]

    let name = names.randomElement()!
    let age = Int.random(in: 18...25)
    let subjects = Array(subjectsList.shuffled().prefix(Int.random(in: 2...5)))
    let address = Address(
        street: streets.randomElement()!,
        city: cities.randomElement()!,
        postalCode: postalCodes.randomElement()!
    )
    var scores = [String: Int?]()
    for subject in subjects {
        scores[subject] = Int.random(in: 60...100)
    }
    // Randomly assign nil to some scores
    if Bool.random(), let subjectToNullify = subjects.randomElement() {
        scores[subjectToNullify] = nil
    }

    let hasScholarship = Bool.random()
    let graduationYear = Int.random(in: 2024...2028)

    return Student(
        id: id,
        name: name,
        age: age,
        subjects: subjects,
        address: address,
        scores: scores,
        hasScholarship: hasScholarship,
        graduationYear: graduationYear
    )
}

// Main code to generate the JSON file
let fileURL = URL(fileURLWithPath: "students.json")
guard let outputStream = OutputStream(url: fileURL, append: false) else {
    fatalError("Unable to create output stream")
}
outputStream.open()
defer {
    outputStream.close()
}

let desiredFileSizeInBytes = 3 * 1024 * 1024 * 1024 // 3GB
var totalBytesWritten = 0

// Write the opening of the JSON object
let opening = "{ \"students\": [".data(using: .utf8)!
totalBytesWritten += writeData(opening, to: outputStream)

var isFirstStudent = true
var studentId = 1
let jsonEncoder = JSONEncoder()
jsonEncoder.outputFormatting = [.sortedKeys]

while totalBytesWritten < desiredFileSizeInBytes {
    let student = generateStudent(id: studentId)
    let studentData: Data
    do {
        studentData = try jsonEncoder.encode(student)
    } catch {
        fatalError("Failed to encode student: \(error)")
    }
    var dataToWrite = Data()
    if isFirstStudent {
        isFirstStudent = false
    } else {
        dataToWrite.append(",".data(using: .utf8)!)
    }
    dataToWrite.append(studentData)
    let bytesWritten = writeData(dataToWrite, to: outputStream)
    totalBytesWritten += bytesWritten
    studentId += 1
    if studentId % 1000 == 0 {
        print("Generated \(studentId) students, total bytes written: \(totalBytesWritten)")
    }
}

// Write the closing of the JSON object
let closing = "]}".data(using: .utf8)!
totalBytesWritten += writeData(closing, to: outputStream)

print("Finished generating JSON file at \(fileURL.path)")
