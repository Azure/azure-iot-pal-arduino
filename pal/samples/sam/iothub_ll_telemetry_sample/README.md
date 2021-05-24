#### Azure IoT Hub and Arduino Due + Ethernet Shield 2 Demo

Currently supported hardware:

- [Arduino Due board](https://store.arduino.cc/arduino-due) with [Ethernet Shield 2](https://store.arduino.cc/arduino-ethernet-shield-2) on top.

## Prerequisites

You should have the following ready before beginning with any board:

-   [Setup your IoT hub](https://github.com/Azure/azure-iot-device-ecosystem/blob/master/setup_iothub.md)

-   [Provision your device and get its credentials](https://github.com/Azure/azure-iot-device-ecosystem/blob/master/setup_iothub.md#create-new-device-in-the-iot-hub-device-identity-registry)

-   [Arduino IDE](https://www.arduino.cc/en/Main/Software)

-   Install the Azure IoT C SDK libraries by one of two options:
	1. Generate the Libraries by executing the [`make_sdk.py`](https://github.com/Azure/azure-iot-pal-arduino/blob/master/build_all/make_sdk.py) script within the `build_all` folder, E.x.: `python3 make_sdk.py -o <your-output-folder>`
	- Note: this is also currently the ONLY way to build the `AzureIoTSocket_WiFi` library for using the esp32.
	
	2. Install the following libraries through the Arduino IDE Library Manager:
	-   `AzureIoTHub`, `AzureIoTUtility`, `AzureIoTProtocol_MQTT`, `AzureIoTProtocol_HTTP`

## Additional Dependencies

This demo requires the following libraries installed:
   - RTCDue (>=1.1.0)
   - SSLClient (>=1.6.10)
   - EthernetLarge (>=2.0.0)

The latest is not available in the Arduino IDE Library Manager. Installation instructions can be found [here](https://github.com/OPEnSLab-OSU/SSLClient#sslclient-with-ethernet).

## Sample Instructions

1. Install Arduino Due board support package into your Arduino IDE.
    - Open Boards Manager from Tools > Board menu and install Arduino SAM boards platform 1.6.12 or later.
    - Select your Arduino Due (Programming Port) board from Tools > Board menu after installation.

2. Navigate to where your Arduino Due board package is located, typically in `C:\Users\<your username>\AppData\Local\Arduino15\packages\arduino\hardware\sam\<board package version>\` on  Windows and `~/.arduino15/packages/arduino/hardware/sam/<board package version>/` on Linux.

3. Copy the boards.local.txt file from the sample directory to this location. This will add the required defines for the compilation. 

	- Note1: If your device is not intended to connect to the global portal.azure.com, please change the CERT define to the appropriate cert define as laid out in [`certs.c`](https://github.com/Azure/azure-iot-sdk-c/blob/master/certs/certs.c).
    Otherwise, do not change the content of boards.local.txt file.
	
	- Note2: Due to RAM limits, you must select just one CERT define.

4. Open the iothub_ll_telemetry_sample example from the Arduino IDE File->Examples->AzureIoTHub->sam menu.

5. Add your configuration to iot_configs.h
    - Update IoT Hub Connection string.
    - Select SAMPLE_MQTT or SAMPLE_HTTP.
    - Set the right mac address in assigned_mac. Your Ethernet Shield mac address is usually printed on a label on the bottom of the Shield.
    - Assign a floating Arduino Due analog pin for random number generation.
6. Apply required changes to SSLClient library
    - Locate library directory, usually in `C:\Users\<your username>\Documents\Arduino\libraries\SSLClient`.
    - In src\config.h, change `#define BR_USE_UNIX_TIME   0` to `#define BR_USE_UNIX_TIME   1`.
    - In src\SSlClient.h change `unsigned char m_iobuf[2048];` to `unsigned char m_iobuf[BR_SSL_BUFSIZE_BIDI];`.
    - In src\SSLClient.cpp change costructor lines from this:
        ```C++
        br_client_init_TLS12_only(&m_sslctx, &m_x509ctx, m_trust_anchors, m_trust_anchors_num);
        // comment the above line and uncomment the line below if you're having trouble connecting over SSL
        // br_ssl_client_init_full(&m_sslctx, &m_x509ctx, m_trust_anchors, m_trust_anchors_num);
        ```
        to this:
        ```C++
        // br_client_init_TLS12_only(&m_sslctx, &m_x509ctx, m_trust_anchors, m_trust_anchors_num);
        // comment the above line and uncomment the line below if you're having trouble connecting over SSL
        br_ssl_client_init_full(&m_sslctx, &m_x509ctx, m_trust_anchors, m_trust_anchors_num);
        ```

7. Verify and Upload the sketch.
