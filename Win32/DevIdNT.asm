;*******************************************************************************
;* DevIdNT.ASM - Идентификация устройств (Windows NT)                          *
;* Версия 1.03 (Сентябрь 2009 г.)                                              *
;*                                                                             *
;* OS: Windows NT                                                              *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************

.386
LOCALS

.MODEL	FLAT


INCLUDE	ATA.inc
INCLUDE	DevIdNT.inc


L			EQU	<LARGE>

OPEN_EXISTING		EQU	3
FILE_SHARE_READ		EQU	1
FILE_SHARE_WRITE	EQU	2
GENERIC_READ		EQU	80000000h
GENERIC_WRITE		EQU	40000000h


INCLUDELIB	IMPORT32.LIB

EXTRN	CreateFileA:PROC
EXTRN	DeviceIoControl:PROC


.CODE

PUBLIC	NtGetPhysicalDriveHandle
PUBLIC	SMART_IdentifyDevice
PUBLIC	NtGetSCSIDeviceSerialNumber
PUBLIC	NtGetDiskGeometry

;*******************************************************************************
; NtGetPhysicalDriveHandle	Получение дескриптора физического устройства
;				(Windows NT с правами администратора)
;*******************************************************************************
; Использует:	CreateFileA
;
; Вызов:	AL = номер устройства
;
; Возврат:	EAX = дескриптор устройства
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
NtGetPhysicalDriveHandle	PROC

		cmp	al,MAX_DEVICE_NUM
		ja	@@Error

		push	L '0e'
		push	L 'virD'
		push	L 'laci'
		push	L 'syhP'
		push	L '\.\\'
		mov	ecx,esp		; ECX -> "\\.\PhysicalDrive0"
		or	[ecx+17],al	; ECX -> "\\.\PhysicalDriveN"

		xor	eax,eax		; EAX=0
		push	eax
		push	eax
		push	L OPEN_EXISTING
		push	eax
		push	L (FILE_SHARE_READ OR FILE_SHARE_WRITE)
		push	L (GENERIC_READ OR GENERIC_WRITE)
		push	ecx
		call	CreateFileA	; EAX = дескриптор устройства

		add	esp,5 * 4	; восстановление стека

		ret

@@Error:	xor	eax,eax
		dec	eax		; EAX=-1

		ret

NtGetPhysicalDriveHandle	ENDP

;*******************************************************************************
; SMART_IdentifyDevice	Идентификация устройства ATA/ATAPI (SMART)
;*******************************************************************************
; Использует:	DeviceIoControl
;
; Вызов:	EAX = дескриптор устройства
;		DL = номер устройства
;		EDI -> буфер для информации об устройстве
;		       (структура ATA_DEVICE_INFO)
;
; Возврат:	EAX = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
SMART_IdentifyDevice	PROC
			LOCAL	@@gvip:GETVERSIONINPARAMS, \
				@@scip:BYTE:SIZE SENDCMDINPARAMS - 1, \
				@@scop:BYTE:SIZE SENDCMDOUTPARAMS - 1 + DEVICE_INFO_BUFFER_SIZE, \
				@@dwBytesReturned:DWORD = LOCAL_SIZE

		enter	LOCAL_SIZE,0
		push	ebx
		push	esi

		cld

		mov	esi,eax		; ESI = дескриптор устройства
		mov	bl,dl		; BL = номер устройства
		and	bl,MAX_DEVICE_NUM

		xor	eax,eax		; EAX=0

; Обнуляем локальные переменные
		push	edi
		lea	edi,[ebp-LOCAL_SIZE]
		mov	ecx,LOCAL_SIZE / 4
		rep	stosd
		pop	edi

; Получаем информацию о версии драйвера
		push	eax
		lea	ecx,[@@dwBytesReturned]
		push	ecx
		push	L SIZE GETVERSIONINPARAMS
		lea	ecx,[@@gvip]
		push	ecx
		push	eax
		push	eax
		push	L SMART_GET_VERSION
		push	esi
		call	DeviceIoControl
		or	eax,eax
		jz	@@Exit

; Идентификация устройства ATA/ATAPI
		mov	al,[@@gvip.gvip_bIDEDeviceMap]
		mov	cl,bl
		shr	al,cl
		test	al,10h		; устройство ATAPI?
		mov	ah,ID_CMD	; AH=0ECh (команда идентификации
					; устройства ATA)
		jz	@@DoIdentify

		mov	ah,ATAPI_ID_CMD	; AH=0A1h (команда идентификации
					; устройства ATAPI)

@@DoIdentify:	mov	[@@scip.scip_dwBufferSize],DEVICE_INFO_BUFFER_SIZE
		mov	[@@scip.scip_bDriveNumber],bl
		mov	[@@scip.scip_irDriveRegs.ir_bSectorCountReg],1
		mov	[@@scip.scip_irDriveRegs.ir_bSectorNumberReg],1
		and	bl,1
		shl	bl,4
		or	bl,0A0h
		mov	[@@scip.scip_irDriveRegs.ir_bDriveHeadReg],bl
		mov	[@@scip.scip_irDriveRegs.ir_bCommandReg],ah

		push	L 0
		lea	eax,[@@dwBytesReturned]
		push	eax
		push	L (SIZE SENDCMDOUTPARAMS - 1 + DEVICE_INFO_BUFFER_SIZE)
		lea	eax,[@@scop]
		push	eax
		push	L (SIZE SENDCMDINPARAMS - 1)
		lea	eax,[@@scip]
		push	eax
		push	L SMART_RCV_DRIVE_DATA
		push	esi
		call	DeviceIoControl
		or	eax,eax
		jz	@@Exit
		xor	eax,eax		; EAX=0
		cmp	[@@scop.scop_DriverStatus.ds_bDriverError],al	; DRVERR_NO_ERROR?
		jne	@@Exit

