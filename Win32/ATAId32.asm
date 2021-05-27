;*******************************************************************************
;* ATAId32.ASM - Идентификация устройств ATA/ATAPI                             *
;* Версия 1.03 (Сентябрь 2009 г.)                                              *
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
; IdentifyATAPIDevice	Идентификация устройства ATAPI
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	DX = базовый порт
;		AL = номер устройства
;		EDI -> буфер для информации об устройстве
;		       (структура ATAPI_DEVICE_INFO)
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AX, ECX, DX, Flags
;*******************************************************************************
IdentifyATAPIDevice	PROC

		mov	ah,0A1h		; AH=0A1h (команда идентификации
					; устройства ATAPI)
		jmp	IdentifyDevice

;*******************************************************************************
; IdentifyATADevice	Идентификация устройства ATA
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	DX = базовый порт
;		AL = номер устройства
;		EDI -> буфер для информации об устройстве
;		       (структура ATA_DEVICE_INFO)
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AX, ECX, DX, Flags
;*******************************************************************************
IdentifyATADevice:
		mov	ah,0ECh		; AH=0ECh (команда идентификации
					; устройства ATA)

;*******************************************************************************
; IdentifyDevice	Идентификация устройства ATA/ATAPI
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	AH = команда идентификации устройства (ATA - 0ECh, ATAPI - 0A1h)
;		DX = базовый порт
;		AL = номер устройства
;		EDI -> буфер для информации об устройстве
;		       (структура ATA_DEVICE_INFO)
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AL, ECX, DX, Flags
;*******************************************************************************
IdentifyDevice:
		and	al,1
		shl	al,4
		or	al,0A0h
		add	dx,6		; DX = регистр выбора устройства/головки
		out	dx,al		; выбор устройства

		inc	dx		; DX = регистр команды/состояния
		in	al,dx		; AL = байт состояния устройства
		cmp	al,0FFh
		je	@@Error

		call	DevWait
		jc	@@Error

		mov	al,ah
		out	dx,al		; команда идентификации устройства

		call	DevWait
		jc	@@Error

		mov	ecx,100h
@@WaitLoop:	in	al,dx		; AL = байт состояния устройства
		test	al,8		; установлен бит DRQ?
		loopz	@@WaitLoop
		jz	@@Error

		sub	dx,7		; DX = регистр данных

		push	edi

		mov	ecx,100h
		cld
		cli
		rep	insw		; чтение данных
		sti

		pop	edi

		add	dx,7		; DX = регистр команды/состояния
		in	al,dx		; AL = байт состояния устройства
		and	al,71h
		cmp	al,50h
		je	@@Exit

@@Error:	stc

@@Exit:		ret

IdentifyATAPIDevice	ENDP

;*******************************************************************************
; DetectATAPIDevice	Определение наличия устройства ATAPI
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	DX = базовый порт
;		AL = номер устройства
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AX, ECX, DX, Flags
;*******************************************************************************
DetectATAPIDevice	PROC

		and	al,1
		shl	al,4
		or	al,0A0h
		add	dx,6		; DX = регистр выбора устройства/головки
		out	dx,al		; выбор устройства

		inc	dx		; DX = регистр команды/состояния
		in	al,dx		; AL = байт состояния устройства
		cmp	al,0FFh
		je	@@NoDevice

		call	DevWait
		jc	@@NoDevice

;		mov	al,8		; AL=8 (команда общего сброса)
;		out	dx,al
;
;		call	DevWait
;		jc	@@NoDevice

		sub	dx,3		; DX = регистр цилиндра (младший байт)
		xor	al,al
		out	dx,al
		inc	dx		; DX = регистр цилиндра (старший байт)
		out	dx,al

		add	dx,2		; DX = регистр команды/состояния
		mov	al,0ECh		; AL=0ECh (команда идентификации устройства)
		out	dx,al

		call	DevWait
		jc	@@NoDevice

		sub	dx,3		; DX = регистр цилиндра (младший байт)
		in	al,dx
		mov	ah,al
		inc	dx		; DX = регистр цилиндра (старший байт)
		in	al,dx
		cmp	ax,14EBh
		je	@@Exit

@@NoDevice:	stc

@@Exit:		ret

DetectATAPIDevice	ENDP

;*******************************************************************************
; DevWait	Ожидание, пока устройство занято
;*******************************************************************************
; Использует:	нет
;
; Вызов:	DX = регистр команды/состояния
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AL, ECX, Flags
;*******************************************************************************
DevWait		PROC

		mov	ecx,140000h
@@WaitLoop:	in	al,dx		; AL = байт состояния устройства
		test	al,80h		; устройство занято?
		jz	@@Exit
		loop	@@WaitLoop

		stc

@@Exit:		ret

DevWait		ENDP

;*******************************************************************************
; CorrectATADeviceInfo	Коррекция информации об устройстве ATA/ATAPI
;*******************************************************************************
; Использует:	нет
;
; Вызов:	EDI -> буфер с информацией об устройстве
;		       (структура ATA_DEVICE_INFO)
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, ECX, Flags
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
; GetATADeviceSizeInGB	Получение размера устройства ATA в гигабайтах
;*******************************************************************************
; Использует:	нет
;
; Вызов:	EDI -> буфер с информацией об устройстве
;		       (структура ATA_DEVICE_INFO)
;
; Возврат:	EAX = размер устройства ATA в гигабайтах
;		      (1ГБ = 1 000 000 000 байт)
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
GetATADeviceSizeInGB	PROC

; Режим 48-битной LBA?
		test	BYTE PTR [edi.ata_wCommandSet2+1],4
		jz	@@LBA28

		mov	eax,[edi.ata_dwMaxLBA48Address]
		mov	edx,[edi.ata_dwMaxLBA48Address+4]
						; EDX:EAX = общее число секторов
						; в режиме 48-битной LBA
		jmp	@@DoCalcSize

@@LBA28:	xor	edx,edx
		mov	eax,[edi.ata_dwTotalAddrSecs]
						; EDX:EAX = общее число секторов
						; в режиме 28-битной LBA
		or	eax,eax
		jnz	@@DoCalcSize

; Получение общего числа секторов в режиме CHS
		movzx	eax,[edi.ata_wCyls]
		movzx	ecx,[edi.ata_wHeads]
		mul	ecx
		movzx	ecx,[edi.ata_wSecsPerTrack]
		mul	ecx			; EDX:EAX = общее число секторов
						; в режиме CHS

@@DoCalcSize:	mov	ecx,1000000000 / 512
		div	ecx			; EAX = объем диска в гигабайтах
		shr	ecx,1
		cmp	ecx,edx
		adc	eax,0			; округление до гигабайта

		ret

GetATADeviceSizeInGB	ENDP


END
