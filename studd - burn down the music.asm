; Burn down the music.
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
TEMPO:                    .byte  250

MUSICDATA:
                    .byte  0   ; Loop start point * 2
                    .byte  160   ; Song Length * 2
PATTERNDATA:        .word       PAT0
                    .word       PAT1
                    .word       PAT2
                    .word       PAT3
                    .word       PAT4
                    .word       PAT5
                    .word       PAT3
                    .word       PAT1
                    .word       PAT2
                    .word       PAT3
                    .word       PAT4
                    .word       PAT5
                    .word       PAT3
                    .word       PAT6
                    .word       PAT2
                    .word       PAT11
                    .word       PAT8
                    .word       PAT5
                    .word       PAT9
                    .word       PAT10
                    .word       PAT2
                    .word       PAT7
                    .word       PAT12
                    .word       PAT3
                    .word       PAT14
                    .word       PAT15
                    .word       PAT16
                    .word       PAT17
                    .word       PAT18
                    .word       PAT39
                    .word       PAT6
                    .word       PAT2
                    .word       PAT11
                    .word       PAT8
                    .word       PAT5
                    .word       PAT9
                    .word       PAT10
                    .word       PAT2
                    .word       PAT7
                    .word       PAT12
                    .word       PAT3
                    .word       PAT14
                    .word       PAT15
                    .word       PAT16
                    .word       PAT17
                    .word       PAT18
                    .word       PAT19
                    .word       PAT20
                    .word       PAT21
                    .word       PAT22
                    .word       PAT23
                    .word       PAT24
                    .word       PAT25
                    .word       PAT26
                    .word       PAT27
                    .word       PAT28
                    .word       PAT29
                    .word       PAT30
                    .word       PAT31
                    .word       PAT32
                    .word       PAT33
                    .word       PAT33
                    .word       PAT33
                    .word       PAT34
                    .word       PAT34
                    .word       PAT34
                    .word       PAT34
                    .word       PAT34
                    .word       PAT35
                    .word       PAT35
                    .word       PAT36
                    .word       PAT36
                    .word       PAT35
                    .word       PAT35
                    .word       PAT36
                    .word       PAT37
                    .word       PAT38
                    .word       PAT38
                    .word       PAT37
                    .word       PAT37

; *** Pattern data consists of pairs of frequency values CH1,CH2 with a single $FE to
; *** Mark the end of the pattern, and $01 for a rest
PAT0:
         .byte  4  ; Pattern tempo
             .byte  1,30
             .byte  1,30
             .byte  1,28
             .byte  1,28
             .byte  1,27
             .byte  1,27
             .byte  1,25
             .byte  1,25
             .byte  1,24
             .byte  1,24
             .byte  1,23
             .byte  1,23
             .byte  1,21
             .byte  1,21
             .byte  1,20
             .byte  1,20
             .byte  1,19
             .byte  1,19
             .byte  1,18
             .byte  1,18
             .byte  1,17
             .byte  1,17
             .byte  1,16
             .byte  1,16
             .byte  1,17
             .byte  1,17
             .byte  1,18
             .byte  1,18
             .byte  1,19
             .byte  1,19
             .byte  1,20
             .byte  1,20
             .byte  1,21
             .byte  1,21
             .byte  1,23
             .byte  1,23
             .byte  1,24
             .byte  1,24
             .byte  1,25
             .byte  1,25
             .byte  1,27
             .byte  1,27
             .byte  1,28
             .byte  1,28
             .byte  1,30
             .byte  1,30
             .byte  1,28
             .byte  1,27
             .byte  1,25
             .byte  1,24
             .byte  1,23
             .byte  1,21
             .byte  1,20
             .byte  1,19
             .byte  1,18
             .byte  1,17
             .byte  1,16
             .byte  1,17
             .byte  1,18
             .byte  1,19
             .byte  1,20
             .byte  1,21
             .byte  1,23
             .byte  1,24
             .byte  1,25
             .byte  1,27
             .byte  1,28
             .byte  1,30
             .byte  1,28
             .byte  1,25
             .byte  1,23
             .byte  1,20
             .byte  1,18
             .byte  1,16
             .byte  1,18
             .byte  1,20
             .byte  1,23
             .byte  1,25
             .byte  1,28
             .byte  1,25
             .byte  1,20
             .byte  1,16
             .byte  1,20
             .byte  1,25
             .byte  1,20
             .byte  1,16
             .byte  1,20
             .byte  1,25
             .byte  1,20
             .byte  1,16
             .byte  1,20
             .byte  1,25
             .byte  1,20
             .byte  1,16
             .byte  1,20
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,25
             .byte  1,16
             .byte  1,16
             .byte  1,16
             .byte  1,16
             .byte  1,16
             .byte  1,16
             .byte  1,16
             .byte  1,16
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
         .byte  $FE
