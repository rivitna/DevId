LOCALS

.MODEL	TINY


INCLUDE	ATA.inc


; Макрос определения PASCAL-строки
PASSTR	MACRO	name, str
LOCAL	len
name	DB	len, "&str"
len	=	$ - name - 1
ENDM


; Длина заголовка устройства
DEV_TITLE_LEN		EQU	59
; Отступ названия устройства в заголовке (<= DEV_TITLE_LEN - 2)
DEV_TITLE_INDENT	EQU	3
; Символ заполнения заголовка устройства
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
		pop	ds			; DS = сегмент кода
		push	cs
		pop	es			; ES = сегмент кода

; Сканирование устройств ATA/ATAPI
		mov	si,OFFSET ATADeviceList	; DS:SI -> ATADeviceList
		mov	di,OFFSET DevInfo	; ES:DI -> DevInfo
		mov	bp,ATADEVICECOUNT

@@DevLoop:
		mov	dx,[si.add_wBasePort]
		mov	al,[si.add_bDevNum]
; Определение наличия устройства ATAPI
		push	ax
		push	dx
		call	DetectATAPIDevice
		pop	dx
		pop	ax
		mov	bl,0ECh			; BL=0ECh (команда идентификации
						; устройства ATA)
		jc	@@DoIdentifyDev

		mov	bl,0A1h			; BL=0A1h (команда идентификации
						; устройства ATAPI)

@@DoIdentifyDev:
; Идентификация устройства ATA/ATAPI
		call	IdentifyDevice
		jc	@@NextDev

; Вывод информации об устройстве ATA/ATAPI
		mov	dx,[si.add_psName]
		call	PrintDevTitle
		call	PrintDevInfo

@@NextDev:	add	si,SIZE ATADEVDATA
		dec	bp
		jnz	@@DevLoop

		mov	bx,2			; BX=2 (стандартное устройство
						; вывода ошибки)
		mov	dx,OFFSET sPressAnyKey
		mov	cx,PRESSANYKEYLEN
		call	WriteFile

		xor	ah,ah
		int	16h

		mov	ax,4C00h		; AH=4Ch (функция завершения
						; программы)
		int	21h


;*******************************************************************************
; PrintDevTitle	Вывод заголовка устройства
;*******************************************************************************
; Использует:	PrintChar, PrintCharN, PrintStr, PrintNewLine
;
; Вызов:	DS:DX -> PASCAL-строка с названием устройства
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, BX, CX, DX, Flags
;*******************************************************************************
PrintDevTitle	PROC

		mov	bx,dx			; DS:BX -> PASCAL-строка
						; с названием устройства

		mov	cl,DEV_TITLE_INDENT	; CL = количество символов
						; заполнения слева
		mov	dl,DEV_TITLE_FILL_CHAR
		call	PrintCharN

		mov	dl,' '
		call	PrintChar

		mov	cl,[bx]			; CL = длина строки с названием
						; устройства
		lea	dx,[bx+1]		; DS:DX -> строка с названием
						; устройства
		call	PrintStr

		sub	cl,DEV_TITLE_LEN - DEV_TITLE_INDENT - 2
		jnb	@@DoPrintNewLine

		mov	dl,' '
		call	PrintChar

		neg	cl			; CL = количество символов
						; заполнения справа
		mov	dl,DEV_TITLE_FILL_CHAR
		call	PrintCharN

@@DoPrintNewLine:
		jmp	PrintNewLine

PrintDevTitle	ENDP

;*******************************************************************************
; PrintDevInfo	Вывод информации об устройстве
;*******************************************************************************
; Использует:	PrintPasStr, PrintStr, PrintNewLine
;
; Вызов:	DS:DI -> буфер с информацией об устройстве
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, BX, CX, DX, Flags
;*******************************************************************************
PrintDevInfo	PROC

; Тип устройства
		mov	dx,OFFSET sDevice
		call	PrintPasStr

		mov	al,[di+1]
		test	al,80h			; устройство ATAPI?
		mov	dx,OFFSET sHDD
		jz	@@DoPrintType

		and	al,1Fh			; AL = тип устройства ATAPI
		cmp	al,5			; CDROM?
		mov	dx,OFFSET sCDROM
		je	@@DoPrintType
		mov	dx,OFFSET sUnknownATAPI

@@DoPrintType:	call	PrintPasStr
		call	PrintNewLine

; Модель
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

; Серийный номер
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
; PrintPasStr	Вывод PASCAL-строки на стандартное устройство вывода
;*******************************************************************************
; Использует:	PrintStr
;
; Вызов:	DS:DX -> PASCAL-строка
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, BX, CX, DX, Flags
;*******************************************************************************
PrintPasStr	PROC

		mov	bx,dx			; DS:BX -> PASCAL-строка
		mov	cl,[bx]			; CL = длина строки
		inc	dx			; DS:DX -> строка

;*******************************************************************************
; PrintStr	Вывод строки на стандартное устройство вывода
;*******************************************************************************
; Использует:	WriteFile
;
; Вызов:	DS:DX -> строка
;		CL = длина строки
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, BX, CH, Flags
;*******************************************************************************
PrintStr:
		xor	ch,ch			; CX = длина данных в байтах
		mov	bx,1			; BX=1 (стандартное устройство
						; вывода)

;*******************************************************************************
; WriteFile	Запись данных в файл
;*******************************************************************************
; Использует:	int 21h
;
; Вызов:	BX = дескриптор файла
;		DS:DX -> данные
;		CX = длина данных в байтах
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, Flags
;*******************************************************************************
WriteFile:
		mov	ah,40h			; AH=40h (функция записи в файл)
		int	21h

		ret

PrintPasStr	ENDP

;*******************************************************************************
; PrintCharN	Вывод указанного количества копий символа на стандартное
;		устройство вывода
;*******************************************************************************
; Использует:	PrintChar
;
; Вызов:	DL = код символа
;		CL = количество копий символа
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, CL, Flags
;*******************************************************************************
PrintCharN	PROC

@@CharLoop:	call	PrintChar
		dec	cl
		jnz	@@CharLoop

		ret

PrintCharN	ENDP

;*******************************************************************************
; PrintNewLine	Перевод курсора на новую строку на стандартном устройстве вывода
;*******************************************************************************
; Использует:	PrintChar
;
; Вызов:	нет
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, DL, Flags
;*******************************************************************************
PrintNewLine	PROC

		mov	dl,0Dh
		call	PrintChar
		mov	dl,0Ah
		call	PrintChar

		ret

PrintNewLine	ENDP

;*******************************************************************************
; PrintChar	Вывод символа на стандартное устройство вывода
;*******************************************************************************
; Использует:	int 21h
;
; Вызов:	DL = код символа
;
; Возврат:	нет
;
; Изменяемые
;   регистры:	AX, Flags
;*******************************************************************************
PrintChar	PROC

		mov	ah,2			; AH=2 (функция вывода символа)
		int	21h

		ret

PrintChar	ENDP


END		Start
