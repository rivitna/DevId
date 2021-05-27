LOCALS

.MODEL	TINY


INCLUDE	ATA.inc


; ����� ��।������ PASCAL-��ப�
PASSTR	MACRO	name, str
LOCAL	len
name	DB	len, "&str"
len	=	$ - name - 1
ENDM


; ����� ��������� ���ன�⢠
DEV_TITLE_LEN		EQU	59
; ����� �������� ���ன�⢠ � ��������� (<= DEV_TITLE_LEN - 2)
DEV_TITLE_INDENT	EQU	3
; ������ ���������� ��������� ���ன�⢠
DEV_TITLE_FILL_CHAR	EQU	'-'


ATADEVDATA	STRUC
	add_wBasePort	DW	?
	add_bDevNum	DB	?
	add_psName	DW	?
ATADEVDATA	ENDS


.STACK	100h


.DATA

PASSTR	sPriMaster,	<Primary Master>
PASSTR	sPriSlave,	<Primary Slave>
PASSTR	sSecMaster,	<Secondary Master>
PASSTR	sSecSlave,	<Secondary Slave>
PASSTR	sTerMaster,	<Tertiary Master>
PASSTR	sTerSlave,	<Tertiary Slave>
PASSTR	sQuaMaster,	<Quaternary Master>
PASSTR	sQuaSlave,	<Quaternary Slave>

ATADeviceList	ATADEVDATA	<1F0h, 0, OFFSET sPriMaster>
		ATADEVDATA	<1F0h, 1, OFFSET sPriSlave>
		ATADEVDATA	<170h, 0, OFFSET sSecMaster>
		ATADEVDATA	<170h, 1, OFFSET sSecSlave>
		ATADEVDATA	<1E8h, 0, OFFSET sTerMaster>
		ATADEVDATA	<1E8h, 1, OFFSET sTerSlave>
		ATADEVDATA	<168h, 0, OFFSET sQuaMaster>
		ATADEVDATA	<168h, 1, OFFSET sQuaSlave>
ATADEVICECOUNT	=	($ - ATADeviceList) / SIZE ATADEVDATA

PASSTR	sDevice,	<           Device: >
PASSTR	sModel,		<            Model: >
PASSTR	sFirmwareRev,	<Firmware Revision: >
PASSTR	sSerNum,	<    Serial Number: >

PASSTR	sHDD,		<IDE HDD>
PASSTR	sCDROM,		<CD-ROM>
PASSTR	sUnknownATAPI,	<Unknown ATAPI>

sPressAnyKey	DB	0Dh, 0Ah, "Press any key..."
PRESSANYKEYLEN	=	$ - sPressAnyKey


.DATA?

DevInfo		DW	256 DUP(?)


.CODE

EXTRN	IdentifyDevice:PROC
EXTRN	DetectATAPIDevice:PROC

Start:
		push	cs
		pop	ds			; DS = ᥣ���� ����
		push	cs
		pop	es			; ES = ᥣ���� ����

; �����஢���� ���ன�� ATA/ATAPI
		mov	si,OFFSET ATADeviceList	; DS:SI -> ATADeviceList
		mov	di,OFFSET DevInfo	; ES:DI -> DevInfo
		mov	bp,ATADEVICECOUNT

@@DevLoop:
		mov	dx,[si.add_wBasePort]
		mov	al,[si.add_bDevNum]
; ��।������ ������ ���ன�⢠ ATAPI
		push	ax
		push	dx
		call	DetectATAPIDevice
		pop	dx
		pop	ax
		mov	bl,0ECh			; BL=0ECh (������� �����䨪�樨
						; ���ன�⢠ ATA)
		jc	@@DoIdentifyDev

		mov	bl,0A1h			; BL=0A1h (������� �����䨪�樨
						; ���ன�⢠ ATAPI)

@@DoIdentifyDev:
; �����䨪��� ���ன�⢠ ATA/ATAPI
		call	IdentifyDevice
		jc	@@NextDev

; �뢮� ���ଠ樨 �� ���ன�⢥ ATA/ATAPI
		mov	dx,[si.add_psName]
		call	PrintDevTitle
		call	PrintDevInfo

@@NextDev:	add	si,SIZE ATADEVDATA
		dec	bp
		jnz	@@DevLoop

		mov	bx,2			; BX=2 (�⠭���⭮� ���ன�⢮
						; �뢮�� �訡��)
		mov	dx,OFFSET sPressAnyKey
		mov	cx,PRESSANYKEYLEN
		call	WriteFile

		xor	ah,ah
		int	16h

		mov	ax,4C00h		; AH=4Ch (�㭪�� �����襭��
						; �ணࠬ��)
		int	21h


;*******************************************************************************
; PrintDevTitle	�뢮� ��������� ���ன�⢠
;*******************************************************************************
; �ᯮ����:	PrintChar, PrintCharN, PrintStr, PrintNewLine
;
; �맮�:	DS:DX -> PASCAL-��ப� � ��������� ���ன�⢠
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, BX, CX, DX, Flags
;*******************************************************************************
PrintDevTitle	PROC

		mov	bx,dx			; DS:BX -> PASCAL-��ப�
						; � ��������� ���ன�⢠

		mov	cl,DEV_TITLE_INDENT	; CL = ������⢮ ᨬ�����
						; ���������� ᫥��
		mov	dl,DEV_TITLE_FILL_CHAR
		call	PrintCharN

		mov	dl,' '
		call	PrintChar

		mov	cl,[bx]			; CL = ����� ��ப� � ���������
						; ���ன�⢠
		lea	dx,[bx+1]		; DS:DX -> ��ப� � ���������
						; ���ன�⢠
		call	PrintStr

		sub	cl,DEV_TITLE_LEN - DEV_TITLE_INDENT - 2
		jnb	@@DoPrintNewLine

		mov	dl,' '
		call	PrintChar

		neg	cl			; CL = ������⢮ ᨬ�����
						; ���������� �ࠢ�
		mov	dl,DEV_TITLE_FILL_CHAR
		call	PrintCharN

