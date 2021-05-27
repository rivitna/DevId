;*******************************************************************************
;* Ring0.ASM - Выполнение кода в нулевом кольце (Ring 0)                       *
;* Версия 1.03 (Январь 2007 г.)                                                *
;*                                                                             *
;* OS: Windows 9x                                                              *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************

.386P
LOCALS

.MODEL	FLAT


;*******************************************************************************
; Регистр GDTR
;*******************************************************************************
GDTR		STRUC
	gdtr_wLimit		DW	?
	gdtr_dwBase		DD	?
GDTR		ENDS

;*******************************************************************************
; Дескриптор сегмента
;*******************************************************************************
SEG_DESCRIPTOR	STRUC
	segd_wLimit_0_15	DW	?
	segd_wBase_0_15		DW	?
	segd_bBase_16_23	DB	?
	segd_bAR		DB	?	; бит 0    = Accessed
						; биты 1-3 = Type
						; бит 4    = System
						; биты 5-6 = DPL
						; бит 7    = Present
	segd_bLimit_16_19	DB	?	; биты 0-3 = Limit (биты 16-19)
						; бит 4    = Available
						; бит 5    = Reserved
						; бит 6    = DefaultSize
						; бит 7    = Granularity
	segd_bBase_24_31	DB	?
SEG_DESCRIPTOR	ENDS

;*******************************************************************************
; Дескриптор шлюза вызова
;*******************************************************************************
CALLGATE_DESCRIPTOR	STRUC
	cgd_wOffset_0_15	DW	?
	cgd_wSelector		DW	?
	cgd_bWC			DB	?	; биты 0-4 = WC
						; биты 5-7 = 0
	cgd_bAR			DB	?	; бит 0    = Accessed
						; биты 1-3 = Type
						; бит 4    = System
						; биты 5-6 = DPL
						; бит 7    = Present
	cgd_wOffset_16_31	DW	?
CALLGATE_DESCRIPTOR	ENDS


.CODE

PUBLIC	Ring0Call

;*******************************************************************************
; Ring0Call	Вызов процедуры в нулевом кольце (!!! Только Windows 9x !!!)
;*******************************************************************************
; Вызов:	lpRing0Proc  = адрес вызываемой процедуры
;		dwParams     = параметры, передаваемые вызываемой процедуре
;		lpdwRetValue = адрес переменной (DWORD) для сохранения значения,
;		               возвращаемого процедурой
;
; Возврат:	EAX = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
; Вызываемая процедура должна удовлетворять следующим требованиям:
; 1) процедура должна быть дальней (FAR), то есть возврат из процедуры
; должен осуществляться с помощью команды retf (FAR ret);
; 2) регистр ESI не должен модифицироваться.
; Вызов:	EAX = параметр(ы)
; Возврат:	EAX = возвращаемое значение
;*******************************************************************************
Ring0Call	PROC
		ARG	@@lpRing0Proc:DWORD, @@dwParams:DWORD, \
			@@lpdwRetValue:DWORD = ARG_SIZE

		push	ebp			; сохраняем регистры
		mov	ebp,esp
		push	esi

		sldt	ax			; AX = селектор LDT
		and	eax,0FFF8h		; EAX = смещение дескриптора LDT
						; в GDT
		jz	@@NoFreeEntries

		push	esi
		sgdt	FWORD PTR [esp-2]
		pop	esi			; ESI = базовый адрес GDT

		add	esi,eax			; ESI -> дескриптор LDT

		movzx	ecx,WORD PTR [esi]	; ECX = предел LDT
		inc	ecx
		shr	ecx,3			; ECX = число дескрипторов в LDT
		mov	edx,[esi+1]
		mov	dl,[esi+7]
		ror	edx,8			; EDX = базовый адрес LDT
		mov	esi,edx			; ESI = базовый адрес LDT

; Ищем свободный дескриптор в LDT
@@EntryLoop:	cmp	[esi.segd_bAR],0
		je	@@FoundFreeEntry
		add	esi,8
		loop	@@EntryLoop

@@NoFreeEntries:
		xor	eax,eax			; EAX=0
		jmp	@@Exit

@@FoundFreeEntry:
; Найден свободный дескриптор LDT

; Преобразуем дескриптор LDT в шлюз вызова
		mov	eax,[@@lpRing0Proc]
		mov	DWORD PTR [esi],eax
		mov	DWORD PTR [esi+4],eax
		mov	DWORD PTR [esi+2],0EC000028h	; Selector = 28h
							; WC       = 0
							; AR       = 11101100b

; Вызываем процедуру через шлюз вызова
		mov	eax,esi
		sub	eax,edx
		or	al,7			; AX = селектор шлюза вызова
		push	ax
		push	eax			; ESP -> указатель на шлюз вызова
		mov	eax,[@@dwParams]	; EAX = параметры процедуры
		call	FWORD PTR [esp]		; вызов процедуры
						; EAX = возвращаемое значение
		add	esp,6
		mov	ecx,[@@lpdwRetValue]
		jecxz	@@FreeEntry
		mov	DWORD PTR [ecx],eax

@@FreeEntry:
; Освобождаем дескриптор LDT
		xor	eax,eax
		mov	DWORD PTR [esi],eax
		mov	DWORD PTR [esi+4],eax

		inc	eax			; EAX=1

@@Exit:		pop	esi			; восстанавливаем регистры
		pop	ebp

		ret	ARG_SIZE

Ring0Call	ENDP


END
