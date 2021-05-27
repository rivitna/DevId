.386
LOCALS

.MODEL	FLAT


INCLUDE	ATA.inc
INCLUDE	DevIdNT.inc


; ����� ��������� ����������
DEV_TITLE_LEN		EQU	59
; ������ �������� ���������� � ��������� (<= DEV_TITLE_LEN - 2)
DEV_TITLE_INDENT	EQU	3
; ������������ ����� �������� ����������
MAX_DEV_NAME_LEN	EQU	(DEV_TITLE_LEN - DEV_TITLE_INDENT - 1)
; ������ ���������� ��������� ����������
DEV_TITLE_FILL_CHAR	EQU	'-'


L			EQU	<LARGE>

; �������� ��������� ������� GetStdHandle
STD_INPUT_HANDLE	EQU	-10
STD_OUTPUT_HANDLE	EQU	-11
STD_ERROR_HANDLE	EQU	-12


INCLUDELIB	IMPORT32.LIB

EXTRN	GetVersion:PROC
EXTRN	GetStdHandle:PROC
EXTRN	CloseHandle:PROC
EXTRN	lstrlenA:PROC
EXTRN	ReadConsoleInputA:PROC
EXTRN	_wsprintfA:PROC


.CODE

EXTRN	Ring0Call:PROC
EXTRN	IdentifyDevice:PROC
EXTRN	DetectATAPIDevice:PROC
EXTRN	NtGetPhysicalDriveHandle:PROC
EXTRN	SMART_IdentifyDevice:PROC
EXTRN	NtGetSCSIDeviceSerialNumber:PROC
EXTRN	NtGetDiskGeometry:PROC
EXTRN	CorrectATADeviceInfo:PROC
EXTRN	GetATADeviceSizeInGB:PROC
EXTRN	puts:PROC
EXTRN	fputs:PROC
EXTRN	printf:PROC

Start:
; Windows NT?
		call	GetVersion		; EAX = ������� ������ ��
		or	eax,eax			; ��� 31 = 0 (Windows NT)
		jns	@@WinNT

; ����������� ���������� �� ����������� (Windows 9x)
		call	Win9x_PrintDevInfo
		jmp	@@Done

@@WinNT:
; ����������� ���������� �� ����������� (Windows NT)
		call	WinNT_PrintDevInfo

@@Done:
; �������� ������� �������
		call	NEAR PTR @@szPressAnyKeyEnd
		DB	0Dh, 0Ah, "Press any key...", 0
@@szPressAnyKeyEnd:
		push	L STD_ERROR_HANDLE
		call	GetStdHandle		; EAX = ���������� ������������
						; ���������� ������
		push	eax
		call	fputs

		call	PressAnyKey

Exit:
		xor	eax,eax
		ret


szDevice	DB	"           Device: %s", 0Dh, 0Ah, 0
szModel		DB	"            Model: %.40s", 0Dh, 0Ah, 0
szFirmwareRev	DB	"Firmware Revision: %.8s", 0Dh, 0Ah, 0
szSerNum	DB	"    Serial Number: %.20s", 0Dh, 0Ah, 0

szIDEHDD	DB	"IDE HDD %u GB", 0
szHDD		DB	"HDD %u GB", 0
szCDROM		DB	"CD-ROM", 0
szUnknownATAPI	DB	"Unknown ATAPI", 0


;*******************************************************************************
; WinNT_PrintDevInfo	����������� ���������� �� �����������
;			(Windows NT � ������� ��������������)
;*******************************************************************************
; ����������:	CloseHandle, wsprintfA,
;		NtGetPhysicalDriveHandle, SMART_IdentifyDevice,
;		NtGetDiskGeometry, NtGetSCSIDeviceSerialNumber,
;		CorrectATADeviceInfo, PrintDevNumTitle, PrintDevTitle,
;		PrintATADevInfo, printf
;
; �����:	���
;
; �������:	���
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
WinNT_PrintDevInfo	PROC
			LOCAL	@@buf:BYTE:DEVICE_INFO_BUFFER_SIZE = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	ebx
		push	esi
		push	edi

		lea	edi,[@@buf]		; EDI -> @@buf

		xor	bl,bl
@@DevLoop:
; �������� ���������� ����������� ����������
		mov	al,bl			; AL = ����� ����������
		call	NtGetPhysicalDriveHandle; EAX = ���������� ����������
		inc	eax
		jz	@@NextDev
		dec	eax

		mov	esi,eax			; ESI = ���������� ����������

