********************************
* KEPLERMATIK 0.1              *
* ===============              *
* LOADS MAP.BMP FROM DISK TO   *
* $4000, THEN DE-INTERLEAVES   *
* ALTERNATE BYTES TO $2000 IN  *
* MAIN MEMORY AND AUX MEMORY   *
********************************
* TODO:  FIX AUX/MAIN RAM FLAGS*
********************************

         ORG   $8000
********************************
* VARIABLES                    *
********************************
BMPBUFF EQU    $08
GFXBUFF EQU    $09
BELL     EQU   $FF3A
MLI      EQU   $BF00
OPENCMD  EQU   $C8
READCMD  EQU   $CA
CLOSECMD EQU   $CC
GFXBASE  EQU   $2000
FILEBASE EQU   $4000
BMPSTART EQU   $FA
BMPPTR   EQU   $FC
GFXPTR   EQU   $EB
COLNUM   EQU   $ED
YTEMP    EQU   $EF
RAMPAGE  EQU   $06
BMPBIT   EQU   $FE
GFXBIT   EQU   $CE
CONST1   EQU   $D7

CROUT    EQU   $FD8E
PRBYTE   EQU   $FDDA
PRCHR    EQU   $FDED

VAR2     EQU   $CF

GFXTICK  EQU   $07
BMPTICK  EQU   $08

MAIN     JSR   REMOVE
         JSR   OPEN

         JSR   READ
         JSR   CLOSE
         JSR   LDGFX
         RTS

OPEN     JSR   MLI
         DFB   OPENCMD
         DW    PARAMS
         RTS

READ     LDA   PARAMS+5
         STA   PARAMS+1
         LDA   #4
         STA   PARAMS
         LDA   #<FILEBASE
         STA   PARAMS+2
         LDA   #>FILEBASE
         STA   PARAMS+3
         LDA   #00
         STA   PARAMS+4
         LDA   #$40
         STA   PARAMS+5
         LDA   #$AA
         STA   PARAMS+6
         LDA   #$AA
         STA   PARAMS+7
         JSR   MLI
         DFB   READCMD
         DW    PARAMS
         LDA   PARAMS+6
         STA   BMPBUFF
         LDA   PARAMS+7
         STA   GFXBUFF
         RTS
CLOSE    LDA   #1
         STA   PARAMS
         JSR   MLI
         DFB   READCMD
         DW    PARAMS
         RTS

LDGFX    JSR   DISPGFX
         LDA   #$01
         STA   CONST1
         LDA   #<GFXBASE  ;INITIALIZE GFXPTR WITH FRAME BUFFER ADDRESS
         STA   GFXPTR
         LDA   #>GFXBASE
         STA   GFXPTR+1
         LDA   #$C0
         STA   RAMPAGE+1
         LDA   #$55
         STA   RAMPAGE
         STA   $C001      ;80STORE ON
         STA   $C002      ;RAMRD OFF
         STA   $C004      ;RAMWRT OFF
         STA   $C055      ;PAGE2 ON
         STA   $C057      ;HIRES ON
         LDX   #$00       ;SET UP INCREMENTS TO 0
         LDA   #$00
        
         STA   BMPBIT

         LDY   #$0A       ;GET BITMAP OFFSET FROM FILE POSITION $000A

         LDA   FILEBASE,Y ;CALCULATE START OF BMP AND STORE IN BMPSTART
         STA   BMPBUFF
         INY
         LDA   FILEBASE,Y
         STA   GFXBUFF
         CLC
         ;LDA   #<FILEBASE
         ;ADC   BMPBUFF
         LDA   #$3E
         STA   BMPSTART
         ;LDA   #>FILEBASE
         ;ADC   GFXBUFF
         LDA   #$40
         STA   BMPSTART+1
        
         ;CLC
        ; LDA   #$20             ; INITIALIZE BMPPTR
         ;LDA   #$00
         ;ADC   BMPSTART 
         LDA   #$F6              ; 16-BIT ADD $343A TO BMPSTART TO GET
         STA   BMPPTR            ; START OF LINE 1 AND STORE IN BMPPTR
         ;LDA   #$35             ; REMEMBER, FILE IS UPSIDE DOWN COMPARED
         ;LDA   #$00
         ;ADC   BMPSTART+1       ; TO FRAME BUFFER =)
         LDA   #$75
         STA   BMPPTR+1

         LDY   #$00              ; INVERT BITS OF THE FIRST BYTE
         LDA   (BMPPTR),Y
         EOR   #$FF
         STA   BMPBUFF

         LDA   #$07
         STA   GFXBIT
 
         LDA   #$08
         STA   BMPBIT
              
