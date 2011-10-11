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


void playMelody(int pin, int notes[], int durations[]) {
  for (int thisNote = 0; thisNote < 2; thisNote++) {
    int noteDuration = 1000 / durations[thisNote];
    tone(pin, notes[thisNote], noteDuration);
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    noTone(pin);
  }
}


void playMelodyRfidScan(int pin) {
  playMelody(pin, rfidMelody, rfidMelodyDurations);
}

void playMelodySmsReceived(int pin) {
  playMelody(pin, smsMelody, smsMelodyDurations);
}


