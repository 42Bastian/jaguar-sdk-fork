;
; Jaguar Example Source Code
; Jaguar Workshop Series #4
; Copyright (c)1994 Atari Corp.
; ALL RIGHTS RESERVED
;
; Program: scale.cof	- Object Scaling Example
;  Module: scl_init.s	- Program entry and initialization
;
; Revision History:
; 6/19/94   - SDS: Copied from clp_init.s sources
;----------------------------------------------------------------------------
; This Jaguar sample program initializes the Jaguar console and sets up
; video. An object list of two branch objects (required), a single scalable
; bitmap object pointing to a 16-bit CRY Jaguar logo, and a STOP object
; is then constructed.
;
; During each frame interrupt a series of routines are called to adjust the
; scaling of the bitmap and update and refresh the object list as necessary.
;

		.include	"jaguar.inc"
		.include	"scale.inc"

; Globals
		.globl		a_vdb
		.globl		a_vde
		.globl		a_hdb
		.globl		a_hde
		.globl		width
		.globl		height
; Externals

		.extern		InitLister
		.extern		UpdateList
		.extern		InitScaleVars
		.extern		ScaleBitmap
		.extern		jagbits
		.extern		main_obj_list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Program Entry Point Follows...

		.text

		move.l	#$00070007,G_END	; big-endian mode
		move.w	#$FFFF,VI		; disable interrupts

		move.l	#INITSTACK,a7		; Point stack pointer at end of RAM
			
		jsr	InitVideo		; Setup our video registers.
		jsr	InitScaleVars		; Setup Variables
		jsr	InitLister		; Initialize Object Display List
		jsr	InitVBint		; Initialize our VBLANK routine

		move.l	d0,OLP			; Value in D0 from InitLister
		move.w	#$6C1,VMODE		; Configure Video

		illegal				; Bye bye...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Procedure: InitVBint 
; Install our vertical blank handler and enable interrupts
;
;

InitVBint:
		move.l	d0,-(sp)

		move.l	#UpdateList,LEVEL0	; Install our Auto-Vector 0 handler

		move.w	a_vde,d0
		ori.w	#1,d0			; Must be ODD
		move.w	d0,VI

		move.w	INT1,d0
		or.w	#$1,d0			; Turn on the video interrupts
		move.w	d0,INT1

		move.w	sr,d0
		and.w	#$F8FF,d0		; Lower the 68k IPL to allow interrupts
		move.w	d0,sr

		move.l	(sp)+,d0
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Procedure: InitVideo (same as in vidinit.s)
;            Build values for hdb, hde, vdb, and vde and store them.
;
 						
InitVideo:
		move.l	d0,-(sp)		; Save the one register we use
	
		move.w	CONFIG,d0		; Also is joystick register
		andi.w	#VIDTYPE,d0		; 0 = PAL, 1 = NTSC
		beq	palvals

		move.w	#NTSC_HMID,d2
		move.w	#NTSC_WIDTH,d0

		move.w	#NTSC_VMID,d6
		move.w	#NTSC_HEIGHT,d4

		bra	calc_vals
palvals:
		move.w	#PAL_HMID,d2
		move.w	#PAL_WIDTH,d0

		move.w	#PAL_VMID,d6
		move.w	#PAL_HEIGHT,d4

calc_vals:
		move.w	d0,width
		move.w	d4,height

		move.w	d0,d1
		asr	#1,d1			; Width/2

		sub.w	d1,d2			; Mid - Width/2
		add.w	#4,d2			; (Mid - Width/2)+4

		sub.w	#1,d1			; Width/2 - 1
		ori.w	#$400,d1		; (Width/2 - 1)|$400
		
		move.w	d1,a_hde
		move.w	d1,HDE

		move.w	d2,a_hdb
		move.w	d2,HDB1
		move.w	d2,HDB2

		move.w	d6,d5
		sub.w	d4,d5
		move.w	d5,a_vdb

		add.w	d4,d6
		move.w	d6,a_vde

		move.w	a_vdb,VDB
		move.w	#$FFFF,VDE
			
		move.l	#0,BORD1		; Black border
		move.w	#0,BG			; Init line buffer to black
			
		move.l	(sp)+,d0
		rts
		
;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Uninitialized Data!!!
;;;;;;;;;;;;;;;;;;;;;;;;;;

		.bss

a_hdb:		.ds.w	1
a_hde:		.ds.w	1
a_vdb:		.ds.w	1
a_vde:		.ds.w	1
width:		.ds.w	1
height:		.ds.w	1

		.end
	
