; Hang over Jaunt
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
                    .byte  0   ; Loop start point * 2
                    .byte  120   ; Song Length * 2
PATTERNDATA:        .word       PAT0
                    .word       PAT0
                    .word       PAT1
                    .word       PAT2
                    .word       PAT0
                    .word       PAT0
                    .word       PAT1
                    .word       PAT5
                    .word       PAT3
                    .word       PAT4
                    .word       PAT6
                    .word       PAT7
                    .word       PAT8
                    .word       PAT9
                    .word       PAT10
                    .word       PAT10
                    .word       PAT3
                    .word       PAT11
                    .word       PAT12
                    .word       PAT13
                    .word       PAT14
                    .word       PAT16
                    .word       PAT10
                    .word       PAT10
                    .word       PAT15
                    .word       PAT15
                    .word       PAT17
                    .word       PAT17
                    .word       PAT15
                    .word       PAT26
                    .word       PAT18
                    .word       PAT19
                    .word       PAT20
                    .word       PAT21
                    .word       PAT22
                    .word       PAT23
                    .word       PAT24
                    .word       PAT10
                    .word       PAT10
                    .word       PAT3
                    .word       PAT4
                    .word       PAT6
                    .word       PAT7
                    .word       PAT8
                    .word       PAT9
                    .word       PAT3
                    .word       PAT11
                    .word       PAT12
                    .word       PAT13
                    .word       PAT14
                    .word       PAT16
                    .word       PAT10
                    .word       PAT10
                    .word       PAT15
                    .word       PAT15
                    .word       PAT17
                    .word       PAT17
                    .word       PAT15
                    .word       PAT15
                    .word       PAT25

; *** Pattern data consists of pairs of frequency values CH1,CH2 with a single $FE to
; *** Mark the end of the pattern, and $01 for a rest
PAT0:
         .byte  13  ; Pattern tempo
             .byte  91,30
             .byte  121,180
             .byte  136,27
             .byte  144,180
             .byte  91,23
             .byte  121,180
             .byte  136,21
             .byte  144,180
             .byte  91,16
             .byte  121,180
             .byte  136,23
             .byte  144,180
             .byte  91,24
             .byte  108,180
             .byte  136,28
             .byte  144,180
         .byte  $FE
PAT1:
         .byte  13  ; Pattern tempo
             .byte  81,30
             .byte  108,161
             .byte  121,16
             .byte  128,161
             .byte  81,27
             .byte  108,161
             .byte  121,30
             .byte  128,161
             .byte  81,16
             .byte  108,161
             .byte  121,27
             .byte  128,161
             .byte  81,30
             .byte  96,161
             .byte  121,27
             .byte  128,161
         .byte  $FE
PAT2:
         .byte  13  ; Pattern tempo
             .byte  102,30
             .byte  136,203
             .byte  151,23
             .byte  161,203
             .byte  102,24
             .byte  136,203
             .byte  151,25
             .byte  161,203
             .byte  102,16
             .byte  136,203
             .byte  151,27
             .byte  161,203
             .byte  102,28
             .byte  121,203
             .byte  151,30
             .byte  161,203
         .byte  $FE
PAT3:
         .byte  13  ; Pattern tempo
             .byte  91,30
             .byte  91,180
             .byte  91,0
             .byte  91,203
             .byte  121,0
             .byte  121,240
             .byte  121,0
             .byte  121,180
             .byte  121,16
             .byte  121,180
             .byte  121,0
             .byte  121,203
             .byte  91,0
             .byte  91,240
             .byte  91,0
             .byte  91,180
         .byte  $FE
PAT4:
         .byte  13  ; Pattern tempo
             .byte  72,30
             .byte  72,180
             .byte  72,0
             .byte  72,203
             .byte  72,0
             .byte  72,240
             .byte  91,0
             .byte  91,180
             .byte  91,16
             .byte  91,180
             .byte  91,0
             .byte  91,203
             .byte  108,0
             .byte  108,240
             .byte  108,0
             .byte  108,180
         .byte  $FE
PAT5:
         .byte  13  ; Pattern tempo
             .byte  102,30
             .byte  136,203
             .byte  151,23
             .byte  161,203
             .byte  102,24
             .byte  136,203
             .byte  151,25
             .byte  161,203
             .byte  102,16
             .byte  136,203
             .byte  151,17
             .byte  161,18
             .byte  102,19
             .byte  121,20
             .byte  151,21
             .byte  161,23
         .byte  $FE
