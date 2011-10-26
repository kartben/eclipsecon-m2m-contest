#include "WProgram.h"
#include "temperature_LM35.h"

float getTemperature(int pin) {
  float C = ( analogRead(pin) *0.0048828125 * 100. ) - 273. ;

  // there seems to be an offset of about 25C.
  // Would probably be better to really calibrate the sensor with its dedicated pin though..
  C = C - 25.0 ; 

  return C ;
}