; Копируем информацию в буфер
		push	edi
		lea	esi,[@@scop.scop_bBuffer]
		mov	ecx,DEVICE_INFO_BUFFER_SIZE / 4
		rep	movsd
		pop	edi

		inc	eax		; EAX=1

@@Exit:		pop	esi
		pop	ebx
		leave

		ret

SMART_IdentifyDevice	ENDP

;*******************************************************************************
; NtGetSCSIDeviceSerialNumber	Получение серийного номера устройства SCSI
;*******************************************************************************
; Использует:	DeviceIoControl
;
; Вызов:	EAX = дескриптор физического устройства
;		EDI -> буфер для серийного номера устройства SCSI
;
; Возврат:	EAX = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
NtGetSCSIDeviceSerialNumber	PROC
				LOCAL	@@sptwb:BYTE:SIZE SCSI_PASS_THROUGH_WITH_BUFFERS + SIZE SCSI_PASS_THROUGH, \
					@@dwBytesReturned:DWORD = LOCAL_SIZE

		enter	LOCAL_SIZE,0

		cld

		mov	edx,eax		; EDX = дескриптор устройства

; Обнуляем локальные переменные
		push	edi
		lea	edi,[ebp-LOCAL_SIZE]
		mov	ecx,LOCAL_SIZE / 4
		xor	eax,eax
		rep	stosd
		pop	edi

; Получение серийного номера устройства SCSI
		mov	[@@sptwb.sptwb_spt.spt_Length],SIZE SCSI_PASS_THROUGH
		mov	[@@sptwb.sptwb_spt.spt_CdbLength],CDB6GENERIC_LENGTH
		mov	[@@sptwb.sptwb_spt.spt_SenseInfoLength],SPT_SENSE_BUFFER_SIZE
		mov	[@@sptwb.sptwb_spt.spt_DataIn],SCSI_IOCTL_DATA_IN
		mov	[@@sptwb.sptwb_spt.spt_DataTransferLength],SPT_DATA_BUFFER_SIZE
		mov	[@@sptwb.sptwb_spt.spt_TimeOutValue],2
		mov	[@@sptwb.sptwb_spt.spt_DataBufferOffset],OFFSET sptwb_DataBuf
		mov	[@@sptwb.sptwb_spt.spt_SenseInfoOffset],OFFSET sptwb_SenseBuf
		; Operation Code
		mov	[@@sptwb.sptwb_spt.spt_Cdb],SCSIOP_INQUIRY
		; Flags: Enable Vital product data
		mov	[@@sptwb.sptwb_spt.spt_Cdb+1],CDB_INQUIRY_EVPD
		; Page Code: Unit serial number
		mov	[@@sptwb.sptwb_spt.spt_Cdb+2],80h
		; Allocation Length
		mov	[@@sptwb.sptwb_spt.spt_Cdb+4],SPT_DATA_BUFFER_SIZE

		push	L 0
		lea	eax,[@@dwBytesReturned]
		push	eax
		push	L (OFFSET sptwb_DataBuf + SPT_DATA_BUFFER_SIZE)
		lea	eax,[@@sptwb]
		push	eax
		push	L SIZE SCSI_PASS_THROUGH
		push	eax
		push	L IOCTL_SCSI_PASS_THROUGH
		push	edx
		call	DeviceIoControl
		or	eax,eax
		jz	@@Exit
		xor	eax,eax		; EAX=0
		cmp	[@@sptwb.sptwb_DataBuf+1],80h
		jne	@@Exit

; Копируем серийный номер в буфер
		push	esi
		push	edi
		lea	esi,[@@sptwb.sptwb_DataBuf+4]
		movzx	ecx,BYTE PTR [@@sptwb.sptwb_DataBuf+3]
		rep	movsb
		stosb
		pop	edi
		pop	esi

		inc	eax		; EAX=1

@@Exit:		leave

		ret

NtGetSCSIDeviceSerialNumber	ENDP

;*******************************************************************************
; NtGetDiskGeometry	Получение информации о геометрии физического диска
;*******************************************************************************
; Использует:	DeviceIoControl
;
; Вызов:	EAX = дескриптор физического устройства
;		EDI -> буфер для информации о геометрии физического диска
;		       (структура DISK_GEOMETRY)
;
; Возврат:	EAX = флаг успешного/неудачного завершения
;
; Изменяемые
;   регистры:	EAX, ECX, EDX, Flags
;*******************************************************************************
NtGetDiskGeometry	PROC

		xor	ecx,ecx		; ECX=0

		push	ecx
		mov	edx,esp

		push	ecx
		push	edx
		push	L SIZE DISK_GEOMETRY
		push	edi
		push	ecx
		push	ecx
		push	L IOCTL_DISK_GET_DRIVE_GEOMETRY
		push	eax
		call	DeviceIoControl

		pop	ecx

		ret

NtGetDiskGeometry	ENDP


END
