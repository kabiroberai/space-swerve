//#-hidden-code
import Foundation
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

class GameMessageHandler: PlaygroundRemoteLiveViewProxyDelegate {
    let currentDifficulty: Difficulty
    init(currentDifficulty: Difficulty) {
        self.currentDifficulty = currentDifficulty
    }

    func remoteLiveViewProxy(
        _ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy,
        received message: PlaygroundValue
    ) {
        guard case let .boolean(status) = message, status else { return }

        // don't change the assessment status if it's already been set
        if !Difficulty.completedDifficulties.isEmpty && PlaygroundPage.current.assessmentStatus == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                PlaygroundPage.current.assessmentStatus = .pass(
                    message: "I hope you enjoyed playing my game! Feel free to continue playing to see how high you can score 😄"
                )
            }
        }
    }

    func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {}
}

// maintain a strong reference to the Game Message Handler
var messageHandler: GameMessageHandler?

func startGame(ofDifficulty difficulty: Difficulty) {
    let liveView = PlaygroundPage.current.liveView as! PlaygroundRemoteLiveViewProxy
    messageHandler = GameMessageHandler(currentDifficulty: difficulty)
    liveView.delegate = messageHandler
    liveView.send(difficulty)
}
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, ., easy, medium, hard)
/*:
 Before you start, you must choose a difficulty level. The different options are `.easy`, `.medium`, and `.hard`. Select one of them and then tap **Run My Code**.

 - Note: For the best experience, keep your iPad in landscape mode with your face at a comfortable distance.
 */
startGame(ofDifficulty: /*#-editable-code Difficulty*/<#T##Difficulty##Difficulty#>/*#-end-editable-code*/)
/*:
 To "complete" a level, achieve its corresponding score:

 - **Easy**: 300
 - **Medium**: 250
 - **Hard**: 200
 */
