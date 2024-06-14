; The Music Studio Demo 2
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
; studd3 : grabbed tune from The Music Studio, copy/pasted into Simon's player, and the assembled with dasm. -Dave.
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





; *** DATA ***
BORDER_COL:               EQU $0
TEMPO:                    .byte  242

MUSICDATA:
                    .byte  0   ; Loop start point * 2
                    .byte  34   ; Song Length * 2
PATTERNDATA:        .word       PAT0
                    .word       PAT1
                    .word       PAT2
                    .word       PAT3
                    .word       PAT4
                    .word       PAT5
                    .word       PAT6
                    .word       PAT6
                    .word       PAT7
                    .word       PAT8
                    .word       PAT9
                    .word       PAT9
                    .word       PAT10
                    .word       PAT11
                    .word       PAT12
                    .word       PAT13
                    .word       PAT14

; *** Pattern data consists of pairs of frequency values CH1,CH2 with a single $FE to
; *** Mark the end of the pattern, and $01 for a rest
PAT0:
         .byte  16  ; Pattern tempo
             .byte  76,16
             .byte  114,227
             .byte  1,0
             .byte  114,227
             .byte  1,227
             .byte  1,227
             .byte  114,0
             .byte  1,227
             .byte  1,192
             .byte  96,192
             .byte  1,0
             .byte  1,192
             .byte  86,171
             .byte  1,171
             .byte  76,0
             .byte  1,171
         .byte  $FE
PAT1:
         .byte  16  ; Pattern tempo
             .byte  1,16
             .byte  114,227
             .byte  1,0
             .byte  1,227
             .byte  114,227
             .byte  1,227
             .byte  114,0
             .byte  1,227
             .byte  1,192
             .byte  96,192
             .byte  1,0
             .byte  1,192
             .byte  114,171
             .byte  1,171
             .byte  128,0
             .byte  121,171
         .byte  $FE
PAT2:
         .byte  16  ; Pattern tempo
             .byte  1,16
             .byte  86,227
             .byte  1,0
             .byte  1,227
             .byte  86,227
             .byte  1,227
             .byte  76,0
             .byte  1,227
             .byte  1,192
             .byte  114,192
             .byte  1,0
             .byte  1,192
             .byte  114,171
             .byte  1,171
             .byte  128,0
             .byte  121,171
         .byte  $FE
PAT3:
         .byte  16  ; Pattern tempo
             .byte  1,16
             .byte  76,227
             .byte  1,0
             .byte  1,227
             .byte  76,227
             .byte  1,227
             .byte  76,0
             .byte  1,227
             .byte  1,192
             .byte  86,192
             .byte  1,0
             .byte  1,192
             .byte  96,171
             .byte  114,171
             .byte  128,0
             .byte  114,171
         .byte  $FE
PAT4:
         .byte  16  ; Pattern tempo
             .byte  1,16
             .byte  227,30
             .byte  1,0
             .byte  227,30
             .byte  227,1
             .byte  227,1
             .byte  1,30
             .byte  227,1
             .byte  192,30
             .byte  192,1
             .byte  1,0
             .byte  192,30
             .byte  171,1
             .byte  171,1
             .byte  1,30
             .byte  171,1
         .byte  $FE
PAT5:
         .byte  16  ; Pattern tempo
             .byte  1,16
             .byte  227,30
             .byte  1,0
             .byte  227,1
             .byte  227,30
             .byte  227,1
             .byte  1,0
             .byte  227,30
             .byte  192,1
             .byte  192,30
             .byte  1,30
             .byte  192,1
             .byte  171,30
             .byte  171,30
             .byte  1,30
             .byte  171,30
         .byte  $FE
PAT6:
         .byte  16  ; Pattern tempo
             .byte  114,16
             .byte  227,128
             .byte  114,0
             .byte  227,128
             .byte  227,114
             .byte  227,128
             .byte  96,0
             .byte  227,1
             .byte  192,114
             .byte  192,128
             .byte  114,0
             .byte  192,128
             .byte  171,114
             .byte  171,128
             .byte  1,0
             .byte  171,1
         .byte  $FE
PAT7:
         .byte  16  ; Pattern tempo
             .byte  76,16
             .byte  86,227
             .byte  76,0
             .byte  86,227
             .byte  76,227
             .byte  86,227
             .byte  96,0
             .byte  1,227
             .byte  86,192
             .byte  96,192
             .byte  114,0
             .byte  128,192
             .byte  114,171
             .byte  96,171
             .byte  86,0
             .byte  1,171
         .byte  $FE
PAT8:
         .byte  16  ; Pattern tempo
             .byte  76,16
             .byte  86,227
             .byte  76,0
             .byte  86,227
             .byte  76,227
             .byte  86,227
             .byte  96,0
             .byte  1,227
             .byte  128,192
             .byte  114,192
             .byte  114,0
             .byte  128,192
             .byte  114,171
             .byte  128,171
             .byte  114,0
             .byte  1,171
         .byte  $FE
PAT9:
         .byte  16  ; Pattern tempo
             .byte  128,16
             .byte  121,227
             .byte  114,0
             .byte  114,227
             .byte  1,227
             .byte  114,227
             .byte  114,0
             .byte  1,227
             .byte  128,192
             .byte  121,192
             .byte  114,0
             .byte  114,192
             .byte  1,171
             .byte  114,171
             .byte  114,0
             .byte  1,171
         .byte  $FE
PAT10:
         .byte  16  ; Pattern tempo
             .byte  128,16
             .byte  121,227
             .byte  38,0
             .byte  43,227
             .byte  57,227
             .byte  64,227
             .byte  57,0
             .byte  64,227
             .byte  57,192
             .byte  43,192
             .byte  38,0
             .byte  43,192
             .byte  57,171
             .byte  64,171
             .byte  57,0
             .byte  64,171
         .byte  $FE
PAT11:
         .byte  16  ; Pattern tempo
             .byte  64,16
             .byte  64,227
             .byte  38,0
             .byte  43,227
             .byte  57,227
             .byte  64,227
             .byte  57,0
             .byte  64,227
             .byte  57,192
             .byte  43,192
             .byte  38,0
             .byte  43,192
             .byte  57,171
             .byte  64,171
             .byte  57,0
             .byte  64,171
         .byte  $FE
PAT12:
         .byte  16  ; Pattern tempo
             .byte  64,16
             .byte  64,227
             .byte  1,0
             .byte  57,227
             .byte  57,227
             .byte  1,227
             .byte  57,0
             .byte  57,227
             .byte  1,192
             .byte  1,192
             .byte  48,0
             .byte  1,192
             .byte  1,171
             .byte  48,171
             .byte  1,0
             .byte  1,171
         .byte  $FE
PAT13:
         .byte  16  ; Pattern tempo
             .byte  48,16
             .byte  1,227
             .byte  1,0
             .byte  227,30
             .byte  227,1
             .byte  227,30
             .byte  1,0
             .byte  227,30
             .byte  192,1
             .byte  192,30
             .byte  1,0
             .byte  192,30
             .byte  171,30
             .byte  171,1
             .byte  1,30
             .byte  171,30
         .byte  $FE
PAT14:
         .byte  16  ; Pattern tempo
             .byte  1,30
             .byte  227,30
             .byte  1,0
             .byte  227,1
         .byte  $FE



		end		start