*-----------------------------------------------------------
* Title      : 68000 Monitor Program
* Written by : Daniel Hitchings
* Date       : 5/2/13
*-----------------------------------------------------------
    ORG    $1000
STACK       EQU $3000

INPUT       EQU $2C60 

COM_BUFF    EQU $2C10

OUT_BUFF    EQU $2BC0

COM_TABL
        DC.B 'HELP ',0
        DC.B 'MDSP ',0
        DC.B 'MTST ',0
        DC.B 'SWAP ',0
        DC.B 'GO ',0
        DC.B 'SR ',0
        DC.B 'MCHG ',0
        DC.B 'REG ',0
        DC.B 'BFILL ',0
        DC.B 'BMOV ',0
END_TBL DC.B 'EXIT ',0

COM_ERR 
        DC.B 'WHAT',0
        
ARG_ERR_MSG
        DC.B 'ARGUMENTS WERE INCORRECT, CHECK HELP FOR FORMATTING',0
        
REG_MSG
        DC.B 'D0=D1=D2=D3=D4=D5=D6=D7=A0=A1=A2=A3=A4=A5=A6=A7='
        
PROMPT  DC.B 'MONITOR441> ',0
        
COM_ADDR
        DC.L HELP
        DC.L MDSP
        DC.L MTST
        DC.L SWAP
        DC.L GO
        DC.L SR
        DC.L MCHG
        DC.L REG
        DC.L BFILL
        DC.L BMOV
        DC.L EXIT
    ORG $1200
START
    MOVE.L #STACK, $0
    MOVE.L #BUS_ERR, $8     ;move exception handlers
    MOVE.L #ADDR_ERR, $C
    MOVE.L #ILL_INST, $10
    MOVE.L #DIV_ZERO, $14
    MOVE.L #PRIV_VIOL, $20
    MOVE.L #TRACE, $24
    MOVE.L #LINE_A, $28
    MOVE.L #LINE_F, $2C
MAIN
    LEA PROMPT, A1
    MOVE.B #14, D0
    TRAP #15
    LEA INPUT, A1
    MOVE.B #2, D0
    TRAP #15
    
PARSE_INPUT
    LEA INPUT, A1
    MOVE.B #$20, D2
CLR_SPC
    CMP.B (A1), D2
    ADD #$01, A1
    BEQ CLR_SPC
    
    MOVEQ #0, D1
    SUB #$01, A1
    
    LEA COM_BUFF, A2
INPUT_COPY
    MOVE.B (A1)+, (A2)+
    ADDI #1, D1
    CMPI #8, D1
    BGE ERR
    CMPI.B #$20, (A1)
    BEQ LOAD_COM
    CMPI.B #$00, (A1)
    BEQ LOAD_COM
    BRA INPUT_COPY    

LOAD_COM
    MOVE.B #$20, (A2)
    LEA COM_BUFF, A1
    LEA COM_TABL, A2
    LEA COM_ADDR, A3
    ;ADD #$01, A3
    
FIND_COM
    CMPM.B (A1)+, (A2)+
    BNE NEXT_COM
    CMPI.B #$20, (A1)
    BNE FIND_COM
    CMPI.B #$20, (A2)
    BNE ERR
    
    MOVE.L (A3), A5
    JMP (A5)
    
NEXT_COM
    LEA     COM_BUFF, A1
FIND_NEXT
    CMPI.B  #$00, (A2)+
    BNE     FIND_NEXT    
    ADD     #$04, A3
    CMPA    #END_TBL, A2
    BGT     ERR
    JMP     FIND_COM
    
    ORG $1300
ERR
    LEA     COM_ERR, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     MAIN

ARG_ERR
    LEA     ARG_ERR_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    JMP     MAIN

GET_ARG             ;TRIES TO GET ARGUMENT THAT A5 IS POINTING TO AND STORE IT IN D7
    CMPI.B  #$24, (A5)
    BNE     ARG_ERR
    MOVEQ   #$00, D7
    MOVEQ   #$00, D6
ADD_ARG
    ADD     #$01, A5
    ROL.L   #4, D7
    ADD.L   D6, D7
    MOVE.B  (A5)+, D6
    CMPI.B  #$39, D6
    BLE     NUM
    SUBQ.B  #$07, D6
NUM
    SUB.B   #$30, D6
    CMPI.B  #$00, -(A5)
    BEQ     GOT_ARG
    CMPI.B  #$20, (A5)
    BEQ     GOT_ARG
    CMPI.B  #$3B, (A5)
    BEQ     GOT_ARG
    BRA     ADD_ARG
GOT_ARG
    RTS
    
