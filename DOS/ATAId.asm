;*******************************************************************************
;* ATAId.ASM - Идентификация устройств ATA/ATAPI                               *
;* Версия 1.02 (Сентябрь 2009 г.)                                              *
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
; IdentifyATAPIDevice	Идентификация устройства ATAPI
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	DX = базовый порт
;		AL = номер устройства
;		ES:DI -> буфер для информации об устройстве
;		         (структура ATAPI_DEVICE_INFO)
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AX, BL, CX, DX, Flags
;*******************************************************************************
IdentifyATAPIDevice	PROC

		mov	bl,0A1h		; BL=0A1h (команда идентификации
					; устройства ATAPI)
		jmp	IdentifyDevice

;*******************************************************************************
; IdentifyATADevice	Идентификация устройства ATA
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	DX = базовый порт
;		AL = номер устройства
;		ES:DI -> буфер для информации об устройстве
;		         (структура ATA_DEVICE_INFO)
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AX, BL, CX, DX, Flags
;*******************************************************************************
IdentifyATADevice:
		mov	bl,0ECh		; BL=0ECh (команда идентификации
					; устройства ATA)

;*******************************************************************************
; IdentifyDevice	Идентификация устройства ATA/ATAPI
;*******************************************************************************
; Использует:	DevWait
;
; Вызов:	BL = команда идентификации устройства
;		DX = базовый порт
;		AL = номер устройства
;		ES:DI -> буфер для информации об устройстве
;		         (структура ATA_DEVICE_INFO)
;
; Возврат:	CF = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	AX, BL, CX, DX, Flags
;*******************************************************************************
IdentifyDevice:
		and	al,1
		mov	cl,4
		shl	al,cl
		or	al,0A0h
		add	dx,6		; DX = регистр выбора устройства/головки
		out	dx,al		; выбор устройства

		inc	dx		; DX = регистр команды/состояния
		in	al,dx		; AL = байт состояния устройства
		cmp	al,0FFh
		je	@@Error

		call	DevWait
		jc	@@Error

		mov	al,bl
		out	dx,al		; команда идентификации устройства

		call	DevWait
		jc	@@Error

		mov	cx,100h
@@WaitLoop:	in	al,dx		; AL = байт состояния устройства
		test	al,8		; установлен бит DRQ?
		jnz	@@Ok
		loop	@@WaitLoop

@@Error:	stc

		ret

@@Ok:		sub	dx,7		; DX = регистр данных

		push	di

		mov	cx,100h
		cld
		cli
@@ReadInfoLoop:	in	ax,dx		; чтение данных
		stosw
		loop	@@ReadInfoLoop
		sti

		pop	di

		add	dx,7		; DX = регистр команды/состояния
		in	al,dx		; AL = байт состояния устройства
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
;   регистры:	AX, CX, DX, Flags
;*******************************************************************************
DetectATAPIDevice	PROC

		and	al,1
		mov	cl,4
		shl	al,cl
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

		inc	dx
		inc	dx		; DX = регистр команды/состояния
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
;   регистры:	AX, CX, Flags
;*******************************************************************************
DevWait		PROC

		mov	ah,14h
@@WaitLoop1:	xor	cx,cx
@@WaitLoop2:	in	al,dx		; AL = байт состояния устройства
		test	al,80h		; устройство занято?
		jz	@@Exit
		loop	@@WaitLoop2
		dec	ah
		jnz	@@WaitLoop1

		stc

@@Exit:		ret

DevWait		ENDP


END
