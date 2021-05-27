;*******************************************************************************
;* ATAId32.ASM - ������������� ��������� ATA/ATAPI                             *
;* ������ 1.03 (�������� 2009 �.)                                              *
;*                                                                             *
;* OS: Win32                                                                   *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************

.386
LOCALS

.MODEL	FLAT


INCLUDE	ATA.inc


.CODE

PUBLIC	IdentifyATAPIDevice
PUBLIC	IdentifyATADevice
PUBLIC	IdentifyDevice
PUBLIC	DetectATAPIDevice
PUBLIC	CorrectATADeviceInfo
PUBLIC	GetATADeviceSizeInGB

;*******************************************************************************
; IdentifyATAPIDevice	������������� ���������� ATAPI
;*******************************************************************************
; ����������:	DevWait
;
; �����:	DX = ������� ����
;		AL = ����� ����������
;		EDI -> ����� ��� ���������� �� ����������
;		       (��������� ATAPI_DEVICE_INFO)
;
; �������:	CF = ���� ���������/���������� ����������
;
; ����������
;   ��������:	AX, ECX, DX, Flags
;*******************************************************************************
IdentifyATAPIDevice	PROC

		mov	ah,0A1h		; AH=0A1h (������� �������������
					; ���������� ATAPI)
		jmp	IdentifyDevice

;*******************************************************************************
; IdentifyATADevice	������������� ���������� ATA
;*******************************************************************************
; ����������:	DevWait
;
; �����:	DX = ������� ����
;		AL = ����� ����������
;		EDI -> ����� ��� ���������� �� ����������
;		       (��������� ATA_DEVICE_INFO)
;
; �������:	CF = ���� ���������/���������� ����������
;
; ����������
;   ��������:	AX, ECX, DX, Flags
;*******************************************************************************
IdentifyATADevice:
		mov	ah,0ECh		; AH=0ECh (������� �������������
					; ���������� ATA)

;*******************************************************************************
; IdentifyDevice	������������� ���������� ATA/ATAPI
;*******************************************************************************
; ����������:	DevWait
;
; �����:	AH = ������� ������������� ���������� (ATA - 0ECh, ATAPI - 0A1h)
;		DX = ������� ����
;		AL = ����� ����������
;		EDI -> ����� ��� ���������� �� ����������
;		       (��������� ATA_DEVICE_INFO)
;
; �������:	CF = ���� ���������/���������� ����������
;
; ����������
;   ��������:	AL, ECX, DX, Flags
;*******************************************************************************
IdentifyDevice:
		and	al,1
		shl	al,4
		or	al,0A0h
		add	dx,6		; DX = ������� ������ ����������/�������
		out	dx,al		; ����� ����������

		inc	dx		; DX = ������� �������/���������
		in	al,dx		; AL = ���� ��������� ����������
		cmp	al,0FFh
		je	@@Error

		call	DevWait
		jc	@@Error

		mov	al,ah
		out	dx,al		; ������� ������������� ����������

		call	DevWait
		jc	@@Error

		mov	ecx,100h
@@WaitLoop:	in	al,dx		; AL = ���� ��������� ����������
		test	al,8		; ���������� ��� DRQ?
		loopz	@@WaitLoop
		jz	@@Error

		sub	dx,7		; DX = ������� ������

		push	edi

		mov	ecx,100h
		cld
		cli
		rep	insw		; ������ ������
		sti

		pop	edi

		add	dx,7		; DX = ������� �������/���������
		in	al,dx		; AL = ���� ��������� ����������
		and	al,71h
		cmp	al,50h
		je	@@Exit

@@Error:	stc

@@Exit:		ret

IdentifyATAPIDevice	ENDP

;*******************************************************************************
; DetectATAPIDevice	����������� ������� ���������� ATAPI
;*******************************************************************************
; ����������:	DevWait
;
; �����:	DX = ������� ����
;		AL = ����� ����������
;
; �������:	CF = ���� ���������/���������� ����������
;
; ����������
;   ��������:	AX, ECX, DX, Flags
;*******************************************************************************
DetectATAPIDevice	PROC

		and	al,1
		shl	al,4
		or	al,0A0h
		add	dx,6		; DX = ������� ������ ����������/�������
		out	dx,al		; ����� ����������

		inc	dx		; DX = ������� �������/���������
		in	al,dx		; AL = ���� ��������� ����������
		cmp	al,0FFh
		je	@@NoDevice

		call	DevWait
		jc	@@NoDevice

