void LCD_MoveCursor(int pos) {
  Serial3.print(0xFE, BYTE) ;
  Serial3.print(0x80, BYTE) ;
  Serial3.print(pos, BYTE) ;
}

void LCD_ClearScreen() {   
  Serial3.print(0xFE, BYTE) ;
  Serial3.print(0x01, BYTE) ;
}


