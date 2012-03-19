#include <SoftwareSerial.h>

/*
 * ----------------------------
 * EclipseCon satellite station
 * ----------------------------
 * The Arduino Fio is put in POWER_DOWN mode until a low level is detected
 * on interrupt 0 (pin 2), meaning that the attached XBee end-device just
 * woke up.
 * 
 * While it is awake, the Arduino is collecting values of connected sensors, 
 * and send them to the Cube.
 *
 * Copyright (C) 2006 MacSimski 2006-12-30 
 * Copyright (C) 2007 D. Cuartielles 2007-07-08 - Mexico DF
 * Copyright (C) 2011 B. Cabé 2011-10-06
 * 
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

#define TEMPERATURE_SENSOR_PIN 1
#define ILLUMINANCE_SENSOR_PIN 0
#define SOUND_SENSOR_PIN 2

#define PHOTOCELL_RESISTOR 10.0


int wakePin = 2;                 // pin used for waking up

void flashLed(int pin, int times, int wait) {
  for (int i = 0; i < times; i++) {
    digitalWrite(pin, HIGH);
    delay(wait);
    digitalWrite(pin, LOW);

    if (i + 1 < times) {
      delay(wait);
    }
  }
}

void setup()
{
  pinMode(2, INPUT);
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);

  Serial.begin(9600);
}

void loop()
{
  int sensorValue ;

  // get illuminance
  sensorValue = analogRead(ILLUMINANCE_SENSOR_PIN);    
  float Vout0 = sensorValue * 0.003222656;	                            // calculate the voltage
  int lux = 500 / ( PHOTOCELL_RESISTOR * ( (3.3-Vout0) / Vout0 ) );

  delay(10);

  // get temperature
  sensorValue = analogRead(TEMPERATURE_SENSOR_PIN);    
  float K = (((sensorValue / 1023.) * 3.3) * 100.);
  float tempC = K-273.;

  sendValues(lux, (int) (tempC * 100.)) ;
  delay(1000);
}