;		mov	al,8		; AL=8 (������� ������ ������)
;		out	dx,al
;
;		call	DevWait
;		jc	@@NoDevice

		sub	dx,3		; DX = ������� �������� (������� ����)
		xor	al,al
		out	dx,al
		inc	dx		; DX = ������� �������� (������� ����)
		out	dx,al

		add	dx,2		; DX = ������� �������/���������
		mov	al,0ECh		; AL=0ECh (������� ������������� ����������)
		out	dx,al

		call	DevWait
		jc	@@NoDevice

		sub	dx,3		; DX = ������� �������� (������� ����)
		in	al,dx
		mov	ah,al
		inc	dx		; DX = ������� �������� (������� ����)
		in	al,dx
		cmp	ax,14EBh
		je	@@Exit

@@NoDevice:	stc

@@Exit:		ret

DetectATAPIDevice	ENDP

;*******************************************************************************
; DevWait	��������, ���� ���������� ������
;*******************************************************************************
; ����������:	���
;
; �����:	DX = ������� �������/���������
;
; �������:	CF = ���� ���������/���������� ����������
;
; ����������
;   ��������:	AL, ECX, Flags
;*******************************************************************************
DevWait		PROC

		mov	ecx,140000h
@@WaitLoop:	in	al,dx		; AL = ���� ��������� ����������
		test	al,80h		; ���������� ������?
		jz	@@Exit
		loop	@@WaitLoop

		stc

@@Exit:		ret

DevWait		ENDP

;*******************************************************************************
; CorrectATADeviceInfo	��������� ���������� �� ���������� ATA/ATAPI
;*******************************************************************************
; ����������:	���
;
; �����:	EDI -> ����� � ����������� �� ����������
;		       (��������� ATA_DEVICE_INFO)
;
; �������:	���
;
; ����������
;   ��������:	AX, ECX, Flags
;*******************************************************************************
CorrectATADeviceInfo	PROC

		push	edi

		cld

		add	edi,14h
		mov	ecx,20 / 2
@@SerNumLoop:	mov	ax,[edi]
		xchg	al,ah
		stosw
		loop	@@SerNumLoop

		add	edi,6
		mov	cl,(8 + 40) / 2
@@ModelNumLoop:	mov	ax,[edi]
		xchg	al,ah
		stosw
		loop	@@ModelNumLoop

		pop	edi

		ret

CorrectATADeviceInfo	ENDP

;*******************************************************************************
; GetATADeviceSizeInGB	��������� ������� ���������� ATA � ����������
;*******************************************************************************
; ����������:	���
;
; �����:	EDI -> ����� � ����������� �� ����������
;		       (��������� ATA_DEVICE_INFO)
;
; �������:	EAX = ������ ���������� ATA � ����������
;		      (1�� = 1 000 000 000 ����)
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
GetATADeviceSizeInGB	PROC

; ����� 48-������ LBA?
		test	BYTE PTR [edi.ata_wCommandSet2+1],4
		jz	@@LBA28

		mov	eax,[edi.ata_dwMaxLBA48Address]
		mov	edx,[edi.ata_dwMaxLBA48Address+4]
						; EDX:EAX = ����� ����� ��������
						; � ������ 48-������ LBA
		jmp	@@DoCalcSize

@@LBA28:	xor	edx,edx
		mov	eax,[edi.ata_dwTotalAddrSecs]
						; EDX:EAX = ����� ����� ��������
						; � ������ 28-������ LBA
		or	eax,eax
		jnz	@@DoCalcSize

; ��������� ������ ����� �������� � ������ CHS
		movzx	eax,[edi.ata_wCyls]
		movzx	ecx,[edi.ata_wHeads]
		mul	ecx
		movzx	ecx,[edi.ata_wSecsPerTrack]
		mul	ecx			; EDX:EAX = ����� ����� ��������
						; � ������ CHS

@@DoCalcSize:	mov	ecx,1000000000 / 512
		div	ecx			; EAX = ����� ����� � ����������
		shr	ecx,1
		cmp	ecx,edx
		adc	eax,0			; ���������� �� ���������

		ret

GetATADeviceSizeInGB	ENDP


END
