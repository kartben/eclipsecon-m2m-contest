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
 *  - RX3: 
 *  - TX3: 
 *
 *  - digital 50 -> digital 12 (SPI MOSI)
 *  - digital 51 -> digital 11 (SPI MISO)
 *  - digital 52 -> digital 13 (SPI SCK)
 *
 *  - digital 2 -> Serial LCD RX
 *  - digital 3 -> Ardumoto PWM-A
 *  - digital 4 -> Ardumoto PWM-B
 *  - digital 5 -> Ardumoto DIR-A
 *  - digital 6 -> Ardumoto DIR-B
 *  - digital 8 -> Speaker
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

#include <XBee021.h>

/********************/
/** XBee variables **/
/********************/
uint32_t knownFios[] = { 
  0x40773379, 0x40773426 } 
;

String fioNames[] = { 
  "STATION1", "STATION2"  } 
;

XBee xbee = XBee();
XBeeResponse response = XBeeResponse();
// create reusable response objects for responses we expect to handle 
ZBRxResponse rx = ZBRxResponse();
ModemStatusResponse msr = ModemStatusResponse();

/********************/


/********************/
/** LCD variables  **/
/********************/
NewSoftSerial lcdSerial(21, 2);
long lastLCDRefresh = 0;
/********************/

#define NB_SENSORS 4

#define PHOTORESISTOR_SENSOR_PIN 0
#define HUMIDITY_SENSOR_PIN 1
#define TEMPERATURE_SENSOR_PIN 2
//#define MICROPHONE_SENSOR_PIN 3

#define MOTOR_A_PWM 3       // PWM control for motor outputs 1 and 2
#define MOTOR_B_PWM 4      // PWM control for motor outputs 3 and 4
#define MOTOR_A_DIR 5      // direction control for motor outputs 1 and 2
#define MOTOR_B_DIR 6     // direction control for motor outputs 3 and 4

String sensorNames[] = { 
  "ILLUMINANCE", "HUMIDITY", "TEMPERATURE", "NOISE" } 
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
char smsBuffer[250];
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
  10,41,51,129 };

byte gateway[] = { 
  10,41,51,254 };

byte mask[] = { 
  255,255,255,0 };


//  The address of the server you want to connect to (MongoDB REST API):
byte server[] = { 
  91,121,117,128}; 

// initialize the library instance:
Client client(server, 80);

long lastConnectionTime = 0;        // last time you connected to the server, in milliseconds
boolean lastConnected = false;      // state of the connection last time through the main loop
const int postingInterval = 5000; 
char jsonDocument[1024] = "";

// ***************************

