#include <WiFi.h>
#include <WebServer.h>
#include "driver/dac.h"

// WiFi Hotspot credentials
const char *ssid = "DroneWiFi"; // WiFi Hotspot SSID
const char *password = "";      // No password

WebServer server(80); // Create a WebServer on port 80

bool motorsStarted = false; // Motor state
bool fpgaReset = false;     // FPGA reset state
bool forwards = false;
bool backwards = false;
bool right = false;
bool left = false;

void setup()
{
  Serial.begin(115200);

  // Set up WiFi hotspot
  WiFi.softAP(ssid, password);

  // Print the IP address of the WiFi hotspot
  Serial.println("WiFi Hotspot IP Address: ");
  Serial.println(WiFi.softAPIP());

  // Set pins as outputs and initialize to LOW
  pinMode(19, OUTPUT); // start motors
  pinMode(18, OUTPUT); // reset fpga
  pinMode(17, OUTPUT); // forward
  pinMode(16, OUTPUT); // backwards
  pinMode(0, OUTPUT);  // right
  pinMode(2, OUTPUT);  // left

  digitalWrite(19, LOW);
  digitalWrite(18, LOW);
  digitalWrite(17, LOW);
  digitalWrite(16, LOW);
  digitalWrite(0, LOW);
  digitalWrite(2, LOW);

  // DAC leftovers
  // Initialize DAC
  // dac_output_enable(DAC_CHANNEL_1);

  // Route for root / webpage
  server.on("/", HTTP_GET, handleRoot);
  // Route to handle slider value updates
  server.on("/update", HTTP_GET, handleUpdate);
  // Route to handle START MOTORS button
  server.on("/start_motors", HTTP_GET, handleStartMotors);
  // Route to handle RESET FPGA button
  server.on("/reset_fpga", HTTP_GET, handleResetFPGA);
  // Route to handle FORWARDS button
  server.on("/forwards", HTTP_GET, handleForwards);
  // Route to handle BACKWARDS button
  server.on("/backwards", HTTP_GET, handleBackwards);
  // Route to handle RIGHT button
  server.on("/right", HTTP_GET, handleRight);
  // Route to handle LEFT button
  server.on("/left", HTTP_GET, handleLeft);
  // Start the server
  server.begin();
}

void loop()
{
  server.handleClient(); // Handle client requests

  // Ensure GPIO pins are always set to zero
  digitalWrite(19, motorsStarted); // start motors
  digitalWrite(18, fpgaReset);     // reset fpga
  digitalWrite(17, forwards);      // forward
  digitalWrite(16, backwards);     // backwards
  digitalWrite(0, right);          // right
  digitalWrite(2, left);           // left
}

// Handle root / webpage
void handleRoot()
{
  // HTML content for the webpage with Bootstrap, buttons, and JavaScript
  String html = "<!DOCTYPE html><html><head><title>Thrust Control</title>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css'>";
  html += "<style>";
  html += "body { font-size: 1.2em; }";
  html += ".btn { font-size: 1.5em; padding: 1em; margin: 0.5em; }";
  html += ".range { width: 100%; }";
  html += "</style>";
  html += "</head><body class='text-center'>";
  html += "<div class='container'><h1 class='mt-5'>Thrust Control</h1>";
  html += "<input type='range' class='form-control-range mt-3 range' id='slider' name='slider' min='0' max='255' value='0' oninput='updateValue(this.value)' ";
  html += "ontouchmove='updateValue(this.value)' onmousemove='updateValue(this.value)'><br>";
  html += "<button class='btn btn-primary mt-3' onclick='startMotors()'>START MOTORS</button>";
  html += "<button class='btn btn-danger mt-3' onclick='resetFPGA()'>RESET FPGA</button>";
  html += "<div class='mt-3'><button class='btn btn-secondary' onclick='moveForwards()'>FORWARDS</button>";
  html += "<button class='btn btn-secondary' onclick='moveBackwards()'>BACKWARDS</button>";
  html += "<button class='btn btn-secondary' onclick='moveRight()'>RIGHT</button>";
  html += "<button class='btn btn-secondary' onclick='moveLeft()'>LEFT</button></div>";
  html += "<script>function updateValue(value) {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.onreadystatechange = function() {";
  html += "if (this.readyState == 4 && this.status == 200) {";
  html += "console.log('Value updated:', value);";
  html += "}};";
  html += "xhttp.open('GET', '/update?value=' + value, true);";
  html += "xhttp.send();";
  html += "}";
  html += "function startMotors() {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.open('GET', '/start_motors', true);";
  html += "xhttp.send();";
  html += "}";
  html += "function resetFPGA() {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.open('GET', '/reset_fpga', true);";
  html += "xhttp.send();";
  html += "}";
  html += "function moveForwards() {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.open('GET', '/forwards', true);";
  html += "xhttp.send();";
  html += "}";
  html += "function moveBackwards() {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.open('GET', '/backwards', true);";
  html += "xhttp.send();";
  html += "}";
  html += "function moveRight() {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.open('GET', '/right', true);";
  html += "xhttp.send();";
  html += "}";
  html += "function moveLeft() {";
  html += "var xhttp = new XMLHttpRequest();";
  html += "xhttp.open('GET', '/left', true);";
  html += "xhttp.send();";
  html += "}</script>";
  html += "</div></body></html>";

  server.send(200, "text/html", html); // Send HTML response
}

// Handle update request
void handleUpdate()
{
  // Get the value of the slider from the request
  String sliderValue = server.arg("value");
  int thrustValue = sliderValue.toInt();

  // Print binary representation of the value
  Serial.print("Thrust Value (Binary): ");
  for (int i = 7; i >= 0; i--)
  {
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

// Handle start motors request
void handleStartMotors()
{
  motorsStarted = !motorsStarted;
  digitalWrite(19, motorsStarted ? HIGH : LOW);
  Serial.println(motorsStarted ? "Motors started" : "Motors stopped");

  server.send(200, "text/plain", motorsStarted ? "Motors started" : "Motors stopped");
}

// Handle reset FPGA request
void handleResetFPGA()
{
  fpgaReset = !fpgaReset;
  motorsStarted = false; // even if reset is on, restart also the motors.
  digitalWrite(18, fpgaReset ? HIGH : LOW);
  Serial.println(fpgaReset ? "FPGA reset" : "FPGA reset cleared");

  server.send(200, "text/plain", fpgaReset ? "FPGA reset" : "FPGA reset cleared");
}

// Handle forwards request
void handleForwards()
{
  forwards = !forwards;
  digitalWrite(17, forwards ? HIGH : LOW);
  Serial.println(forwards ? "Moving forwards" : "Stopped moving forwards");

  server.send(200, "text/plain", forwards ? "Moving forwards" : "Stopped moving forwards");
}

// Handle backwards request
void handleBackwards()
{
  backwards = !backwards;
  digitalWrite(16, backwards ? HIGH : LOW);
  Serial.println(backwards ? "Moving backwards" : "Stopped moving backwards");

  server.send(200, "text/plain", backwards ? "Moving backwards" : "Stopped moving backwards");
}

// Handle right request
void handleRight()
{
  right = !right;
  digitalWrite(0, right ? HIGH : LOW);
  Serial.println(right ? "Moving right" : "Stopped moving right");

  server.send(200, "text/plain", right ? "Moving right" : "Stopped moving right");
}

// Handle left request
void handleLeft()
{
  left = !left;
  digitalWrite(2, left ? HIGH : LOW);
  Serial.println(left ? "Moving left" : "Stopped moving left");

  server.send(200, "text/plain", left ? "Moving left" : "Stopped moving left");
}
