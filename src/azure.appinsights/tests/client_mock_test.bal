// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

@test:Config {}
public function testPublishEventInvalidKey() {
    TelemetryConfiguration config = {
        instrumentationKey: "xxxxxxxxxxx-xxx-xxxxxxxx"
    };
    Client telemetryClient = new (config);
    http:Client httpClient = <http:Client>test:mock(http:Client);
    telemetryClient.httpClient = httpClient;

    Event event = {
        name: "Sending a custom event…",
        properties: {
            orgName: "Parkavi",
            name: "foo",
            'version: "1.0.0"
        },
        clientIP: "203.94.95.4"
    };
    test:prepare(httpClient).when("post").thenReturn(getMockResponseInvalidKey());

    EventResult|ClientError|EventError publishResult = telemetryClient->trackEvent(event);
    if publishResult is EventError {
        EventError eventError = <EventError>publishResult;
        test:assertEquals(eventError.detail().eventResult.itemsReceived, 1);
        test:assertEquals(eventError.detail().eventResult.itemsAccepted, 0);
        test:assertEquals(eventError.detail()?.statusCode, 400);
    } else {
        test:assertFail("invalid type of EventResult or ClientError is received");
    }
}

@test:Config {}
public function testPublishEventValid() {
    TelemetryConfiguration config = {
        instrumentationKey: "xxxxxxxxxxx-xxx-xxxxxxxx"
    };
    Client telemetryClient = new (config);
    http:Client httpClient = <http:Client>test:mock(http:Client);

    http:Response mockResponse = getMockResponseValidKey();
    test:prepare(httpClient).when("post").thenReturn(mockResponse);
    telemetryClient.httpClient = httpClient;
    Event event = {
        name: "Sending a custom event…",
        properties: {
            orgName: "Parkavi",
            name: "foo",
            'version: "1.0.0"
        },
        clientIP: "203.94.95.4"
    };

    EventResult|ClientError|EventError publishResult = telemetryClient->trackEvent(event);
    if publishResult is EventResult {
        EventResult eventResult = <EventResult>publishResult;
        test:assertEquals(eventResult.itemsReceived, 1);
        test:assertEquals(eventResult.itemsAccepted, 1);
    } else {
        test:assertFail("invalid type of EventError or ClientError is received");
    }
}
