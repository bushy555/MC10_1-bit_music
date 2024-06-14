; The Music Studio - demo 1.
;
;
; ********************************************************************************************************
; ZX SPECCY *the music studio* engine for mc10
; 
; (C) Simon Jonassen 2021 - free for all, use as you see fit
;
; remember where it came from and give credit where due
;
;
;
; studd2 : grabbed tune from The Music Studio, copy/pasted into Simon's player, and the assembled with dasm. -Dave.
; dasm %1.asm -f3 -o%1.bin
; Loading into VMC-10 emulator: Util->Load binary: Load:$5000 Exec:$5000.  Back at prompt, enter>   EXEC
;
; ********************************************************************************************************
		PROCESSOR	6803
                ORG	$5000

start		sei
		jsr	initvu
		ldd	#PATTERNDATA 		; Get start address of pattern data
		pshb
		psha
		pulx
		stx	nextpat+1
		addd	MUSICDATA		; Add loop start point to the pattern data start address
		ldd	#PATTERNDATA 		; Get start address of pattern data
		addd	MUSICDATA+2		; Add song length to the pattern data loop start address
		std	patloopend+1		; Set pattern data loop end address
		

; ********************************************************************************************************
; * NEXT_PATTERN
; ********************************************************************************************************
nextpat		ldx	#0000
		ldx	,x
		ldaa	,x			; X = Pattern data pointer 
		staa	qtempo+1
		inx
playnote	ldd	,x
		cmpa	#$fe			; $FE indicates end of pattern
		bne	continue

		ldx	nextpat+1
		inx
		inx
		stx	nextpat+1


patloopend	cpx	#0000			; Check for end of pattern loop
		blo	nextpat
		cli
		jsr	initvu
		rts

; ********************************************************************************************************
; * NOTE ROUTINE
; ********************************************************************************************************

continue	staa	ch1freq+1
		stab	ch2freq+1
noteptr		inx
		inx				; Increment the note pointer by 2 (one note per chan)

qtempo		ldd	#0000			; A = Tempo | B = 0
		std	tempc
		stab	bord1+1
		stab	bord2+1			; So now tempb = 0, tempc = Tempo | bord1 & bord2 = 0

outputnote

		ldab	ch1freq+1		; Put note frequency for chan 1 into IXH
		stab	ch1ix+1
		stab	ch1count
		decb
		stab	ltemp1
		beq	continue1


		ldab	#128
continue1	stab	xore1+1
		stab	xore1b+1

		ldab	ch2freq+1		; Put note frequency for chan 2 into IXL
		stab	ch2ix+1
		stab	ch2count
		stab	ltemp2
		decb
		stab	ltemp2
		beq	continue2

		ldab	#128
continue2	stab	xore2+1
		stab	xore2b+1

continue3
bord1		ldaa	#00
		dec	ch1count		; Dec H, which also holds the frequency value
		bne	l8055
xore1		eora	#00
		staa	bord1+1
ch1freq		ldab	#00
		stab	ch1count

ch1ix		ldab	#00
		cmpb	#$20
		bcc	l8055			; if B  $20 then this is not a drum effect, skip the INC D
		inc	ch1freq+1		; create the "fast falling pitch" percussion effect
l8055		dec	ltemp1
		bne	bord2
xore1b		eora	#00
		staa	bord1+1

		ldab	ch1freq+1
		decb
		stab	ltemp1

bord2		adda	#00			;adda
		staa	$bfff
		dec	ch2count
		bne	l806d
		ldaa	bord2+1
xore2		eora	#00
		staa	bord2+1
ch2freq		ldab	#00
		stab	ch2count
ch2ix		ldab	#00
		cmpb	#$20
		bcc	l806d			; if A  $20 then this is not a drum effect, skip the INC D
		inc	ch2freq+1		; create the "fast falling pitch" percussion effect

l806d		dec	ltemp2
		bne	l8073
		ldaa	bord2+1
xore2b		eora	#00
		staa	bord2+1
		ldab	ch2freq+1
		decb
		stab	ltemp2
l8073		dec	tempb
		bne	continue3
		stx	oldx+1
		jsr	vu
		jsr	vu2
oldx		ldx	#$0000
		dec	tempc
		bne	continue3
		jmp	playnote