PAT1:
         .byte  4  ; Pattern tempo
             .byte  180,1
             .byte  180,1
             .byte  180,1
         .byte  $FE
PAT2:
         .byte  46  ; Pattern tempo
             .byte  180,1
         .byte  $FE
PAT3:
         .byte  7  ; Pattern tempo
             .byte  144,1
             .byte  144,1
             .byte  144,1
             .byte  144,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  144,1
             .byte  144,1
             .byte  144,1
             .byte  144,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
         .byte  $FE
PAT4:
         .byte  4  ; Pattern tempo
             .byte  240,1
             .byte  240,1
             .byte  240,1
         .byte  $FE
PAT5:
         .byte  46  ; Pattern tempo
             .byte  240,1
         .byte  $FE
PAT6:
         .byte  4  ; Pattern tempo
             .byte  180,72
             .byte  72,61
             .byte  180,61
         .byte  $FE
PAT7:
         .byte  7  ; Pattern tempo
             .byte  144,72
             .byte  144,72
             .byte  144,72
             .byte  144,72
             .byte  1,81
             .byte  1,81
             .byte  1,81
             .byte  1,81
             .byte  144,72
             .byte  144,72
             .byte  144,72
             .byte  144,72
             .byte  1,68
             .byte  1,68
             .byte  1,68
             .byte  1,68
         .byte  $FE
PAT8:
         .byte  4  ; Pattern tempo
             .byte  240,81
             .byte  81,68
             .byte  240,68
         .byte  $FE
PAT9:
         .byte  7  ; Pattern tempo
             .byte  72,91
             .byte  144,91
             .byte  144,72
             .byte  144,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  144,91
             .byte  144,72
             .byte  144,91
             .byte  144,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
         .byte  $FE
PAT10:
         .byte  4  ; Pattern tempo
             .byte  180,72
             .byte  91,72
             .byte  180,91
         .byte  $FE
PAT11:
         .byte  7  ; Pattern tempo
             .byte  144,68
             .byte  144,68
             .byte  144,68
             .byte  144,68
             .byte  1,72
             .byte  1,72
             .byte  1,72
             .byte  1,72
             .byte  144,81
             .byte  144,81
             .byte  144,81
             .byte  144,81
             .byte  1,72
             .byte  1,72
             .byte  1,72
             .byte  1,72
         .byte  $FE
PAT12:
         .byte  7  ; Pattern tempo
             .byte  240,72
             .byte  240,72
             .byte  240,72
             .byte  240,72
             .byte  240,72
             .byte  240,72
             .byte  240,72
             .byte  240,72
         .byte  $FE
PAT14:
         .byte  7  ; Pattern tempo
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,68
         .byte  $FE
PAT15:
         .byte  7  ; Pattern tempo
             .byte  136,61
             .byte  136,61
             .byte  136,61
             .byte  136,61
             .byte  1,68
             .byte  1,68
             .byte  1,68
             .byte  1,68
             .byte  136,72
             .byte  136,72
             .byte  136,72
             .byte  136,72
             .byte  1,81
             .byte  1,81
             .byte  1,81
             .byte  1,81
         .byte  $FE
PAT16:
         .byte  7  ; Pattern tempo
             .byte  180,72
             .byte  180,72
             .byte  180,72
             .byte  180,72
             .byte  180,72
             .byte  180,72
             .byte  180,72
             .byte  180,72
         .byte  $FE
PAT17:
         .byte  7  ; Pattern tempo
             .byte  144,68
             .byte  144,68
             .byte  144,68
             .byte  144,68
             .byte  1,72
             .byte  1,72
             .byte  1,72
             .byte  1,72
             .byte  144,81
             .byte  144,81
             .byte  144,81
             .byte  144,81
             .byte  1,91
             .byte  1,91
             .byte  1,91
             .byte  1,91
         .byte  $FE
PAT18:
         .byte  7  ; Pattern tempo
             .byte  192,81
             .byte  192,81
             .byte  192,81
             .byte  192,81
             .byte  192,81
             .byte  192,81
             .byte  192,81
             .byte  192,81
         .byte  $FE
PAT19:
         .byte  31  ; Pattern tempo
             .byte  240,240
             .byte  240,1
             .byte  215,215
             .byte  215,1
             .byte  192,192
             .byte  192,1
             .byte  215,215
             .byte  215,1
             .byte  240,240
             .byte  240,1
         .byte  $FE