PAT6:
         .byte  13  ; Pattern tempo
             .byte  61,30
             .byte  61,161
             .byte  61,0
             .byte  61,240
             .byte  61,0
             .byte  61,192
             .byte  68,0
             .byte  68,161
             .byte  68,16
             .byte  68,161
             .byte  68,0
             .byte  68,240
             .byte  72,0
             .byte  72,192
             .byte  72,0
             .byte  72,161
         .byte  $FE
PAT7:
         .byte  13  ; Pattern tempo
             .byte  102,30
             .byte  102,203
             .byte  102,0
             .byte  102,240
             .byte  102,0
             .byte  102,151
             .byte  102,0
             .byte  102,203
             .byte  102,16
             .byte  102,203
             .byte  102,0
             .byte  102,240
             .byte  68,0
             .byte  68,151
             .byte  68,18
             .byte  68,203
         .byte  $FE
PAT8:
         .byte  13  ; Pattern tempo
             .byte  51,30
             .byte  51,180
             .byte  51,0
             .byte  51,203
             .byte  54,0
             .byte  54,240
             .byte  54,0
             .byte  54,180
             .byte  61,16
             .byte  61,180
             .byte  61,0
             .byte  61,203
             .byte  68,0
             .byte  68,240
             .byte  68,0
             .byte  68,180
         .byte  $FE
PAT9:
         .byte  13  ; Pattern tempo
             .byte  72,30
             .byte  72,180
             .byte  72,0
             .byte  72,203
             .byte  81,0
             .byte  81,240
             .byte  81,0
             .byte  81,180
             .byte  91,16
             .byte  91,180
             .byte  91,0
             .byte  91,203
             .byte  68,0
             .byte  68,240
             .byte  68,0
             .byte  68,180
         .byte  $FE
PAT10:
         .byte  13  ; Pattern tempo
             .byte  91,30
             .byte  121,180
             .byte  136,0
             .byte  144,180
             .byte  91,0
             .byte  121,180
             .byte  136,0
             .byte  144,180
             .byte  91,16
             .byte  121,180
             .byte  136,0
             .byte  144,180
             .byte  91,0
             .byte  108,180
             .byte  136,0
             .byte  144,180
         .byte  $FE
PAT11:
         .byte  13  ; Pattern tempo
             .byte  72,30
             .byte  72,180
             .byte  72,0
             .byte  72,203
             .byte  72,0
             .byte  72,240
             .byte  61,0
             .byte  61,180
             .byte  61,16
             .byte  61,180
             .byte  61,0
             .byte  61,203
             .byte  45,0
             .byte  45,240
             .byte  45,0
             .byte  45,180
         .byte  $FE
PAT12:
         .byte  13  ; Pattern tempo
             .byte  45,30
             .byte  40,161
             .byte  45,0
             .byte  45,240
             .byte  48,0
             .byte  48,192
             .byte  54,0
             .byte  48,161
             .byte  61,16
             .byte  61,161
             .byte  68,0
             .byte  68,240
             .byte  72,0
             .byte  68,192
             .byte  81,0
             .byte  81,161
         .byte  $FE
PAT13:
         .byte  13  ; Pattern tempo
             .byte  68,30
             .byte  61,203
             .byte  54,0
             .byte  51,240
             .byte  40,0
             .byte  40,151
             .byte  45,0
             .byte  51,203
             .byte  54,16
             .byte  61,203
             .byte  68,0
             .byte  72,240
             .byte  81,0
             .byte  91,151
             .byte  102,18
             .byte  108,203
         .byte  $FE
PAT14:
         .byte  13  ; Pattern tempo
             .byte  61,30
             .byte  61,180
             .byte  68,0
             .byte  72,203
             .byte  68,0
             .byte  61,240
             .byte  68,0
             .byte  72,180
             .byte  45,16
             .byte  45,180
             .byte  48,0
             .byte  54,203
             .byte  45,0
             .byte  40,240
             .byte  45,0
             .byte  48,180
         .byte  $FE
PAT15:
         .byte  13  ; Pattern tempo
             .byte  102,30
             .byte  136,203
             .byte  151,0
             .byte  161,203
             .byte  102,0
             .byte  136,203
             .byte  151,0
             .byte  161,203
             .byte  102,16
             .byte  136,203
             .byte  151,0
             .byte  161,203
             .byte  102,0
             .byte  121,203
             .byte  151,0
             .byte  161,203
         .byte  $FE
