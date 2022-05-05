#include "FastLED.h"

#define NUMLEDS     120
#define DATAPIN     11
#define CLOCKPIN    13
#define BAUDRATE    115200

CRGB leds[NUMLEDS];
byte buff[5];

void setup() {
  FastLED.addLeds<DOTSTAR, DATAPIN, CLOCKPIN, BGR>(leds, NUMLEDS);
  FastLED.clear(true);
  FastLED.show();
  Serial.begin(BAUDRATE);
}

void loop() {
  if (Serial.available()) {
    int nb = Serial.readBytes(buff, 5);
    if (nb == 5) {
      CRGB color = CRGB(buff[0], buff[1], buff[2]);
      FastLED.clear();
      if (buff[3] > buff[4]) {
        for (int i = buff[3] - 1; i < NUMLEDS; i++) {
          leds[i] = color;
        }
        for (int i = 0; i < buff[4]; i++) {
          leds[i] = color;
        }
      } else {
        for (int i = buff[3] - 1; i < buff[4]; i++) {
          leds[i] = color;
        }
      }
      FastLED.show();
    }
  }
}
