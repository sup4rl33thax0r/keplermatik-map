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
SCRATCH1 EQU   $08
SCRATCH2 EQU   $09
BELL     EQU   $FF3A
PRCHR    EQU   $FDED
CROUT    EQU   $FD8E
PRBYTE   EQU   $FDDA
MLI      EQU   $BF00
OPENCMD  EQU   $C8
READCMD  EQU   $CA
CLOSECMD EQU   $CC
GFXBASE  EQU   $2000
FILEBASE EQU   $4000
BMPSTART EQU   $FA
BMPPTR   EQU   $FC
GFXPTR   EQU   $EB
BMPEOR   EQU   $ED
YTEMP    EQU   $EF
RAMPAGE  EQU   $06
GFXTICK  EQU   $07
BMPTICK  EQU   $08
GFXROWL  EQU   $27
BMPROWL  EQU   $44
*
****************************************
* 
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
         STA   SCRATCH1
         LDA   PARAMS+7
         STA   SCRATCH2
         RTS
CLOSE    LDA   #1
         STA   PARAMS
         JSR   MLI
         DFB   READCMD
         DW    PARAMS
         RTS

****************************************
* GRAPHICS ROUTINES                    *
* ------------------------------------ *
* These routines take the BMP data     *
* loaded at $4000 on the main page and *
* copy it to $2000 on the main and aux *
* pages in the very specific way       *
* required by DHGR.                    *
*                                      *
* In general, the first LDGFX sets up  *
* the required soft switches and       *
* initializes the pointers to both BMP *
* (BMPSTART) and video RAM (GFXPTR).   *
* It also initializes the end-of-row   *
* pointer (BMPEOR).                    *
*                                      *
* The code then begins performing what *
* we affectionately call "the pixel    *
* pokey" where we bang bits off the    *
* end of the bitmap byte pointed to by *
* BMPPTR into the carry flag, using    *
* this flag as temporary storage for   *
* the pixel before banging it into the *
* byte in video RAM that's pointed to  *
* by GFXPTR.  This also has the handy  *
* effect of reversing the order of the *
* bits which is required by the way    *
* that video RAM is structured.        *
*                                      *
* While the pixel pokey is going on,   *
* we keep track of two counters with   *
* the X and Y registers.  The X counts *
* down from 7 to 0 and tracks bits of  *
* the current BMP byte.  The Y counts  *
* down from 6 to 0 and tracks the 7    *
* bits of the video RAM byte.  When    *
* these counters each hit zero, which  *
* implies we finished a byte, other    *
* stuff happens.                       *
*
* When the BMP counter (X) hits zero,  *
* we check to see if we're at the end  *
* of the BMP row.  If not, we just     *
* increment the BMP pointer, reset X   *
* and get back to the pixel pokey.     *
* If we are at the end of the row,     *
* things get interesting.              *
*
* Essentially, there is non-intuitive  *
* but regular structure to the DHGR    *
* memory map.  First, rows are set up  *
* in 8 row blocks where the rows are   *
* $0400 away from one another.  In our *
* implementation, this puts row 0 at   *
* $2000, row 1 at $2400, and so on     *
* 
* These

***************************
*                   Write *
*                   ----- *
* 80STORE    off    $C000 *
*            on     $C001 *
* RAMRD      off    $C002 *
*            on     $C003 *   
* RAMWRT     off    $C004 *    
*            on     $C005 *
* PAGE2      off    $C054 *
*            on     $C055 *
* HIRES      off    $C056 *
*            on     $C057 *
***************************
* For AUX:                *
* 80STORE ON: $C001       *
* PAGE2   ON: $C055       *
* HIRES   ON: $C057       *
* RAMRD  OFF: $C002       *
* RAMWRT OFF: $C004       *
*                         *
* For MAIN:               *
* 80STORE ON: $C001       *
* PAGE2  OFF: $C054       *
* HIRES   ON: $C057       *
* RAMRD  OFF: $C002       *
* RAMWRT OFF: $C004       *
***************************
LDGFX    LDA   #<GFXBASE  ;INITIALIZE GFXPTR WITH FRAME BUFFER ADDRESS
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
         LDY   #$0A       ;GET BITMAP OFFSET FROM FILE POSITION $000A

         LDA   FILEBASE,Y ;CALCULATE START OF BMP AND STORE IN BMPSTART
         STA   SCRATCH1
         INY
         LDA   FILEBASE,Y
         STA   SCRATCH2
         CLC
         ;LDA   #<FILEBASE
         ;ADC   SCRATCH1
         LDA   #$3E
         STA   BMPSTART
         ;LDA   #>FILEBASE
         ;ADC   SCRATCH2
         LDA   #$40
         STA   BMPSTART+1
        
         ;CLC
        ; LDA   #$20             ; INITIALIZE BMPPTR
         ;LDA   #$00
         ;ADC   BMPSTART 
         LDA   #$F6        ; 16-BIT ADD $343A TO BMPSTART TO GET
         STA   BMPPTR           ; START OF LINE 1 AND STORE IN BMPPTR
         ;LDA   #$35             ; REMEMBER, FILE IS UPSIDE DOWN COMPARED
         ;LDA   #$00
         ;ADC   BMPSTART+1       ; TO FRAME BUFFER =)
         LDA   #$75
         STA   BMPPTR+1

         LDY   #GFXTICK           ; FRAMEBUFFER USES 7 BITS PER BYTE
         LDX   #BMPTICK           ; BMP FORMAT USES 8 BITS PER BYTE
         CLC
