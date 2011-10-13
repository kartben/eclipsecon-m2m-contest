#include <avr/sleep.h>
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
int sleepStatus = 0;             // variable to store a request for sleep

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

void wakeUpNow()        // here the interrupt is handled after wakeup
{
  // execute code here after wake-up before returning to the loop() function
  // timers and code using timers (serial.print and more...) will not work here.
  // we don't really need to execute any special functions here, since we
  // just want the thing to wake up
}

void setup()
{
  pinMode(wakePin, INPUT);
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);

  Serial.begin(9600);

  /* Now it is time to enable an interrupt. In the function call 
   * attachInterrupt(A, B, C)
   * A   can be either 0 or 1 for interrupts on pin 2 or 3.   
   * 
   * B   Name of a function you want to execute while in interrupt A.
   *
   * C   Trigger mode of the interrupt pin. can be:
   *             LOW        a low level trigger
   *             CHANGE     a change in level trigger
   *             RISING     a rising edge of a level trigger
   *             FALLING    a falling edge of a level trigger
   *
   * In all but the IDLE sleep modes only LOW can be used.
   */

  attachInterrupt(0, wakeUpNow, LOW); // use interrupt 0 (pin 2) and run function
  // wakeUpNow when pin 2 gets LOW 
}

void sleepNow()         // here we put the arduino to sleep
{
  flashLed(13, 2, 500) ;

  /* Now is the time to set the sleep mode. In the Atmega8 datasheet
   * http://www.atmel.com/dyn/resources/prod_documents/doc2486.pdf on page 35
   * there is a list of sleep modes which explains which clocks and 
   * wake up sources are available in which sleep mode.
   *
   * In the avr/sleep.h file, the call names of these sleep modes are to be found:
   *
   * The 5 different modes are:
   *     SLEEP_MODE_IDLE         -the least power savings 
   *     SLEEP_MODE_ADC
   *     SLEEP_MODE_PWR_SAVE
   *     SLEEP_MODE_STANDBY
   *     SLEEP_MODE_PWR_DOWN     -the most power savings
   *
   * For now, we want as much power savings as possible, so we 
   * choose the according 
   * sleep mode: SLEEP_MODE_PWR_DOWN
   * 
   */
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);   // sleep mode is set here

  sleep_enable();          // enables the sleep bit in the mcucr register
  // so sleep is possible. just a safety pin 

  /* Now it is time to enable an interrupt. We do it here so an 
   * accidentally pushed interrupt button doesn't interrupt 
   * our running program. if you want to be able to run 
   * interrupt code besides the sleep function, place it in 
   * setup() for example.
   * 
   * In the function call attachInterrupt(A, B, C)
   * A   can be either 0 or 1 for interrupts on pin 2 or 3.   
   * 
   * B   Name of a function you want to execute at interrupt for A.
   *
   * C   Trigger mode of the interrupt pin. can be:
   *             LOW        a low level triggers
   *             CHANGE     a change in level triggers
   *             RISING     a rising edge of a level triggers
   *             FALLING    a falling edge of a level triggers
   *
   * In all but the IDLE sleep modes only LOW can be used.
   */

  attachInterrupt(0,wakeUpNow, LOW); // use interrupt 0 (pin 2) and run function
  // wakeUpNow when pin 2 gets LOW 

    sleep_mode();            // here the device is actually put to sleep!!
  // THE PROGRAM CONTINUES FROM HERE AFTER WAKING UP

  sleep_disable();         // first thing after waking from sleep:
  // disable sleep...
  detachInterrupt(0);      // disables interrupt 0 on pin 2 so the 
  // wakeUpNow code will not be executed 
  // during normal running time.
}

void loop()
{
  sleepNow();

  // we woke up
  delay(100) ; 
  flashLed(13, 5, 40) ;

  delay(1500) ;

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

  // find a way to get noise level smartly :)

  sendValues(lux, (int) (tempC * 100.)) ;

  delay(500) ;
}



