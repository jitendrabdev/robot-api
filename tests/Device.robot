*** Settings ***
Suite Setup       Server_Service_Start_Stop    Start
Suite Teardown    Server_Service_Start_Stop    Stop
Resource          ../resources/RestApi.robot

*** Test Cases ***
List all available devices
    ${content}    ${response_code}    ${header}    Execute Get Request    ${DEVICE_ENDPOINT}
    Should Be Equal    '${response_code}'    '200'

Connect to a device with valid ip
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Disconnect Device
        Connect Device    ${device_ips}[${i}]    ${True}
    END

Get the state of a device
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Disconnect Device
        Connect Device    ${device_ips}[${i}]    ${True}
        Get Device State    ${True}
        Disconnect Device
    END

Update the name of a device when device is connected
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Set Name and Validate    ${device_ips}[${i}]    ValidName
    END

Update the brightness of device when device is connected
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Set Brightness    ${device_ips}[${i}]    BrightnessPositveValues
    END

Update the color of device when device is connected
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Set Color    ${device_ips}[${i}]    ValidColors    200
    END

Connect Device with Invalid IPs
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_CONNECT_ENDPOINT}    {"ip":"10.102.102.11"}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${False}

Check device state on multiple connection
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    Disconnect Device
    FOR    ${i}    IN RANGE    ${count}
        log    ${device_ips}[${i}]
        Connect Device    ${device_ips}[${i}]    ${True}
        ${device_state}    Get Device State    ${True}
        ${device_state}    Load Json    ${device_state}
        ${device_state}    Convert To Dictionary    ${device_state}
        ${device_ip}    Get Value By Key From Json    ${device_state}    ip
        Should Be Equal    ${device_ip}    ${device_ips}[${i}]
        Disconnect Device
    END

Get the state of a device if device is not connected
    Disconnect Device
    Get Device State    ${False}

Update the name of a device when device is not connected
    Disconnect Device
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_NAME_ENDPOINT}    {"name":"${NEW_NAME}"}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${False}

Update the brightness of device when device is not connected
    Disconnect Device
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_BRIGHTNESS_ENDPOINT}    {"brightness":${${NEW_BRIGHTNESS}}}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${False}

Update color of device when device is not connected
    Disconnect Device
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_COLOR_ENDPOINT}    {"color":"${NEW_COLOR}"}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${False}

Connect device when one device is already connected
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    Connect Device    ${DEVICE_IP2}    ${False}

Updated name should be persist after device disconnect and connect
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_NAME_ENDPOINT}    {"name":"${NEW_NAME}"}
    Should Be Equal    '${response_code}'    '200'
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_name}    Get Value By Key From Json    ${device_state}    name
    Should Be Equal    ${device_name}    ${NEW_NAME}
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_name}    Get Value By Key From Json    ${device_state}    name
    Should Be Equal    ${device_name}    ${NEW_NAME}

Updated brightness should persist after device disconnect and connect
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_BRIGHTNESS_ENDPOINT}    {"brightness":${NEW_BRIGHTNESS}}
    Should Be Equal    '${response_code}'    '200'
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_brightness}    Get Value By Key From Json    ${device_state}    brightness
    Should Be Equal    ${device_brightness}    ${NEW_BRIGHTNESS}
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_brightness}    Get Value By Key From Json    ${device_state}    brightness
    Should Be Equal    ${device_brightness}    ${NEW_BRIGHTNESS}

Updated color should be persist after device disconnect and connect
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_COLOR_ENDPOINT}    {"color":"${NEW_COLOR}"}
    Should Be Equal    ${response_code}    ${RESPONSE_SUCCESS_CODE}
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_color}    Get Value By Key From Json    ${device_state}    color
    Should Be Equal    ${device_color}    ${NEW_COLOR}
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_color}    Get Value By Key From Json    ${device_state}    color
    Should Be Equal    ${device_color}    ${NEW_COLOR}

Device all parameters like name, brightness and color should be reset after server restart
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_COLOR_ENDPOINT}    {"color":"${NEW_COLOR}"}
    Should Be Equal    ${response_code}    ${RESPONSE_SUCCESS_CODE}
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_color}    Get Value By Key From Json    ${device_state}    color
    Should Be Equal    ${device_color}    ${NEW_COLOR}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_BRIGHTNESS_ENDPOINT}    {"brightness":${NEW_BRIGHTNESS}}
    Should Be Equal    '${response_code}'    '200'
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_brightness}    Get Value By Key From Json    ${device_state}    brightness
    Should Be Equal    ${device_brightness}    ${NEW_BRIGHTNESS}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_NAME_ENDPOINT}    {"name":"${NEW_NAME}"}
    Should Be Equal    '${response_code}'    '200'
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_name}    Get Value By Key From Json    ${device_state}    name
    Should Be Equal    ${device_name}    ${NEW_NAME}
    Server_Service_Start_Stop    Stop
    Server_Service_Start_Stop    Start
    Connect Device    ${DEVICE_IP1}    ${True}
    ${device_state}    Get Device State    ${True}
    ${device_state}    Load Json    ${device_state}
    ${device_state}    Convert To Dictionary    ${device_state}
    ${device_color}    Get Value By Key From Json    ${device_state}    color
    Should Not Be Equal    ${device_color}    ${NEW_COLOR}
    ${device_color}    Get Value By Key From Json    ${device_state}    name
    Should Not Be Equal    ${device_color}    ${NEW_NAME}
    ${device_color}    Get Value By Key From Json    ${device_state}    brightness
    Should Not Be Equal    ${device_color}    ${NEW_BRIGHTNESS}

API behaviour when provided request input value as string for /brightness
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_BRIGHTNESS_ENDPOINT}    {"brightness":"${NEW_NAME}"}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${False}

API behaviour when provided request input value as integer for /color
    Disconnect Device
    Connect Device    ${DEVICE_IP1}    ${True}
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_COLOR_ENDPOINT}    {"color":${NEW_BRIGHTNESS}}
    API Response Validation    ${content}    ${response_code}    ${RESPONSE_SUCCESS_CODE}    ${False}
