#include "humidity_HIH4030.h"
#include "microphone_ADMP401.h"
#include "temperature_LM35.h"
#include "rfid.h"
#include "pitches.h"

#include <stdlib.h>
#include <NewSoftSerial.h>

#include "QuectelM10.h"

#define MICROPHONE_SENSOR_PIN 0
#define HUMIDITY_SENSOR_PIN 1
#define TEMPERATURE_SENSOR_PIN 2
#define PHOTORESISTOR_SENSOR_PIN 3

#define SPEAKER_PIN 8

char s[20];

// Variables for RFID scanning
char rfidSerial[20] = "" ;

// Variables for GSM
char smsBuffer[160];
char phoneNumber[20];


void setup()
{
  Serial.begin(9600);
  Serial3.begin(9600);


  Serial.println("******************************") ;
  Serial.println("***  Welcome to the Cube!  ***") ;
  Serial.println("******************************") ;

  // Setup GSM
  Serial.println() ;
  Serial.println() ;
  Serial.println("... Initializing GSM stack ...") ;
  Serial.println() ;
  if (gsm.begin())
    Serial.println("\n... GSM ... READY!");
  else Serial.println("\n... GSM ... IDLE!");

  // Setup RFID
  setupRfid() ;
}

void loop(){
  // Check if an RFID tag is present
  if ( read_serial(rfidSerial) > 0 ) {
    Serial.println(rfidSerial) ;
    delay(50) ;
    playMelodyRfidScan(SPEAKER_PIN) ;
  }

  // Check if we have received an SMS
  if(gsm.readSMS(smsBuffer, 160, phoneNumber, 20))
  {
    Serial.println("\n\n---------");
    Serial.print("Phone #: ");
    Serial.println(phoneNumber);
    Serial.print("Message: ");
    Serial.println(smsBuffer);
    Serial.println("---------\n\n");
    playMelodySmsReceived(SPEAKER_PIN);
  } 

  delay(1000) ;
  
  float humidity = getHumidity(HUMIDITY_SENSOR_PIN) ;
  float temperature = getTemperature(TEMPERATURE_SENSOR_PIN) ;
  float soundLevel = getSoundLevel(MICROPHONE_SENSOR_PIN) ;
  float illuminance = getSoundLevel(PHOTORESISTOR_SENSOR_PIN) ;

  /*
  Serial3.println("HUM: " + String(dtostrf(humidity,2,2,s)) + "%") ;
   delay(10);
   Serial3.print(254, BYTE) ;
   Serial3.print(1, BYTE) ;
   
   Serial3.println("SOUND: " + String(soundLevel)) ;
   delay(10);
   Serial3.print(254, BYTE) ;
   Serial3.print(1, BYTE) ;
   
   Serial3.println("TMP: " + String(dtostrf(temperature,2,2,s)) + "C") ;
   delay(10);
   Serial3.print(254, BYTE) ;
   Serial3.print(1, BYTE) ;
   */
}





