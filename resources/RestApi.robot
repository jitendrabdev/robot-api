*** Settings ***
Resource          ../test_data/TestData.robot
Library           Collections
Library           ExcelLibrary
Library           ../lib/rest_util/RestGeneric.py

*** Variables ***
${DEVICE_ENDPOINT}    ${BASE_URL}/devices
${HOSTNAME}       localhost
${PORT}           8080
${BASE_URL}       http://${HOSTNAME}:${PORT}
${DEVICE_STATE_ENDPOINT}    ${BASE_URL}/state
${DEVICE_CONNECT_ENDPOINT}    ${BASE_URL}/connect
${DEVICE_BRIGHTNESS_ENDPOINT}    ${BASE_URL}/brightness
${DEVICE_COLOR_ENDPOINT}    ${BASE_URL}/color
${DEVICE_DISCONNECT_ENDPOINT}    ${BASE_URL}/disconnect
${DEVICE_NAME_ENDPOINT}    ${BASE_URL}/name
${DATA_FILE}      ${TEST_DATA_LOCATION}\\Device\\InputData.csv

*** Keywords ***
Connect Device
    [Arguments]    ${device_ip}    ${success_code}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_CONNECT_ENDPOINT}    {"ip":"${device_ip}"}
    log    ${content}
    Should Be Equal    '${response_code}'    '200'
    ${content}    Load Json    ${content}
    ${content}    Convert To Dictionary    ${content}
    ${success_response}    Get Value By Key From Json    ${content}    success
    ${success_response}    Convert To Boolean    ${success_response}
    Should Be Equal    ${success_response}    ${success_code}

Get Device State
    ${content}    ${response_code}    ${header}    Execute Get Request    ${DEVICE_STATE_ENDPOINT}
    Should Be Equal    '${response_code}'    '200'
    Log    ${content}
    [Return]    ${content}

Disconnect Device
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_DISCONNECT_ENDPOINT}
    Log    ${content}
    Should Be Equal    '${response_code}'    '200'

Set Name and Validate
    [Arguments]    ${ip}    ${data_column}
    Disconnect Device
    Connect Device    ${ip}    ${True}
    ${list}    Get Csv Column Data    ${DATA_FILE}    TestData    ${data_column}
    ${list}    Convert To List    ${list}
    ${lstcount}    Get Length    ${list}
    FOR    ${i}    IN RANGE    ${lstcount}
        Log    ${list}[${i}]
        ${modified_name}    Set Variable    ${list}[${i}]
        ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_NAME_ENDPOINT}    {"name":"${modified_name}"}
        Should Be Equal    '${response_code}'    '200'
        ${device_state}    Get Device State
        ${device_state}    Load Json    ${device_state}
        ${device_state}    Convert To Dictionary    ${device_state}
        ${device_name}    Get Value By Key From Json    ${device_state}    name
        Should Be Equal    ${device_name}    ${modified_name}
    END
    Disconnect Device

Set Color
    [Arguments]    ${ip}    ${data_column}    ${status_code}
    Disconnect Device
    Connect Device    ${ip}    ${True}
    ${list}    Get Csv Column Data    ${DATA_FILE}    TestData    ${data_column}
    ${list}    Convert To List    ${list}
    ${lstcount}    Get Length    ${list}
    FOR    ${i}    IN RANGE    ${lstcount}
        Log    ${list}[${i}]
        ${modified_color}    Set Variable    ${list}[${i}]
        ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_COLOR_ENDPOINT}    {"color":"${modified_color}"}
        Should Be Equal    '${response_code}'    '${status_code}'
        ${device_state}    Get Device State
        ${device_state}    Load Json    ${device_state}
        ${device_state}    Convert To Dictionary    ${device_state}
        ${device_color}    Get Value By Key From Json    ${device_state}    color
        Should Be Equal    ${device_color}    ${modified_color}
    END
    Disconnect Device

Set Brightness
    [Arguments]    ${ip}    ${data_column}
    Disconnect Device
    Connect Device    ${ip}    ${True}
    ${list}    Get Csv Column Data    ${DATA_FILE}    TestData    ${data_column}
    ${list}    Convert To List    ${list}
    ${lstcount}    Get Length    ${list}
    FOR    ${i}    IN RANGE    ${lstcount}
        Log    ${list}[${i}]
        ${modified_brightness}    Set Variable    ${list}[${i}]
        ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_BRIGHTNESS_ENDPOINT}    {"brightness":"${modified_brightness}"}
        Should Be Equal    '${response_code}'    '200'
        ${device_state}    Get Device State
        ${device_state}    Load Json    ${device_state}
        ${device_state}    Convert To Dictionary    ${device_state}
        ${device_brightness}    Get Value By Key From Json    ${device_state}    brightness
        Should Be Equal    ${device_brightness}    ${modified_brightness}
    END
    Disconnect Device

Read Json File

Get List of IPs of All Devices
    ${content}    ${response_code}    ${header}    Execute Get Request    ${DEVICE_ENDPOINT}
    Should Be Equal    '${response_code}'    '200'
    ${content}    Load Json    ${content}
    ${count}    Get Length    ${content}
    @{device_ips}    Create List
    FOR    ${i}    IN RANGE    ${count}
        ${dictionary}    Convert To Dictionary    ${content[${i}]}
        ${device_ip}    Get Value By Key From Json    ${dictionary}    ip
        Append To List    ${device_ips}    ${device_ip}
    END
    [Return]    ${device_ips}