; ********************************************************************************************************
; FAKE VU METER CODE
; ********************************************************************************************************
initvu		clr	target			; VU METER
		clr	target2
		ldd	#$800f
		stab	current
		stab	current2
		jsr	cls
		rts

vu		ldaa	#132			;ch1
		ldx	#$40e0
		ldab	current
		abx
		cmpb	target
		blo	up
		bhi	down

		ldab	ch1freq+1
		addb	ch1ix+1
		lsrb
		lsrb	
		lsrb
		stab	target
		rts

up		cmpb	#16 
		blo	green
		ldaa	#148

green		cmpb	#24
		blo	yella1
		ldaa	#180
yella1		staa	,x
		incb
		stab	current
		rts

down		ldaa	#$80
		staa	,x
		decb
		stab	current
		rts


vu2		ldaa	#129			;ch2
		ldx	#$4100
		ldab	current2
		abx
		cmpb	target2
		blo	up2
		bhi	down2

		ldab	ch2freq+1
		addb	ch2ix+1
		lsrb
		lsrb	
		lsrb
		stab	target2
		rts

up2		cmpb	#16 
		blo	green2
		ldaa	#145

green2		cmpb	#24
		blo	yella2
		ldaa	#177
yella2		staa	,x
		incb
		stab	current2
		rts

down2		ldaa	#$80
		staa	,x
		decb
		stab	current2
		rts

cls		ldx	#$4000
nxt		staa	,x
		inx
		cpx	#$41ff
		bls	nxt
		rts

tempc		.byte	0
tempb		.byte	0
ch1count	.word	0
ch2count	.word	0
ltemp1		.word	0
ltemp2		.word	0
target		.byte	0
target2		.byte	0
current		.byte	0
current2	.byte	0


BORDER_COL:               EQU $0
TEMPO:                    .byte 250

MUSICDATA:
                    .word 0   ; Loop start point * 2
                    .word 16; 108   ; Song Length * 2

;                   .byte  16   ; Song Length * 2

PATLOOP
PATTERNS
PATTERNDATA         .word       PAT0
                    .word       PAT0
                    .word       PAT1
                    .word       PAT1
                    .word       PAT2
                    .word       PAT2
                    .word       PAT3
                    .word       PAT3

; *** Pattern data consists of pairs of frequency values CH1,CH2 with a single $FE to
; *** Mark the end of the pattern, and $01 for a rest
PAT0
         .byte  10  ; Pattern tempo
             .byte  215,108
             .byte  215,1
             .byte  215,17
             .byte  215,1
             .byte  215,108
             .byte  215,1
             .byte  215,17
             .byte  215,1
             .byte  215,108
             .byte  215,1
             .byte  215,17
             .byte  215,1
             .byte  161,108
             .byte  161,1
             .byte  180,108
             .byte  180,1
             .byte  215,91
             .byte  215,91
             .byte  215,108
             .byte  215,108
             .byte  215,81
             .byte  215,81
             .byte  215,81
             .byte  215,81
             .byte  215,108
             .byte  215,108
             .byte  215,108
             .byte  215,17
             .byte  240,17
             .byte  240,17
             .byte  227,121
             .byte  227,114
             .byte  215,108
             .byte  215,1
             .byte  215,17
             .byte  215,1
             .byte  215,108
             .byte  215,1
             .byte  215,17
             .byte  215,1
             .byte  215,108
             .byte  215,1
             .byte  215,17
             .byte  215,1
             .byte  161,108
             .byte  161,1
             .byte  180,108
             .byte  180,1
             .byte  215,91
             .byte  215,91
             .byte  215,17
             .byte  215,91
             .byte  215,91
             .byte  215,91
             .byte  215,17
             .byte  215,108
             .byte  227,81
             .byte  227,81
             .byte  227,17
             .byte  227,17
             .byte  227,81
             .byte  227,17
             .byte  227,81
             .byte  227,17
         .byte  254

NOPAT:



