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