PAT20:
         .byte  28  ; Pattern tempo
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
         .byte  $FE
PAT21:
         .byte  28  ; Pattern tempo
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,18
             .byte  180,18
             .byte  180,18
             .byte  180,18
         .byte  $FE
PAT22:
         .byte  16  ; Pattern tempo
             .byte  180,18
             .byte  180,180
             .byte  180,91
             .byte  180,91
             .byte  180,151
             .byte  180,76
             .byte  180,91
             .byte  180,91
             .byte  227,18
             .byte  227,76
             .byte  227,76
             .byte  227,76
             .byte  240,240
             .byte  240,81
             .byte  240,81
             .byte  240,81
             .byte  180,18
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,18
             .byte  180,1
         .byte  $FE
PAT23:
         .byte  16  ; Pattern tempo
             .byte  180,18
             .byte  180,180
             .byte  180,91
             .byte  180,91
             .byte  180,151
             .byte  180,76
             .byte  180,91
             .byte  180,91
             .byte  227,18
             .byte  227,57
             .byte  227,57
             .byte  227,57
             .byte  240,240
             .byte  240,81
             .byte  240,81
             .byte  240,81
             .byte  76,18
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,18
             .byte  180,1
         .byte  $FE
PAT24:
         .byte  16  ; Pattern tempo
             .byte  180,76
             .byte  180,76
             .byte  180,76
             .byte  180,76
             .byte  81,18
             .byte  180,81
             .byte  180,81
             .byte  180,81
             .byte  76,18
             .byte  227,18
             .byte  227,76
             .byte  227,76
             .byte  240,240
             .byte  240,81
             .byte  240,81
             .byte  240,81
             .byte  180,18
             .byte  180,76
             .byte  180,1
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,18
             .byte  180,1
         .byte  $FE
PAT25:
         .byte  16  ; Pattern tempo
             .byte  180,18
             .byte  180,180
             .byte  180,91
             .byte  180,91
             .byte  180,151
             .byte  180,76
             .byte  180,91
             .byte  180,91
             .byte  227,18
             .byte  227,57
             .byte  227,57
             .byte  227,57
             .byte  240,240
             .byte  240,81
             .byte  240,81
             .byte  240,81
             .byte  180,18
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,1
             .byte  180,1
             .byte  180,18
             .byte  180,1
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,180
             .byte  180,18
             .byte  180,1
         .byte  $FE
PAT26:
         .byte  13  ; Pattern tempo
             .byte  161,18
             .byte  161,161
             .byte  161,81
             .byte  161,81
             .byte  161,136
             .byte  161,68
             .byte  161,81
             .byte  161,81
             .byte  203,18
             .byte  203,68
             .byte  203,68
             .byte  203,68
             .byte  215,215
             .byte  215,72
             .byte  215,72
             .byte  215,72
             .byte  161,18
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,18
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,18
             .byte  161,1
         .byte  $FE
PAT27:
         .byte  13  ; Pattern tempo
             .byte  161,18
             .byte  161,161
             .byte  161,81
             .byte  161,81
             .byte  161,136
             .byte  161,68
             .byte  161,81
             .byte  161,81
             .byte  203,18
             .byte  203,51
             .byte  203,51
             .byte  203,51
             .byte  215,215
             .byte  215,72
             .byte  215,72
             .byte  215,72
             .byte  68,18
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,18
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,18
             .byte  161,1
         .byte  $FE
PAT28:
         .byte  13  ; Pattern tempo
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  161,68
             .byte  72,18
             .byte  161,72
             .byte  161,72
             .byte  161,72
             .byte  68,18
             .byte  203,18
             .byte  203,68
             .byte  203,68
             .byte  215,215
             .byte  215,72
             .byte  215,72
             .byte  215,72
             .byte  161,18
             .byte  161,68
             .byte  161,1
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,18
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,18
             .byte  161,1
         .byte  $FE
PAT29:
         .byte  13  ; Pattern tempo
             .byte  161,18
             .byte  161,161
             .byte  161,81
             .byte  161,81
             .byte  161,136
             .byte  161,68
             .byte  161,81
             .byte  161,81
             .byte  203,18
             .byte  203,51
             .byte  203,51
             .byte  203,51
             .byte  215,215
             .byte  215,72
             .byte  215,72
             .byte  215,72
             .byte  161,18
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,1
             .byte  161,1
             .byte  161,18
             .byte  161,1
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,161
             .byte  161,18
             .byte  161,1
         .byte  $FE