PIXPOKEY ROL   BMPBUFF        ; PUT YOUR RIGHT FOOT IN
         ROR   GFXBUFF        ; TAKE YOUR LEFT FOOT OUT    
         DEC   BMPBIT         ; DO THE PIXEL POKEY AND SHAKE OUR CARRY BIT ALL ABOUT
         BEQ   EORCHK         ; THEN GO CHECK EOR IF WE REACH END OF BMP BYTE

PIXPOKE2 DEC   GFXBIT
         BEQ   INCGFXP        ; IF WE HAVE REACHED END OF GFX BYTE GO INCREMENT POINTER
         JMP   PIXPOKEY       ; ELSE LOAD ANOTHER BIT

INCGFXP  ROR   GFXBUFF        ; RIGHT JUSTIFY BITS
         LDA   GFXBUFF

         STY   YTEMP
         LDY   #$00   
         STA   (GFXPTR),Y
         LDY   YTEMP

         TXA
         BIT   CONST1
         BEQ   INCGFXP2
         INX
         STA   $C055
         INC   GFXPTR
         JMP   INCGFXP3

INCGFXP2 INX
         STA   $C054

INCGFXP3 LDA   #$07
         STA   GFXBIT
         JMP   PIXPOKEY

DECBMP   SEC
         LDA   BMPPTR
         SBC   #$48
         STA   BMPPTR
         LDA   BMPPTR+1
         SBC   #$00
         STA   BMPPTR+1
         
         LDY   #$00
         LDA   (BMPPTR),Y
         EOR   #$FF
         STA   BMPBUFF
   
         LDA   #$08
         STA   BMPBIT
         LDX   #$00
        
         STA    $C055

         LDA   #$07
         STA   GFXBIT
         JMP   PIXPOKEY

INCBMPP  INY
         LDA   #$08
         STA   BMPBIT

         LDA   (BMPPTR),Y
         EOR   #$FF
         STA   BMPBUFF
         JMP   PIXPOKE2

EORCHK   CPY   #$45       ; IF WE HAVEN'T JUST FINISHED THE ROW
         BNE   INCBMPP    ; MOVE ALONG 
         STY   YTEMP
         LDY   #$00       ; RIGHT JUSTIFY BITS
         ROR   GFXBUFF
         LDA   GFXBUFF            
         STA   (GFXPTR),Y
         LDY   YTEMP       

         LDA   GFXPTR+1   ; HIGH BYTE OF GFXPTR BEING $3F RESULTS IN ALL
         CMP   #$3F       ; SORT OF CONDITIONS TO CHECK OUT

         BNE   CHKBOXP    ; IF NOT A GAP ROW, HANDLE AS NORMAL ROW

         LDA   GFXPTR     ; CHECK LOW BYTE TO FIND WHICH GAP ROW
         CMP   #$A7       ; FIRST GAP IN FRAMEBUFFER MAP
         BEQ   GP3FA7
         CMP   #$CF       ; SECOND GAP IN FRAMEBUFFER MAP
         BEQ   GP3FCF
         CMP   #$F7       ; END OF FILE
         BEQ   DISPGFX