BEGINROW LDA   BMPPTR         ; CALCULATE EOR + 1
         ADC   #BMPROWL           ; HARDCODED FOR DOUBLE HIRES
         STA   BMPEOR         ; WE CHECK FOR THIS LATER TO SEE
         LDA   BMPPTR+1       ; IF WE'RE AT THE NEXT ROW AND NEED TO
         ADC   #$00           ; INCREMENT GFXPTR
         STA   BMPEOR+1
         LDA   #$00
         STA   GFXPTR

         

PIXPOKEY STY   YTEMP          ; TEMP STORE Y
         JSR   PRSTATUS   
         LDY   #$00           ; RSTGFXP MAY BE RESETTING ON FIRST BYTE?
         CLC
         LDA   (BMPPTR),Y
         ROR   A              ; PUT YOUR RIGHT FOOT IN
         STA   (BMPPTR),Y
         LDY   #$00
         LDA   (GFXPTR),Y
         ROL   A              ; TAKE YOUR LEFT FOOT OUT
         STA   (GFXPTR),Y
         LDY   YTEMP
         DEX                  ; DO THE PIXEL POKEY AND SHAKE
         BEQ   EORCHK         ; OUR CARRY BIT ALL ABOUT, THEN GO CHECK EOR IF X IS 0

PIXPOKE2 
         DEY                  ; NOT AT END OF ROW, SEE IF GFXPTR OFFSET
         BEQ   RSTGFXP        ; NEEDS TO BE RESET
         JMP   PIXPOKEY

RSTGFXP  LDA   RAMPAGE
         CMP   #$54
         BEQ   RSTGFXP2
         LDA   #$54
         STA   RAMPAGE
         JMP   RSTGFXP3

RSTGFXP2 LDA   #$55
         STA   RAMPAGE
         INC   GFXPTR       
         CLC
RSTGFXP3 LDY   #$00
         STA   (RAMPAGE),Y   ; CHANGED FROM RAMPAGE+1 AS I THINK WAS A BUG
         LDA   #$00          ;KLUGE
         STA   (GFXPTR),Y
         LDY   #GFXTICK
         JMP   PIXPOKEY


DECBMP   SEC
         LDA   BMPPTR
         SBC   #$8E
         STA   BMPPTR
         LDA   BMPPTR+1
         SBC   #$00
         STA   BMPPTR+1
         JSR   RSTEORP
         JMP   PIXPOKEY

INCBMPP  CLC                ;INCREMENT BMP POINTER
         LDA   BMPPTR
         ADC   #$01
         STA   BMPPTR
         LDA   BMPPTR+1
         ADC   #$00
         STA   BMPPTR+1
         LDX   #BMPTICK
         RTS

RSTBMPP  JSR   INCBMPP
         JMP   PIXPOKE2

RSTEORP  ;JSR   INCBMPP 
         CLC
         LDA   BMPPTR
         ADC   #BMPROWL
         STA   BMPEOR
         LDA   BMPPTR+1
         ADC   #$00
         STA   BMPEOR+1
         RTS

EORCHK   LDA   BMPPTR     ; WE ARE HITTING ROW ONE BYTE EARLY
         CMP   BMPEOR     ; CHANGE TO RUN OFF BMPPTR
         BNE   RSTBMPP    ; EARLY CHECK LSB FOR END OF ROW
         LDA   BMPPTR+1
         CMP   BMPEOR+1
         BNE   RSTBMPP    ; IF NOT AT END OF ROW, GO RESET BMPPTR

                            ; SO YOU SAY WE'RE AT THE END OF ROW
         LDA   GFXPTR+1     ; HIGH BYTE OF GFXPTR BEING $3F RESULTS IN ALL *
         CMP   #$3F       ; SORT OF CONDITIONS TO CHECK OUT
         BNE   CHKBOXP
         LDA   GFXPTR   ; CHECK LOW BYTE
         CMP   #$A7       ; FIRST GAP IN FRAMEBUFFER MAP
         BEQ   GP3FA7
         CMP   #$CF       ; SECOND GAP IN FRAMEBUFFER MAP
         BEQ   GP3FCF
         CMP   #$F7       ; END OF FILE
         BEQ   DISPGFX

CHKBOXP  LDA   GFXPTR
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
         LDA   $C053
         STA   $C00D
         LDA   #$00
         STA   $C05E
         LDA   $C055
         RTS

PRSTATUS STA   $C054
         LDA   #$D8      ;'X'
         JSR   PRCHR
         TXA             ; PRINT BMP BIT COUNTER
         JSR   PRBYTE
         LDA   #$A0      ;' '
         JSR   PRCHR
         LDA   #$D9      ;'Y'
         JSR   PRCHR
         TYA             ; PRINT GFX BIT COUNTER
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
         JSR   CROUT
         LDY   #$00
         STA   (RAMPAGE),Y
         RTS

PRMEMFI2 LDY   #$00
         STA   (RAMPAGE),Y   ; CHANGED FROM RAMPAGE+1 AS I THINK WAS A BUG
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
         DW    $8200
         DW    $AAAA
*
FILENAME DFB   ENDNAME-NAME
NAME     ASC   "/EXAMPLES/MAP.BMP"
ENDNAME  EQU   *
