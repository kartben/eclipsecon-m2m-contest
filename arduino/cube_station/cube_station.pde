#include "humidity_HIH4030.h"
#include "microphone_ADMP401.h"
#include "temperature_LM35.h"
#include "illuminance_GL5528.h"

#include "rfid.h"
#include "pitches.h"

#include <stdlib.h>
#include <NewSoftSerial.h>

#include "QuectelM10.h"

#include <SPI.h>
#include <Ethernet.h>

#define NB_SENSORS 4

#define MICROPHONE_SENSOR_PIN 0
#define HUMIDITY_SENSOR_PIN 1
#define TEMPERATURE_SENSOR_PIN 2
#define PHOTORESISTOR_SENSOR_PIN 3

String sensorNames[] = { 
  "NOISE", "HUMIDITY", "TEMPERATURE", "ILLUMINANCE" } 
;

float lastSensorValues[] = { 
  0.0, 0.0, 0.0, 0.0};

#define SPEAKER_PIN 8

char s[20];

// Variables for RFID scanning

char rfidSerial[20] = "" ;

// ***************************

// Variables for GSM
char smsBuffer[160];
char phoneNumber[20];

long lastSmsCheckTime = 0;
const int smsCheckInterval = 10000; 

// ***************************

// Variables for Ethernet/MongoREST

// assign a MAC address for the ethernet controller fill in your address here:
byte mac[] = { 
  0x90, 0xA2, 0xDA, 0x00, 0x44, 0x86};
// assign an IP address for the controller:
byte ip[] = { 
  192,168,1,20 };

//  The address of the server you want to connect to (MongoDB REST API):
byte server[] = { 
  192,168,1,1}; 

// initialize the library instance:
Client client(server, 27080);

long lastConnectionTime = 0;        // last time you connected to the server, in milliseconds
boolean lastConnected = false;      // state of the connection last time through the main loop
const int postingInterval = 5000; 
char jsonDocument[1024] = "";

// ***************************

void setup()
{
  // Serial is used for debug/info traces
  Serial.begin(9600);

  // Serial2 is used for GPRS shield

  // Serial3 is used for LCD display
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
  // Setup data Ethernet stack
  Ethernet.begin(mac, ip);
}

void loop(){
  // Check if an RFID tag is present
  if ( read_serial(rfidSerial) > 0 ) {
    Serial.println(rfidSerial) ;
    delay(50) ;
    playMelodyRfidScan(SPEAKER_PIN) ;
  }

  if(millis() - lastSmsCheckTime > smsCheckInterval) {
    Serial.print("Check SMS ... ") ;
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
    Serial.println("done!") ;
    lastSmsCheckTime = millis();
  }

  delay(100) ;

  float humidity = getHumidity(HUMIDITY_SENSOR_PIN) ; 
  lastSensorValues[HUMIDITY_SENSOR_PIN] = humidity ;
  float temperature = getTemperature(TEMPERATURE_SENSOR_PIN) ;
  lastSensorValues[TEMPERATURE_SENSOR_PIN] = temperature ;
  float soundLevel = getSoundLevel(MICROPHONE_SENSOR_PIN) ; 
  lastSensorValues[MICROPHONE_SENSOR_PIN] = soundLevel ;
  float illuminance = getSoundLevel(PHOTORESISTOR_SENSOR_PIN) ;
  lastSensorValues[PHOTORESISTOR_SENSOR_PIN] = illuminance ;

  Serial.println("HUM: " + String(dtostrf(humidity,2,2,s)) + "%") ;
  Serial.println("SOUND: " + String(dtostrf(soundLevel,2,2,s))) ;
  Serial.println("TMP: " + String(dtostrf(temperature,2,2,s)) + "C") ;
  Serial.println("ILLUM: " + String(dtostrf(illuminance,2,2,s)) + " lux") ;


  while (client.available() > 0) {
    char c = client.read();
    Serial.print(c);
  }

  if (!client.connected() && lastConnected) {
    Serial.println();
    Serial.println("disconnecting client.");
    client.stop();
  }

  // if you're not connected, and at least "postingInterval" seconds have passed 
  // since your last connection, then connect again and send data:
  if(!client.connected() && (millis() - lastConnectionTime > postingInterval)) {
    String json = "docs=[" ;

    // build values of the "local" data (i.e. sensors physically connected to the cube)
    for(int i = 0 ; i < NB_SENSORS ; i++) {
      json += "{\"sensor\":\"CUBE_" + sensorNames[i] + "\",\"value\":" + String(dtostrf(lastSensorValues[i], 2, 2, s)) + "}" ;
      if(i < NB_SENSORS - 1)
        json += ",";  
    }

    json += "]" ; 

    Serial.println(json) ;
    sendData(json, "/sensors/data/_insert" );
  }
  
  lastConnected = client.connected();

}


// this method makes a HTTP connection to the MongoDB REST interface:
void sendData(String thisData, String url) {
  // if there's a successful connection:
  if (client.connect()) {
    client.println("POST " + url + " HTTP/1.1");
    client.println( "Host: 192.168.1.1:27080" );
    client.print( "Content-Length: " );
    client.println(thisData.length(), DEC);
    client.println( "Content-Type: application/x-www-form-urlencoded" );

    // here's the actual content of the POST request:
    client.println();
    client.println(thisData);
    client.println();

    // note the time that the connection was made:
    lastConnectionTime = millis();
  } 
  else {
    // if we couldn't make a connection:
    Serial.println("KO");
  }
}











