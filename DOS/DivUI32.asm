LOCALS

.MODEL	SMALL


.CODE

PUBLIC	DivUI32

;*******************************************************************************
; DivUI32	Деление беззнаковых 32-разрядных чисел
;*******************************************************************************
; Использует:	нет
;
; Вызов:	DX:AX = делимое
;		CX:BX = делитель
;
; Возврат:	DX:AX = результат деления
;		CX:BX = остаток от деления
;
; Изменяемые
;   регистры:	AX, BX, CX, DX, Flags
;*******************************************************************************
DivUI32		PROC

		push	bp
		push	si
		push	di

		mov	bp,32

		xor	di,di
		xor	si,si

@@SubLoop:	shl	ax,1
		rcl	dx,1
		rcl	si,1
		rcl	di,1

		cmp	di,cx
		jb	@@NoSub
		ja	@@Subtract

		cmp	si,bx
		jb	@@NoSub

@@Subtract:	sub	si,bx
		sbb	di,cx
		inc	ax

@@NoSub:	dec	bp
		jnz	@@SubLoop

		mov	cx,di
		mov	bx,si

		pop	di
		pop	si
		pop	bp

		ret

DivUI32		ENDP


END
