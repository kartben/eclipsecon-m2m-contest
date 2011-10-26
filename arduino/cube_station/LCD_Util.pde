extern NewSoftSerial lcdSerial ;

void LCD_MoveCursor(int pos) {
  lcdSerial.print(0xFE, BYTE) ;
  lcdSerial.print(0x80, BYTE) ;
  lcdSerial.print(pos, BYTE) ;
}

void LCD_ClearScreen() {   
  lcdSerial.print(0xFE, BYTE) ;
  lcdSerial.print(0x01, BYTE) ;
}

void LCD_SetBacklight(byte level) {
  lcdSerial.print(0x80, BYTE) ;
  lcdSerial.print(level, BYTE) ;
}

