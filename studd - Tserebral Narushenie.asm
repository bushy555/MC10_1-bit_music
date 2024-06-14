; Tserebral Narushenie
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
TEMPO:                    .byte  244

MUSICDATA:
                    .byte  140   ; Loop start point * 2
                    .byte  142   ; Song Length * 2
PATTERNDATA:        .word       PAT2
                    .word       PAT3
                    .word       PAT0
                    .word       PAT1
                    .word       PAT0
                    .word       PAT7
                    .word       PAT4
                    .word       PAT6
                    .word       PAT5
                    .word       PAT19
                    .word       PAT13
                    .word       PAT8
                    .word       PAT9
                    .word       PAT13
                    .word       PAT8
                    .word       PAT9
                    .word       PAT13
                    .word       PAT8
                    .word       PAT9
                    .word       PAT10
                    .word       PAT13
                    .word       PAT8
                    .word       PAT9
                    .word       PAT13
                    .word       PAT8
                    .word       PAT9
                    .word       PAT13
                    .word       PAT8
                    .word       PAT9
                    .word       PAT10
                    .word       PAT13
                    .word       PAT11
                    .word       PAT9
                    .word       PAT13
                    .word       PAT11
                    .word       PAT9
                    .word       PAT13
                    .word       PAT11
                    .word       PAT9
                    .word       PAT12
                    .word       PAT13
                    .word       PAT11
                    .word       PAT9
                    .word       PAT13
                    .word       PAT11
                    .word       PAT9
                    .word       PAT13
                    .word       PAT11
                    .word       PAT9
                    .word       PAT12
                    .word       PAT14
                    .word       PAT15
                    .word       PAT16
                    .word       PAT14
                    .word       PAT17
                    .word       PAT14
                    .word       PAT15
                    .word       PAT16
                    .word       PAT14
                    .word       PAT17
                    .word       PAT20
                    .word       PAT20
                    .word       PAT20
                    .word       PAT21
                    .word       PAT4
                    .word       PAT6
                    .word       PAT22
                    .word       PAT23
                    .word       PAT26
                    .word       PAT27
                    .word       PAT28

; *** Pattern data consists of pairs of frequency values CH1,CH2 with a single $FE to
; *** Mark the end of the pattern, and $01 for a rest
PAT0:
         .byte  13  ; Pattern tempo
             .byte  240,240
             .byte  240,121
             .byte  81,121
             .byte  61,121
             .byte  240,240
             .byte  240,121
             .byte  240,240
             .byte  240,121
             .byte  121,40
             .byte  121,40
             .byte  81,45
             .byte  121,40
             .byte  81,121
             .byte  61,121
             .byte  240,51
             .byte  54,121
             .byte  240,240
             .byte  240,121
             .byte  61,121
             .byte  121,19
             .byte  240,240
             .byte  240,121
             .byte  240,240
             .byte  240,121
             .byte  1,121
             .byte  1,121
             .byte  81,121
             .byte  61,121
             .byte  240,240
             .byte  51,121
             .byte  240,240
             .byte  45,121
             .byte  203,203
             .byte  203,102
             .byte  40,102
             .byte  45,102
             .byte  203,203
             .byte  203,102
             .byte  203,203
             .byte  203,102
             .byte  40,102
             .byte  45,102
             .byte  81,102
             .byte  40,102
             .byte  81,102
             .byte  54,102
             .byte  203,203
             .byte  51,102
             .byte  180,180
             .byte  180,91
             .byte  91,45
             .byte  51,91
             .byte  180,180
             .byte  180,91
             .byte  180,180
             .byte  180,91
             .byte  180,180
             .byte  180,91
             .byte  171,86
             .byte  171,86
             .byte  180,180
             .byte  180,86
             .byte  171,86
             .byte  171,86
         .byte  $FE
PAT1:
         .byte  13  ; Pattern tempo
             .byte  240,240
             .byte  240,121
             .byte  81,121
             .byte  61,121
             .byte  240,240
             .byte  240,121
             .byte  240,240
             .byte  240,121
             .byte  121,40
             .byte  121,40
             .byte  81,45
             .byte  121,40
             .byte  81,121
             .byte  61,121
             .byte  240,51
             .byte  54,121
             .byte  240,240
             .byte  240,121
             .byte  61,121
             .byte  121,19
             .byte  240,240
             .byte  240,121
             .byte  240,240
             .byte  240,121
             .byte  1,121
             .byte  1,121
             .byte  81,121
             .byte  61,121
             .byte  240,240
             .byte  51,121
             .byte  240,240
             .byte  45,121
             .byte  203,203
             .byte  203,136
             .byte  40,136
             .byte  45,136
             .byte  203,203
             .byte  203,136
             .byte  203,203
             .byte  203,136
             .byte  40,136
             .byte  45,136
             .byte  81,136
             .byte  40,136
             .byte  81,136
             .byte  54,136
             .byte  203,203
             .byte  51,136
             .byte  180,180
             .byte  180,91
             .byte  91,23
             .byte  180,91
             .byte  180,180
             .byte  180,91
             .byte  180,23
             .byte  180,91
             .byte  180,23
             .byte  180,23
             .byte  171,40
             .byte  171,38
             .byte  34,23
             .byte  180,38
             .byte  40,23
             .byte  171,45
         .byte  $FE
