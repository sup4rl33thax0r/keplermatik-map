PRSTATUS STA   $C054
         LDA   #$D8      ;'X'
         JSR   PRCHR
         LDA   BMPBIT          ; PRINT BMP BIT COUNTER
         JSR   PRBYTE
         LDA   #$A0      ;' '
         JSR   PRCHR
         LDA   #$D9      ;'Y'
         JSR   PRCHR
         LDA   GFXBIT             ; PRINT GFX BIT COUNTER
         JSR   PRBYTE
         LDA   #$A0      ;' '
         JSR   PRCHR
         LDA   #$C2      ;'B' 
         JSR   PRCHR
         LDA   BMPPTR+1  ;PRINT BMP POINTER ADDRESS
         JSR   PRBYTE
         LDA   BMPPTR
         JSR   PRBYTE
         LDA   #$A0      ;' '
         JSR   PRCHR
         LDA   #$C7      ;'G'
         JSR   PRCHR
         LDA   GFXPTR+1  ;PRINT GFX POINTER ADDRESS
         JSR   PRBYTE
         LDA   GFXPTR
         JSR   PRBYTE
         LDA   #$A0      ;' '
         JSR   PRCHR
         LDA   #$C3      ;'C'
         JSR   PRCHR
         TYA   
         JSR   PRBYTE
         LDA   #$A0      ;' '
         JSR   PRCHR
         ;LDA   RAMPAGE
         TXA
         JSR   PRBYTE
         JSR   CROUT
         STY   YTEMP
         LDY   #$00
         STA   (RAMPAGE),Y
         LDY   YTEMP
         RTS


         

PRBMP    STA   YTEMP          ; TEMP STORE Y 
         ;PHA
         LDY   #$00           ; RSTGFXP MAY BE RESETTING ON FIRST BYTE?
         LDA   (BMPPTR),Y
         JSR   PRBYTE
         ;PLA
         LDA   YTEMP
         RTS
         


PRMEMFI2 LDY   #$00
         STA   (RAMPAGE),Y   ; CHANGED FROM RAMPAGE+1 AS I THINK WAS A BUG
         RTS