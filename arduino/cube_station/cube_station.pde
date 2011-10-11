/**
*
* Pin mapping:
*
*  - RX1: RFID-RX (to be wired to digital pin 7)
*  - TX1: RFID-TX (to be wired to digital pin 8)
*
*  - RX2: GSM-TX
*  - TX2: GSM-RX
*
*  - TX3: LCDDISPLQY-RX
*
*  - digital 50 -> digital 12 (SPI MOSI)
*  - digital 51 -> digital 11 (SPI MISO)
*  - digital 52 -> digital 13 (SPI SCK)
*
*  - digital 3 -> Ardumoto PWM-A
*  - digital 4 -> Ardumoto PWM-B
*  - digital 5 -> Ardumoto DIR-A
*  - digital 6 -> Ardumoto DIR-B
*/

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

#define MOTOR_A_PWM 3       // PWM control for motor outputs 1 and 2
#define MOTOR_B_PWM 11      // PWM control for motor outputs 3 and 4
#define MOTOR_A_DIR 12      // direction control for motor outputs 1 and 2
#define MOTOR_B_DIR 13     // direction control for motor outputs 3 and 4
String sensorNames[] = { 
  "NOISE", "HUMIDITY", "TEMPERATURE", "ILLUMINANCE" } 
;

float lastSensorValues[] = { 
  0.0, 0.0, 0.0, 0.0};

#define SPEAKER_PIN 8

char s[20];

// variables for LCD display
char LCD_secondLine[17] = "                " ;

// Variables for RFID scanning

char rfidSerial[20] = "" ;

// ***************************

// Variables for GSM
boolean smsReceived = false;
int smsDisplayIndex = -1 ;
char smsBuffer[160];
char smsMarqueeBuffer[250];
char phoneNumber[20];

long lastSmsCheckTime = 0;
const int smsCheckInterval = 20000; 

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
  LCD_SetBacklight(0xFF);


  Serial.println("******************************") ;
  Serial.println("***  Welcome to the Cube!  ***") ;
  Serial.println("******************************") ;

  LCD_ClearScreen();
  Serial3.print(" ...  BOOT  ... ") ; 

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

  // Setup ta Ethernet stack
  Ethernet.begin(mac, ip);

  // Setup motors (fans)
  pinMode(MOTOR_A_PWM, OUTPUT);
  pinMode(MOTOR_B_PWM, OUTPUT);
  pinMode(MOTOR_A_DIR, OUTPUT);
  pinMode(MOTOR_B_DIR, OUTPUT);
  digitalWrite(MOTOR_A_DIR, HIGH);
  digitalWrite(MOTOR_B_DIR, HIGH);
  analogWrite(MOTOR_A_PWM, 64);
  analogWrite(MOTOR_B_PWM, 64);


  Serial3.println("       OK") ; 
  delay(100) ;
  LCD_ClearScreen();
}

void loop(){
  while (client.available() > 0) {
    char c = client.read();
    Serial.print(c);
  }

  if (!client.connected() && lastConnected) {
    Serial.println();
    Serial.println("disconnecting client.");
    client.stop();
  }

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
      memset(smsMarqueeBuffer, ' ', 250);
      String s = "SMS from " + String(phoneNumber) + " --> " ;
      s += smsBuffer;
      s += "  ";
      s.toCharArray(smsMarqueeBuffer, s.length()) ;
      Serial.println(smsMarqueeBuffer) ;

      smsDisplayIndex = 0;
      smsReceived = true; 

      // Blink LCD
      for(int i = 0; i < 5 ; i++) {
        LCD_SetBacklight(0) ; 
        delay(120) ;
        LCD_SetBacklight(0xFF) ; 
        delay(120) ;
      }

      playMelodySmsReceived(SPEAKER_PIN);
    } 
    Serial.println("done!") ;
    lastSmsCheckTime = millis();
  }

  if(smsReceived)
  {
    // is it a command for the fans? (command example: "FAN1 40", to set Fan#1 to a 40% speed)
    int motor, speed; 
    int res = sscanf(smsBuffer, "FAN%d %d", &motor, &speed) ;
    if(res == 2) {
      // it is a command indeed!
      int adjustedSpeed = map(speed, 0, 100, 0, 255) ;
      Serial.println("Setting speed of motor #" + String(motor) + " to " + String(adjustedSpeed) + "(" + String(speed) +  "%)" ) ;
      analogWrite((motor == 1) ? MOTOR_A_PWM : MOTOR_B_PWM , adjustedSpeed);

      // store the received command in mongodb
      String json = "docs=[" ;
      json += "{\"command\":\"FAN" + String(motor) + " " + String(speed) +  "\",\"type\":\"SMS\", \"from\":\"" + phoneNumber + "\"}" ;
      json += "]" ; 

      Serial.println(json) ;
      sendData(json, "/cmd/histo/_insert" );

      // we don't want to display such an SMS
      smsDisplayIndex = -1 ;
    }

    smsReceived = false ; // SMS has been processed
  }

  // display SMS if any
  if(smsDisplayIndex >= 0 && smsDisplayIndex < 250) {
    for(int i = 0 ; i < 15 ; i++)
      LCD_secondLine[i] = LCD_secondLine[i+1] ;
    LCD_secondLine[15] = smsMarqueeBuffer[smsDisplayIndex++] ;
    LCD_MoveCursor(16);
    Serial3.print(LCD_secondLine) ;
  } 


  float humidity = getHumidity(HUMIDITY_SENSOR_PIN) ; 
  lastSensorValues[HUMIDITY_SENSOR_PIN] = humidity ;
  float temperature = getTemperature(TEMPERATURE_SENSOR_PIN) ;
  lastSensorValues[TEMPERATURE_SENSOR_PIN] = temperature ;
  float soundLevel = getSoundLevel(MICROPHONE_SENSOR_PIN) ; 
  lastSensorValues[MICROPHONE_SENSOR_PIN] = soundLevel ;
  float illuminance = getSoundLevel(PHOTORESISTOR_SENSOR_PIN) ;
  lastSensorValues[PHOTORESISTOR_SENSOR_PIN] = illuminance ;


  LCD_MoveCursor(0) ;
  Serial3.print("                ") ;
  LCD_MoveCursor(0) ;

  switch(millis() / 5000 % 4) {
  case 0:  
    Serial3.print("Hum. " + String(dtostrf(humidity,2,2,s)) + "%") ; 
    break;
  case 1:  
    Serial3.print("Noise. " + String(dtostrf(soundLevel,2,2,s))) ;
    break;
  case 2: 
    Serial3.print("Temp. " + String(dtostrf(temperature,2,2,s)) + (char)0xDF + "C") ;
    break; 
  case 3: 
    Serial3.print("Illum. " + String(dtostrf(illuminance,2,2,s)) + " lux") ; 
    break;
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


  delay(120);

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






























