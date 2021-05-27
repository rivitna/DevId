;*******************************************************************************
;* Ring0.ASM - ���������� ���� � ������� ������ (Ring 0)                       *
;* ������ 1.03 (������ 2007 �.)                                                *
;*                                                                             *
;* OS: Windows 9x                                                              *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************

.386P
LOCALS

.MODEL	FLAT


;*******************************************************************************
; ������� GDTR
;*******************************************************************************
GDTR		STRUC
	gdtr_wLimit		DW	?
	gdtr_dwBase		DD	?
GDTR		ENDS

;*******************************************************************************
; ���������� ��������
;*******************************************************************************
SEG_DESCRIPTOR	STRUC
	segd_wLimit_0_15	DW	?
	segd_wBase_0_15		DW	?
	segd_bBase_16_23	DB	?
	segd_bAR		DB	?	; ��� 0    = Accessed
						; ���� 1-3 = Type
						; ��� 4    = System
						; ���� 5-6 = DPL
						; ��� 7    = Present
	segd_bLimit_16_19	DB	?	; ���� 0-3 = Limit (���� 16-19)
						; ��� 4    = Available
						; ��� 5    = Reserved
						; ��� 6    = DefaultSize
						; ��� 7    = Granularity
	segd_bBase_24_31	DB	?
SEG_DESCRIPTOR	ENDS

;*******************************************************************************
; ���������� ����� ������
;*******************************************************************************
CALLGATE_DESCRIPTOR	STRUC
	cgd_wOffset_0_15	DW	?
	cgd_wSelector		DW	?
	cgd_bWC			DB	?	; ���� 0-4 = WC
						; ���� 5-7 = 0
	cgd_bAR			DB	?	; ��� 0    = Accessed
						; ���� 1-3 = Type
						; ��� 4    = System
						; ���� 5-6 = DPL
						; ��� 7    = Present
	cgd_wOffset_16_31	DW	?
CALLGATE_DESCRIPTOR	ENDS


.CODE

PUBLIC	Ring0Call

;*******************************************************************************
; Ring0Call	����� ��������� � ������� ������ (!!! ������ Windows 9x !!!)
;*******************************************************************************
; �����:	lpRing0Proc  = ����� ���������� ���������
;		dwParams     = ���������, ������������ ���������� ���������
;		lpdwRetValue = ����� ���������� (DWORD) ��� ���������� ��������,
;		               ������������� ����������
;
; �������:	EAX = ���� ���������/���������� ����������
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
; ���������� ��������� ������ ������������� ��������� �����������:
; 1) ��������� ������ ���� ������� (FAR), �� ���� ������� �� ���������
; ������ �������������� � ������� ������� retf (FAR ret);
; 2) ������� ESI �� ������ ����������������.
; �����:	EAX = ��������(�)
; �������:	EAX = ������������ ��������
;*******************************************************************************
Ring0Call	PROC
		ARG	@@lpRing0Proc:DWORD, @@dwParams:DWORD, \
			@@lpdwRetValue:DWORD = ARG_SIZE

		push	ebp			; ��������� ��������
		mov	ebp,esp
		push	esi

		sldt	ax			; AX = �������� LDT
		and	eax,0FFF8h		; EAX = �������� ����������� LDT
						; � GDT
		jz	@@NoFreeEntries

		push	esi
		sgdt	FWORD PTR [esp-2]
		pop	esi			; ESI = ������� ����� GDT

		add	esi,eax			; ESI -> ���������� LDT

		movzx	ecx,WORD PTR [esi]	; ECX = ������ LDT
		inc	ecx
		shr	ecx,3			; ECX = ����� ������������ � LDT
		mov	edx,[esi+1]
		mov	dl,[esi+7]
		ror	edx,8			; EDX = ������� ����� LDT
		mov	esi,edx			; ESI = ������� ����� LDT

; ���� ��������� ���������� � LDT
@@EntryLoop:	cmp	[esi.segd_bAR],0
		je	@@FoundFreeEntry
		add	esi,8
		loop	@@EntryLoop

@@NoFreeEntries:
		xor	eax,eax			; EAX=0
		jmp	@@Exit

@@FoundFreeEntry:
; ������ ��������� ���������� LDT

; ����������� ���������� LDT � ���� ������
		mov	eax,[@@lpRing0Proc]
		mov	DWORD PTR [esi],eax
		mov	DWORD PTR [esi+4],eax
		mov	DWORD PTR [esi+2],0EC000028h	; Selector = 28h
							; WC       = 0
							; AR       = 11101100b

; �������� ��������� ����� ���� ������
		mov	eax,esi
		sub	eax,edx
		or	al,7			; AX = �������� ����� ������
		push	ax
		push	eax			; ESP -> ��������� �� ���� ������
		mov	eax,[@@dwParams]	; EAX = ��������� ���������
		call	FWORD PTR [esp]		; ����� ���������
						; EAX = ������������ ��������
		add	esp,6
		mov	ecx,[@@lpdwRetValue]
		jecxz	@@FreeEntry
		mov	DWORD PTR [ecx],eax

@@FreeEntry:
; ����������� ���������� LDT
		xor	eax,eax
		mov	DWORD PTR [esi],eax
		mov	DWORD PTR [esi+4],eax

		inc	eax			; EAX=1

@@Exit:		pop	esi			; ��������������� ��������
		pop	ebp

		ret	ARG_SIZE

Ring0Call	ENDP


END