GET_VAL         ;GET THE VALUE THAT A5 IS POINTING TO AND PUT IT IN D7. D1 STORES THE LENGTH OF THE VALUE.
    MOVEQ   #$00, D7
    MOVEQ   #$00, D6
ADD_VAL
    MOVE.B  (A5)+, D6
    CMPI.B  #$39, D6
    BLE     NUM_VAL
    SUBQ.B  #$07, D6
NUM_VAL
    SUB.B   #$30, D6
    ROL.L   #4, D7
    ADD.L   D6, D7
    SUB.B   #$01, D1
    CMPI.B  #$00, D1
    BLE     GOT_VAL
    BRA     ADD_VAL
GOT_VAL
    RTS
    
DISP_ADDR       ;PRINT OUT THE VALUE OF A2 (USEFUL FOR MDSP AND MCHG)
    MOVE.B  #$24, D1
    MOVE    #6, D0
    TRAP    #15
    MOVE.L  A2, D0
    LEA     OUT_BUFF, A1
    MOVE.W  #8, D2
DSP_ADR_LP
    ROL.L   #4, D0
    MOVE.L  D0, D3
    AND.L   #$0F, D3
    CMPI.B  #$09, D3
    BLE     LESS_ADDR
    ADD     #$07, D3
LESS_ADDR
    ADD     #$30, D3
    MOVE.B  D3, (A1)+
    SUBQ.W  #1, D2
    BNE     DSP_ADR_LP
    
    MOVE.B  #$00, (A1)+
    LEA     OUT_BUFF, A1
    MOVE.B  #14, D0
    TRAP #15
    MOVE.B	#$3A, D1
    MOVE.B	#6, D0
    TRAP	#15
    RTS
     
HELP
    LEA HELP_DISP, A1
    MOVE.B #13, D0
    TRAP #15
    JMP MAIN

MDSP
    LEA     OUT_BUFF, A2
    LEA     INPUT, A5
    ADD     #$05, A5
    JSR     GET_ARG
    MOVE.L  D7, A2
    ADD     #$01, A5
    JSR     GET_ARG
    MOVE.L  D7, A3
    MOVEQ   #$00, D1
    LEA     INPUT, A1
NEW_LINE
    MOVE.B  #$00, (A1)
    MOVE.B  #13, D0
    TRAP    #15
    JSR     DISP_ADDR
    MOVE.W  #08, D6
DISP_MEM
    MOVE.B  #16, D2
    CMPA    A2, A3
    BEQ     DONE_DISP
    MOVE.B  (A2)+, D1
    MOVE.B  #15, D0
    TRAP    #15
    MOVE.B  #$20, D1
    MOVE.B  #6, D0
    TRAP    #15
    SUB     #01, D6
    BEQ     NEW_LINE
    BRA     DISP_MEM

DONE_DISP
    MOVE.B  #$00, D1
    MOVE.B  #0, D0
    TRAP    #15
    JMP     MAIN

MTST
    LEA     OUT_BUFF, A2
    LEA     INPUT, A5
    ADD     #$05, A5
    JSR     GET_ARG
    MOVE.L  D7, A2
    ADD     #$01, A5
    JSR     GET_ARG
    MOVE.L  D7, A3
    MOVE.L  A2, A5      ;STORE COPY OF START LOCATION
WRITE_TEST
    CMPA    A2, A3
    BLT     DONE_WRITE
    MOVE.W  #$A5A5, (A2)+
    BRA     WRITE_TEST
DONE_WRITE
    MOVE.L  A5, A2
READ_TEST
    CMP.W   #$A5A5, (A2)
    BNE     MEM_ERR
    MOVE.W  #$5A5A, (A2)+
    CMPA    A2, A3
    BGT     READ_TEST
    
    MOVE.L  A5, A2
FINAL_TEST
    CMP.W   #$5A5A, (A2)
    BNE     MEM_ERR
    MOVE.W  #$0000, (A2)+
    CMPA    A2, A3
    BGT     FINAL_TEST
    
    JMP     MAIN

MEM_ERR                 ;TODO: OUTPUT LOCATION OF ERROR (A2)
    LEA     MEM_ERR_MSG, A1
    MOVE.B  #13, D0
    TRAP    #15
    JMP     MAIN

GO
    LEA     INPUT, A5
    ADD     #$03, A5
    JSR     GET_ARG
    LEA     OUT_BUFF, A1
    MOVE.L  D7, A1
    JMP     (A1)
    
MCHG
    LEA     INPUT, A5
    ADD     #$05, A5
    JSR     GET_ARG
    MOVE.L  D7, A2
