/*:
 # Chapter 2.6 - Future and Just (Finish)
 Future and Just are two special types of Publishers. Just emits just once, before terminating, whereas Future culminates in a single result, either an output value or failure completion, initialized by wrapping any asynchronous call.
 */

import Foundation
import Combine


// (1) A simple publisher using Just, to produce once to each subscriber, before 💀
let _ = Just("A data stream")
    .sink { (value) in
        print("value is \(value)")
    }

// (2) Connect subject to a publisher, and publish the value `29`
let subject = PassthroughSubject<Int, Never>()

Just(29)
    .subscribe(subject)

// (3) A simple use of Future, in a function
enum FutureError: String, Error {
    case notMultiple2 = "The number is not a multiple of 2"
    case notMultipleOf2and4 = "The number is not a multiple of 2 and 4"
}

let future = Future<String, FutureError> { promise in
    let second = Calendar.current.component(.second, from: Date())
    print("second is \(second)")
    if second.isMultiple(of: 2) {
        if second.isMultiple(of: 4) {
            promise(.success("the number is a multiple of 2 and 4!"))
        } else {
            promise(.failure(.notMultipleOf2and4))
        }
    } else {
        promise(.failure(.notMultiple2))
    }
}
    .catch{ customError in
        Just(customError.rawValue)
    }
    .delay(for: .init(1), scheduler: RunLoop.main)
    .eraseToAnyPublisher()

let subscriber = future.sink { print($0) }
