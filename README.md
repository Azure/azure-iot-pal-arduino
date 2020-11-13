# azure-iot-pal-arduino

This repository contains all of the Arduino-specific source files for the Azure IoT Arduino 
libraries. 

#### Published libraries
The published Azure IoT Arduino libraries are here:
* [AzureIoTHub Arduino **published library**](https://github.com/Azure/azure-iot-arduino)
* [AzureIoTProtocol_MQTT Arduino **published library**](https://github.com/Azure/azure-iot-arduino-protocol-mqtt)
* [AzureIoTProtocol_HTTP Arduino **published library**](https://github.com/Azure/azure-iot-arduino-protocol-http)
* [AzureIoTUtility Arduino **published library**](https://github.com/Azure/azure-iot-arduino-utility)
* [AzureIoTSocket_WiFi **published library**](https://github.com/Azure/azure-iot-arduino-socket-esp32-wifi)

Contributions should _not_ be made to these locations, as they are auto-generated.

#### Arduino-specific library sources

Arduino-specific sources for the Azure IoT Arduino libraries are kept in this repository:
* [AzureIoTHub **Arduino sources**](https://github.com/Azure/azure-iot-pal-arduino/tree/master/build_all/base-libraries/AzureIoTHub)
* [AzureIoTProtocol_MQTT **Arduino sources**](https://github.com/Azure/azure-iot-pal-arduino/tree/master/build_all/base-libraries/AzureIoTProtocol_MQTT)
* [AzureIoTProtocol_HTTP **Arduino sources**](https://github.com/Azure/azure-iot-pal-arduino/tree/master/build_all/base-libraries/AzureIoTProtocol_HTTP)
* [AzureIoTUtility **Arduino sources**](https://github.com/Azure/azure-iot-pal-arduino/tree/master/build_all/base-libraries/AzureIoTUtility)
* [AzureIoTSocket_WiFi **Arduino sources**](https://github.com/Azure/azure-iot-pal-arduino/tree/master/pal/AzureIoTSocket_WiFi)

Arduino-specific contributions should be made to these locations.

#### Non-Arduino-specific Azure IoT sources

The non-Arduino-specific portions of the Azure IoT C SDK are found here:
* [AzureIoTHub **sources**](https://github.com/Azure/azure-iot-sdk-c)
* [AzureIoTProtocol_MQTT **sources**](https://github.com/Azure/azure-umqtt-c)
* [AzureIoTProtocol_HTTP **sources**](https://github.com/Azure/azure-c-shared-utility)
* [AzureIoTUtility **sources**](https://github.com/Azure/azure-c-shared-utility)

Contributions which are not Arduino-specific should be made to these locations.

#### Azure IoT Arduino Library README.md sources

The README.txt files for the Arduino libraries are auto-generated during the release
process from a template file using a script.
Contributions to the README.md files for any of the four Azure IoT Arduino libraries should be made by 
modifying one or both of 

* [README_builder.ps1](https://github.com/Azure/azure-iot-pal-arduino/blob/master/build_all/README_builder.ps1)
* [README_template.md](https://github.com/Azure/azure-iot-pal-arduino/blob/master/build_all/README_template.md)


### Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
