#include "WProgram.h"
#include "pitches.h"

int rfidMelody[] = {
  NOTE_G5, NOTE_C5};

int rfidMelodyDurations[] = {
  4, 4};

int smsMelody[] = {
  NOTE_C6, NOTE_C6};

int smsMelodyDurations[] = {
  6, 6};


int melody1[] = {
  NOTE_C6, NOTE_A5, NOTE_C6, NOTE_A5, NOTE_C6, NOTE_A5, NOTE_C6};
int melody1Durations[] = {
  12,12,12,12,12,12,4};

int happyBirthdayMelody[] = {
  NOTE_G6, NOTE_G6, NOTE_A6, NOTE_G6, NOTE_C7, NOTE_B6, 0,
  NOTE_G6, NOTE_G6, NOTE_A6, NOTE_G6, NOTE_D6, NOTE_C6, 0,
  NOTE_G6, NOTE_G6, NOTE_G7, NOTE_E6, NOTE_C6, NOTE_C6, NOTE_B6, NOTE_A6, 0,
  NOTE_F6, NOTE_F6, NOTE_E6, NOTE_C6, NOTE_D6, NOTE_C6};

int happyBirthdayMelodyDurations[] = {  
  2, 4, 2, 2, 2, 2, 2,
  2, 4, 2, 2, 2, 2, 2,
  2, 4, 2, 2, 2, 2, 2, 2, 2,
  2, 4, 2, 2, 2, 2};

int unknownMelody[] = {
  NOTE_C5, NOTE_C5,  NOTE_F5,  NOTE_F5, NOTE_G5, NOTE_G5, NOTE_A5, NOTE_G5, NOTE_F5, 0,
  NOTE_G5, NOTE_A5,  NOTE_F5,  NOTE_G5, NOTE_G5, NOTE_A5, NOTE_F5, NOTE_G5, 0,
  NOTE_C5, NOTE_F5,  NOTE_F5,  NOTE_G5, NOTE_G5, NOTE_A5, NOTE_G5, NOTE_F5, 0,
  NOTE_A5, NOTE_AS5, NOTE_C6,  NOTE_A5, NOTE_G5, NOTE_F5, NOTE_G5, NOTE_F5
};

int unknownMelodyDurations[] = {
  4, 4, 2, 2, 2, 2, 1, 4, 4,   4,
  2, 2, 2, 2, 2, 2, 2, 2, 4,
  2, 2, 2, 2, 2, 1, 4, 4, 4,
  4, 4, 2, 2, 4, 4, 2, 1

};


void playMelody(int pin, int notes[], int durations[], int nbNotes) {
  for (int thisNote = 0; thisNote < nbNotes; thisNote++) {
    int noteDuration = 1000 / durations[thisNote];
    tone(pin, notes[thisNote], noteDuration);
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    noTone(pin);
  }
}


void playMelodyRfidScan(int pin) {
  playMelody(pin, rfidMelody, rfidMelodyDurations, sizeof(rfidMelody) / sizeof(int));
}

void playMelodySmsReceived(int pin) {
  playMelody(pin, smsMelody, smsMelodyDurations, sizeof(smsMelody) / sizeof(int));
}





