#include <functional>
#include <vector>
#include <map>
#include <Ethernet.h>
#include <ArduinoJson.h>
#include <Scheduler.h>
#include <Button2.h>

uint8_t macAddress[] = { 0x02, 0x00, 0x00, 0x00, 0x00, 0x01 };
auto server = EthernetServer(80);

std::vector<int> lightPins = { LED_BUILTIN, 14 };
std::vector<int> buttonPins = { 2 };
std::vector<Button2> buttons = {};

bool currentLightStatus = false;
bool ethernetInitialized = false;
bool ethernetDisconnected = false;

// MARK: Main setup section

void setup() {
  for (const auto& pin : lightPins)  {
    pinMode(pin, OUTPUT);
  }
  for (const auto& pin : buttonPins)  {
    auto button = Button2();
    button.begin(pin);
    button.setDebounceTime(50);
    button.setTapHandler(handleButtonTap);
    buttons.push_back(button);
  }

  Serial.begin(9600);
  // Uncomment when debugging:
  // while (!Serial) {
  //   delay(10);
  // };
  // Serial.println("Serial started");

  Scheduler.startLoop(loopNetworkServer);
  Scheduler.startLoop(loopButtons);

  Serial.println("Setup complete");
}

// Ignore main loop
void loop() {
  delay(1000);
}

// MARK: HTTP Server loop section

std::map<int, String> httpStatuses = {
  { 100, String("Continue") },
  { 101, String("Switching Protocols") },
  { 102, String("Processing") },
  { 103, String("Early Hints") },
  { 200, String("OK") },
  { 201, String("Created") },
  { 202, String("Accepted") },
  { 203, String("Non-Authoritative Information") },
  { 204, String("No Content") },
  { 205, String("Reset Content") },
  { 206, String("Partial Content") },
  { 207, String("Multi-Status") },
  { 208, String("Already Reported") },
  { 226, String("IM Used") },
  { 300, String("Multiple Choices") },
  { 301, String("Moved Permanently") },
  { 302, String("Found") },
  { 303, String("See Other") },
  { 304, String("Not Modified") },
  { 305, String("Use Proxy") },
  { 306, String("Switch Proxy") },
  { 307, String("Temporary Redirect") },
  { 308, String("Permanent Redirect") },
  { 400, String("Bad Request") },
  { 401, String("Unauthorized") },
  { 402, String("Payment Required") },
  { 403, String("Forbidden") },
  { 404, String("Not Found") },
  { 405, String("Method Not Allowed") },
  { 406, String("Not Acceptable") },
  { 407, String("Proxy Authentication Required") },
  { 408, String("Request Timeout") },
  { 409, String("Conflict") },
  { 410, String("Gone") },
  { 411, String("Length Required") },
  { 412, String("Precondition Failed") },
  { 413, String("Payload Too Large") },
  { 414, String("URI Too Long") },
  { 415, String("Unsupported Media Type") },
  { 416, String("Range Not Satisfiable") },
  { 417, String("Expectation Failed") },
  { 418, String("I'm a teapot") },
  { 421, String("Misdirected Request") },
  { 422, String("Unprocessable Content") },
  { 423, String("Locked") },
  { 424, String("Failed Dependency") },
  { 425, String("Too Early") },
  { 426, String("Upgrade Required") },
  { 428, String("Precondition Required") },
  { 429, String("Too Many Requests") },
  { 431, String("Request Header Fields Too Large") },
  { 451, String("Unavailable For Legal Reasons") },
  { 500, String("Internal Server Error") },
  { 501, String("Not Implemented") },
  { 502, String("Bad Gateway") },
  { 503, String("Service Unavailable") },
  { 504, String("Gateway Timeout") },
  { 505, String("HTTP Version Not Supported") },
  { 506, String("Variant Also Negotiates") },
  { 507, String("Insufficient Storage") },
  { 508, String("Loop Detected") },
  { 510, String("Not Extended") },
  { 511, String("Network Authentication Required") },
};