PAT1
         .byte  10  ; Pattern tempo
             .byte  161,81
             .byte  161,1
             .byte  161,16
             .byte  161,1
             .byte  161,81
             .byte  161,1
             .byte  161,16
             .byte  161,1
             .byte  161,81
             .byte  161,1
             .byte  161,16
             .byte  161,1
             .byte  121,81
             .byte  121,1
             .byte  136,81
             .byte  136,1
             .byte  161,68
             .byte  161,68
             .byte  161,16
             .byte  161,81
             .byte  161,61
             .byte  161,61
             .byte  161,16
             .byte  161,61
             .byte  161,81
             .byte  161,81
             .byte  161,81
             .byte  161,16
             .byte  180,16
             .byte  180,16
             .byte  171,91
             .byte  171,86
             .byte  161,81
             .byte  161,1
             .byte  161,16
             .byte  161,1
             .byte  161,81
             .byte  161,1
             .byte  161,16
             .byte  161,1
             .byte  161,81
             .byte  161,1
             .byte  161,16
             .byte  161,1
             .byte  121,81
             .byte  121,1
             .byte  136,16
             .byte  136,1
             .byte  161,68
             .byte  161,68
             .byte  161,16
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,16
             .byte  161,81
             .byte  171,61
             .byte  171,61
             .byte  171,16
             .byte  171,61
             .byte  171,61
             .byte  171,61
             .byte  171,16
             .byte  171,61
         .byte  254
PAT2
         .byte  10  ; Pattern tempo
             .byte  114,57
             .byte  227,151
             .byte  227,17
             .byte  227,151
             .byte  114,57
             .byte  227,151
             .byte  227,17
             .byte  227,151
             .byte  114,57
             .byte  227,151
             .byte  227,17
             .byte  227,151
             .byte  171,57
             .byte  171,151
             .byte  192,17
             .byte  192,151
             .byte  227,48
             .byte  227,96
             .byte  227,57
             .byte  227,114
             .byte  227,43
             .byte  227,86
             .byte  227,17
             .byte  227,86
             .byte  227,57
             .byte  227,114
             .byte  227,57
             .byte  227,17
             .byte  255,17
             .byte  255,17
             .byte  240,64
             .byte  121,61
             .byte  114,57
             .byte  227,151
             .byte  227,17
             .byte  227,151
             .byte  114,57
             .byte  227,151
             .byte  227,17
             .byte  227,151
             .byte  114,57
             .byte  227,151
             .byte  227,17
             .byte  227,151
             .byte  171,57
             .byte  171,151
             .byte  192,57
             .byte  192,151
             .byte  227,48
             .byte  227,96
             .byte  227,17
             .byte  227,96
             .byte  227,48
             .byte  227,96
             .byte  227,17
             .byte  227,57
             .byte  240,43
             .byte  240,86
             .byte  240,17
             .byte  240,17
             .byte  240,43
             .byte  240,17
             .byte  240,43
             .byte  240,17
         .byte  254
PAT3
         .byte  10  ; Pattern tempo
             .byte  86,43
             .byte  171,114
             .byte  171,17
             .byte  171,114
             .byte  86,43
             .byte  171,114
             .byte  171,17
             .byte  171,114
             .byte  86,43
             .byte  171,114
             .byte  171,17
             .byte  171,114
             .byte  128,43
             .byte  128,114
             .byte  144,17
             .byte  144,114
             .byte  171,36
             .byte  171,72
             .byte  171,43
             .byte  171,86
             .byte  171,32
             .byte  171,64
             .byte  171,17
             .byte  171,64
             .byte  171,43
             .byte  171,86
             .byte  171,43
             .byte  171,17
             .byte  192,17
             .byte  192,17
             .byte  180,48
             .byte  91,45
             .byte  86,43
             .byte  171,114
             .byte  171,17
             .byte  171,114
             .byte  86,43
             .byte  171,114
             .byte  171,17
             .byte  171,114
             .byte  86,43
             .byte  171,114
             .byte  171,17
             .byte  171,114
             .byte  128,43
             .byte  128,114
             .byte  144,43
             .byte  144,114
             .byte  171,36
             .byte  171,72
             .byte  171,17
             .byte  171,72
             .byte  171,36
             .byte  171,72
             .byte  171,17
             .byte  171,43
             .byte  180,32
             .byte  180,64
             .byte  180,17
             .byte  180,17
             .byte  180,32
             .byte  180,17
             .byte  180,32
             .byte  180,17
         .byte  $FE






		end		start