; ������������� ���������� ATA/ATAPI (SMART)
		mov	dl,bl			; DL = ����� ����������
		call	SMART_IdentifyDevice
		or	eax,eax
		jz	@@TrySCSI

		call	CorrectATADeviceInfo	; ��������� ����������

; ����� ���������� �� ���������� ATA/ATAPI
		mov	al,bl			; AL = ����� ����������
		call	PrintDevNumTitle
		call	PrintATADevInfo
		jmp	@@DoCloseHandle

@@TrySCSI:
; ��������� ���������� � ��������� ����������� �����
		mov	eax,esi			; EAX = ���������� ����������
		call	NtGetDiskGeometry
		or	eax,eax
		jz	@@DoCloseHandle
		cmp	[edi.dg_MediaType],FixedMedia	; ������� ����?
		jne	@@DoCloseHandle

; ����� ���������� �� ����������
		mov	al,bl			; AL = ����� ����������
		call	PrintDevNumTitle

; ����������� �������� �������� �����
		mov	eax,[edi.dg_TracksPerCylinder]
		mul	[edi.dg_SectorsPerTrack]
		mul	DWORD PTR [edi]		; EAX = ����� ����� ��������
		mul	[edi.dg_BytesPerSector]
		mov	ecx,500000000
		div	ecx
		shr	eax,1			; EAX = ����� ����� � ����������
		adc	eax,0			; ���������� �� ���������

		push	eax
		push	L OFFSET szHDD
		push	edi
		call	_wsprintfA
		add	esp,12

		push	edi
		push	L OFFSET szDevice
		call	printf
		add	esp,8

; ��������� ��������� ������ ���������� SCSI
		mov	eax,esi			; EAX = ���������� ����������
		call	NtGetSCSIDeviceSerialNumber
		or	eax,eax
		jz	@@DoCloseHandle

; ����� ��������� ������ ���������� SCSI
		push	edi
		push	L OFFSET szSerNum
		call	printf
		add	esp,8

@@DoCloseHandle:
; ����������� ���������� ����������
		push	esi
		call	CloseHandle

@@NextDev:	inc	ebx
		cmp	bl,MAX_DEVICE_NUM
		jbe	@@DevLoop

		pop	edi
		pop	esi
		pop	ebx
		leave

		ret

WinNT_PrintDevInfo	ENDP

;*******************************************************************************
; Win9x_PrintDevInfo	����������� ���������� �� ����������� (Windows 9x)
;*******************************************************************************
; ����������:	Win9x_IdentifyDevice, CorrectATADeviceInfo, PrintDevTitle,
;		PrintATADevInfo
;
; �����:	���
;
; �������:	���
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************

;*******************************************************************************
; ��������� ���������� ATA/ATAPI
;*******************************************************************************
ATADEVDATA	STRUC
	add_wBasePort	DW	?
	add_bDevNum	DB	?
	add_lpszName	DD	?
ATADEVDATA	ENDS

szPriMaster	DB	"Primary Master", 0
szPriSlave	DB	"Primary Slave", 0
szSecMaster	DB	"Secondary Master", 0
szSecSlave	DB	"Secondary Slave", 0
szTerMaster	DB	"Tertiary Master", 0
szTerSlave	DB	"Tertiary Slave", 0
szQuaMaster	DB	"Quaternary Master", 0
szQuaSlave	DB	"Quaternary Slave", 0

ATADeviceList	ATADEVDATA	<1F0h, 0, OFFSET szPriMaster>
		ATADEVDATA	<1F0h, 1, OFFSET szPriSlave>
		ATADEVDATA	<170h, 2, OFFSET szSecMaster>
		ATADEVDATA	<170h, 3, OFFSET szSecSlave>
		ATADEVDATA	<1E8h, 4, OFFSET szTerMaster>
		ATADEVDATA	<1E8h, 5, OFFSET szTerSlave>
		ATADEVDATA	<168h, 6, OFFSET szQuaMaster>
		ATADEVDATA	<168h, 7, OFFSET szQuaSlave>
ATADEVICECOUNT	=	($ - ATADeviceList) / SIZE ATADEVDATA

Win9x_PrintDevInfo	PROC
			LOCAL	@@devinfo:ATA_DEVICE_INFO = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi
		push	edi

; ������������ ��������� ATA/ATAPI
		mov	esi,OFFSET ATADeviceList	; ESI -> ATADeviceList
		lea	edi,[@@devinfo]			; EDI -> @@devinfo

		mov	ecx,ATADEVICECOUNT
@@DevLoop:	push	ecx

