output_path = ''
device_type = 'esp32' # Note: use esp8266 to remove mbedtls elements so that definitions don't conflict with tlsio_arduino methods

cmds = {
    "help":         {'short': 'h', 'text': "Print Help text"},
    "output":       {'short': 'o', 'text': "arg required: Sets the path used to save output folders and libraries."},
    "device":       {'short': 'd', 'text': "arg required: Sets the type of device the libraries are being targeted at (e.x. esp8266, esp32)."},
    }
