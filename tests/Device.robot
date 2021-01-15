*** Settings ***
Resource          ../resources/RestApi.robot

*** Test Cases ***
Get All Devices
    ${content}    ${response_code}    ${header}    Execute Get Request    ${DEVICE_ENDPOINT}
    Should Be Equal    '${response_code}'    '200'

Check connectivity
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Disconnect Device
        Connect Device    ${device_ips}[${i}]    ${True}
    END

Check Device State
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Disconnect Device
        Connect Device    ${device_ips}[${i}]    ${True}
        Get Device State
        Disconnect Device
    END

Check Name Change
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Set Name and Validate    ${device_ips}[${i}]    ValidName
    END

Check Brightness change
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Set Brightness    ${device_ips}[${i}]    BrightnessPositveValues
    END

Check Color Change
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    FOR    ${i}    IN RANGE    ${count}
        Set Color    ${device_ips}[${i}]    ValidColors    200
    END

Connect Device with Invalid IPs
    ${content}    ${response_code}    ${header}    Execute Post Request    ${DEVICE_CONNECT_ENDPOINT}    {"ip":"10.102.102.11"}
    ${content}    Load Json    ${content}
    ${content}    Convert To Dictionary    ${content}
    ${success_response}    Get Value By Key From Json    ${content}    success
    ${success_response}    Convert To Boolean    ${success_response}
    Should Be Equal    ${success_response}    ${False}
    should be equal    '200'    '${response_code}'

Check device state on multiple connection
    ${device_ips}    Get List of IPs of All Devices
    ${count}    Get Length    ${device_ips}
    Disconnect Device
    FOR    ${i}    IN RANGE    ${count}
        log    ${device_ips}[${i}]
        Connect Device    ${device_ips}[${i}]    ${True}
        ${device_state}    Get Device State
        ${device_state}    Load Json    ${device_state}
        ${device_state}    Convert To Dictionary    ${device_state}
        ${device_ip}    Get Value By Key From Json    ${device_state}    ip
        Should Be Equal    ${device_ip}    ${device_ips}[${i}]
        Disconnect Device
    END
