//
//  UntappdAPITests.swift
//  UntappdAPITests
//
//  Created by Jeff Kempista on 12/8/14.
//  Copyright (c) 2014 Jeff Kempista. All rights reserved.
//

import UIKit
import XCTest

class UntappdAPITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        let absoluteURL = "untapped:////x-callback-url//authenticated#access_token=0A86593D2959AB7336F1E25584F99D60F8A690B4"
        var error = NSError()
        let regex = NSRegularExpression(pattern: "/^untapped:////x-callback-url//authenticated#access_token=[//w]$", options: nil, error: nil)
        let matches = regex?.matchesInString(absoluteURL, options: nil, range: NSRange(location: 0, length: countElements(absoluteURL)))
        
        XCTAssertNotNil(matches)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