CHKBOXP  LDA   GFXPTR     ; LOOK TO SEE IF WE ARE AT THE LAST ROW OF 8
         AND   #$3F       ; APPLY MASK FOR B00111111
         CMP   #$27       ; MASKED VALUE = B00100111?
         BEQ   CHKBOXP2
         LDA   GFXPTR
         AND   #$7F
         CMP   #$4F
         BEQ   CHKBOXP2
         LDA   GFXPTR
         AND   #$7F
         CMP   #$77
         BNE   INCBOXP    ; IF NOT, GO TO THE NEXT OFFSET IN THE BOX
         
CHKBOXP2 LDA   GFXPTR+1
         AND   #$3C       ; APPLY MASK FOR B00111100
         CMP   #$3C       ; MASKED VALUE = B00111100?
         BEQ   RESBOXP    ; IF SO, RESET BOX OFFSET BACK TO 0

INCBOXP  CLC              ; INCREMENT GFXPTR BY THE BOX LINE OFFSET
         LDA   GFXPTR     ; BOX LINE OFFSETS ARE $0400 APART BUT ONLY
         ADC   #$D9       ; $03D9 FROM THE END OF ONE LINE TO THE
         STA   GFXPTR     ; BEGINNING OF THE NEXT
         LDA   GFXPTR+1
         ADC   #$03
         STA   GFXPTR+1
         JMP   DECBMP

RESBOXP  SEC              ; RESET BOX LINE OFFSET BY JUMPING TO THE
         LDA   GFXPTR     ; NEXT FRAMEBUFFER OFFSET WHERE BOX LINE
         SBC   #$A7       ; OFFSET IS ZERO
         STA   GFXPTR
         LDA   GFXPTR+1
         SBC   #$1B
         STA   GFXPTR+1
         JMP   DECBMP

GP3FA7   LDA   #$28       ; JUMP GFXPTR FROM $3FA7 TO $2028
         STA   GFXPTR
         LDA   #$20
         STA   GFXPTR+1
         JMP   DECBMP

GP3FCF   LDA   #$50       ; JUMP GFXPTR FROM $3FCF TO $2050
         STA   GFXPTR
         LDA   #$20
         STA   GFXPTR+1
         JMP   DECBMP


DISPGFX  LDA   $C057
         LDA   $C050
         LDA   $C05E
         LDA   $C052
         STA   $C00D
         LDA   #$00
         STA   $C05E
         LDA   $C055
         RTS




*
********************************
* DISABLE /RAM VOLUME TO FREE  *
* AUX MEMORY FOR USE           *
********************************

REMOVE   LDA   $BF98
         AND   #$30
         CMP   #$30
         BNE   NORAM
         LDA   $BF26
         CMP   $BF16
         BNE   GOTRAM
         LDA   $BF27
         CMP   $BF17
         BNE   GOTRAM
NORAM    SEC
OKXIT    RTS
GOTRAM   LDA   $BF26
         STA   OLDVEC
         LDA   $BF27
         STA   OLDVEC+1
         LDA   $BF16
         STA   $BF26
         LDA   $BF17
         STA   $BF27
         LDX   $BF31
DEVLP    LDA   $BF32,X
         AND   #$70
         CMP   #$30
         BEQ   GOTSLT
         DEX
         BPL   DEVLP
         BMI   NORAM
GOTSLT   LDA   $BF32+1,X
         STA   $BF32,X
         INX
         CPX   $BF31
         BCS   FINSLT
         JMP   GOTSLT
FINSLT   DEC   $BF31
         LDA   #$00
         STA   $BF32,X
         CLC
         BCC   OKXIT
OLDVEC   DW    0


********************************
* PARAMS TABLE                 *
********************************

PARAMS   DFB   3                        
         DW    FILENAME
         DW    $8B00
         DW    $AAAA
*
FILENAME DFB   ENDNAME-NAME
NAME     ASC   "/EXAMPLES/MAP.BMP"
ENDNAME  EQU   *