PAT30:
         .byte  10  ; Pattern tempo
             .byte  151,18
             .byte  151,151
             .byte  151,76
             .byte  151,76
             .byte  151,128
             .byte  151,64
             .byte  151,76
             .byte  151,76
             .byte  192,18
             .byte  192,64
             .byte  192,64
             .byte  192,64
             .byte  203,203
             .byte  203,68
             .byte  203,68
             .byte  203,68
             .byte  151,18
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,18
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,18
             .byte  151,1
         .byte  $FE
PAT31:
         .byte  10  ; Pattern tempo
             .byte  151,18
             .byte  151,151
             .byte  151,76
             .byte  151,76
             .byte  151,128
             .byte  151,64
             .byte  151,76
             .byte  151,76
             .byte  192,18
             .byte  192,48
             .byte  192,48
             .byte  192,48
             .byte  203,203
             .byte  203,68
             .byte  203,68
             .byte  203,68
             .byte  64,18
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,18
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,18
             .byte  151,1
         .byte  $FE
PAT32:
         .byte  7  ; Pattern tempo
             .byte  151,64
             .byte  151,64
             .byte  151,64
             .byte  151,64
             .byte  68,18
             .byte  151,68
             .byte  151,68
             .byte  151,68
             .byte  64,18
             .byte  192,18
             .byte  192,64
             .byte  192,64
             .byte  203,203
             .byte  203,68
             .byte  203,68
             .byte  203,68
             .byte  151,18
             .byte  151,64
             .byte  151,1
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,18
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,18
             .byte  151,1
         .byte  $FE
PAT33:
         .byte  4  ; Pattern tempo
             .byte  151,18
             .byte  151,151
             .byte  151,76
             .byte  151,76
             .byte  151,128
             .byte  151,64
             .byte  151,76
             .byte  151,76
             .byte  192,18
             .byte  192,48
             .byte  192,48
             .byte  192,48
             .byte  203,203
             .byte  203,68
             .byte  203,68
             .byte  203,68
             .byte  151,18
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,1
             .byte  151,1
             .byte  151,18
             .byte  151,1
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,151
             .byte  151,18
             .byte  151,1
         .byte  $FE
PAT34:
         .byte  4  ; Pattern tempo
             .byte  151,30
             .byte  151,27
             .byte  151,24
             .byte  151,23
             .byte  151,21
             .byte  151,19
             .byte  151,18
             .byte  151,17
             .byte  192,16
             .byte  192,18
             .byte  192,19
             .byte  192,21
             .byte  203,23
             .byte  203,24
             .byte  203,27
             .byte  203,28
             .byte  151,30
             .byte  151,27
             .byte  151,24
             .byte  151,23
             .byte  151,21
             .byte  151,19
             .byte  151,18
             .byte  151,17
             .byte  151,16
             .byte  151,18
             .byte  151,19
             .byte  151,21
             .byte  151,23
             .byte  151,24
             .byte  151,27
             .byte  151,28
         .byte  $FE
PAT35:
         .byte  4  ; Pattern tempo
             .byte  45,30
             .byte  72,1
             .byte  192,30
             .byte  192,1
             .byte  45,28
             .byte  72,1
             .byte  192,28
             .byte  192,1
             .byte  192,27
             .byte  192,27
             .byte  192,27
             .byte  192,27
             .byte  192,25
             .byte  192,1
             .byte  192,25
             .byte  192,1
             .byte  45,24
             .byte  72,1
             .byte  192,24
             .byte  192,1
             .byte  45,23
             .byte  72,1
             .byte  192,23
             .byte  192,23
             .byte  72,21
             .byte  192,21
             .byte  192,21
             .byte  192,1
             .byte  72,20
             .byte  192,20
             .byte  72,1
             .byte  72,1
             .byte  45,19
             .byte  72,19
             .byte  192,19
             .byte  192,19
             .byte  45,18
             .byte  72,18
             .byte  192,18
             .byte  192,18
             .byte  192,17
             .byte  192,17
             .byte  192,17
             .byte  192,17
             .byte  192,16
             .byte  192,16
             .byte  192,16
             .byte  192,16
             .byte  45,0
             .byte  72,0
             .byte  192,0
             .byte  192,0
             .byte  45,30
             .byte  72,28
             .byte  192,27
             .byte  192,25
             .byte  72,24
             .byte  192,23
             .byte  192,21
             .byte  192,20
             .byte  72,19
             .byte  192,18
             .byte  192,17
             .byte  192,16
         .byte  $FE
