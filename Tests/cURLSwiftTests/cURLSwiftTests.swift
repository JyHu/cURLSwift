import XCTest
@testable import cURLSwift

final class cURLSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let curl = "curl --form=message=\" I like it \"\n -X POST -H \"Accept: application/json\" https://httpbin.org/post"
        let request1 = try cURL(curl: curl)
        print(request1.description)
        
        let curl2 =
            """
            curl 'https://oauth1.skytigris.cn/auth/network' \
              -X POST \
              -H 'Host: oauth1.skytigris.cn' \
              -H 'Connection: keep-alive' \
              -H 'Accept: */*' \
              -H 'User-Agent: Tiger%20Trade/8DC719 CFNetwork/1399.4 Darwin/22.1.0' \
              -H 'Accept-Language: zh-TW,zh-Hant;q=0.9' \
              -H 'Content-Length: 0' \
              --proxy http://localhost:9090
            """
        let request2 = try cURL(curl: curl2)
        print(request2.description)
        
        let curl3 =
            """
            curl --request POST \
                --url $__ROBOT_URL__ \
                --header 'Content-Type: application/json' \
                --data '{
                    "msg_type": "interactive",
                    "card": {
                        "elements": [
                            {
                                "tag": "markdown",
                                "content": "'"$__EFFICENT_LOG__"'"
                            },
                            {
                                "tag": "action",
                                "actions": [
                                    {
                                        "tag": "button",
                                        "text": {
                                            "tag": "plain_text",
                                            "content": "详细信息"
                                        },
                                        "type": "primary",
                                        "url": "http://172.25.34.64:8080/job/'${JOB_NAME}'/'${BUILD_NUMBER}'"
                                    }
                                ]
                            }
                        ],
                        "header": {
                            "template": "red",
                            "title": {
                                "content": "'"$__NOTIFY_TITLE__"'",
                                "tag": "plain_text"
                            }
                        }
                    }
                }'
            """
        let request3 = try cURL(curl: curl3)
        print(request3.description)
        
        print("")
    }
    
    func testMakeSource() {
        Parser.parseOptions()
    }
}
