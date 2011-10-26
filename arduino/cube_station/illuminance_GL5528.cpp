#include "WProgram.h"
#include "illuminance_GL5528.h"

#define PHOTOCELL_RESISTOR 10.0                                     // Resistance used in the voltage divider

float getIlluminance(int pin) {
  int val = analogRead(pin);
  float Vout0 = val * 0.0048828125;	                            // calculate the voltage
  int lux = 500. / ( PHOTOCELL_RESISTOR * ( (5.0 - Vout0) / Vout0 ) );   // calculate the Lux

  return lux ;
}