PAT16:
         .byte  13  ; Pattern tempo
             .byte  51,30
             .byte  54,180
             .byte  61,0
             .byte  68,203
             .byte  72,0
             .byte  81,240
             .byte  91,0
             .byte  102,180
             .byte  121,16
             .byte  121,180
             .byte  102,0
             .byte  102,203
             .byte  91,0
             .byte  91,240
             .byte  81,0
             .byte  81,180
         .byte  $FE
PAT17:
         .byte  13  ; Pattern tempo
             .byte  81,30
             .byte  108,161
             .byte  121,0
             .byte  128,161
             .byte  81,0
             .byte  108,161
             .byte  121,0
             .byte  128,161
             .byte  81,16
             .byte  108,161
             .byte  121,0
             .byte  128,161
             .byte  81,0
             .byte  96,161
             .byte  121,0
             .byte  128,161
         .byte  $FE
PAT18:
         .byte  13  ; Pattern tempo
             .byte  91,45
             .byte  121,180
             .byte  136,54
             .byte  144,180
             .byte  91,72
             .byte  121,180
             .byte  136,68
             .byte  144,180
             .byte  91,61
             .byte  121,180
             .byte  136,54
             .byte  144,180
             .byte  91,61
             .byte  108,180
             .byte  136,54
             .byte  144,180
         .byte  $FE
PAT19:
         .byte  13  ; Pattern tempo
             .byte  91,48
             .byte  121,180
             .byte  136,54
             .byte  144,180
             .byte  91,68
             .byte  121,180
             .byte  136,72
             .byte  144,180
             .byte  91,61
             .byte  121,180
             .byte  136,1
             .byte  144,180
             .byte  91,1
             .byte  108,180
             .byte  136,1
             .byte  144,180
         .byte  $FE
PAT20:
         .byte  13  ; Pattern tempo
             .byte  102,51
             .byte  136,203
             .byte  151,54
             .byte  161,203
             .byte  102,61
             .byte  136,203
             .byte  151,68
             .byte  161,203
             .byte  102,51
             .byte  136,203
             .byte  151,54
             .byte  161,203
             .byte  102,61
             .byte  121,203
             .byte  151,68
             .byte  161,203
         .byte  $FE
PAT21:
         .byte  13  ; Pattern tempo
             .byte  81,34
             .byte  108,161
             .byte  121,36
             .byte  128,161
             .byte  81,40
             .byte  108,161
             .byte  121,45
             .byte  128,161
             .byte  81,40
             .byte  108,161
             .byte  121,1
             .byte  128,161
             .byte  81,1
             .byte  96,161
             .byte  121,1
             .byte  128,161
         .byte  $FE
PAT22:
         .byte  13  ; Pattern tempo
             .byte  102,68
             .byte  136,203
             .byte  151,76
             .byte  161,203
             .byte  102,68
             .byte  136,203
             .byte  151,61
             .byte  161,203
             .byte  102,51
             .byte  136,203
             .byte  151,61
             .byte  161,203
             .byte  102,51
             .byte  121,203
             .byte  151,45
             .byte  161,203
         .byte  $FE
PAT23:
         .byte  13  ; Pattern tempo
             .byte  91,36
             .byte  121,180
             .byte  136,1
             .byte  144,180
             .byte  91,1
             .byte  121,180
             .byte  136,1
             .byte  144,180
             .byte  91,36
             .byte  121,180
             .byte  136,40
             .byte  144,180
             .byte  91,45
             .byte  108,180
             .byte  136,1
             .byte  144,180
         .byte  $FE
PAT24:
         .byte  13  ; Pattern tempo
             .byte  102,51
             .byte  136,203
             .byte  151,1
             .byte  161,203
             .byte  102,1
             .byte  136,203
             .byte  151,1
             .byte  161,203
             .byte  102,51
             .byte  136,203
             .byte  151,54
             .byte  161,203
             .byte  102,61
             .byte  121,203
             .byte  151,91
             .byte  161,203
         .byte  $FE
PAT25:
         .byte  22  ; Pattern tempo
             .byte  180,16
             .byte  1,91
             .byte  1,0
             .byte  1,1
             .byte  180,91
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
PAT26:
         .byte  13  ; Pattern tempo
             .byte  102,30
             .byte  136,203
             .byte  151,0
             .byte  161,203
             .byte  102,0
             .byte  136,203
             .byte  151,0
             .byte  161,203
             .byte  102,16
             .byte  136,203
             .byte  151,17
             .byte  161,18
             .byte  102,19
             .byte  121,20
             .byte  151,21
             .byte  161,23
         .byte  $FE


		end		start