@@DoPrintNewLine:
		jmp	PrintNewLine

PrintDevTitle	ENDP

;*******************************************************************************
; PrintDevInfo	�뢮� ���ଠ樨 �� ���ன�⢥
;*******************************************************************************
; �ᯮ����:	PrintPasStr, PrintStr, PrintNewLine
;
; �맮�:	DS:DI -> ���� � ���ଠ樥� �� ���ன�⢥
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, BX, CX, DX, Flags
;*******************************************************************************
PrintDevInfo	PROC

; ��� ���ன�⢠
		mov	dx,OFFSET sDevice
		call	PrintPasStr

		mov	al,[di+1]
		test	al,80h			; ���ன�⢮ ATAPI?
		mov	dx,OFFSET sHDD
		jz	@@DoPrintType

		and	al,1Fh			; AL = ⨯ ���ன�⢠ ATAPI
		cmp	al,5			; CDROM?
		mov	dx,OFFSET sCDROM
		je	@@DoPrintType
		mov	dx,OFFSET sUnknownATAPI

@@DoPrintType:	call	PrintPasStr
		call	PrintNewLine

; ������
		cmp	WORD PTR [di.ata_sModelNumber],0
		je	@@Model_Done

		mov	dx,OFFSET sModel
		call	PrintPasStr

		lea	dx,[di.ata_sModelNumber]
		mov	cl,SIZE ata_sModelNumber
		call	PrintStr
		call	PrintNewLine

@@Model_Done:

; Firmware Revision
		cmp	WORD PTR [di.ata_sFirmwareRev],0
		je	@@FirmwareRev_Done

		mov	dx,OFFSET sFirmwareRev
		call	PrintPasStr

		lea	dx,[di.ata_sFirmwareRev]
		mov	cl,SIZE ata_sFirmwareRev
		call	PrintStr
		call	PrintNewLine

@@FirmwareRev_Done:

; ��਩�� �����
		cmp	WORD PTR [di.ata_sSerialNumber],0
		je	@@SerNum_Done

		mov	dx,OFFSET sSerNum
		call	PrintPasStr

		lea	dx,[di.ata_sSerialNumber]
		mov	cl,SIZE ata_sSerialNumber
		call	PrintStr
		call	PrintNewLine

@@SerNum_Done:

		ret

PrintDevInfo	ENDP


;*******************************************************************************
; PrintPasStr	�뢮� PASCAL-��ப� �� �⠭���⭮� ���ன�⢮ �뢮��
;*******************************************************************************
; �ᯮ����:	PrintStr
;
; �맮�:	DS:DX -> PASCAL-��ப�
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, BX, CX, DX, Flags
;*******************************************************************************
PrintPasStr	PROC

		mov	bx,dx			; DS:BX -> PASCAL-��ப�
		mov	cl,[bx]			; CL = ����� ��ப�
		inc	dx			; DS:DX -> ��ப�

;*******************************************************************************
; PrintStr	�뢮� ��ப� �� �⠭���⭮� ���ன�⢮ �뢮��
;*******************************************************************************
; �ᯮ����:	WriteFile
;
; �맮�:	DS:DX -> ��ப�
;		CL = ����� ��ப�
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, BX, CH, Flags
;*******************************************************************************
PrintStr:
		xor	ch,ch			; CX = ����� ������ � �����
		mov	bx,1			; BX=1 (�⠭���⭮� ���ன�⢮
						; �뢮��)

;*******************************************************************************
; WriteFile	������ ������ � 䠩�
;*******************************************************************************
; �ᯮ����:	int 21h
;
; �맮�:	BX = ���ਯ�� 䠩��
;		DS:DX -> �����
;		CX = ����� ������ � �����
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, Flags
;*******************************************************************************
WriteFile:
		mov	ah,40h			; AH=40h (�㭪�� ����� � 䠩�)
		int	21h

		ret

PrintPasStr	ENDP

;*******************************************************************************
; PrintCharN	�뢮� 㪠������� ������⢠ ����� ᨬ���� �� �⠭���⭮�
;		���ன�⢮ �뢮��
;*******************************************************************************
; �ᯮ����:	PrintChar
;
; �맮�:	DL = ��� ᨬ����
;		CL = ������⢮ ����� ᨬ����
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, CL, Flags
;*******************************************************************************
PrintCharN	PROC

@@CharLoop:	call	PrintChar
		dec	cl
		jnz	@@CharLoop

		ret

PrintCharN	ENDP

;*******************************************************************************
; PrintNewLine	��ॢ�� ����� �� ����� ��ப� �� �⠭���⭮� ���ன�⢥ �뢮��
;*******************************************************************************
; �ᯮ����:	PrintChar
;
; �맮�:	���
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, DL, Flags
;*******************************************************************************
PrintNewLine	PROC

		mov	dl,0Dh
		call	PrintChar
		mov	dl,0Ah
		call	PrintChar

		ret

PrintNewLine	ENDP

;*******************************************************************************
; PrintChar	�뢮� ᨬ���� �� �⠭���⭮� ���ன�⢮ �뢮��
;*******************************************************************************
; �ᯮ����:	int 21h
;
; �맮�:	DL = ��� ᨬ����
;
; ������:	���
;
; �����塞�
;   ॣ�����:	AX, Flags
;*******************************************************************************
PrintChar	PROC

		mov	ah,2			; AH=2 (�㭪�� �뢮�� ᨬ����)
		int	21h

		ret

PrintChar	ENDP


END		Start
