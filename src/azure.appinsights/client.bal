// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/time;

boolean azureAppInsightsEnabled = config:getAsBoolean("AZURE_APP_INSIGHTS_ENABLE", false);

# Azure insight event publishing connector client endpoint.
#
# + httpClient - Connector http endpoint
public type Client client object {

    http:Client httpClient;
    private TelemetryConfiguration telemetryConfiguration;

    # Initializes the event publisher connector client endpoint.
    #
    # +  telemetryConfiguration - Configurations required to initialize the `Client` endpoint
    public function __init(TelemetryConfiguration telemetryConfiguration) {
        self.httpClient = new ("https://dc.services.visualstudio.com/v2/track");
        self.telemetryConfiguration = telemetryConfiguration;
    }

    # Sends a custom event record to Azure Application Insights.
    #
    # + event - Event data to be published
    # + return - An event client object on success, else returns an error
    public remote function trackEvent(Event event) returns @tainted EventResult|ClientError|EventError {
        string iKey = self.telemetryConfiguration.instrumentationKey;
        time:Time now = time:currentTime();
        json jsonPayload = {
            name: "Microsoft.ApplicationInsights." + iKey + ".Event",
            time: now.toString(),
            iKey: iKey,
            data: {
                baseType: "EventData",
                baseData: event.name,
                properties: event.properties,
                measurements: event.metrics
            }
        };

        if (event.clientIP is string) {
            json tags = {
                "ai.location.ip": event.clientIP
            };
            jsonPayload = checkpanic jsonPayload.mergeJson(tags);
        }

        return sendRequestWithPayload(self.httpClient, jsonPayload);
    }
};

function sendRequestWithPayload(http:Client httpClient, json jsonPayload) returns @tainted EventResult|ClientError|EventError {
    http:Request httpRequest = new;
    httpRequest.setJsonPayload(jsonPayload);
    http:Response|error responseOrError = httpClient->post("/", httpRequest);
    if responseOrError is error {
        ClientError responseError = error(APP_INSIGHT_CLIENT_ERROR, message = "error occurred sending event to azure application insights",
            cause = responseOrError);
        return responseError;
    }

    http:Response response = <http:Response>responseOrError;
    if response.statusCode == http:STATUS_OK {
        json|error eventResponseJsonOrError = response.getJsonPayload();
        if eventResponseJsonOrError is error {
            ClientError jsonParseError = error(APP_INSIGHT_CLIENT_ERROR, message = "error occurred parsing response from azure application insights",
                cause = eventResponseJsonOrError);
            return jsonParseError;
        }

        json eventResponseJson = <json>eventResponseJsonOrError;
        EventResult eventResult = {
            itemsReceived: <int>eventResponseJson.itemsReceived,
            itemsAccepted: <int>eventResponseJson.itemsAccepted
        };
        return eventResult;
    } else {
        return createError(response);
    }
}

function createError(http:Response resp) returns @tainted ClientError|EventError {
    json|error errorJsonOrError = resp.getJsonPayload();
    if errorJsonOrError is error {
        ClientError jsonParseError = error(APP_INSIGHT_CLIENT_ERROR, message = "error occurred parsing client response",
            cause = errorJsonOrError);
        return jsonParseError;
    }

    map<json> errorJson = <map<json>>errorJsonOrError;
    EventResult eventResult = {
        itemsReceived: <int>errorJson.itemsReceived,
        itemsAccepted: <int>errorJson.itemsAccepted
    };

    if errorJson.hasKey("errors") {
        json[] innerErrorsJson = <json[]>errorJson.errors;
        if innerErrorsJson.length() > 0 {
            int statusCode = <int>innerErrorsJson[0].statusCode;
            string message = <string>innerErrorsJson[0].message;
            EventError eventError = error(EVENT_CLIENT_ERROR, eventResult = eventResult,
                statusCode = statusCode,
                message = message);
            return eventError;
        }
    }

    EventError eventError = error(EVENT_CLIENT_ERROR, eventResult = eventResult);
    return eventError;
}

Client appInsightsClient = configureClient();
# Get a configured telemetry client of Azure App Insights.
#
# + return - The client
function configureClient() returns Client {
    string instrumentationKey = "TELEMETRY_INSTRUMENTATION_KEY";
    TelemetryConfiguration config = {
        instrumentationKey: instrumentationKey
    };

    Client telemetryClient = new (config);
    return telemetryClient;
}

function sendCreateOrgEventToAzureAppInsight(string orgName, string? clientIP) {
    if azureAppInsightsEnabled {
        Event createOrgEvent = {
            name: "org-creation-parkavi",
            properties: {
                organization: "Parkavi"
            },
            clientIP: clientIP
        };

        EventResult|ClientError|EventError publishResults = appInsightsClient->trackEvent(createOrgEvent);
        if (publishResults is EventResult) {
            log:printDebug("event type org creation sent to azure application insights successfully: " + orgName);
        } else {
            log:printError("error occurred publishing event", err = publishResults);
        }
    } else {
        log:printDebug("azure application insights event publishing is disabled. " +
        "set AZURE_APP_INSIGHTS_ENABLE to \"true\". current value: " + azureAppInsightsEnabled.toString());
    }
}

public function main() {
    var azAppInsightEvent = start sendCreateOrgEventToAzureAppInsight("Parkavi", "123-123-123-123");
}