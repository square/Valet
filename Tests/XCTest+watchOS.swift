//
//  XCTest+watchOS.swift
//  Valet
//
//  Created by Dan Federman on 3/3/18.
//  Copyright © 2018 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if os(watchOS)
    import Foundation
    import ObjectiveC


    // MARK: - XCTestCase

    /// A bare-bones re-implementation of XCTestCase for running tests from the watch extension.
    @objcMembers
    class XCTestCase: NSObject {

        // MARK: Class Internal

        class func runAllTests() {
            let testClasses = allTestClasses()

            for testClass in testClasses {
                let testInstance = testClass.init()
                let testSelectors = allTestSelectors(in: testClass)

                testSelectors.forEach {
                    testInstance.setUp()
                    print("Executing \(testClass).\($0)")
                    testInstance.perform($0)
                    testInstance.tearDown()
                    print("- PASSED: \(testClass).\($0)")
                }
                print("\n")
            }
            print("ALL TESTS PASSED")
            exit(0)
        }

        // MARK: Class Private

        class private func allTestSelectors(in testClass: XCTestCase.Type) -> [Selector] {
            var testSelectors = [Selector]()

            var methodCount: UInt32 = 0
            guard let methodList = class_copyMethodList(testClass, &methodCount) else {
                return testSelectors
            }

            for methodIndex in 0..<Int(methodCount) {
                let method = methodList[methodIndex]
                let selector = method_getName(method)
                let selectorName = sel_getName(selector)
                let methodName = String(cString: selectorName, encoding: .utf8)!

                guard methodName.hasPrefix("test") else {
                    continue
                }

                testSelectors.append(selector)
            }

            return testSelectors
        }

        class private func allTestClasses() -> [XCTestCase.Type] {
            var testClasses = [XCTestCase.Type]()
            let classesCount = objc_getClassList(nil, 0)

            guard classesCount > 0 else {
                return testClasses
            }

            let testClassDescription = NSStringFromClass(XCTestCase.self)
            let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(classesCount))
            for classIndex in 0..<objc_getClassList(AutoreleasingUnsafeMutablePointer(classes), classesCount) {
                if let currentClass = classes[Int(classIndex)],
                    let superclass = class_getSuperclass(currentClass),
                    NSStringFromClass(superclass) == testClassDescription
                {
                    testClasses.append(currentClass as! XCTestCase.Type)
                }
            }

            return testClasses
        }

        // MARK: Lifecycle

        required override init() {}

        // MARK: Internal

        func setUp() {}
        func tearDown() {}

        func expectation(description: String, file: StaticString = #file, line: UInt = #line) -> XCTestExpectation {
            let expectation = XCTestExpectation(description: description, file: file, line: line)
            expectations.append(expectation)
            return expectation
        }

        func waitForExpectations(timeout: TimeInterval, file: StaticString = #file, line: UInt = #line, handler: ((NSError?) -> Void)? = nil) {
            guard !expectations.isEmpty else {
                assertionFailure()
                return
            }

            let runLoop = RunLoop.current
            let timeoutDate = Date(timeIntervalSinceNow: timeout)
            repeat {
                var expectationsAllFulfilled = true
                expectations.forEach {
                    expectationsAllFulfilled = expectationsAllFulfilled && $0.isFulfilled
                }

                guard !expectationsAllFulfilled else {
                    break
                }

                runLoop.run(until: Date(timeIntervalSinceNow: 0.1))
            } while Date() < timeoutDate

            var failedExpectations = [XCTestExpectation]()
            expectations.forEach {
                if !$0.isFulfilled {
                    failedExpectations.append($0)
                    assertionFailure("expectation not met: \($0.description)", file: file, line: line)
                }
                $0.canBeFulfilled = false
            }

            expectations = []

            handler?(failedExpectations.isEmpty ? nil : NSError(domain: "XCTestCase", code: 0, userInfo: nil))
            // Fulfill the failed expectations so the deinit assert isn't triggered.
            failedExpectations.forEach { $0.forceFulfill() }
        }

        // MARK: Private

        private var expectations = [XCTestExpectation]()
    }

    // MARK: - XCTestExpectation

    /// A bare-bones re-implementation of XCTestExpectation for running tests from the watch extension.
    class XCTestExpectation {

        // MARK: Lifecycle

        init(description: String, file: StaticString, line: UInt) {
            self.description = description
            self.file = file
            self.line = line
        }

        deinit {
            assert(isFulfilled, "expectation deinit without being fulfilled: \(description)", file: file, line: line)
        }

        // MARK: Internal

        let description: String
        private(set) var isFulfilled = false
        var canBeFulfilled = true

        func fulfill(_ file: StaticString = #file, line: UInt = #line) {
            guard !isFulfilled else {
                assertionFailure("expectation already fulfilled: \(description)", file: file, line: line)
                return
            }

            guard canBeFulfilled else {
                assertionFailure("expectation fulfilled after wait completed: \(description)", file: file, line: line)
                return
            }

            isFulfilled = true
        }

        // MARK: Fileprivate

        fileprivate func forceFulfill() {
            isFulfilled = true
        }

        // MARK: Private

        private let file: StaticString
        private let line: UInt
    }

    // MARK: – XCTAssert Static Methods

    func XCTAssertTrue(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        do {
            let result = try expression()
            assert(result, message, file: file, line: line)
        } catch _ {
            assertionFailure(message, file: file, line: line)
        }
    }

    func XCTAssertFalse(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        do {
            let result = try expression()
            assert(!result, message, file: file, line: line)
        } catch _ {
            assertionFailure(message, file: file, line: line)
        }
    }

    func XCTAssertNil(_ expression: @autoclosure () throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        do {
            let result = try expression()
            assert(result == nil, message, file: file, line: line)
        } catch _ {
            assertionFailure(message, file: file, line: line)
        }
    }

    func XCTAssertEqual<T: Equatable>(_ expression1: @autoclosure () throws -> T?, _ expression2: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        do {
            let (value1, value2) = (try expression1(), try expression2())
            assert(value1 == value2, message, file: file, line: line)
        } catch _ {
            assertionFailure(message, file: file, line: line)
        }
    }

    func XCTAssertNotEqual<T: Equatable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        do {
            let (value1, value2) = (try expression1(), try expression2())
            assert(value1 != value2, message, file: file, line: line)
        } catch _ {
            assertionFailure(message, file: file, line: line)
        }
    }

    func XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
        assertionFailure(message, file: file, line: line)
    }

    func measure(file: StaticString = #file, line: Int = #line, block: () -> Void) {
        // We don't need to do anything here.
    }
#endif
