CSP_BREAK MACRO : break : ENDM
; CSP_BREAK MACRO : IFDEF TESTING : break : ENDIF : ENDM

PrintMsg MACRO Address
		ld 	hl, Address
		call 	PrintRst16
	ENDM


ErrorIfNoCarry MACRO ErrAddr
		jp 	c, .Continue
		ld 	hl, ErrAddr
.Stop:
		Border 	2
		jr 	.Stop
.Continue:
	ENDM


Border	MACRO Colour
	IF Colour=0
		xor	a
	ELSE
		ld 	a, Colour
	ENDIF
		out 	(ULA_PORT), a
	IF Colour=0
		xor 	a
	ELSE
		ld 	a, Colour*8
	ENDIF
		ld 	(23624), a
	ENDM



EspSend MACRO Text
		ld 	hl, .txtB
		ld 	e, .txtE - .txtB
		call 	espSend
		jr 	.txtE
.txtB
    	DB Text
.txtE
	ENDM

EspCmd MACRO Text
		ld 	hl, .txtB
		ld 	e, .txtE - .txtB
		call 	espSend
		jr 	.txtE
.txtB
    	DB Text
    	DB 13, 10
.txtE
	ENDM

EspCmdOkErr MACRO text
		EspCmd text
    		call checkOkErr
    	ENDM

NextRegRead MACRO Register
		ld bc, $243B             ; Port.NextReg = $243B
		ld a, Register
		call NextRegReadProc
        ENDM
