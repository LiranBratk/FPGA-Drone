#include <WiFi.h>
#include <WebServer.h>
#include "driver/dac.h"

// WiFi Hotspot credentials
const char* ssid = "DroneWiFi"; // WiFi Hotspot SSID
const char* password = "";      // No password

WebServer server(80); // Create a WebServer on port 80

void setup() {
  Serial.begin(115200);

  // Set up WiFi hotspot
  WiFi.softAP(ssid, password);

  // Print the IP address of the WiFi hotspot
  Serial.println("WiFi Hotspot IP Address: ");
  Serial.println(WiFi.softAPIP());

  // DAC leftovers
  // Initialize DAC
  // dac_output_enable(DAC_CHANNEL_1);

  // Route for root / webpage
  server.on("/", HTTP_GET, handleRoot);
  // Route to handle slider value updates
  server.on("/update", HTTP_GET, handleUpdate);
  // Start the server
  server.begin();
}

void loop() {
  server.handleClient(); // Handle client requests
}

// Handle root / webpage
void handleRoot() {
  // HTML content for the webpage with an inverted slider and JavaScript
  String html = "<!DOCTYPE html><html><head><title>Thrust Slider</title></head><body>";
  html += "<h1>Thrust Slider</h1>";
  html += "<input type='range' id='slider' name='slider' min='0' max='255' oninput='updateValue(this.value)' ";
  html += "ontouchmove='updateValue(this.value)' onmousemove='updateValue(this.value)'><br>";
  html += "<script>function updateValue(value) {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.onreadystatechange = function() {";
  html += "if (this.readyState == 4 && this.status == 200) {";
  html += "console.log('Value updated:', value);";
  html += "}};";
  html += "xhttp.open('GET', '/update?value=' + value, true);";
  html += "xhttp.send();";
  html += "}</script>";
  html += "</body></html>";

  server.send(200, "text/html", html); // Send HTML response
}

// Handle update request
void handleUpdate() {
  // Get the value of the slider from the request
  String sliderValue = server.arg("value");
  int thrustValue = sliderValue.toInt();

  // Print binary representation of the value
  Serial.print("Thrust Value (Binary): ");
  for (int i = 7; i >= 0; i--) {
    Serial.print((thrustValue >> i) & 1);
  }
  Serial.println(); // New line

  Serial.write(thrustValue); // Send thrust value via Serial

  // DAC leftovers
  // Map the value from 0-255 to 0-255*255 (0-65535) for DAC
  // dacWrite(25, thrustValue);
  // dac_output_voltage(DAC_CHANNEL_1, thrustValue * 255);

  server.send(200, "text/plain", "OK"); // Send response to the client
}
