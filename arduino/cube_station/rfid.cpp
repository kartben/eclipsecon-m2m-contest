/*
  RFID Eval 13.56MHz Shield example sketch v10
 
 Aaron Weiss, aaron at sparkfun dot com
 OSHW license: http://freedomdefined.org/OSHW
 
 works with 13.56MHz MiFare 1k tags
 
 D7 -> RFID RX
 D8 -> RFID TX
 */

#include "rfid.h"
#include "WProgram.h"

#include <stdio.h>

#define BEEP_WHEN_TAG_DETECTED 1

//Prototypes
void check_for_notag(void);
void halt(void);
void parse(void);
void print_serial(void);
void read_serial(void);
void seek(void);
void set_flag(void);

//Global var
int flag = 0;
int Str1[11];

//INIT
void setupRfid()  
{
  Serial1.begin(19200);
  delay(10);
  halt();
}

void check_for_notag()
{
  seek();
  delay(10);
  parse();
  set_flag();

  if(flag = 1){
    seek();
    delay(10);
    parse();
  }
}

void halt()
{
  //Halt tag
  Serial1.print(255, BYTE);
  Serial1.print(0, BYTE);
  Serial1.print(1, BYTE);
  Serial1.print(147, BYTE);
  Serial1.print(148, BYTE);
}

void parse()
{
  while(Serial1.available()){
    if(Serial1.read() == 255){
      for(int i=1;i<11;i++){
        Str1[i]= Serial1.read();
      }
    }
  }
}


/**
 * Reads RFID tag. If a tag is found, its serial is put into 'serial' buffer, and the function returns 1
 */
int read_serial(char* serial)
{
  seek();
  delay(10);
  parse();
  set_flag();

  if(flag == 1) {
    sprintf(serial, "%X%X%X%X", Str1[8], Str1[7], Str1[6], Str1[5]) ;
    delay(100);
    //check_for_notag();
    return 1 ;
  } 
  else {
    return -1 ;
  }
}

void seek()
{
  //search for RFID tag
  Serial1.print(255, BYTE);
  Serial1.print(0, BYTE);
  Serial1.print(1, BYTE);
  Serial1.print(130, BYTE);
  Serial1.print(131, BYTE); 
  delay(10);
}

void set_flag()
{
  if(Str1[2] == 6){
    flag++;
  }
  if(Str1[2] == 2){
    flag = 0;
  }
}