template<typename TypeKey, typename TypeValue>
String getHttpStatusText(std::map<TypeKey, TypeValue> map, TypeKey key) {
  const auto iterator = map.find(key);
  if (iterator != map.end()) {
    return iterator->second;
  } else {
    return String("");
  }
}

void sendClientResponse(EthernetClient& client, int status, String body) {
  auto statusText = getHttpStatusText(httpStatuses, status);

  if (statusText.compareTo("") == 0) {
    body = "{ \"message\": \"Unknown response status " + String(status) + "\"}";
    status = 500;
    statusText = getHttpStatusText(httpStatuses, status);
  }

  client.println("HTTP/1.1 " + String(status) + " " + statusText);
  client.println("Connection: close");
  client.println("Content-Type: application/json");
  client.println();
  client.println(body.c_str());

  client.flush();
  client.stop();
}

void handleGetStatus(EthernetClient& client) {
  String status = currentLightStatus ? "on" : "off";
  sendClientResponse(client, 200, "{ \"status\": \"" + status + "\" }");
}

void handlePostTurnOnOff(EthernetClient& client, bool turnOn) {
  setLightOutput(turnOn);
  String status = currentLightStatus ? "on" : "off";
  sendClientResponse(client, 200, "{ \"status\": \"" + status + "\" }");
}

void handleNotFound(EthernetClient& client) {
  sendClientResponse(client, 404, "{ \"message\": \"Requested endpoint was not found\" }");
}

void loopNetworkServer() {
  if (!ethernetInitialized) {
    Serial.println("Ethernet not configured yet");
    const auto result = Ethernet.begin(macAddress, 10000);
    if (result != 1) {
      Serial.println("Ethernet configuration failed");
      delay(100);
      return;
    } else {
      Serial.println("Initial Ethernet configuration succeeded");
    }

    ethernetInitialized = true;
  } else if (Ethernet.linkStatus() != LinkON || Ethernet.localIP().toString().compareTo("0.0.0.0") == 0) {
    ethernetDisconnected = true;
    Serial.println("Ethernet is disconnected");
  }

  if (ethernetDisconnected) {
    Serial.println("Reconnectng Ethernet");
    const auto result = Ethernet.begin(macAddress, 5000);
    if (result != 1) {
      Serial.println("Ethernet reconfiguration failed");
      delay(100);
      return;
    } else {
      Serial.println("Ethernet reconnection succeeded");
    }

    ethernetDisconnected = false;
  }

  EthernetClient client = server.available();
  if (!client) {
    return;
  }

  String request("");
  while (client.available()) {
    request.concat((char)client.read());
  }

  String method = request.substring(0, request.indexOf(" "));
  String path = request.substring(method.length() + 1, method.length() + 1 + request.substring(method.length() + 1).indexOf(" "));
  String body = request.indexOf("\r\n\r\n") == -1 ? "" : request.substring(request.indexOf("\r\n\r\n") + 4);

  if (method.compareTo("GET") == 0 && path.compareTo("/api/status") == 0) {
    handleGetStatus(client);
  } else if (method.compareTo("POST") == 0 && path.compareTo("/api/turn-on") == 0) {
    handlePostTurnOnOff(client, true);
  } else if (method.compareTo("POST") == 0 && path.compareTo("/api/turn-off") == 0) {
    handlePostTurnOnOff(client, false);
  } else if (method.compareTo("POST") == 0 && path.compareTo("/api/toggle") == 0) {
    handlePostTurnOnOff(client, !currentLightStatus);
  } else {
    handleNotFound(client);
  }
}

// MARK: Button loop section

void loopButtons() {
  for (auto& button : buttons)  {
    button.loop();
  }
}

void handleButtonTap(Button2& button) {
  Serial.println("Button clicked");
  toggleLightOutput();
}

// MARK: Output section

void toggleLightOutput() {
  setLightOutput(!currentLightStatus);
}

void setLightOutput(bool newStatus) {
  currentLightStatus = newStatus;

  for (const auto& pin : lightPins)  {
    digitalWrite(pin, currentLightStatus ? HIGH : LOW);
  }
}
