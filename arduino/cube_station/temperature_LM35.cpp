#include "WProgram.h"
#include "temperature_LM35.h"

float getTemperature(int pin) {
  float K = (((analogRead(pin) / 1023.) * 5.) * 100.);
  float C = K-273.;
  
  return C ;
}

