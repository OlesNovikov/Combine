# Combine

This is training project taken from LinkedIn course [Learning Combine with Swift](https://www.linkedin.com/learning/learning-combine-with-swift).

<h2>1. Combine Fundamentals</h2>

Combine lifecycle:

<img src="https://tva1.sinaimg.cn/large/e6c9d24egy1h5i7nm205gj21i80u0n2c.jpg" width="600">

**Publisher** exists until minimum 1 subscriber listens. It can return **completion** or **failure**



<h3>1.1 Transmit data with publishers</h3>

```swift
// A simple publisher using Just, to produce once for each subscriber
let _ = Just("Hello world")
    .sink { (value) in
        print("value is \(value)")
}
```

<h3>1.2 Manipulate data with operators</h3>

<img src="https://tva1.sinaimg.cn/large/e6c9d24egy1h5i7y7bitij21jw0u0aef.jpg" width="600">

Operators

<img src="https://tva1.sinaimg.cn/large/e6c9d24egy1h5i802uk8ej21280h0wgf.jpg" width="600">

```swift
//(1) Create a new publisher operator, to square each value, using `map()`
[1,5,9]
    .publisher
    .map { $0 * $0 }
    .sink { print($0) }
```

<h3>1.3 Consume data with subscribers</h3>

```swift
// assign data to label property - text
let label = UILabel()
Just("John")
    .map {"My name is \($0)"}
    .assign(to: \.text, on: label)
```



<h3>1.4 Publish and subscribe to data with subjects</h3>

A **Subject** is considered a special type of **Publisher**, conforming to its own protocol, the `Subject` protocol. Apple defines subjects as *a publisher that exposes a method for outside callers to publish elements*.

A publisher that you can use to inject values into a stream, done through one of its required methods, `send()`, to commonly bridge existing imperative code with Combine.

```swift
//(1) Declare an Int PassthroughSubject
let subject = PassthroughSubject<Int, Never>()

//(2) Attach a subscriber to the subject
let subscription = subject
    .sink{ print($0) }

//(3) Publish the value `94`, via the subject, directly
subject.send(94)
```



<h3>1.5 Publish data once with Future and Just</h3>

**Just** - publisher wich publish value once, then finish execution

**Future** - publisher wich will perform value in the future with a `promise`

```swift
let future = Future<String, FutureError> { promise in
    let calendar = Calendar.current
    let second = calendar.component(.second, from: Date())
    print("second is \(second)")
    if second.isMultiple(of: 3){
        promise(.success("We are successful: \(second)"))
    } else {
        promise(.failure(.notMultiple))
    }
}
    .catch { error in
        Just("Caught the error")
    }
    .delay(for: .init(1), scheduler: RunLoop.main)
    .eraseToAnyPublisher()

future.sink(receiveCompletion: { print($0) },
            receiveValue: { print($0) })
```



<h2>2. Work with REST APIs</h2>

<h3>2.1 Call REST API with DataTaskPublisher</h3>

```swift
//(1) Create a `dataTaskPublisher`
let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
let publisher = URLSession.shared.dataTaskPublisher(for: url!)
    .map {$0.data}
    .decode(type: [Post].self, decoder: JSONDecoder())

//(2) Subscribe to the publisher
let cancellableSink = publisher
    .sink(receiveCompletion: { completion in
        print(String(describing: completion))
    }, receiveValue: { value in
        print("returned value \(value)")
    })
```



<h3>2.2 Handle errors with Combine</h3>

```swift
enum APIError: Error{
    case networkError(error: String)
    case responseError(error: String)
    case unknownError
}

//(1) Create a `dataTaskPublisher`
let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
let publisher = URLSession.shared.dataTaskPublisher(for: url!)
    .map { $0.data }
    .decode(type: [Post].self, decoder: JSONDecoder())

//(2) Subscribe to the publisher with `mapError` Error handling
let cancellableSink = publisher
    .retry(2)
    .mapError{ error -> Error in
        switch error{
        case URLError.cannotFindHost:
            return APIError.networkError(error: error.localizedDescription)
        default:
            return APIError.responseError(error: error.localizedDescription)
        }
    }
    .sink(receiveCompletion: {completion in
        print(String(describing: completion))
    }, receiveValue: {value in
        print("returned value \(value)")
    })
```



<h3>2.3 Unit testing and Combine</h3>

```swift
func testPublisher() {
        let _ = APIService.getPosts()
        .sink(receiveCompletion: { error in
            print("Completed subscription \(String(describing:error))")
        }, receiveValue: {results in
            print("Got \(results.count) posts back")
            XCTAssert(results.count > 0)
            XCTAssert(results.count == 100,
                      "We got \(results.count) instead of 100 posts back")
            XCTAssert(results[0].title == self.expectedTitle,
                      "We got back the title \(results[0].title) instead of \(self.expectedTitle)")
        })
        .store(in: &subscriptions)
    }
```

Using several operators in calling to API endpoint:

```swift
let emptyPost = Post(userId: 0, id: 0, title: "Empty", body: "No Results")

//(1) Create a `dataTaskPublisher`
let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
let publisher = URLSession.shared.dataTaskPublisher(for: url!)
    .map { $0.data }
    .decode(type: [Post].self, decoder: JSONDecoder())
    .map{ $0.first }
    .replaceNil(with: emptyPost)
    .compactMap({ $0.title })

//(2) Subscribe to the publisher
let cancellableSink = publisher
    .sink(receiveCompletion: { completion in
        print(String(describing: completion))
    }, receiveValue: { value in
        print("returned value \(value)")
    })
```



<h2>3. Advanced Concepts</h2>

<h3>3.1 Manage threads with schedulers</h3>

​	Schedulers allow you to orchestrate where and when to publish, and knowing how to queue your upstream publishers, or downstream subscription streams, whether they should be processing in the background, in your main thread, sequence serially or concurrently. When using Combine to update your application’s UI elements, it is crucial you optimize your streams to use the main thread, but to also not degrade the user experiences.

```swift
let publisher = URLSession.shared.dataTaskPublisher(for: url!)
    .map { $0.data }
    .decode(type: [Post].self, decoder: JSONDecoder())
    .receive(on: ImmediateScheduler.shared)

let cancellableSink = publisher
    .subscribe(on: queue)
    //.receive(on: DispatchQueue.global())
    .sink(receiveCompletion: { completion in
        print("Subscriber: On main thread?: \(Thread.current.isMainThread)")
        print("Subscriber: thread info: \(Thread.current)")
    }, receiveValue: { value in
        print("Subscriber: On main thread?: \(Thread.current.isMainThread)")
        print("Subscriber: thread info: \(Thread.current)")
    })
```



<h3>3.2 Work with custom publishers and subscribers</h3>

```swift
extension Publisher{
    
    func isPrimeInteger<T: BinaryInteger>() -> Publishers
        .CompactMap<Self, T> where Output == T {
            compactMap{self.isPrime($0)}
    }
  // func isPrime<T: BinaryInteger>(_ n: T) -> T? { ... }
}

let numbers:[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
numbers
    .publisher
    .isPrimeInteger()
    .sink { print($0) }
```



<h3>3.3 Throttle publisher data with backpressure</h3>

```swift
class CitySubscriber: Subscriber {
  //Tells the subscriber that we have successfully subscribed and may request items and it can send values. We enter how many values we want to receive from the publisher.
   func receive(subscription: Subscription) {
        subscription.request(.max(2))
     //subscription.request(.unlimited)
   }
  //Tells the subscriber that the publisher has produced an element, and we can use this method to output the results, and returns the requested number of items, sent to a publisher from a subscriber via the subscription.
   func receive(_ input: String) -> Subscribers.Demand {
        print("City: \(input)")
        return .none
   }
  //Tells the subscriber that the publisher has completed publishing, either normally or with an error
   func receive(completion: Subscribers.Completion<Never>) {
        print("Subscription \(completion)")
   }
}

let citySubscription = CitySubscriber()
cityPublisher.subscribe(citySubscription)
```



<h3>3.4 Abstract Combine implementations with type erasures</h3>

```swift
let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
let publisher = URLSession.shared.dataTaskPublisher(for: url!)
    .map {$0.data}
    .decode(type: [Post].self, decoder: JSONDecoder())
//(1) Add `.eraseToAnyPublisher()`
    .eraseToAnyPublisher()
```



<h3>3.5 Leverage the Combine advanced operators</h3>

Operators wich can be used (filtering, aggregating and demanding...)

```swift
let numbers = (1...20)
    .publisher

let numbersTwo = (21...40)
    .publisher

let words = (21...40)
		.compactMap { String($0) }
    .publisher

let cancellableSink = numbers
    //.filter {$0 % 2 == 0}
    //.compactMap{value in Float(value)}
    //.first()
    //.last(where: {$0 < 20 })
    //.dropFirst()
    //.drop(while: {$0 % 3 == 0} )
    //.prefix(4)
    //.prefix(while: {$0 < 5})
    //.append(21,22,23)
    //.prepend(21,22,23)
    //.merge(with: numbersTwo)
    //.combineLatest(words)
    //.zip(numbersTwo)
    //.collect()
    //.throttle(for: .seconds(2), scheduler: DispatchQueue.main, latest: true)
    .sink {print($0)}
```

