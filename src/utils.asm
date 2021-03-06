
; DE = pointer to string that's null terminated
; HL <- string length
; Modifies: DE
StringLength:
		ld hl, 0
.loop
		ld a, (de) : and a : ret z
		inc de
		inc hl
		jr .loop

; Uses RST 16 to loop through and print a sequence of characters
; HL = string pointer, null terminated
; Modifies: A
PrintRst16:
		ei
.loop:
	        ld a, (hl)
		inc hl
		or a
		jr z, .return
		rst 16
		jr .loop
.return:
	        di
		ret

; DE = points to the base 10 number null terminated string.
; HL <- 16 bit value of DE
; Fc <- carry set on error
; Modifies: A, BC
;
;     HL is the 16-bit value of the number
;     DE points to the byte after the number
;     z flag reset (nz)
StringToNumber16:
	ld hl, 0				; init HL to zero
ConvLoop:
	ld a, (de)
	and a
	ret z					; null character exit

	sub $30					; take DE and subtract $30 (48 starting point for numbers in ascii)
	ret c					; if we have a carry, then we're

	scf					; set the carry flag to test-
	cp 10					; if A >= 10 then we also have an error
	jr nc, .error

	inc de

	ld b, h					; copy HL to BC
	ld c, l

	add hl, hl				; (HL * 4 + HL) * 2 = HL * 10
	add hl, hl
	add hl, bc
	add hl, hl

	add a, l
	ld l, a
	jr nc, ConvLoop
	inc h
	jr ConvLoop

.error
	scf
	ret