; ������������� ���������� ATA/ATAPI (Windows 9x)
		mov	dx,[esi.add_wBasePort]
		mov	al,[esi.add_bDevNum]
		call	Win9x_IdentifyDevice
		or	eax,eax				; ���������� ��������?
		jz	@@NextDev

		call	CorrectATADeviceInfo		; ��������� ����������

; ����� ���������� �� ���������� ATA/ATAPI
		mov	eax,[esi.add_lpszName]
		call	PrintDevTitle
		call	PrintATADevInfo

@@NextDev:	pop	ecx
		add	esi,SIZE ATADEVDATA
		loop	@@DevLoop

		pop	edi
		pop	esi
		leave

		ret

Win9x_PrintDevInfo	ENDP


;*******************************************************************************
; PrintDevNumTitle	����� ��������� � ������� ����������
;*******************************************************************************
; ����������:	PrintDevTitle
;
; �����:	AL = ����� ����������
;
; �������:	���
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
PrintDevNumTitle	PROC

		push	L '0ec'
		push	L 'iveD'		; ESP -> "Device0"
		or	BYTE PTR [esp+6],al
		mov	eax,esp			; EAX -> "DeviceN"
		call	PrintDevTitle

		pop	eax			; �������������� �����
		pop	eax

		ret

PrintDevNumTitle	ENDP

;*******************************************************************************
; PrintDevTitle	����� ��������� ����������
;*******************************************************************************
; ����������:	lstrlenA,
;		puts
;
; �����:	EAX -> ������ � ��������� ����������
;
; �������:	���
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
PrintDevTitle	PROC
		LOCAL	@@buf:BYTE:(((DEV_TITLE_LEN + 3) + 3) AND (NOT 3)) = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi
		push	edi

		cld

		mov	esi,eax			; ESI -> ������ � ���������
						; ����������
		lea	edi,[@@buf]		; EDI -> @@buf
		push	edi

		mov	al,DEV_TITLE_FILL_CHAR
		mov	ecx,DEV_TITLE_LEN
		rep	stosb
		mov	WORD PTR [edi],0A0Dh
		mov	BYTE PTR [edi+2],0

		lea	edi,[@@buf+DEV_TITLE_INDENT]
		mov	al,' '
		stosb

		push	esi
		call	lstrlenA		; EAX = ����� �������� ����������
		cmp	eax,MAX_DEV_NAME_LEN
		jb	@@ValidLen
		mov	ecx,MAX_DEV_NAME_LEN
		jmp	@@DoCopyName
@@ValidLen:	mov	BYTE PTR [edi+eax],' '
		mov	ecx,eax
@@DoCopyName:	rep	movsb

		call	puts

		pop	edi
		pop	esi
		leave

		ret

PrintDevTitle	ENDP

;*******************************************************************************
; PrintATADevInfo	����� ���������� �� ���������� ATA/ATAPI
;*******************************************************************************
; ����������:	wsprintfA,
;		GetATADeviceSizeInGB, printf
;
; �����:	EDI -> ����� � ����������� �� ����������
;
; �������:	���
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
PrintATADevInfo	PROC
		LOCAL	@@buf:BYTE:32 = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi

; ��� ����������
		mov	al,[edi+1]
		test	al,80h			; ���������� ATAPI?
		jz	@@ATA

		and	al,1Fh			; AL = ��� ���������� ATAPI
		cmp	al,5			; CDROM?
		mov	eax,OFFSET szCDROM
		je	@@DoPrintType
		mov	eax,OFFSET szUnknownATAPI
		jmp	@@DoPrintType

@@ATA:
; ������� ����
		lea	esi,[@@buf]		; ESI -> @@buf
		call	GetATADeviceSizeInGB	; EAX = ������ ����� � ����������
		push	eax
		push	L OFFSET szIDEHDD
		push	esi
		call	_wsprintfA
		add	esp,12
		mov	eax,esi			; EAX -> @@buf

@@DoPrintType:	mov	esi,OFFSET printf

		push	eax
		push	L OFFSET szDevice
		call	esi			; call printf
		add	esp,8

; ������
		lea	eax,[edi.ata_sModelNumber]
		cmp	WORD PTR [eax],0
		je	@@Model_Done

		push	eax
		push	L OFFSET szModel
		call	esi			; call printf
		add	esp,8

@@Model_Done:

; Firmware Revision
		lea	eax,[edi.ata_sFirmwareRev]
		cmp	WORD PTR [eax],0
		je	@@FirmwareRev_Done

		push	eax
		push	L OFFSET szFirmwareRev
		call	esi			; call printf
		add	esp,8

