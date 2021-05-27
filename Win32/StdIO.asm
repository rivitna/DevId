;*******************************************************************************
;* StdIO.ASM - ����������� ����-�����                                          *
;* ������ 1.02 (������ 2012 �.)                                                *
;*                                                                             *
;* OS: Win32                                                                   *
;*                                                                             *
;* Copyright (c) 2001-2012 rivitna                                             *
;*******************************************************************************

.386
LOCALS

.MODEL	FLAT


L			EQU	<LARGE>

; �������� ��������� ������� GetStdHandle
STD_INPUT_HANDLE	EQU	-10
STD_OUTPUT_HANDLE	EQU	-11
STD_ERROR_HANDLE	EQU	-12

PRINTF_BUFFER_SIZE	EQU	1024	; ������ ������ ��� ���������������� ������

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
; printf	��������������� ����� �� ����������� ���������� ������
;*******************************************************************************
; ����������:	wvsprintfA,
;		puts
;
; �����:	lpszFormat -> ������ �������
;		...
;
; �������:	EAX = ���������� ���������� ��������
;
; ����������
;   ��������:	ESP, EAX, ECX, EDX, Flags
;*******************************************************************************
printf		PROC	C
		ARG	@@lpszFormat:DWORD
		LOCAL	@@buf:BYTE:PRINTF_BUFFER_SIZE

		lea	eax,[@@buf]		; EAX -> @@buf
		push	eax

		lea	ecx,[@@lpszFormat+4]	; ECX -> �������������� ���������
		push	ecx
		push	[@@lpszFormat]
		push	eax
		call	wvsprintfA

		call	puts			; EAX = ���������� ����������
						; ��������

		ret

printf		ENDP

;*******************************************************************************
; puts		����� ������ �� ����������� ���������� ������
;*******************************************************************************
; ����������:	GetStdHandle,
;		fputs
;
; �����:	lpszString -> ��������� ������
;
; �������:	EAX = ���������� ���������� ��������
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
puts		PROC	NEAR

		push	DWORD PTR [esp+4]	; ESP+4 -> lpszString
		push	L STD_OUTPUT_HANDLE
		call	GetStdHandle		; EAX = ���������� ������������
						; ���������� ������
		push	eax
		call	fputs			; EAX = ���������� ����������
						; ��������

		ret	4

puts		ENDP

;*******************************************************************************
; fputs		����� ������ � ����
;*******************************************************************************
; ����������:	lstrlenA, WriteFile
;
; �����:	hFile = ���������� �����
;		lpszString -> ��������� ������
;
; �������:	EAX = ���������� ���������� ��������
;
; ����������
;   ��������:	EAX, ECX, EDX, Flags
;*******************************************************************************
fputs		PROC	NEAR

		push	DWORD PTR [esp+8]	; ESP+8 -> lpszString
		call	lstrlenA		; EAX = ����� ������
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
		call	WriteFile		; EAX = ���� ���������/����������
						; ����������
		pop	ecx			; ECX = ���������� ����������
						; ��������
		or	eax,eax
		jz	@@Exit

		mov	eax,ecx			; EAX = ���������� ����������
						; ��������

@@Exit:		ret	8

fputs		ENDP


END
