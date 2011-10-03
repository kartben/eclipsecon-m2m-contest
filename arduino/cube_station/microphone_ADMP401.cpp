#include "WProgram.h"
#include "microphone_ADMP401.h"

int getSoundLevel(int pin) {
  // the microphone outputs a value oscillating around VCC/2, VCC=3.3V
  return map( abs(analogRead(pin) - 338), 0, 676, 0, 100 );
}
