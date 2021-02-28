	;; main entry is Parse.start
	MODULE Parse
currentOption:	DW 0
showHelp:
		ld hl, Msg.help
		call PrintRst16
		pop af					; discard the return address (from call Parse.start)
		and a					; Exit Fc=0
		jp Exit.nop


doGet:
		ld a, State.GET
		ld (State.type), a
		jr startToken

doPost:
		ld a, State.POST
		ld (State.type), a
		jr Parse.startToken

parseError:
		pop af
		ld hl, Err.badOption
		xor a					; set A = 0
		scf					; Exit Fc=1
		jp Exit.nop


; HL = start of arguments
; Modifies: A, HL
start:
		ld a, h : or l				; check if HL is zero
		jr z, Parse.showHelp			; if no args, show help

startToken
		ld a, (hl)
		inc hl

		;; terminated by $00, $0d or ':'
		call checkForEnd
		ret z

		cp 'g' : jr z, doGet
		cp 'p' : jr z, doPost
		cp '-' : jr z, parseOption

		jr startToken

parseOption
		ld a, (hl)
		inc hl
		call checkForEnd
		jr z, parseError

		push af					; backup A value
.eatSpaces:
		ld a, (hl)
		inc hl
		cp ' ' : jr z, .eatSpaces
		call checkForEnd
		jr z, parseError

		ld b, a
		pop af					; restore A - holds option flag

		cp 'b' : jr z, parseBank
		cp 'h' : jr z, parseHost
		cp 'p' : jr z, parsePort
		cp 'u' : jr z, parseUrl
		cp 'l' : jr z, parseLength
		cp 'o' : jr z, parseOffset
		jr parseError

continueOption:
		ld (currentOption), de
		ld a, b
.loop
		ld (de), a
		inc de
		ld a, (hl)
		inc hl

		cp '$' : jp z, readFromNextBASIC	; then we have a NextBASIC var

		cp ' ' : jr z, .optionDone
		call checkForEnd
		jr z, .optionDone
		jr .loop
.optionDone:
		xor a
		ld (de), a				; add null terminator to the option

		jp startToken

parseBank:	ld de, State.bank : jr continueOption
parseHost:	ld de, State.host : jr continueOption
parsePort:	ld de, State.port : jr continueOption
parseUrl:	ld de, State.url : jr continueOption
parseLength:	ld de, State.length : jr continueOption
parseOffset:	ld de, State.offset : jr continueOption


readFromNextBASIC
		push hl					; preserve the command line arg position
		dec de					; dec DE because we want to overwrite this character

		;; via https://gitlab.com/thesmog358/tbblue/-/blob/master/src/asm/dot_commands/$.asm
		ld bc, (currentOption)
		ld a, (bc)				; get the string letter
		and $df 				; capitalise
		cp 'A'
		jr c, .parseError			; bail if < A
		cp 'Z'+1
		jp nc, .parseError			; or if > Z
		and $1f
		ld c, a					; C=bits 0..4 of letter
		set 6, c				; bit 6=1 for strings
		ld hl, (VARS)
.findVariable
		ld a, (hl)				; first letter of next variable
		and $7f
		jr z, .varNotFound			; on if $80 encountered (end of vars)
		cp c
		jr z, .variableFound			; on if matches string name
		push de
		push bc
		call48k NEXT_ONE_r3			; DE=next variable
		pop bc
		ex de, hl				; HL=next variable
		pop de
		jr .findVariable			; back to check it
.variableFound:
		inc hl
		ld c, (hl)
		inc hl
		ld b, (hl)				; BC=string length
		inc hl					; HL=string address

		ldir					; copy HL to DE

		xor a
		ld (de), a				; null terminate

		pop hl					; point back to the right place in the command line
		jp startToken

.parseError
		pop hl
		jp parseError

.varNotFound
		pop hl					; pop but we don't need it
		ld hl, Err.varNotFound
		xor a					; set A = 0
		scf					; Exit Fc=1
		jp Exit.nop


; A = character to test
; Fz <- if at end
checkForEnd:
		and a  : ret z				; A is null
		cp ':' : ret z
		cp $0d : ret z
		ret

	ENDMODULE
