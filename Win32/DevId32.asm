.386
LOCALS

.MODEL	FLAT


INCLUDE	ATA.inc
INCLUDE	DevIdNT.inc


; Длина заголовка устройства
DEV_TITLE_LEN		EQU	59
; Отступ названия устройства в заголовке (<= DEV_TITLE_LEN - 2)
DEV_TITLE_INDENT	EQU	3
; Максимальная длина названия устройства
MAX_DEV_NAME_LEN	EQU	(DEV_TITLE_LEN - DEV_TITLE_INDENT - 1)
; Символ заполнения заголовка устройства
DEV_TITLE_FILL_CHAR	EQU	'-'


L			EQU	<LARGE>

; Значения параметра функции GetStdHandle
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
		call	GetVersion		; EAX = текущая версия ОС
		or	eax,eax			; бит 31 = 0 (Windows NT)
		jns	@@WinNT

; Отображение информации об устройствах (Windows 9x)
		call	Win9x_PrintDevInfo
		jmp	@@Done

@@WinNT:
; Отображение информации об устройствах (Windows NT)
		call	WinNT_PrintDevInfo

@@Done:
; Ожидание нажатия клавиши
		call	NEAR PTR @@szPressAnyKeyEnd
		DB	0Dh, 0Ah, "Press any key...", 0
@@szPressAnyKeyEnd:
		push	L STD_ERROR_HANDLE
		call	GetStdHandle		; EAX = дескриптор стандартного
						; устройства ошибки
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
; WinNT_PrintDevInfo	Отображение информации об устройствах
;			(Windows NT с правами администратора)
;*******************************************************************************
; Использует:	CloseHandle, wsprintfA,
;		NtGetPhysicalDriveHandle, SMART_IdentifyDevice,
;		NtGetDiskGeometry, NtGetSCSIDeviceSerialNumber,
;		CorrectATADeviceInfo, PrintDevNumTitle, PrintDevTitle,
;		PrintATADevInfo, printf
;
; Вызов:	нет
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
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
; Получаем дескриптор физического устройства
		mov	al,bl			; AL = номер устройства
		call	NtGetPhysicalDriveHandle; EAX = дескриптор устройства
		inc	eax
		jz	@@NextDev
		dec	eax

		mov	esi,eax			; ESI = дескриптор устройства

; Идентификация устройства ATA/ATAPI (SMART)
		mov	dl,bl			; DL = номер устройства
		call	SMART_IdentifyDevice
		or	eax,eax
		jz	@@TrySCSI

		call	CorrectATADeviceInfo	; коррекция информации

; Вывод информации об устройстве ATA/ATAPI
		mov	al,bl			; AL = номер устройства
		call	PrintDevNumTitle
		call	PrintATADevInfo
		jmp	@@DoCloseHandle

@@TrySCSI:
; Получение информации о геометрии физического диска
		mov	eax,esi			; EAX = дескриптор устройства
		call	NtGetDiskGeometry
		or	eax,eax
		jz	@@DoCloseHandle
		cmp	[edi.dg_MediaType],FixedMedia	; Жесткий диск?
		jne	@@DoCloseHandle

; Вывод информации об устройстве
		mov	al,bl			; AL = номер устройства
		call	PrintDevNumTitle

; Определение размеров жесткого диска
		mov	eax,[edi.dg_TracksPerCylinder]
		mul	[edi.dg_SectorsPerTrack]
		mul	DWORD PTR [edi]		; EAX = общее число секторов
		mul	[edi.dg_BytesPerSector]
		mov	ecx,500000000
		div	ecx
		shr	eax,1			; EAX = объем диска в гигабайтах
		adc	eax,0			; округление до гигабайта

		push	eax
		push	L OFFSET szHDD
		push	edi
		call	_wsprintfA
		add	esp,12

		push	edi
		push	L OFFSET szDevice
		call	printf
		add	esp,8

; Получение серийного номера устройства SCSI
		mov	eax,esi			; EAX = дескриптор устройства
		call	NtGetSCSIDeviceSerialNumber
		or	eax,eax
		jz	@@DoCloseHandle

; Вывод серийного номера устройства SCSI
		push	edi
		push	L OFFSET szSerNum
		call	printf
		add	esp,8

@@DoCloseHandle:
; Освобождаем дескриптор устройства
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
; Win9x_PrintDevInfo	Отображение информации об устройствах (Windows 9x)
;*******************************************************************************
; Использует:	Win9x_IdentifyDevice, CorrectATADeviceInfo, PrintDevTitle,
;		PrintATADevInfo
;
; Вызов:	нет
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************

;*******************************************************************************
; Параметры устройства ATA/ATAPI
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

; Сканирование устройств ATA/ATAPI
		mov	esi,OFFSET ATADeviceList	; ESI -> ATADeviceList
		lea	edi,[@@devinfo]			; EDI -> @@devinfo

		mov	ecx,ATADEVICECOUNT
@@DevLoop:	push	ecx

; Идентификация устройства ATA/ATAPI (Windows 9x)
		mov	dx,[esi.add_wBasePort]
		mov	al,[esi.add_bDevNum]
		call	Win9x_IdentifyDevice
		or	eax,eax				; информация получена?
		jz	@@NextDev

		call	CorrectATADeviceInfo		; коррекция информации