CHG_LOOP
	LEA     OUT_BUFF, A1
	JSR		DISP_ADDR
    MOVE.B  #2, D0
    TRAP    #15
    LEA		OUT_BUFF, A1
    CMPI.B	#$2E, (A1)
    BEQ		DONE_CHG
    CMPI.W	#4, D1
	BNE		ARG_ERR
	LEA		OUT_BUFF, A5
    JSR		GET_VAL
	MOVE.W	D7, (A2)+
	BRA		CHG_LOOP

DONE_CHG		
    JMP     MAIN

REG
    LEA     STACK, A7
    MOVEM.L D0-D7/A0-A7, -(A7)
    MOVEQ   #00, D5
NXT_REG
    LEA     REG_MSG, A1
    ADD     D5, A1
    ADD     #$03, D5
    MOVE.W  #03, D1
    MOVE.B  #01, D0
    TRAP    #15
    LEA     OUT_BUFF, A1
    MOVE.W  #8, D2
    MOVE.L  (A7)+, D0
NXT_DIG
    ROL.L   #4, D0
    MOVE.L  D0, D3
    AND.L   #$0F, D3
    CMPI.B  #$09, D3
    BLE     LESS
    ADD     #$07, D3
LESS
    ADD     #$30, D3
    MOVE.B  D3, (A1)+
    SUBQ.W  #1, D2
    BNE     NXT_DIG
    
    MOVE.B  #$00, (A1)+
    LEA     OUT_BUFF, A1
    MOVE.B  #13, D0
    TRAP #15
    
    CMPA    #STACK, A7
    BLT     NXT_REG   
    
SR
	LEA		STACK, A7
	MOVE	SR, -(A7)
	LEA		SR_MSG, A1
	MOVE.B	#14, D0
	TRAP	#15
	LEA		OUT_BUFF, A1
	MOVE.W	#4, D2
	MOVE.L	(A7)+, D0
NXT_SR
    ROL.L   #4, D0
    MOVE.L  D0, D3
    AND.L   #$0F, D3
    CMPI.B  #$09, D3
    BLE     LESS_SR
    ADD     #$07, D3
LESS_SR
    ADD     #$30, D3
    MOVE.B  D3, (A1)+
    SUBQ.W  #1, D2
    BNE     NXT_SR
    
    MOVE.B  #$00, (A1)+
    LEA     OUT_BUFF, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     MAIN

SR_MSG
	DC.B	'SR=',0

BFILL
    LEA     INPUT, A5
    ADD     #$06, A5
    JSR     GET_ARG
    MOVE.L  D7, A2
    ADD     #$01, A5
    JSR     GET_ARG
    MOVE.L  D7, A3
    MOVEQ	#00, D1
    MOVE.L	A5, A6
    ADD		#01, A6
GET_LENGTH
	ADD		#01, D1
	CMPI.B	#$00, (A6)+
	BNE		GET_LENGTH
	CMPI.B	#05, D1
	BNE		ARG_ERR        
    JSR     GET_VAL    ;D7 NOW STORES THE WORD WE WANT TO FILL
FILL_MEM
    CMPA    A3, A2
    BGE     DONE_FILL
    MOVE.W  D7, (A2)+
    BRA     FILL_MEM

DONE_FILL
    MOVE.B  #$00, D1
    MOVE.B  #0, D0
    TRAP    #15
    JMP     MAIN

BMOV
    LEA     INPUT, A5
    ADD     #05, A5
    JSR     GET_ARG
    MOVE.L  D7, A2
    ADD     #01, A5
    JSR     GET_ARG
    MOVE.L  D7, A3
    ADD     #01, A5
    JSR     GET_ARG
    MOVE.L  D7, A4
MOVE_MEM
    CMPA    A3, A2
    BGE     DONE_MOVE
    MOVE.W  (A2)+, (A4)+
    BRA     MOVE_MEM
    
DONE_MOVE
    MOVE.B  #$00, D1
    MOVE.B  #0, D0
    TRAP    #15
    JMP     MAIN
    
SWAP
    LEA     INPUT, A5
    ADD     #05, A5
    JSR     GET_ARG
    MOVE.L  D7, A2
    ADD     #01, A5
    JSR     GET_ARG
    MOVE.L  D7, A3
    ADD     #01, A5
    CMPI.B  #$42, (A5)
    BEQ     SWAPB
    CMPI.B  #$57, (A5)
    BEQ     SWAPW
    CMPI.B  #$4C, (A5)
    BEQ     SWAPL
    JMP     ARG_ERR
    
SWAPB
    MOVE.B  (A2), D1
    MOVE.B  (A3), (A2)
    MOVE.B  D1, (A3)
    JMP     MAIN
SWAPW
    MOVE.W  (A2), D1
    MOVE.W  (A3), (A2)
    MOVE.W  D1, (A3)
    JMP     MAIN
SWAPL
    MOVE.L  (A2), D1
    MOVE.L  (A3), (A2)
    MOVE.L  D1, (A3)
    JMP     MAIN

