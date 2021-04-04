	MODULE Bank

loadToBank	DEFB 1			; 1 = default = load into a bank, 0 = load by file
prevBankA	DEFB 0
prevBankB	DEFB 0
userBank	DEFB 0

pageA		EQU MMU4_8000_NR_54
pageB		EQU MMU5_A000_NR_55

					; NOTE: MMU3/5 are safe from being
					;       paged out when making NextZXOS
					;       calls (unlike MMU0/1/6/7)

buffer		EQU $8000
	IFDEF TESTING
debug		DW $A000
	ENDIF

; C <- 16K bank number to use as active bank
; Modifies: A, BC (via macro)
init:
		;; check the bank init method, `loadToBank` = 1 if we're loading
		;; data in and out of banks, and set to 0 if we're working with
		;; files
		ld a, (loadToBank)
		or a
		jr z, .initNewBank

		;; double the value as we'll get 16K bank
		ld a, c
		add a, a
		ld (userBank), a

		;; backup the banks that are sitting over $8000 and $A000
		;; note that with a dot file, the stack originally is sitting at $FF42
		;; so if I do use this area, I need to set my own stackTop
		NextRegRead pageA		; loads A with pageA bank number
		ld (prevBankA), a
		NextRegRead pageB
		ld (prevBankB), a

		;; now page in our user banks
		ld a, (userBank)
		nextreg	pageA, a ; set bank to A
		inc a
		nextreg	pageB, a ; set bank to A
		ret

.initNewBank
		call allocPage
		ld (userBank), a
		NextRegRead pageA		; loads A with pageA bank number
		ld (prevBankA), a
		ld a, (userBank)
		nextreg	pageA, a ; set bank to A
		ret
erase:
		;; FIXME should probably zero out the file
		ld a, (loadToBank)			; exit if we're writing to a file
		or a
		ret z

		ld bc, $4000				; 16k
		ld hl, buffer
		ld de, buffer + 1
		ld (hl), 0
		ldir
		ret

restore:
		push af					; protect the F flags

		ld a, (loadToBank)
		or a
		jr z, .releaseBank

		ld a, (prevBankA)
		nextreg	pageA, a
		ld a, (prevBankB)
		nextreg	pageB, a
		pop af
		ret

.releaseBank
		ld a, (prevBankA)
		nextreg	pageA, a
		ld a, (userBank)
		ld e, a
		call freePage
		pop af
		ret


;; via Matt Davies — 30/03/2021
allocPage:
                push    ix
                push    bc
                push    de
                push    hl

                ; Allocate a page by using the OS function IDE_BANK.
                ld      hl,$0001        ; Select allocate function and allocate from normal memory.
                call    .callP3dos
                ccf
                ld      a,e
                pop     hl
                pop     de
                pop     bc
                pop     ix
                ret     nc
                xor     a               ; Out of memory, page # is 0 (i.e. error), CF = 1
                scf
                ret

.callP3dos:
                exx                     ; Function parameters are switched to alternative registers.
                ld      de,IDE_BANK     ; Choose the function.
                ld      c,7             ; We want RAM 7 swapped in when we run this function (so that the OS can run).
                rst     8
                db      M_P3DOS         ; Call the function, new page # is in E
                ret

freePage:
                push    af
                push    ix
                push    bc
                push    de
                push    hl

                ld      e,a             ; E = page #
                ld      hl,$0003        ; Deallocate function from normal memory
                call    allocPage.callP3dos

                pop     hl
                pop     de
                pop     bc
                pop     ix
                pop     af
                ret

	ENDMODULE


; Not used directly - called from the NextRegRead macro
;
; A = register value
; A <- value of register
; Modifies: B
NextRegReadProc:
		out (c), a
		inc b
		in a, (c)
		ret