; Вывод информации об устройстве ATA/ATAPI
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
; PrintDevNumTitle	Вывод заголовка с номером устройства
;*******************************************************************************
; Использует:	PrintDevTitle
;
; Вызов:	AL = номер устройства
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
PrintDevNumTitle	PROC

		push	L '0ec'
		push	L 'iveD'		; ESP -> "Device0"
		or	BYTE PTR [esp+6],al
		mov	eax,esp			; EAX -> "DeviceN"
		call	PrintDevTitle

		pop	eax			; восстановление стека
		pop	eax

		ret

PrintDevNumTitle	ENDP

;*******************************************************************************
; PrintDevTitle	Вывод заголовка устройства
;*******************************************************************************
; Использует:	lstrlenA,
;		puts
;
; Вызов:	EAX -> строка с названием устройства
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
PrintDevTitle	PROC
		LOCAL	@@buf:BYTE:(((DEV_TITLE_LEN + 3) + 3) AND (NOT 3)) = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi
		push	edi

		cld

		mov	esi,eax			; ESI -> строка с названием
						; устройства
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
		call	lstrlenA		; EAX = длина названия устройства
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
; PrintATADevInfo	Вывод информации об устройстве ATA/ATAPI
;*******************************************************************************
; Использует:	wsprintfA,
;		GetATADeviceSizeInGB, printf
;
; Вызов:	EDI -> буфер с информацией об устройстве
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
PrintATADevInfo	PROC
		LOCAL	@@buf:BYTE:32 = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi

; Тип устройства
		mov	al,[edi+1]
		test	al,80h			; устройство ATAPI?
		jz	@@ATA

		and	al,1Fh			; AL = тип устройства ATAPI
		cmp	al,5			; CDROM?
		mov	eax,OFFSET szCDROM
		je	@@DoPrintType
		mov	eax,OFFSET szUnknownATAPI
		jmp	@@DoPrintType

@@ATA:
; Жесткий диск
		lea	esi,[@@buf]		; ESI -> @@buf
		call	GetATADeviceSizeInGB	; EAX = размер диска в гигабайтах
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

; Модель
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

; Серийный номер
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
; Данные, передаваемые в процедуру Ring0_IdentifyDevice
;*******************************************************************************
RING0_ID_DEV_DATA_IN	STRUC
	r0idd_wBasePort	DW	?
	r0idd_bDevNum	DB	?
	r0idd_lpBuffer	DD	?
RING0_ID_DEV_DATA_IN	ENDS

;*******************************************************************************
; Win9x_IdentifyDevice	Идентификация устройства ATA/ATAPI (Windows 9x)
;*******************************************************************************
; Использует:	Ring0Call, Ring0_IdentifyDevice
;
; Вызов:	DX = базовый порт
;		AL = номер устройства
;		EDI -> буфер для информации об устройстве
;
; Возврат:	EAX = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	EAX, ECX, DX, Flags
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
		or	eax,eax			; процедура выполнена?
		jz	@@Exit

		mov	eax,[@@dwSuccess]

@@Exit:		leave

		ret

Win9x_IdentifyDevice	ENDP

;*******************************************************************************
; Ring0_IdentifyDevice	Идентификация устройства ATA/ATAPI (Ring 0)
;*******************************************************************************
; Использует:	DetectATAPIDevice, IdentifyDevice
;
; Вызов:	EAX -> данные для получения информации (RING0_ID_DEV_DATA_IN)
;
; Возврат:	EAX = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	EAX, ECX, DX, Flags
;*******************************************************************************
Ring0_IdentifyDevice	PROC	FAR

		push	edi

		mov	edi,[eax.r0idd_lpBuffer]
		mov	dx,[eax.r0idd_wBasePort]
		mov	al,[eax.r0idd_bDevNum]

		push	eax
		push	edx
		call	DetectATAPIDevice	; устройство ATAPI?
		pop	edx
		pop	eax
		mov	ah,0ECh			; AH=0ECh (команда идентификации
						; устройства ATA)
		jc	@@DoIdentify

		mov	ah,0A1h			; AH=0A1h (команда идентификации
						; устройства ATAPI)

@@DoIdentify:	call	IdentifyDevice		; идентификация устройства
						; ATA/ATAPI

		setnc	al
		movzx	eax,al

		pop	edi

		ret

Ring0_IdentifyDevice	ENDP


;*******************************************************************************
; PressAnyKey	Ожидание нажатия любой клавиши
;*******************************************************************************
; Использует:	GetStdHandle, ReadConsoleInputA
;
; Вызов:	нет
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
PressAnyKey	PROC
		LOCAL	@@keyevent:BYTE:20, @@dwNumEventsRead:DWORD = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	esi

		push	L STD_INPUT_HANDLE
		call	GetStdHandle
		mov	esi,eax			; ESI = дескриптор стандартного
						; устройства ввода

@@WaitLoop:	lea	eax,[@@dwNumEventsRead]
		push	eax
		push	L 1
		lea	eax,[@@keyevent]
		push	eax
		push	esi
		call	ReadConsoleInputA	; EAX = флаг успешного/неудачного
						; завершения
		or	eax,eax
		jz	@@Exit
		cmp	WORD PTR [@@keyevent],1	; событие ввода с клавиатуры?
		jne	@@WaitLoop
		cmp	DWORD PTR [@@keyevent+4],0	; нажата клавиша?
		je	@@WaitLoop

@@Exit:		pop	esi
		leave

		ret

PressAnyKey	ENDP


END	Start
