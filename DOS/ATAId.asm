;*******************************************************************************
;* ATAId.ASM - �����䨪��� ���ன�� ATA/ATAPI                               *
;* ����� 1.02 (������� 2009 �.)                                              *
;*                                                                             *
;* OS: DOS                                                                     *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************

LOCALS

.MODEL	SMALL


.CODE

PUBLIC	IdentifyATAPIDevice
PUBLIC	IdentifyATADevice
PUBLIC	IdentifyDevice
PUBLIC	DetectATAPIDevice

;*******************************************************************************
; IdentifyATAPIDevice	�����䨪��� ���ன�⢠ ATAPI
;*******************************************************************************
; �ᯮ����:	DevWait
;
; �맮�:	DX = ������ ����
;		AL = ����� ���ன�⢠
;		ES:DI -> ���� ��� ���ଠ樨 �� ���ன�⢥
;		         (������� ATAPI_DEVICE_INFO)
;
; ������:	CF = 䫠� �ᯥ譮��/��㤠筮�� �����襭��
;
; �����塞�
;   ॣ�����:	AX, BL, CX, DX, Flags
;*******************************************************************************
IdentifyATAPIDevice	PROC

		mov	bl,0A1h		; BL=0A1h (������� �����䨪�樨
					; ���ன�⢠ ATAPI)
		jmp	IdentifyDevice

;*******************************************************************************
; IdentifyATADevice	�����䨪��� ���ன�⢠ ATA
;*******************************************************************************
; �ᯮ����:	DevWait
;
; �맮�:	DX = ������ ����
;		AL = ����� ���ன�⢠
;		ES:DI -> ���� ��� ���ଠ樨 �� ���ன�⢥
;		         (������� ATA_DEVICE_INFO)
;
; ������:	CF = 䫠� �ᯥ譮��/��㤠筮�� �����襭��
;
; �����塞�
;   ॣ�����:	AX, BL, CX, DX, Flags
;*******************************************************************************
IdentifyATADevice:
		mov	bl,0ECh		; BL=0ECh (������� �����䨪�樨
					; ���ன�⢠ ATA)

;*******************************************************************************
; IdentifyDevice	�����䨪��� ���ன�⢠ ATA/ATAPI
;*******************************************************************************
; �ᯮ����:	DevWait
;
; �맮�:	BL = ������� �����䨪�樨 ���ன�⢠
;		DX = ������ ����
;		AL = ����� ���ன�⢠
;		ES:DI -> ���� ��� ���ଠ樨 �� ���ன�⢥
;		         (������� ATA_DEVICE_INFO)
;
; ������:	CF = 䫠� �ᯥ譮��/��㤠筮�� �����襭��
;
; �����塞�
;   ॣ�����:	AX, BL, CX, DX, Flags
;*******************************************************************************
IdentifyDevice:
		and	al,1
		mov	cl,4
		shl	al,cl
		or	al,0A0h
		add	dx,6		; DX = ॣ���� �롮� ���ன�⢠/�������
		out	dx,al		; �롮� ���ன�⢠

		inc	dx		; DX = ॣ���� �������/���ﭨ�
		in	al,dx		; AL = ���� ���ﭨ� ���ன�⢠
		cmp	al,0FFh
		je	@@Error

		call	DevWait
		jc	@@Error

		mov	al,bl
		out	dx,al		; ������� �����䨪�樨 ���ன�⢠

		call	DevWait
		jc	@@Error

		mov	cx,100h
@@WaitLoop:	in	al,dx		; AL = ���� ���ﭨ� ���ன�⢠
		test	al,8		; ��⠭����� ��� DRQ?
		jnz	@@Ok
		loop	@@WaitLoop

@@Error:	stc

		ret

@@Ok:		sub	dx,7		; DX = ॣ���� ������

		push	di

		mov	cx,100h
		cld
		cli
@@ReadInfoLoop:	in	ax,dx		; �⥭�� ������
		stosw
		loop	@@ReadInfoLoop
		sti

		pop	di

		add	dx,7		; DX = ॣ���� �������/���ﭨ�
		in	al,dx		; AL = ���� ���ﭨ� ���ன�⢠
		and	al,71h
		cmp	al,50h
		jne	@@Error

		push	di

		add	di,14h
		mov	cx,20 / 2
@@SerNumLoop:	mov	ax,es:[di]
		xchg	al,ah
		stosw
		loop	@@SerNumLoop

		add	di,6
		mov	cl,(8 + 40) / 2
@@ModelNumLoop:	mov	ax,es:[di]
		xchg	al,ah
		stosw
		loop	@@ModelNumLoop

		pop	di

		clc

		ret

IdentifyATAPIDevice	ENDP

;*******************************************************************************
; DetectATAPIDevice	��।������ ������ ���ன�⢠ ATAPI
;*******************************************************************************
; �ᯮ����:	DevWait
;
; �맮�:	DX = ������ ����
;		AL = ����� ���ன�⢠
;
; ������:	CF = 䫠� �ᯥ譮��/��㤠筮�� �����襭��
;
; �����塞�
;   ॣ�����:	AX, CX, DX, Flags
;*******************************************************************************
DetectATAPIDevice	PROC

		and	al,1
		mov	cl,4
		shl	al,cl
		or	al,0A0h
		add	dx,6		; DX = ॣ���� �롮� ���ன�⢠/�������
		out	dx,al		; �롮� ���ன�⢠

		inc	dx		; DX = ॣ���� �������/���ﭨ�
		in	al,dx		; AL = ���� ���ﭨ� ���ன�⢠
		cmp	al,0FFh
		je	@@NoDevice

		call	DevWait
		jc	@@NoDevice

;		mov	al,8		; AL=8 (������� ��饣� ���)
;		out	dx,al
;
;		call	DevWait
;		jc	@@NoDevice

		sub	dx,3		; DX = ॣ���� 樫���� (����訩 ����)
		xor	al,al
		out	dx,al
		inc	dx		; DX = ॣ���� 樫���� (���訩 ����)
		out	dx,al

		inc	dx
		inc	dx		; DX = ॣ���� �������/���ﭨ�
		mov	al,0ECh		; AL=0ECh (������� �����䨪�樨 ���ன�⢠)
		out	dx,al

		call	DevWait
		jc	@@NoDevice

		sub	dx,3		; DX = ॣ���� 樫���� (����訩 ����)
		in	al,dx
		mov	ah,al
		inc	dx		; DX = ॣ���� 樫���� (���訩 ����)
		in	al,dx
		cmp	ax,14EBh
		je	@@Exit

@@NoDevice:	stc

@@Exit:		ret

DetectATAPIDevice	ENDP

;*******************************************************************************
; DevWait	��������, ���� ���ன�⢮ �����
;*******************************************************************************
; �ᯮ����:	���
;
; �맮�:	DX = ॣ���� �������/���ﭨ�
;
; ������:	CF = 䫠� �ᯥ譮��/��㤠筮�� �����襭��
;
; �����塞�
;   ॣ�����:	AX, CX, Flags
;*******************************************************************************
DevWait		PROC

		mov	ah,14h
@@WaitLoop1:	xor	cx,cx
@@WaitLoop2:	in	al,dx		; AL = ���� ���ﭨ� ���ன�⢠
		test	al,80h		; ���ன�⢮ �����?
		jz	@@Exit
		loop	@@WaitLoop2
		dec	ah
		jnz	@@WaitLoop1

		stc

@@Exit:		ret

DevWait		ENDP


END