PAT2:
         .byte  13  ; Pattern tempo
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  240,240
             .byte  240,1
             .byte  203,203
             .byte  203,1
             .byte  1,1
             .byte  1,1
             .byte  203,203
             .byte  203,1
             .byte  203,203
             .byte  203,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  203,203
             .byte  1,1
             .byte  180,180
             .byte  180,1
             .byte  1,1
             .byte  1,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  171,171
             .byte  171,1
             .byte  180,180
             .byte  180,1
             .byte  171,171
             .byte  171,1
         .byte  $FE
PAT3:
         .byte  13  ; Pattern tempo
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  240,240
             .byte  240,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  240,240
             .byte  240,1
             .byte  240,240
             .byte  240,1
             .byte  203,203
             .byte  203,1
             .byte  1,1
             .byte  1,1
             .byte  203,203
             .byte  203,1
             .byte  203,203
             .byte  203,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  203,203
             .byte  203,1
             .byte  180,180
             .byte  180,1
             .byte  1,1
             .byte  1,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  180,180
             .byte  180,1
             .byte  171,171
             .byte  171,1
             .byte  180,23
             .byte  180,1
             .byte  171,23
             .byte  171,1
         .byte  $FE
PAT4:
         .byte  13  ; Pattern tempo
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,40
             .byte  161,45
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,45
             .byte  161,51
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,51
             .byte  161,54
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,54
             .byte  81,30
             .byte  203,30
             .byte  203,81
             .byte  136,136
             .byte  136,81
             .byte  203,0
             .byte  203,81
             .byte  136,54
             .byte  136,51
             .byte  203,30
             .byte  203,151
             .byte  151,81
             .byte  151,151
             .byte  203,0
             .byte  203,151
             .byte  151,51
             .byte  151,45
             .byte  161,30
             .byte  161,81
             .byte  81,161
             .byte  81,81
             .byte  161,0
             .byte  161,81
             .byte  81,40
             .byte  81,38
             .byte  161,30
             .byte  161,68
             .byte  81,161
             .byte  81,68
             .byte  161,0
             .byte  161,40
             .byte  68,0
             .byte  81,54
         .byte  $FE
PAT5:
         .byte  13  ; Pattern tempo
             .byte  240,30
             .byte  240,81
             .byte  161,61
             .byte  161,81
             .byte  240,0
             .byte  61,81
             .byte  161,40
             .byte  161,45
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,61
             .byte  240,0
             .byte  61,81
             .byte  161,45
             .byte  161,51
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,51
             .byte  161,54
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,54
             .byte  81,30
             .byte  203,30
             .byte  203,81
             .byte  136,136
             .byte  136,81
             .byte  203,0
             .byte  203,81
             .byte  136,54
             .byte  136,51
             .byte  203,30
             .byte  203,151
             .byte  151,81
             .byte  151,151
             .byte  203,0
             .byte  203,151
             .byte  151,51
             .byte  151,45
             .byte  161,30
             .byte  161,81
             .byte  81,161
             .byte  81,81
             .byte  161,0
             .byte  161,81
             .byte  81,40
             .byte  81,38
             .byte  161,30
             .byte  161,68
             .byte  81,161
             .byte  81,68
             .byte  161,0
             .byte  161,40
             .byte  68,0
             .byte  81,54
         .byte  $FE
PAT6:
         .byte  13  ; Pattern tempo
             .byte  240,30
             .byte  240,81
             .byte  161,61
             .byte  161,81
             .byte  240,0
             .byte  61,81
             .byte  161,40
             .byte  161,45
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,61
             .byte  240,0
             .byte  240,81
             .byte  61,45
             .byte  161,51
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,51
             .byte  161,54
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,54
             .byte  161,30
             .byte  203,30
             .byte  203,68
             .byte  136,136
             .byte  136,68
             .byte  203,0
             .byte  203,68
             .byte  136,54
             .byte  136,51
             .byte  203,30
             .byte  203,151
             .byte  151,61
             .byte  151,151
             .byte  203,0
             .byte  203,151
             .byte  151,51
             .byte  151,45
             .byte  161,30
             .byte  161,121
             .byte  81,161
             .byte  81,121
             .byte  161,0
             .byte  161,121
             .byte  81,40
             .byte  81,38
             .byte  161,30
             .byte  161,68
             .byte  81,161
             .byte  81,68
             .byte  161,0
             .byte  161,40
             .byte  68,23
             .byte  81,54
         .byte  $FE
