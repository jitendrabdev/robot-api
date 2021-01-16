*** Settings ***
Resource          ../test_data/TestData.robot
Library           Collections
Library           ExcelLibrary
Library           ../lib/rest_util/RestGeneric.py
Library           OperatingSystem

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
${RESPONSE_SUCCESS_CODE}    ${200}
${RESPONSE_FAIL_CODE}    ${500}
${DEVICE_IP1}     192.168.100.10
${DEVICE_IP2}     192.168.100.11
${NEW_COLOR}      \#336699
${NEW_BRIGHTNESS}    ${4}
${NEW_NAME}       NewName
${NSSM_PATH}      "C:\\jitendra\\robot-api\\conf\\nssm-2.24\\win64\\nssm.exe"
${SERVER_SERVICE_NAME}    Smarthomeservice

*** Keywords ***
Connect Device
    [Arguments]    ${device_ip}    ${success_code}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_CONNECT_ENDPOINT}    {"ip":"${device_ip}"}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${success_code}

Get Device State
    [Arguments]    ${success_code}
    ${content}    ${response_code}    ${header}    Execute Get Request    ${DEVICE_STATE_ENDPOINT}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${success_code}
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
        ${device_state}    Get Device State    ${True}
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
        ${device_state}    Get Device State    ${True}
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
        ${device_state}    Get Device State    ${True}
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

API Response Validation
    [Arguments]    ${api_response}    ${response_code_actual}    ${response_code_expected}    ${success_code}
    Should Be Equal    ${response_code_actual}    ${response_code_expected}
    Log    ${api_response}
    ${content}    Load Json    ${api_response}
    ${content}    Convert To Dictionary    ${content}
    ${success_response}    Get Value By Key From Json    ${content}    success
    ${success_response}    Convert To Boolean    ${success_response}
    Should Be Equal    ${success_response}    ${success_code}

Server_Service_Start_Stop
    [Arguments]    ${start_stop_command}
    ${status}    Run    ${NSSM_PATH} ${start_stop_command} ${SERVER_SERVICE_NAME}
    log    ${status}
    Comment    Should Contain    ${status}    successfully