void setup()
{
  // Serial is used for debug/info traces
  Serial.begin(9600);

  // Serial1 is used for RFID Tag reader

  // Serial2 is used for GPRS shield

  // Serial3 is used for Xbee modem
  Serial3.begin(9600);
  xbee.setSerial(&Serial3);

  // lcdSerial is used for LCD display
  lcdSerial.begin(9600);

  LCD_SetBacklight(0xFF);


  Serial.println("******************************") ;
  Serial.println("***  Welcome to the Cube!  ***") ;
  Serial.println("******************************") ;

  LCD_ClearScreen();
  lcdSerial.print(" ...  BOOT  ... ") ; 

  // Setup ta Ethernet stack
  lcdSerial.print("ETH.") ; 
  Ethernet.begin(mac, ip, gateway, mask);
  delay(1000) ;
  lcdSerial.print(" OK!") ; 

  // Setup GSM
  Serial.println() ;
  Serial.println("... Initializing GSM stack ...") ;
  Serial.println() ;
  lcdSerial.print("GSM.") ; 
  if (gsm.begin()) {
    Serial.println("\n... GSM ... READY!");
    lcdSerial.print(" OK!") ; 
  }
  else {
    Serial.println("\n... GSM ... IDLE!");
    lcdSerial.print(" KO!") ; 
  }

  // Setup RFID
  setupRfid() ;

  // Setup motors (fans)
  pinMode(MOTOR_A_PWM, OUTPUT);
  pinMode(MOTOR_B_PWM, OUTPUT);
  pinMode(MOTOR_A_DIR, OUTPUT);
  pinMode(MOTOR_B_DIR, OUTPUT);
  digitalWrite(MOTOR_A_DIR, HIGH);
  digitalWrite(MOTOR_B_DIR, HIGH);
  analogWrite(MOTOR_A_PWM, 0);
  analogWrite(MOTOR_B_PWM, 0);

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

  // Try to read an Xbee packet
  int xbeeIlluminance = 0 ;
  int  xbeeTemperature = 0 ;
  char xbeeStationName[16] = "";
  if (xbeeCheck(xbeeIlluminance, xbeeTemperature, xbeeStationName))
  {
    Serial.print(String(xbeeIlluminance) + " lux - ") ;
    Serial.println(String(xbeeTemperature) + " C") ;

    // store the received command in mongodb
    String json = "docs=[" ;
    json += "{\"sensor\":\"" + String(xbeeStationName) +  "_ILLUMINANCE\",\"value\":" + String(xbeeIlluminance) + "}" ;
    json += "," ;
    json += "{\"sensor\":\"" + String(xbeeStationName) +  "_TEMPERATURE\",\"value\":" + String(dtostrf(xbeeTemperature/100., 2, 2, s)) + "}" ;
    json += "]" ; 

    Serial.println(json) ;
    sendData(json, "http://m2mcontest.eclipsecon.org/REST/sensors/data/_insert" ); 
    //    Serial.println(xbeeStationName) ;
  }



  // Check if an RFID tag is present
  if ( read_serial(rfidSerial) > 0 ) {
    playMelodyRfidScan(SPEAKER_PIN) ;
    Serial.println(rfidSerial) ;
    delay(50) ;

    // store the scanned tag ID in mongodb
    String json = "docs=[" ;
    json += "{\"tag\":\"" + String(rfidSerial) +  "\"}" ;
    json += "]" ; 

    Serial.println(json) ;
    sendData(json, "http://m2mcontest.eclipsecon.org/REST/rfid/history/_insert" );

  }

  if(millis() - lastSmsCheckTime > smsCheckInterval) {
    Serial.print("Check SMS ... ") ;
    memset(smsBuffer, '\0', 250);
    // Check if we have received an SMS
    if(gsm.readSMS(smsBuffer, 250, phoneNumber, 20))
    {
      playMelodySmsReceived(SPEAKER_PIN);

      Serial.println("\n\n---------");
      Serial.print("Phone #: ");
      Serial.println(phoneNumber);
      Serial.print("Message: ");
      Serial.println(smsBuffer);
      Serial.println("---------\n\n");
      memset(smsMarqueeBuffer, '\0', 250);
      String s = "SMS from " + String(phoneNumber) + " --> " ;
      s += smsBuffer;
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
      int adjustedSpeed = map(abs(speed), 0, 100, 0, 255) ;
      Serial.println("Setting speed of motor #" + String(motor) + " to " + String(adjustedSpeed) + "(" + String(speed) +  "%)" ) ;
      analogWrite((motor == 1) ? MOTOR_A_PWM : MOTOR_B_PWM , adjustedSpeed);
      digitalWrite(MOTOR_A_DIR, (speed > 0) ? HIGH : LOW);

      // store the received command in mongodb
      String json = "docs=[" ;
      json += "{\"command\":\"FAN" + String(motor) + " " + String(speed) +  "\",\"type\":\"SMS\", \"from\":\"" + phoneNumber + "\"}" ;
      json += "]" ; 

      Serial.println(json) ;
      sendData(json, "http://m2mcontest.eclipsecon.org/REST/commands/history/_insert" );

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
    lcdSerial.print(LCD_secondLine) ;
    delay(150);
  } 


  float humidity = getHumidity(HUMIDITY_SENSOR_PIN) ; 
  lastSensorValues[HUMIDITY_SENSOR_PIN] = humidity ;
  float temperature = getTemperature(TEMPERATURE_SENSOR_PIN) ;
  lastSensorValues[TEMPERATURE_SENSOR_PIN] = temperature ;
  //  float soundLevel = getSoundLevel(MICROPHONE_SENSOR_PIN) ; 
  //  lastSensorValues[MICROPHONE_SENSOR_PIN] = soundLevel ;
  float illuminance = getIlluminance(PHOTORESISTOR_SENSOR_PIN) ;
  lastSensorValues[PHOTORESISTOR_SENSOR_PIN] = illuminance ;

  {

    String valueToDisplay ;

    // refresh display every 100ms, and change displayed sensor every 5sec
    switch(millis() / 5000 % 3) {
    case 0:  
      valueToDisplay = "Hum. " + String(dtostrf(humidity,2,2,s)) + "%" ; 
      break;
    case 1: 
      valueToDisplay = "Temp. " + String(dtostrf(temperature,2,2,s)) + (char)0xDF + "C" ;
      break; 
    case 2: 
      valueToDisplay = "Illum. " + String(dtostrf(illuminance,2,0,s)) + " lux" ; 
      break;
      //  case 3:  
      //    lcdSerial.print("Noise. " + String(dtostrf(soundLevel,2,2,s))) ;
      //    break;
    }

    if( millis() - lastLCDRefresh > 500) {
      lastLCDRefresh = millis() ;

      LCD_MoveCursor(0) ;
      lcdSerial.print("                ") ;
      LCD_MoveCursor(0) ;

      lcdSerial.print(valueToDisplay) ;
    }

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
    sendData(json, "http://m2mcontest.eclipsecon.org/REST/sensors/data/_insert" );
  }

  lastConnected = client.connected();


}


// this method makes a HTTP connection to the MongoDB REST interface:
void sendData(String thisData, String url) {
  if (!client.connect()) {
    Serial.print("Ethernet KO... retrying... ");
    client.flush() ;
    client.stop() ;  
    (client.connect()) ? Serial.println(" OK") : Serial.println(" still KO!")  ;
  }
  if(client.connected()) {
    client.println("POST " + url + " HTTP/1.1");
    client.println( "Host: m2mcontest.eclipsecon.org" );
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
}

boolean xbeeCheck(int &illuminance, int &temperature, char* stationName) {

  xbee.readPacket();

  if (xbee.getResponse().isAvailable()) {
    // got something
    Serial.println("Xbee resp");  

    if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
      // got a zb rx packet
      Serial.println("Packet!");  

      // now fill our zb rx class
      xbee.getResponse().getZBRxResponse(rx);

      int fio = isKnownFio(rx.getRemoteAddress64().getLsb()) ;
      if(fio != -1) {
        Serial.print("Received something from " + fioNames[fio] + ": ") ; 

        illuminance = rx.getData(0) * 255 + rx.getData(1) ;
        temperature = rx.getData(2) * 255 + rx.getData(3) ;
        fioNames[fio].toCharArray(stationName, fioNames[fio].length() + 1) ;

        return true;
      } 
      else {
        Serial.print("Received something from unknown station: ") ; 
        for(int i = 0 ; i < rx.getDataLength() ; i++) {
          Serial.print(rx.getData(i), HEX);  
          Serial.print("-");  
          //delay(100) ;
        }
        Serial.println() ;      
      }
    } 
    else {
      // not something we were expecting
      //      flashLed(errorLed, 1, 25);    
    }
  }
  return false ;
}


int isKnownFio(uint32_t addr) {
  for(int i = 0 ; i < ( sizeof(knownFios) / sizeof(knownFios[0]) ) ; i++) {
    if(knownFios[i] == addr)
      return i ;
  }
  return -1 ;
}