PAT7:
         .byte  13  ; Pattern tempo
             .byte  240,240
             .byte  240,121
             .byte  81,121
             .byte  61,121
             .byte  240,240
             .byte  240,121
             .byte  240,240
             .byte  240,121
             .byte  121,40
             .byte  121,40
             .byte  81,45
             .byte  121,40
             .byte  81,121
             .byte  61,121
             .byte  240,51
             .byte  54,121
             .byte  240,240
             .byte  240,121
             .byte  61,121
             .byte  121,19
             .byte  240,240
             .byte  240,121
             .byte  240,240
             .byte  240,121
             .byte  1,121
             .byte  1,121
             .byte  81,121
             .byte  61,121
             .byte  240,240
             .byte  51,121
             .byte  240,240
             .byte  45,121
             .byte  203,203
             .byte  203,136
             .byte  40,136
             .byte  45,136
             .byte  203,203
             .byte  203,136
             .byte  203,203
             .byte  203,136
             .byte  40,136
             .byte  45,136
             .byte  81,136
             .byte  40,136
             .byte  81,136
             .byte  54,136
             .byte  203,203
             .byte  51,136
             .byte  180,21
             .byte  180,91
             .byte  91,21
             .byte  180,91
             .byte  180,21
             .byte  180,91
             .byte  180,21
             .byte  180,91
             .byte  180,21
             .byte  86,21
             .byte  81,20
             .byte  76,19
             .byte  72,18
             .byte  68,17
             .byte  64,16
             .byte  61,0
         .byte  $FE
PAT8:
         .byte  52  ; Pattern tempo
             .byte  144,144
         .byte  $FE
PAT9:
         .byte  13  ; Pattern tempo
             .byte  144,48
             .byte  144,48
         .byte  $FE
PAT10:
         .byte  28  ; Pattern tempo
             .byte  161,161
             .byte  161,161
             .byte  161,161
         .byte  $FE
PAT11:
         .byte  52  ; Pattern tempo
             .byte  144,121
         .byte  $FE
PAT12:
         .byte  28  ; Pattern tempo
             .byte  161,128
             .byte  161,128
             .byte  161,128
         .byte  $FE
PAT13:
         .byte  4  ; Pattern tempo
             .byte  144,144
         .byte  $FE
PAT14:
         .byte  19  ; Pattern tempo
             .byte  144,16
             .byte  144,40
             .byte  72,48
             .byte  61,48
             .byte  144,48
             .byte  144,48
             .byte  72,48
             .byte  61,40
             .byte  144,40
             .byte  144,40
             .byte  72,54
             .byte  61,54
             .byte  136,54
             .byte  136,61
             .byte  136,54
             .byte  136,54
         .byte  $FE
PAT15:
         .byte  19  ; Pattern tempo
             .byte  144,48
             .byte  144,48
             .byte  72,48
             .byte  61,48
             .byte  144,54
             .byte  144,54
             .byte  72,61
             .byte  61,68
             .byte  144,61
             .byte  144,61
             .byte  144,72
             .byte  144,61
         .byte  $FE
PAT16:
         .byte  34  ; Pattern tempo
             .byte  161,23
             .byte  161,23
         .byte  $FE
PAT17:
         .byte  19  ; Pattern tempo
             .byte  144,48
             .byte  144,48
             .byte  72,48
             .byte  61,48
             .byte  144,48
             .byte  144,48
             .byte  72,48
             .byte  61,48
             .byte  144,180
             .byte  144,180
             .byte  72,180
             .byte  61,180
             .byte  215,121
             .byte  215,121
             .byte  180,121
             .byte  108,121
         .byte  $FE
PAT19:
         .byte  13  ; Pattern tempo
             .byte  240,30
             .byte  240,81
             .byte  161,61
             .byte  161,81
             .byte  240,0
             .byte  61,81
             .byte  161,40
             .byte  161,45
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,61
             .byte  240,0
             .byte  240,81
             .byte  61,45
             .byte  161,51
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,51
             .byte  161,54
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  161,54
             .byte  161,30
             .byte  203,30
             .byte  203,68
             .byte  136,136
             .byte  136,68
             .byte  203,0
             .byte  203,68
             .byte  136,54
             .byte  136,51
             .byte  203,30
             .byte  203,151
             .byte  151,61
             .byte  151,151
             .byte  203,0
             .byte  203,151
             .byte  151,51
             .byte  151,45
             .byte  161,30
             .byte  161,121
             .byte  81,161
             .byte  81,121
             .byte  161,0
             .byte  161,121
             .byte  81,40
             .byte  81,38
             .byte  161,30
             .byte  161,68
             .byte  81,161
             .byte  81,68
             .byte  161,0
             .byte  161,40
             .byte  68,23
         .byte  $FE