PAT36:
         .byte  4  ; Pattern tempo
             .byte  48,30
             .byte  81,1
             .byte  192,30
             .byte  192,1
             .byte  48,28
             .byte  81,1
             .byte  192,28
             .byte  192,1
             .byte  192,27
             .byte  192,27
             .byte  192,27
             .byte  192,27
             .byte  192,25
             .byte  192,1
             .byte  192,25
             .byte  192,1
             .byte  48,24
             .byte  81,1
             .byte  192,24
             .byte  192,1
             .byte  48,23
             .byte  81,1
             .byte  192,23
             .byte  192,23
             .byte  81,21
             .byte  192,21
             .byte  192,21
             .byte  192,1
             .byte  81,20
             .byte  192,20
             .byte  81,1
             .byte  81,1
             .byte  48,19
             .byte  81,19
             .byte  192,19
             .byte  192,19
             .byte  48,18
             .byte  81,18
             .byte  192,18
             .byte  192,18
             .byte  192,17
             .byte  192,17
             .byte  192,17
             .byte  192,17
             .byte  192,16
             .byte  192,16
             .byte  192,16
             .byte  192,16
             .byte  48,0
             .byte  81,0
             .byte  192,0
             .byte  192,0
             .byte  48,30
             .byte  81,28
             .byte  192,27
             .byte  192,25
             .byte  81,24
             .byte  192,23
             .byte  192,21
             .byte  192,20
             .byte  81,19
             .byte  192,18
             .byte  192,17
             .byte  192,16
         .byte  $FE
PAT37:
         .byte  4  ; Pattern tempo
             .byte  48,30
             .byte  81,1
             .byte  192,30
             .byte  192,1
             .byte  48,28
             .byte  81,1
             .byte  192,28
             .byte  192,1
             .byte  192,27
             .byte  192,27
             .byte  192,27
             .byte  192,27
             .byte  192,25
             .byte  192,1
             .byte  192,25
             .byte  192,1
             .byte  48,24
             .byte  81,1
             .byte  192,24
             .byte  192,1
             .byte  48,23
             .byte  81,1
             .byte  192,23
             .byte  192,23
             .byte  81,21
             .byte  192,21
             .byte  192,21
             .byte  192,1
             .byte  81,20
             .byte  192,20
             .byte  81,1
             .byte  81,1
             .byte  48,19
             .byte  81,19
             .byte  180,19
             .byte  161,19
             .byte  48,18
             .byte  81,18
             .byte  136,18
             .byte  121,18
             .byte  108,17
             .byte  96,17
             .byte  91,17
             .byte  81,17
             .byte  72,16
             .byte  68,16
             .byte  61,16
             .byte  54,16
             .byte  48,0
             .byte  81,0
             .byte  45,0
             .byte  40,0
             .byte  48,30
             .byte  81,28
             .byte  34,27
             .byte  34,25
             .byte  81,24
             .byte  34,23
             .byte  34,21
             .byte  34,20
             .byte  81,19
             .byte  34,18
             .byte  40,17
             .byte  54,16
         .byte  $FE
PAT38:
         .byte  4  ; Pattern tempo
             .byte  45,30
             .byte  72,1
             .byte  34,30
             .byte  34,1
             .byte  45,28
             .byte  72,1
             .byte  34,28
             .byte  34,1
             .byte  34,27
             .byte  34,27
             .byte  34,27
             .byte  34,27
             .byte  34,25
             .byte  34,1
             .byte  34,25
             .byte  34,1
             .byte  45,24
             .byte  72,1
             .byte  34,24
             .byte  34,1
             .byte  45,23
             .byte  72,1
             .byte  34,23
             .byte  34,23
             .byte  72,21
             .byte  34,21
             .byte  34,21
             .byte  34,1
             .byte  72,20
             .byte  34,20
             .byte  72,1
             .byte  72,1
             .byte  45,19
             .byte  72,19
             .byte  34,19
             .byte  34,19
             .byte  45,18
             .byte  72,18
             .byte  34,18
             .byte  34,18
             .byte  34,17
             .byte  34,17
             .byte  34,17
             .byte  34,17
             .byte  34,16
             .byte  34,16
             .byte  34,16
             .byte  34,16
             .byte  45,0
             .byte  72,0
             .byte  34,0
             .byte  54,0
             .byte  45,30
             .byte  72,28
             .byte  68,27
             .byte  81,25
             .byte  72,24
             .byte  91,23
             .byte  108,21
             .byte  144,20
             .byte  72,19
             .byte  161,18
             .byte  240,17
             .byte  1,16
         .byte  $FE
PAT39:
         .byte  28  ; Pattern tempo
             .byte  240,240
             .byte  240,1
             .byte  215,215
             .byte  215,1
             .byte  192,192
             .byte  192,1
             .byte  215,215
             .byte  215,1
             .byte  240,240
             .byte  240,1
         .byte  $FE


		end		start