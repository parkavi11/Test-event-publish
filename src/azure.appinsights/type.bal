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

public const APP_INSIGHT_CLIENT_ERROR = "{registry/azure.appinsights}AppInsightsClientError";
public const EVENT_CLIENT_ERROR = "{registry/azure.appinsights}EventError";

# Configurations for the telemetry client.
#
# + instrumentationKey - event publishing key
public type TelemetryConfiguration record {|
    string instrumentationKey;
|};

# Arguments related to publish an event.
#
# + name - A name for the event
# + properties - Named string values you can use to search and filter events
# + metrics - Numeric measurements associated with this event
# + clientIP - IP address of the user
public type Event record {|
    string name;
    map<string>? properties = {};
    map<decimal>? metrics = {};
    string? clientIP;
|};

# The result of the published event.
#
# + itemsReceived - Number of events recieved
# + itemsAccepted - Number of events accepted
public type EventResult record {|
    int itemsReceived;
    int itemsAccepted;
|};

# Error detail when client is unable to communicate with the application insights API
# 
# + message - The error message
# + cause - The cause of the error
# + details - Other details of the error
type ClientErrorDetails record {|
    string message;
    error cause;
    map<anydata> details?;
|};

# Represent an error when event is not correctly processed.
#
# + eventResult - The status of the event
# + statusCode - The status code of the error
# + message - The error message from the application insights endpoint
# + cause - The cause of the error
# + details - Other details of the error
type EventErrorDetails record {|
    EventResult eventResult;
    int statusCode?;
    string message?;
    error cause?;
    map<anydata> details?;
|};

# Represents error type with details.
public type ClientError error<APP_INSIGHT_CLIENT_ERROR, ClientErrorDetails>;
public type EventError error<EVENT_CLIENT_ERROR, EventErrorDetails>;