PAT20:
         .byte  13  ; Pattern tempo
             .byte  1,30
             .byte  1,1
             .byte  1,30
             .byte  1,30
             .byte  1,0
             .byte  1,1
             .byte  1,0
             .byte  1,0
             .byte  1,30
             .byte  1,1
             .byte  1,1
             .byte  1,30
             .byte  1,0
             .byte  1,1
             .byte  1,0
             .byte  1,1
         .byte  $FE
PAT21:
         .byte  7  ; Pattern tempo
             .byte  1,28
             .byte  1,28
             .byte  1,1
             .byte  1,1
             .byte  1,28
             .byte  1,1
             .byte  1,28
             .byte  1,1
             .byte  1,0
             .byte  1,16
             .byte  1,17
             .byte  1,18
             .byte  1,19
             .byte  1,20
             .byte  1,0
             .byte  1,21
             .byte  1,28
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,28
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,28
             .byte  1,1
             .byte  1,1
             .byte  1,1
         .byte  $FE
PAT22:
         .byte  13  ; Pattern tempo
             .byte  240,30
             .byte  240,81
             .byte  161,30
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  40,0
             .byte  161,45
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  45,0
             .byte  161,51
             .byte  240,23
             .byte  240,81
             .byte  161,161
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  51,30
             .byte  161,54
             .byte  240,30
             .byte  240,81
             .byte  161,30
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  161,54
             .byte  81,0
             .byte  203,30
             .byte  203,81
             .byte  136,136
             .byte  136,81
             .byte  203,0
             .byte  203,81
             .byte  54,30
             .byte  136,51
             .byte  203,30
             .byte  203,151
             .byte  151,30
             .byte  151,30
             .byte  203,0
             .byte  203,151
             .byte  51,0
             .byte  151,45
             .byte  161,30
             .byte  161,81
             .byte  81,30
             .byte  81,30
             .byte  161,0
             .byte  161,81
             .byte  81,40
             .byte  81,38
             .byte  161,30
             .byte  161,68
             .byte  81,30
             .byte  81,30
             .byte  161,18
             .byte  161,20
             .byte  68,23
             .byte  81,25
         .byte  $FE
PAT23:
         .byte  13  ; Pattern tempo
             .byte  240,30
             .byte  240,81
             .byte  161,161
             .byte  161,81
             .byte  240,0
             .byte  240,81
             .byte  40,30
             .byte  161,45
             .byte  240,30
             .byte  240,81
             .byte  161,30
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  45,0
             .byte  161,51
             .byte  240,23
             .byte  240,81
             .byte  161,161
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  51,30
             .byte  161,54
             .byte  240,30
             .byte  240,81
             .byte  161,30
             .byte  161,30
             .byte  240,0
             .byte  240,81
             .byte  161,54
             .byte  81,0
             .byte  203,30
             .byte  203,81
             .byte  136,136
             .byte  136,81
             .byte  203,0
             .byte  203,81
             .byte  54,30
             .byte  136,51
             .byte  203,30
             .byte  203,151
             .byte  151,30
             .byte  151,30
             .byte  203,0
             .byte  203,151
             .byte  51,0
             .byte  151,45
             .byte  161,30
             .byte  161,81
             .byte  81,30
             .byte  81,30
             .byte  161,0
             .byte  161,81
             .byte  81,40
             .byte  81,38
             .byte  161,30
             .byte  161,68
             .byte  81,30
             .byte  81,30
             .byte  161,18
             .byte  161,20
             .byte  68,23
             .byte  81,25
         .byte  $FE
PAT26:
         .byte  10  ; Pattern tempo
             .byte  1,16
             .byte  144,1
             .byte  144,121
             .byte  144,96
             .byte  1,1
         .byte  $FE
PAT27:
         .byte  61  ; Pattern tempo
             .byte  144,72
             .byte  144,0
             .byte  144,16
             .byte  144,20
             .byte  144,25
             .byte  144,28
             .byte  1,1
             .byte  144,30
         .byte  $FE
PAT28:
         .byte  22  ; Pattern tempo
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
             .byte  1,1
         .byte  $FE


		end		start