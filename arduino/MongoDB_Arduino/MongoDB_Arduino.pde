#include <SPI.h>
#include <Ethernet.h>

#define USE_GSM 0

#if USE_GSM
#include "QuectelM10.h"
#include <NewSoftSerial.h>
#endif

// assign a MAC address for the ethernet controller.
// fill in your address here:
byte mac[] = { 
  0x90, 0xA2, 0xDA, 0x00, 0x44, 0x86};
// assign an IP address for the controller:
byte ip[] = { 
  192,168,1,20 };

//  The address of the server you want to connect to (MongoDB REST API):
byte server[] = { 
  192,168,1,1 }; 

const int NB_MONITORED_SENSORS = 2 ;
int monitoredSensors[] = { 
  A0, A2 } 
;
String sensorNames[] = { 
  "TEMP1", "OTHER_SENSOR" };


const char* DOCS = "docs=[" ;
const char* OFF = "OFF" ;
const char* ON = "ON" ;

// initialize the library instance:
Client client(server, 27080);

long lastConnectionTime = 0;        // last time you connected to the server, in milliseconds
boolean lastConnected = false;      // state of the connection last time through the main loop
const int postingInterval = 5000; 

void setup() {
  // start the ethernet connection and serial port:
  Ethernet.begin(mac, ip);
  Serial.begin(9600);

  Serial.println("\n*");

  // give the ethernet module time to boot up:
  delay(1000);

  #if USE_GSM
  if (!gsm.begin())
    Serial.println("\nGSM KO");
  #endif

  pinMode(5, OUTPUT);   
}

void loop() {
  // if there's incoming data from the net connection.
  // send it out the serial port.  This is for debugging
  // purposes only:
  if (client.available()) {
    char c = client.read();
    Serial.print(c);
  }

  if (!client.connected() && lastConnected) {
    Serial.println();
    Serial.println("disc.");
    client.stop();
  }

  // if you're not connected, and at least "postingInterval" seconds have passed 
  // since your last connection, then connect again and send data:
  if(!client.connected() && (millis() - lastConnectionTime > postingInterval)) {

//    Serial.print("mem=");
//    Serial.println(freeMemory());

    String dataString ;
    dataString += DOCS ;  
    for (int i = 0 ; i < NB_MONITORED_SENSORS ; i++) {
      // read the analog sensor:
      int sensorReading = analogRead(monitoredSensors[i]);   
      dataString += "{\"s\":\"" ;
      dataString += sensorNames[i] ;
      dataString += "\",\"v\":" ;
      dataString += sensorReading ;
      dataString += "}" ; 
      if (i < NB_MONITORED_SENSORS - 1) {
        dataString += "," ;
        delay(20) ;
      }
    }

    dataString += "]" ;

    sendData(dataString, "/sensors/data/_insert" );

    #if USE_GSM
    checkSMS();
    #endif

    delay(1000);
  }

  lastConnected = client.connected();
}

// this method makes a HTTP connection to the MongoDB REST interface:
void sendData(String thisData, String url) {
  // if there's a successful connection:
  if (client.connect()) {
    Serial.println("OK");
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
    // if you couldn't make a connection:
    Serial.println("KO");
  }
}

#if USE_GSM
void checkSMS() {
  char smsbuffer[160];
  char n[20];
  if(gsm.readSMS(smsbuffer, 160, n, 20))
  {
    String stringBuffer = String(smsbuffer);

    String docs ;
    docs += "docs=[{\"t\":\"SMS\",\"f\":\"" ;
    docs += n ;
    docs += "\",\"c\":\"" ;

    if (stringBuffer.indexOf(OFF) > -1) {
      digitalWrite(5, LOW);
      docs += OFF ;
    }
    if (stringBuffer.indexOf(ON) > -1) 
    {  
      digitalWrite(5, HIGH);
      docs += ON ;
    }
    docs += "\"}]" ;
    Serial.println(docs) ;

    client.stop(); 
    delay(100);
    sendData(docs, "/cmds/histo/_insert");
  }
}
#endif


extern unsigned int __bss_end;
extern unsigned int __heap_start;
extern void *__brkval;

int freeMemory() {
  int free_memory;

  if((int)__brkval == 0)
    free_memory = ((int)&free_memory) - ((int)&__bss_end);
  else
    free_memory = ((int)&free_memory) - ((int)__brkval);

  return free_memory;
}