EXIT
    MOVE.B #9, D0
    TRAP #15             ; halt simulator

BUS_ERR
    LEA     BUS_ERR_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

ADDR_ERR
    LEA     ADDR_ERR_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

ILL_INST
    LEA     ILL_INST_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

DIV_ZERO
    LEA     DIV0_ERR_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

PRIV_VIOL
    LEA     PRIV_VIOL_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

TRACE
    LEA     TRACE_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

LINE_A
    LEA     LINE_A_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG

LINE_F
    LEA     LINE_F_MSG, A1
    MOVE.B  #13, D0
    TRAP #15
    
    JMP     REG


BUS_ERR_MSG
    DC.B    'A BUS ERROR HAS OCCURRED',$0A,$0D,0
ADDR_ERR_MSG
    DC.B    'AN ADDRESS ERROR HAS OCCURRED',$0A,$0D,0    
ILL_INST_MSG
    DC.B    'THAT IS NOT A VALID INSTRUCTION',$0A,$0D,0
DIV0_ERR_MSG
    DC.B    'YOU CANNOT DIVIDE BY ZERO',$0A,$0D,0
PRIV_VIOL_MSG
    DC.B    'PRIVILEGE VIOLATION',0
TRACE_MSG
    DC.B    'TRACE EXCEPTION',0
LINE_A_MSG
    DC.B    'LINE A EXCEPTION',0
LINE_F_MSG
    DC.B    'LINE F EXCEPTION',0
    
MEM_ERR_MSG
    DC.B    'THERE WAS AN ERROR IN MEMORY AT: ',0
    
HELP_DISP
    DC.B    'HELP: DISPLAYS THIS HELP MESSAGE.',$0A,$0D,$0A,$0D
    DC.B    'MDSP: OUTPUTS ADDRESS AND MEMORY CONTENTS.',$0A,$0D
    DC.B    'MDSP <ADDR1> <ADDR2> eg: MDSP $101A $1020',$0A,$0D,$0A,$0D
    DC.B    'MTST: TESTS A BLOCK OF MEMORY FOR READ/WRITE ERRORS',$0A,$0D
    DC.B    'MTST <ADDR1> <ADDR2> eg: MTST $900 $940',$0A,$0D,$0A,$0D
    DC.B    'MCHG: MODIFIES WORD OF DATA IN MEMORY.',$0A,$0D
    DC.B    'MCHG <ADDR> eg: MCHG $900',$0A,$0D
    DC.B    '$900: FFFF<cr>',$0A,$0D,$0A,$0D
    DC.B	'SR: DISPLAYS THE CONTENTS OF THE STATUS REGISTER.',$0A,$0D,$0A,$0D
    DC.B    'SWAP: SWAPS VALUES IN MEMORY. SPECIFY BYTE, WORD, OR LONG WORD.',$0A,$0D
    DC.B    'SWAP <ADDR1> <ADDR2>;B/W/L eg: SWAP $900 $910;W',$0A,$0D,$0A,$0D
    DC.B    'REG: DISPLAYS THE CURRENT REGISTER CONTENTS.',$0A,$0D,$0A,$0D
    DC.B    'BFILL: FILLS A BLOCK OF MEMORY WITH THE GIVEN WORD.',$0A,$0D
    DC.B    'BFILL <ADDR1> <ADDR2> <WORD> eg: BFILL $900 $9D0 FFFF',$0A,$0D,$0A,$0D
    DC.B    'BMOV: MOVES A BLOCK OF MEMORY TO ANOTHER LOCATION.',$0A,$0D
    DC.B    'BMOV <ADDR1> <ADDR2> <ADDR3> eg: BMOV $900 $9D0 $910',$0A,$0D,$0A,$0D
    DC.B    'GO: BEGINS PROGRAM EXECUTION AT THE SPECIFIED ADDRESS.',$0A,$0D
    DC.B    'GO <ADDR> eg: GO $1000',$0A,$0D,$0A,$0D
    DC.B    'EXIT: EXITS THE MONITOR PROGRAM.',$0A,$0D,$0A,$0D
    DC.B	'ALL ADDRESS ARGUMENTS MUST BE PREFACED WITH $',0

	ORG $4500
TEST_PROG
	LEA		TEST_MSG, A1
	MOVE.B	#13, D0
	TRAP	#15
	
	JMP		MAIN

TEST_MSG
	DC.B	'HELLO WORLD!',0

	ORG		$8000
	
PRIV
	ANDI.W	#$DFFF,SR
	ORI.W	#$2000,SR
	JMP		MAIN

DIV
	CLR.L	D0
	CLR.L	D1
	DIVU	D0,D1
	JMP		MAIN

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