@@FirmwareRev_Done:

; �������� �����
		lea	eax,[edi.ata_sSerialNumber]
		cmp	WORD PTR [eax],0
		je	@@SerNum_Done

		push	eax
		push	L OFFSET szSerNum
		call	esi			; call printf
		add	esp,8

@@SerNum_Done:

		pop	esi
		leave

		ret

PrintATADevInfo	ENDP


;*******************************************************************************
; ������, ������������ � ��������� Ring0_IdentifyDevice
;*******************************************************************************
RING0_ID_DEV_DATA_IN	STRUC
	r0idd_wBasePort	DW	?
	r0idd_bDevNum	DB	?
	r0idd_lpBuffer	DD	?
RING0_ID_DEV_DATA_IN	ENDS

;*******************************************************************************
; Win9x_IdentifyDevice	������������� ���������� ATA/ATAPI (Windows 9x)
;*******************************************************************************
; ����������:	Ring0Call, Ring0_IdentifyDevice
;
; �����:	DX = ������� ����
;		AL = ����� ����������
;		EDI -> ����� ��� ���������� �� ����������
;
; �������:	EAX = ���� ���������/���������� ����������
;
; ����������
;   ��������:	EAX, ECX, DX, Flags
;*******************************************************************************
Win9x_IdentifyDevice	PROC
			LOCAL	@@r0idd:RING0_ID_DEV_DATA_IN, \
				@@dwSuccess:DWORD = LOCAL_SIZE

		enter	LOCAL_SIZE,0

		mov	[@@r0idd.r0idd_wBasePort],dx
		mov	[@@r0idd.r0idd_bDevNum],al
		mov	[@@r0idd.r0idd_lpBuffer],edi

		lea	eax,[@@dwSuccess]
		push	eax
		lea	eax,[@@r0idd]
		push	eax
		push	L OFFSET Ring0_IdentifyDevice
		call	Ring0Call
		or	eax,eax			; ��������� ���������?
		jz	@@Exit

		mov	eax,[@@dwSuccess]

@@Exit:		leave

		ret

Win9x_IdentifyDevice	ENDP

;*******************************************************************************
; Ring0_IdentifyDevice	������������� ���������� ATA/ATAPI (Ring 0)
;*******************************************************************************
; ����������:	DetectATAPIDevice, IdentifyDevice
;
; �����:	EAX -> ������ ��� ��������� ���������� (RING0_ID_DEV_DATA_IN)
;
; �������:	EAX = ���� ���������/���������� ����������
;
; ����������
;   ��������:	EAX, ECX, DX, Flags
;*******************************************************************************
Ring0_IdentifyDevice	PROC	FAR

		push	edi

		mov	edi,[eax.r0idd_lpBuffer]
		mov	dx,[eax.r0idd_wBasePort]
		mov	al,[eax.r0idd_bDevNum]

		push	eax
		push	edx
		call	DetectATAPIDevice	; ���������� ATAPI?
		pop	edx
		pop	eax
		mov	ah,0ECh			; AH=0ECh (������� �������������
						; ���������� ATA)
		jc	@@DoIdentify

		mov	ah,0A1h			; AH=0A1h (������� �������������
						; ���������� ATAPI)

@@DoIdentify:	call	IdentifyDevice		; ������������� ����������
						; ATA/ATAPI

		setnc	al
		movzx	eax,al

		pop	edi

		ret

Ring0_IdentifyDevice	ENDP


;*******************************************************************************
; PressAnyKey	�������� ������� ����� �������
;*******************************************************************************
; ����������:	GetStdHandle, ReadConsoleInputA
;
; �����:	���
;
; �������:	���
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
PressAnyKey	PROC
		LOCAL	@@keyevent:BYTE:20, @@dwNumEventsRead:DWORD = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi

		push	L STD_INPUT_HANDLE
		call	GetStdHandle
		mov	esi,eax			; ESI = ���������� ������������
						; ���������� �����

@@WaitLoop:	lea	eax,[@@dwNumEventsRead]
		push	eax
		push	L 1
		lea	eax,[@@keyevent]
		push	eax
		push	esi
		call	ReadConsoleInputA	; EAX = ���� ���������/����������
						; ����������
		or	eax,eax
		jz	@@Exit
		cmp	WORD PTR [@@keyevent],1	; ������� ����� � ����������?
		jne	@@WaitLoop
		cmp	DWORD PTR [@@keyevent+4],0	; ������ �������?
		je	@@WaitLoop

@@Exit:		pop	esi
		leave

		ret

PressAnyKey	ENDP


END	Start
