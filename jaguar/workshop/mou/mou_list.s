;
; Jaguar Example Source Code
; Jaguar Workshop Series #1
; Copyright (c)1994 Atari Corp.
; ALL RIGHTS RESERVED
;
; Program: mou.cof      - Minimum time object list update
;  Module: mou_list.s   - Object List Refresh and Initialization
;
; Revision History:
; 6/4/94   - SDS: Created
; 6/13/94  - SDS: Added scr_height and scr_width variables for centering.
;                 Deleted copy_list routine and changed it to copy_phrases in
;                 mou_init.s.

		.include        "jaguar.inc"
		.include        "mou.inc"

		.globl          InitLister
		.globl		UpdateList

		.extern         a_vde
		.extern         a_vdb
		.extern         a_hdb
		.extern         a_hde
		.extern		width
		.extern		height
		.extern		jagbits

		.text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitLister: Initialize Object List Processor List
;
;    Returns: Pre-word-swapped address of current object list in d0.l
;
;  Registers: d1.l/d0.l - Phrase being built
;             d2.l      - Address of STOP object in destination buffer
;             d3.l      - Calculation register
;             d4.l      - Width of image in phrases
;             d5.l      - Height of image in scanlines
;             a0.l      - Roving object list pointer
		
InitLister:
		movem.l d1-d5/a0,-(sp)		; Save registers
			
		lea     main_obj_list,a0
		move.l	a0,d2			; Copy

		add.l   #(LISTSIZE-1)*8,d2	; Address of STOP object

; Write first BRANCH object (branch if YPOS > a_vde )

		clr.l   d1
		move.l  #(BRANCHOBJ|O_BRLT),d0	; $4000 = VC < YPOS
		jsr     format_link             ; Stuff in our LINK address
						
		move.w  a_vde,d3                ; for YPOS
		lsl.w   #3,d3                   ; Make it bits 13-3
		or.w    d3,d0

		move.l  d1,(a0)+                                
		move.l  d0,(a0)+                ; First OBJ is done.

; Write second branch object (branch if YPOS < a_vdb)   
; Note: LINK address is the same so preserve it

		andi.l  #$FF000007,d0           ; Mask off CC and YPOS
		ori.l   #O_BRGT,d0		; $8000 = VC > YPOS
		move.w  a_vdb,d3                ; for YPOS
		lsl.w   #3,d3                   ; Make it bits 13-3
		or.w    d3,d0

		move.l  d1,(a0)+                ; Second OBJ is done
		move.l  d0,(a0)+        

; Write a standard BITMAP object
		clr.l   d1
		clr.l   d0                      ; Type = BITOBJ
			
		jsr     format_link

		move.l  #BMP_HEIGHT,d5          ; Height of image
		lsl.l   #8,d5                   ; HEIGHT
		lsl.l   #6,d5
		or.l    d5,d0

		move.w  height,d3         	; Center bitmap vertically
		sub.w   #BMP_HEIGHT,d3
		add.w   a_vdb,d3
		andi.w  #$FFFE,d3               ; Must be even

		lsl.w   #3,d3
		or.w    d3,d0                   ; Stuff YPOS in low phrase

		move.l  #jagbits,d3
		andi.l  #$FFFFF0,d3
		lsl.l   #8,d3                   ; Shift bitmap_addr into position
		or.l    d3,d1
     
		move.l  d1,(a0)+
		move.l	d1,bmp_highl
		move.l  d0,(a0)+
		move.l	d0,bmp_lowl

		move.l  #O_TRANS,d1             ; Now for PHRASE 2 of BITOBJ
		move.l  #O_DEPTH16|O_NOGAP,d0   ; Bit Depth = 16-bit, Contiguous data

		move.w	width,d3		; Get width in clocks
		lsr.w	#2,d3			; /4 Pixel Divisor
		sub.w   #BMP_WIDTH,d3
		lsr.w   #1,d3
		or.w    d3,d0

		move.l  #BMP_PHRASES,d4 
		move.l  d4,d3                   ; Copy for below

		lsl.l   #8,d4                   ; DWIDTH
		lsl.l   #8,d4
		lsl.l   #2,d4
		or.l    d4,d0

		lsl.l   #8,d4                   ; IWIDTH Bits 28-31
		lsl.l   #2,d4
		or.l    d4,d0

		lsr.l   #4,d3                   ; IWIDTH Bits 37-32
		or.l    d3,d1

		move.l  d1,(a0)+                ; Write second PHRASE of BITOBJ
		move.l  d0,(a0)+

; Write a STOP object at end of list
		clr.l   d1
		move.l  #(STOPOBJ|O_STOPINTS),d0

		move.l  d1,(a0)+                
		move.l  d0,(a0)+

; Now return swapped list pointer in D0                      

		move.l	#main_obj_list,d0  
		swap    d0

		movem.l (sp)+,d1-d5/a0
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Procedure: format_link
;
;    Inputs: d1.l/d0.l is a 64-bit phrase
;            d2.l contains the LINK address to put into bits 42-24 of phrase
;
;   Returns: Updated phrase in d1.l/d0.l

format_link:
		movem.l d2-d3,-(sp)

		andi.l  #$3FFFF8,d2             ; Ensure alignment/valid address
		move.l  d2,d3                   ; Make a copy

		swap	d2                   	; Put bits 10-3 in bits 31-24
		clr.w	d2
		lsl.l   #5,d2
		or.l    d2,d0

		lsr.l   #8,d3                   ; Put bits 21-11 in bits 42-32
		lsr.l   #3,d3
		or.l    d3,d1

		movem.l (sp)+,d2-d3             ; Restore regs
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateList: Update list fields destroyed by the object processor.
;
;  Registers:	a0.l      - General Purpose Pointer

UpdateList:
		move.l	a0,-(sp)

		move.l	#main_obj_list+BITMAP_OFF,a0

		move.l	bmp_highl,(a0)		; Phrase = d1.l/d0.l
		move.l	bmp_lowl,4(a0)

		move.w	#$101,INT1		; Signal we're done
		move.w	#$0,INT2

		move.l	(sp)+,a0
		rte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Storage space for our object lists

		.bss
		.dphrase			

main_obj_list:
		.ds.l           LISTSIZE*2
bmp_highl:
		.ds.l		1
bmp_lowl:
		.ds.l		1

		.end
