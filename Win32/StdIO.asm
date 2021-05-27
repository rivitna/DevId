;*******************************************************************************
;* StdIO.ASM - Стандартный ввод-вывод                                          *
;* Версия 1.02 (Январь 2012 г.)                                                *
;*                                                                             *
;* OS: Win32                                                                   *
;*                                                                             *
;* Copyright (c) 2001-2012 rivitna                                             *
;*******************************************************************************

.386
LOCALS

.MODEL	FLAT


L			EQU	<LARGE>

; Значения параметра функции GetStdHandle
STD_INPUT_HANDLE	EQU	-10
STD_OUTPUT_HANDLE	EQU	-11
STD_ERROR_HANDLE	EQU	-12

PRINTF_BUFFER_SIZE	EQU	1024	; размер буфера для форматированного вывода

INCLUDELIB	IMPORT32.LIB

EXTRN	lstrlenA:PROC
EXTRN	GetStdHandle:PROC
EXTRN	WriteFile:PROC
EXTRN	wvsprintfA:PROC


.CODE

PUBLIC	printf
PUBLIC	puts
PUBLIC	fputs

;*******************************************************************************
; printf	Форматированный вывод на стандартное устройство вывода
;*******************************************************************************
; Использует:	wvsprintfA,
;		puts
;
; Вызов:	lpszFormat -> строка формата
;		...
;
; Возврат:	EAX = количество выведенных символов
;
; Изменяемые
;   регистры:	ESP, EAX, ECX, EDX, Flags
;*******************************************************************************
printf		PROC	C
		ARG	@@lpszFormat:DWORD
		LOCAL	@@buf:BYTE:PRINTF_BUFFER_SIZE

		lea	eax,[@@buf]		; EAX -> @@buf
		push	eax

		lea	ecx,[@@lpszFormat+4]	; ECX -> дополнительные параметры
		push	ecx
		push	[@@lpszFormat]
		push	eax
		call	wvsprintfA

		call	puts			; EAX = количество выведенных
						; символов

		ret

printf		ENDP

;*******************************************************************************
; puts		Вывод строки на стандартное устройство вывода
;*******************************************************************************
; Использует:	GetStdHandle,
;		fputs
;
; Вызов:	lpszString -> выводимая строка
;
; Возврат:	EAX = количество выведенных символов
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
puts		PROC	NEAR

		push	DWORD PTR [esp+4]	; ESP+4 -> lpszString
		push	L STD_OUTPUT_HANDLE
		call	GetStdHandle		; EAX = дескриптор стандартного
						; устройства вывода
		push	eax
		call	fputs			; EAX = количество выведенных
						; символов

		ret	4

puts		ENDP

;*******************************************************************************
; fputs		Вывод строки в файл
;*******************************************************************************
; Использует:	lstrlenA, WriteFile
;
; Вызов:	hFile = дескриптор файла
;		lpszString -> выводимая строка
;
; Возврат:	EAX = количество выведенных символов
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
fputs		PROC	NEAR

		push	DWORD PTR [esp+8]	; ESP+8 -> lpszString
		call	lstrlenA		; EAX = длина строки
		or	eax,eax
		jz	@@Exit

		xor	ecx,ecx
		push	ecx
		mov	edx,esp
		push	ecx
		push	edx
		push	eax
		push	DWORD PTR [esp+24]	; ESP+24 -> lpszString
		push	DWORD PTR [esp+24]	; ESP+24 -> hFile
		call	WriteFile		; EAX = флаг успешного/неудачного
						; завершения
		pop	ecx			; ECX = количество выведенных
						; символов
		or	eax,eax
		jz	@@Exit

		mov	eax,ecx			; EAX = количество выведенных
						; символов

@@Exit:		ret	8

fputs		ENDP


END
