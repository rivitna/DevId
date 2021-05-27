;*******************************************************************************
;* DevIdNT.INC - Типы данных для устройств (Windows NT)                        *
;* Версия 1.01 (Сентябрь 2009 г.)                                              *
;*                                                                             *
;* OS: Windows NT                                                              *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************


; Максимальный номер устройства
MAX_DEVICE_NUM	EQU	7


;*******************************************************************************
;* Информация о геометрии физических дисков
;*******************************************************************************

IOCTL_DISK_GET_DRIVE_GEOMETRY	EQU	70000h

DISK_GEOMETRY	STRUC
	dg_Cylinders		DQ	?
	dg_MediaType		DD	?
	dg_TracksPerCylinder	DD	?
	dg_SectorsPerTrack	DD	?
	dg_BytesPerSector	DD	?
DISK_GEOMETRY	ENDS

; MediaType
RemovableMedia	EQU	0Bh	; Съемный носитель
FixedMedia	EQU	0Ch	; Жесткий диск


;*******************************************************************************
;* Идентификация устройств ATA/ATAPI (SMART)
;*******************************************************************************

SMART_GET_VERSION		EQU	74080h
SMART_SEND_DRIVE_COMMAND	EQU	7C084h
SMART_RCV_DRIVE_DATA		EQU	7C088h

GETVERSIONINPARAMS	STRUC
	gvip_bVersion		DB	?	; Binary driver version
	gvip_bRevision		DB	?	; Binary driver revision
	gvip_bReserved		DB	?	; Not used
	gvip_bIDEDeviceMap	DB	?	; Bit map of IDE devices
	gvip_dwCapabilities	DD	?	; Bit mask of driver capabilities
	gvip_dwReserved		DD	4 DUP(?); For future use
GETVERSIONINPARAMS	ENDS

; Bits returned in the fCapabilities member of GETVERSIONINPARAMS
CAP_ATA_ID_CMD		EQU	1		; ATA ID command supported
CAP_ATAPI_ID_CMD	EQU	2		; ATAPI ID command supported
CAP_SMART_CMD		EQU	4		; SMART commannds supported

IDEREGS		STRUC
	ir_bFeaturesReg		DB	?	; Used for specifying SMART "commands"
	ir_bSectorCountReg	DB	?	; IDE sector count register
	ir_bSectorNumberReg	DB	?	; IDE sector number register
	ir_bCylLowReg		DB	?	; IDE low order cylinder value
	ir_bCylHighReg		DB	?	; IDE high order cylinder value
	ir_bDriveHeadReg	DB	?	; IDE drive/head register
	ir_bCommandReg		DB	?	; Actual IDE command
	ir_bReserved		DB	?	; Reserved for future use.
						; Must be zero
IDEREGS		ENDS

; Valid values for the bCommandReg member of IDEREGS
ATAPI_ID_CMD		EQU	0A1h		; Returns ID sector for ATAPI
ID_CMD			EQU	0ECh		; Returns ID sector for ATA
SMART_CMD		EQU	0B0h		; Performs SMART cmd
						; Requires valid bFeaturesReg,
						; bCylLowReg, and bCylHighReg

; Cylinder register defines for SMART command
SMART_CYL_LOW		EQU	4Fh
SMART_CYL_HI		EQU	0C2h

SENDCMDINPARAMS	STRUC
	scip_dwBufferSize	DD	?	; Buffer size in bytes
	scip_irDriveRegs	IDEREGS	<>	; Structure with drive register
						; values
	scip_bDriveNumber	DB	?	; Physical drive number to send
						; command to (0,1,2,3)
	scip_bReserved		DB	3 DUP(?); Reserved for future expansion
	scip_dwReserved		DD	4 DUP(?); For future use
	scip_bBuffer		DB	?	; Input buffer
SENDCMDINPARAMS	ENDS

DRIVERSTATUS	STRUC
	ds_bDriverError		DB	?	; Error code from driver,
						; or 0 if no error
	ds_bIDEError		DB	?	; Contents of IDE Error register
						; Only valid when bDriverError
						; is SMART_IDE_ERROR
	ds_bReserved		DB	2 DUP(?); Reserved for future expansion
	ds_dwReserved		DD	2 DUP(?); Reserved for future expansion
DRIVERSTATUS	ENDS

; bDriverError values
DRVERR_NO_ERROR		EQU	0		; No error
DRVERR_IDE_ERROR	EQU	1		; Error from IDE controller
DRVERR_INVALID_FLAG	EQU	2		; Invalid command flag
DRVERR_INVALID_COMMAND	EQU	3		; Invalid command byte
DRVERR_INVALID_BUFFER	EQU	4		; Bad buffer (null, invalid addr..)
DRVERR_INVALID_DRIVE	EQU	5		; Drive number not valid
DRVERR_INVALID_IOCTL	EQU	6		; Invalid IOCTL
DRVERR_ERROR_NO_MEM	EQU	7		; Could not lock user's buffer
DRVERR_INVALID_REGISTER	EQU	8		; Some IDE Register not valid
DRVERR_NOT_SUPPORTED	EQU	9		; Invalid cmd flag set
DRVERR_NO_IDE_DEVICE	EQU	10		; Cmd issued to device not present
						; although drive number is valid

SENDCMDOUTPARAMS	STRUC
	scop_dwBufferSize	DD		?	; Size of bBuffer in bytes
	scop_DriverStatus	DRIVERSTATUS	<>	; Driver status structure
	scop_bBuffer		DB		?	; Buffer of arbitrary
							; length in which to
							; store the data read
							; from the drive
SENDCMDOUTPARAMS	ENDS


;*******************************************************************************
;* Идентификация устройств SCSI
;*******************************************************************************

IOCTL_SCSI_PASS_THROUGH	EQU	0004D004h

; Define the SCSI pass through structure
SCSI_PASS_THROUGH	STRUC
	spt_Length		DW	?
	spt_ScsiStatus		DB	?
	spt_PathId		DB	?
	spt_TargetId		DB	?
	spt_Lun			DB	?
	spt_CdbLength		DB	?
	spt_SenseInfoLength	DB	?
	spt_DataIn		DB	?
ALIGN	4
	spt_DataTransferLength	DD	?
	spt_TimeOutValue	DD	?
	spt_DataBufferOffset	DD	?
	spt_SenseInfoOffset	DD	?
	spt_Cdb			DB	16 DUP(?)
SCSI_PASS_THROUGH	ENDS

; Command Descriptor Block constants
CDB6GENERIC_LENGTH	EQU	6
CDB10GENERIC_LENGTH	EQU	10
CDB12GENERIC_LENGTH	EQU	12

; Define values for pass-through DataIn field
SCSI_IOCTL_DATA_OUT		EQU	0
SCSI_IOCTL_DATA_IN		EQU	1
SCSI_IOCTL_DATA_UNSPECIFIED	EQU	2

; Cdb
SCSIOP_INQUIRY		EQU	12h	; Operation Code

; Enable Vital Product Data Flag (EVPD)
; used with INQUIRY command
CDB_INQUIRY_EVPD	EQU	01h

SPT_SENSE_BUFFER_SIZE	EQU	32
SPT_DATA_BUFFER_SIZE	EQU	192

SCSI_PASS_THROUGH_WITH_BUFFERS	STRUC
	sptwb_spt	SCSI_PASS_THROUGH	<>
	sptwb_SenseBuf	DB			SPT_SENSE_BUFFER_SIZE DUP(?)
	sptwb_DataBuf	DB			SPT_DATA_BUFFER_SIZE DUP(?)
SCSI_PASS_THROUGH_WITH_BUFFERS	ENDS
