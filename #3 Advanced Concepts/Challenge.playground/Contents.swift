/*:
In this challenge, you will apply many of the concepts you’ve learned in the chapter, by using a Delay, and Backpressure to control the data consumed
*/

import Foundation
import Combine

var queue: DispatchQueue = DispatchQueue(label: "Queue")

// (1) Set a delay of 3 seconds before retrieving data
let numberPublisher = (0...100)
    .publisher
    .delay(for: 3.0, scheduler: queue)
    
// (2) Create a custom Subscriber that implements Backpressure.
final class CustomSubscriber: Subscriber {
    
    typealias Input = Int
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        subscription.request(.max(5))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("Number: \(input)")
        return .none
    }

    func receive(completion: Subscribers.Completion<Never>) {
        print("Subscription \(completion)")
    }

}
let subscription = CustomSubscriber()
numberPublisher.subscribe(subscription)

