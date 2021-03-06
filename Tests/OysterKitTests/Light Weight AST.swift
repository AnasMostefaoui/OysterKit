//    Copyright (c) 2018, RED When Excited
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import Foundation
import OysterKit

final class LightWeightNode : Node, CustomStringConvertible{
    let token   : Token
    let _range   : Range<String.UnicodeScalarView.Index>
    let children: [LightWeightNode]
    let annotations: [RuleAnnotation : RuleAnnotationValue]
    
    init(for token: Token, at range: Range<String.UnicodeScalarView.Index>, annotations : [RuleAnnotation : RuleAnnotationValue]) {
        fatalError("Should not be created by anything other than ColoringIR")
    }
    
    init(for token: Token, range: Range<String.UnicodeScalarView.Index>, children:[LightWeightNode]?,annotations : [RuleAnnotation : RuleAnnotationValue] ){
        self.token = token
        self._range = range
        self.children = children ?? []
        self.annotations = annotations
    }
    
    var range : Range<String.UnicodeScalarView.Index> {
        if let firstChild = children.first, let lastChild = children.last{
            return firstChild.range.lowerBound..<lastChild.range.upperBound
        } else {
            return _range
        }
    }
    
    final var description: String{
        return "\(token)"
    }

}

final class LightWeightAST : IntermediateRepresentation{
    private var     scalars   : String.UnicodeScalarView!
    private var     nodeStack = NodeStack<LightWeightNode>()
    
    var     children  : [LightWeightNode]{
        return nodeStack.top?.nodes ?? []
    }
    
    init() {
    }
    
    func resetState() {
        nodeStack.reset()
    }
    
    final func willEvaluate(rule: Rule, at position: String.UnicodeScalarView.Index) -> MatchResult? {
        nodeStack.push()
        return nil
    }
    
    final func willBuildFrom(source: String, with: Language) {
        scalars = source.unicodeScalars
        nodeStack.reset()
    }
    
    final func didBuild() {
        
    }
    
    let ignoreNodes : Set<String> =  ["whitespace","comment","oneLineComment","oneLineCommentStart","restOfLine","character","newline","step","then","or"]
    
    final func didEvaluate(rule: Rule, matchResult: MatchResult) {
        let children = nodeStack.pop()
        
        switch matchResult {
        case .success(let context):
            if rule.transient || ignoreNodes.contains("\(rule.produces)"){
                nodeStack.top?.adopt(children.nodes)
                return
            }
            
            let newNode : LightWeightNode
            if children.nodes.count > 0 {
                newNode = LightWeightNode(for: rule.produces, range: context.range, children: children.nodes, annotations: rule.annotations)
            } else {
                newNode = LightWeightNode(for: rule.produces, range: context.range, children: nil, annotations: rule.annotations)
            }
            
            nodeStack.top?.append(newNode)
        default: return
        }
    }
    
}
