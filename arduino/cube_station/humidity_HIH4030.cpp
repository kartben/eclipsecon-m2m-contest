/*
  Relative Humidity Sensor Reader
 (for use with the HIH-4030/31 seres sensor)
 
 Datasheet available from:
 http://www.sparkfun.com/datasheets/Sensors/Weather/SEN-09569-HIH-4030-datasheet.pdf
 
 Written By:
 K-MOB
 for Bildr
 09/23/2010
 */
 
#include "WProgram.h"
#include "humidity_HIH4030.h"

int analogPin = 1;    // choose an analog input pin
int sensorValue;     // value coming from the sensor
float supplyVolt = 5.0; // supply voltage
// if you are measuring temperature elsewhere in the code,
// define temperature in-line (use degrees C)
float temperature = 25.; // ambient temperature
float voltage;      // sensor voltage
float sensorRH;     // sensor RH (at 25 degrees C)
float trueRH;      // RH % accounting for temperature

/*
* pin has to be setup in INPUT mode
*/
float getHumidity(int pin) {

  // read the value from the sensor:
  sensorValue = analogRead(pin);

  // convert analog value to a voltage value
  voltage = sensorValue/1023. * supplyVolt;

  // convert the voltage to a relative humidity
  // - the equation is derived from the HIH-4030/31 datasheet
  // - it is not calibrated to your individual sensor
  //  Table 2 of the datasheet illustrates that actual
  //  sensor performance may deviiate from this line
  sensorRH = 161.*voltage/supplyVolt - 25.8;
  // an adjustment can be made for different operating temperatures
  trueRH = sensorRH / (1.0546 - 0.0026*temperature);

  return trueRH;
}

