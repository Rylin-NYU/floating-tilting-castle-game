
#include "Wire.h"
#include <MPU6050_light.h>
#include "Servo.h"
#include <FastLED.h>

MPU6050 mpu(Wire);

//mpu and button
unsigned long timer = 0;
int buttonPin = 11;

//servo
Servo frontServo;
Servo backServo;

//LEDS
#define NUM_LEDS 60 // How many leds on your strip?
#define DATA_PIN 3
CRGB leds[NUM_LEDS];

const int NUM_OF_VALUES_FROM_PROCESSING = 3;
int processing_values[NUM_OF_VALUES_FROM_PROCESSING] = {0, 0, 0};

void setup() {
   Serial.begin(115200);
   Wire.begin(); 
   byte status = mpu.begin();
   Serial.print(F("MPU6050 status: "));
   Serial.println(status);
   while(status!=0){ } // stop everything if could not connect to MPU6050
   Serial.println(F("Calculating offsets, do not move MPU6050"));
   delay(1000);
   // mpu.upsideDownMounting = true; // uncomment this line if the MPU6050 is mounted upside-down
   mpu.calcOffsets(); // gyro and accelero
   Serial.println("Done!\n");
   pinMode(buttonPin, INPUT_PULLUP);
   FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);
   FastLED.setBrightness(50); 
   frontServo.attach(13);
   backServo.attach(4);
   frontServo.write(90);
   backServo.write(90);
   
}

void loop() {
  getSerialData();
  if((millis()-timer)>10){ // print data every 10ms
    mpu.update();
    Serial.print(mpu.getAngleX());
    Serial.print(",");
    Serial.print(mpu.getAngleY());
    Serial.print(",");
    int button = digitalRead(buttonPin) == LOW ? 1 : 0;
    Serial.println(button);
  
    timer = millis(); 
  }

  
  moveFlags();
  
  
  // LEDS based on gameMode sent to us by processing
  int gameMode = processing_values[2];
  
  // Force default immediately every frame
  CRGB activeColor =CRGB::Blue;
  
  if (gameMode == 0) {
    activeColor = CRGB::Blue;      // Menu
  }
  else if (gameMode == 1) {
    activeColor = CRGB::White;     // Tutorial
  }
  else if (gameMode == 2) {
    activeColor = CRGB::Green;     // Endless
  }
  else if (gameMode == 3) {
    activeColor = CRGB::Purple;    // Chaos
  }
  else if (gameMode == 4) {
    activeColor = CRGB::Red;       // Game Over
  }
  
  // ALWAYS update MPU before LED logic
  float tiltX = mpu.getAngleX();
  float tiltY = mpu.getAngleY();

  //else the directions are backwards for some reasn
  tiltX = -tiltX;
  
  if (gameMode == 0) {
    fill_solid(leds, NUM_LEDS, CRGB::Blue);
    FastLED.show();
    return;
  }
  
  if (gameMode == 4) {
    fill_solid(leds, NUM_LEDS, CRGB::Red);
    FastLED.show();
    return;
  }
  
  // when the castle is flat
  if (abs(tiltX) < 5 && abs(tiltY) < 5) {
    if (gameMode != 4){
    fill_solid(leds, NUM_LEDS, CRGB(15,15,15));
    FastLED.show();
    return;
    }
  }
  
  // ---------------- TILT COMPASS ----------------
  float angle = atan2(tiltX, tiltY);
  
  static float filteredAngle = 0;
  filteredAngle += (angle - filteredAngle) * 0.15;
  
  float norm = (filteredAngle + PI) / (2 * PI);

  int ledIndex = NUM_LEDS - 1 - (norm * NUM_LEDS);

  if (gameMode != 4){
    fill_solid(leds, NUM_LEDS, CRGB::Blue); 
  }
    
  for (int i = -2; i <= 2; i++) {
    int idx = (ledIndex + i + NUM_LEDS) % NUM_LEDS;
    leds[idx] = activeColor;
  }
  
  FastLED.show();
}


//similar logic to my leds
void moveFlags() {

  mpu.update();

  float tiltX = mpu.getAngleX();
  float tiltY = mpu.getAngleY();

  tiltX = -tiltX;

  if (abs(tiltX) < 3) tiltX = 0;
  if (abs(tiltY) < 3) tiltY = 0;

  float tiltForce = tiltX + (tiltY * 0.35);
  tiltForce = constrain(tiltForce, -30, 30);

  int neutralFront = 90;
  int neutralBack  = 90;

  int frontSpeed = neutralFront + tiltForce;
  int backSpeed  = neutralBack + tiltForce;

  frontSpeed = constrain(frontSpeed, 60, 120);
  backSpeed  = constrain(backSpeed, 60, 120);

  frontServo.write(frontSpeed);
  backServo.write(backSpeed);
}



/* Receive Serial data from Processing */
/* You won't need to change this code  */

void getSerialData() {
  static int tempValue = 0;  // the "static" makes the local variable retain its value between calls of this function
  static int tempSign = 1;
  static int valueIndex = 0;

  while (Serial.available()) {
    char c = Serial.read();
    if (c >= '0' && c <= '9') {
      // received a digit:
      // multiply the current value by 10, and add the character (converted to a number) as the last digit
      tempValue = tempValue * 10 + (c - '0');
    } else if (c == '-') {
      // received a minus sign:
      // make a note to multiply the final value by -1
      tempSign = -1;
    } else if (c == ',' || c == '\n') {
      // received a comma, or the newline character at the end of the line:
      // update the processing_values array with the temporary value
      if (valueIndex < NUM_OF_VALUES_FROM_PROCESSING) {  // should always be the case, but double-check
        processing_values[valueIndex] = tempValue * tempSign;
      }
      // get ready for the new data by resetting the temporary value and sign
      tempValue = 0;
      tempSign = 1;
      if (c == ',') {
        // move to dealing with the next entry in the processing_values array
        valueIndex = valueIndex + 1;
      } else {
        // except when we reach the end of the line
        // go back to the first entry in this case
        valueIndex = 0;
      }
    }
  }
}
