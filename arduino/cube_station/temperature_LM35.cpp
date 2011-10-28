#include "WProgram.h"
#include "temperature_LM35.h"

float getTemperature(int pin) {
  float C = ( analogRead(pin) *0.0048828125 * 100. ) - 273. ;

  return C ;
}




