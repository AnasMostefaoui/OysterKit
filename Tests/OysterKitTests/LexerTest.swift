//
//  LexerTest.swift
//  OysterKit
//
//  
//  Copyright © 2016 RED When Excited. All rights reserved.
//

import XCTest
@testable import OysterKit

private enum TestToken : Int, Token{
    case dummy
    
    private var productionRule: Rule{
        return ParserRule.terminal(produces: self, "dummy", nil)
    }
}

class LexerTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitialMark(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
    }
    
    func testNegativeMarkTestingFunctions(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        lexer.rewind()

        XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
    }
    
    func testMark(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do{
            let _ = lexer.mark()
            XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
            try lexer.scan(oneOf: CharacterSet.letters)
            try lexer.scan(oneOf: CharacterSet.letters)
            let _ = lexer.mark()
            XCTAssert(lexer.markedLocation == source.unicodeScalars.index(source.unicodeScalars.startIndex, offsetBy: 2))
        } catch {
            XCTFail("Test shouldn't throw")
        }
    }
    
    func testDiscard(){
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do{
            let _ = lexer.mark()                                                        //Marked at 0
            XCTAssert(lexer.markedLocation == source.unicodeScalars.startIndex)
            try lexer.scan(oneOf: CharacterSet.letters)
            let _ = lexer.mark()                                                        //Marked at 1
            try lexer.scan(oneOf: CharacterSet.letters)
            let _ = lexer.mark()                                                        //Marked at 2
            try lexer.scan(oneOf: CharacterSet.letters)
            lexer.rewind()                                                     //Marked at 1
            XCTAssert(lexer.markedLocation == source.unicodeScalars.index(source.unicodeScalars.startIndex, offsetBy: 1))
            lexer.rewind()                                                     //Marked at 0
            XCTAssert(lexer.markedLocation == source.unicodeScalars.index(source.unicodeScalars.startIndex, offsetBy: 0))
        } catch {
            XCTFail("Test shouldn't throw")
        }
    }

    func markAndScan(with lexer:TestLexer, _ characterSet : CharacterSet) {
        let _ = lexer.mark()
        do{
            while (true){
                try lexer.scan(oneOf:characterSet)
            }
        } catch {
            
        }
    }
    
    
    func testProceed(){
        let source = "Hello world"
        let lexer = TestLexer(source: source)
        
        markAndScan(with: lexer,CharacterSet.letters)
                
        let context = lexer.proceed()
            
        XCTAssert(context.matchedString == "Hello", "Expected 'Hello' but got '\(context.matchedString)'")
    }

    func testIssueChildCoalesce(){
        let source = "Goodbye cruel world."
        let lexer = TestLexer(source: source)
        
        let _ = lexer.mark()                                                            //Start of sentance
        
        markAndScan(with: lexer,CharacterSet.letters)                           //Word in sentance
        let goodbye = lexer.proceed()
        markAndScan(with: lexer, CharacterSet.whitespaces)                      //White space
        let _ = lexer.proceed()
        markAndScan(with: lexer,CharacterSet.letters)                           //Word in sentance
        let cruel = lexer.proceed()
        markAndScan(with: lexer, CharacterSet.whitespaces)                      //White space
        let _ = lexer.proceed()
        markAndScan(with: lexer,CharacterSet.letters)                           //Word in sentance
        let world = lexer.proceed()
        markAndScan(with: lexer,CharacterSet(charactersIn: "."))                //Period
        let period = lexer.proceed()
        
        //Check that each token is correct
        XCTAssert(goodbye.matchedString == "Goodbye", "Expected 'Goodbye' but got '\(goodbye.matchedString)'")
        XCTAssert(cruel.matchedString == "cruel", "Expected 'cruel' but got '\(cruel.matchedString)'")
        XCTAssert(world.matchedString == "world", "Expected 'world' but got '\(world.matchedString)'")
        XCTAssert(period.matchedString == ".", "Expected 'period' but got '\(period.matchedString)'")
    }
    
    
    func testNegativeScanCharacterInSet() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do {
            try lexer.scan(oneOf: CharacterSet.lowercaseLetters)
            XCTFail("Scan should have thrown")
        } catch {
            XCTAssert(!lexer.endOfInput)
        }
        
    }
    
    
    func testNegativeScanString() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        do {
            try lexer.scan(terminal: "Hullo")

            XCTFail("Scan should have thrown")
        } catch {
            XCTAssert(!lexer.endOfInput)
        }
        
    }
    
    
    func testScanString() {
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        XCTAssert(!lexer.endOfInput)
        
        do {
            try lexer.scan(terminal: "Hello")
            let context = lexer.proceed()
            
            XCTAssert(source == context.matchedString, "Expected token to be \(source) but got \(context.matchedString)")
        } catch {
            XCTFail("Scan should not have thrown")
        }
        
        XCTAssert(lexer.endOfInput)
    }

    func testScanOneOfCharacterSet() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let source = "Hello"
        let lexer = TestLexer(source: source)
        
        XCTAssert(!lexer.endOfInput)
        
        var expected : Character
        
        do {
            for current in source {
                expected = current
                try lexer.scan(oneOf: CharacterSet.letters)
            }
            let context = lexer.proceed()
            
            XCTAssert(source == context.matchedString, "Expected token to be \(source) but got \(context.matchedString)")
        } catch {
            XCTFail("All characters are letters: \(expected)")
        }
        
        XCTAssert(lexer.endOfInput)
    }
    

}
