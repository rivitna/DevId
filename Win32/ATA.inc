;*******************************************************************************
;* ATA.INC - Типы данных для устройств ATA/ATAPI                               *
;* Версия 1.01 (Сентябрь 2009 г.)                                              *
;*                                                                             *
;* Copyright (c) 2001-2009 rivitna                                             *
;*******************************************************************************


; Размер буфера для идентификации устройства ATA/ATAPI
DEVICE_INFO_BUFFER_SIZE	EQU	512


;*******************************************************************************
; Блок информации, передаваемый по ATA-команде идентификации устройства
; IDENTIFY DEVICE (ECh)
;*******************************************************************************
ATA_DEVICE_INFO STRUC
  ata_wGenConfig            DW ?         ; 0000: General configuration
                                         ;          15   0 = ATA device
                                         ;         14-8  Retired
                                         ;           7   1 = removable media device
                                         ;           6   1 = not removable controller
                                         ;                    and/or device
                                         ;          5-3  Retired
                                         ;           2   Response incomplete
                                         ;           1   Retired
                                         ;           0   Reserved
  ata_wCyls                 DW ?         ; 0002: Number of logical cylinders
  ata_wSpecConfig           DW ?         ; 0004: Specific configuration
  ata_wHeads                DW ?         ; 0006: Number of logical heads
  ata_wBytesPerTrack        DW ?         ; 0008: Retired
  ata_wBytesPerSector       DW ?         ; 000A: Retired
  ata_wSecsPerTrack         DW ?         ; 000C: Number of logical sectors
                                         ;       per logical track
  ata_wCFAReserved1         DW 2 DUP(?)  ; 000E: Reserved for assignment by
                                         ;       the CompactFlash Association
  ata_wNotUsed1             DW ?         ; 0012: Retired
  ata_sSerialNumber         DB 20 DUP(?) ; 0014: Serial number
  ata_wBufferType           DW ?         ; 0028: Retired
  ata_wBufferSize           DW ?         ; 002A: Retired
  ata_wECCBytes             DW ?         ; 002C: Obsolete
  ata_sFirmwareRev          DB 8 DUP(?)  ; 002E: Firmware revision
  ata_sModelNumber          DB 40 DUP(?) ; 0036: Model number
  ata_wRWMultiple           DW ?         ; 005E: READ/WRITE MULTIPLE support
  ata_wDoubleWordIO         DW ?         ; 0060: Reserved
  ata_wCapabilities1        DW ?         ; 0062: Capabilities
  ata_wCapabilities2        DW ?         ; 0064: Capabilities
  ata_wPIOTimingMode        DW ?         ; 0066: Obsolete
  ata_wDMATimingMode        DW ?         ; 0068: Obsolete
  ata_wFieldValidity        DW ?         ; 006A: Field validity
  ata_wCurrCyls             DW ?         ; 006C: Number of current logical cylinders
  ata_wCurrHeads            DW ?         ; 006E: Number of current logical heads
  ata_wCurrSecsPerTrack     DW ?         ; 0070: Number of current logical
                                         ;       sectors per track
  ata_dwCurrCapacity        DD ?         ; 0072: Current capacity in sectors
  ata_wMultiSectorSetting   DW ?         ; 0076: Multiple sector setting
  ata_dwTotalAddrSecs       DD ?         ; 0078: Total number of user addressable
                                         ;       sectors (28-bit LBA)
  ata_wSingleWordDMA        DW ?         ; 007C: Obsolete
  ata_wMultiWordDMA         DW ?         ; 007E: Multiword DMA transfer
  ata_wAdvancedPIOModes     DW ?         ; 0080: PIO transfer modes supported
  ata_wMinDMACycle          DW ?         ; 0082: Minimum Multiword DMA transfer
                                         ;       cycle time per word
  ata_wRecDMACycle          DW ?         ; 0084: Device recommended
                                         ;       Multiword DMA cycle time
  ata_wMinPIOCycle          DW ?         ; 0086: Minimum PIO transfer cycle
                                         ;       time without flow control
  ata_wMinPIOCycleIORDY     DW ?         ; 0088: Minimum PIO transfer
                                         ;       cycle time with IORDY
  ata_wReserved1            DW 6 DUP(?)  ; 008A: Reserved
  ata_wQueueDepth           DW ?         ; 0096: Queue depth
  ata_wReserved2            DW 4 DUP(?)  ; 0098: Reserved
  ata_wMajorVerNum          DW ?         ; 00A0: Major version number
  ata_wMinorVerNum          DW ?         ; 00A2: Minor version number
  ata_wCommandSet1          DW ?         ; 00A4: Command set supported
  ata_wCommandSet2          DW ?         ; 00A6: Command set supported
  ata_wCommandSetExt        DW ?         ; 00A8: Command set/feature
                                         ;       supported extension
  ata_wCommandSetEnabled1   DW ?         ; 00AA: Command set/feature enabled
  ata_wCommandSetEnabled2   DW ?         ; 00AC: Command set/feature enabled
  ata_wCommandSetDefault    DW ?         ; 00AE: Command set/feature default
  ata_wUDMAModes            DW ?         ; 00B0: Ultra DMA modes
  ata_wReqTimeSecErase      DW ?         ; 00B2: Time required for security
                                         ;       erase unit completion
  ata_wReqTimeEnhSecErase   DW ?         ; 00B4: Time required for Enhanced
                                         ;       security erase completion
  ata_wAdvPowerMgmtLevel    DW ?         ; 00B6: Advanced power management
                                         ;       level value
  ata_wMasterPwdRevCode     DW ?         ; 00B8: Master Password Revision Code
  ata_wHWCfgTestResults     DW ?         ; 00BA: Hardware configuration test
                                         ;       results
  ata_wReserved3            DW 6 DUP(?)  ; 00BC: Reserved
  ata_dwMaxLBA48Address     DD 2 DUP(?)  ; 00C8: Maximum user LBA address for
                                         ;       48-bit Address feature set
  ata_wReserved4            DW 23 DUP(?) ; 00D0: Reserved
  ata_wRemMediaStatusNotif  DW ?         ; 00FE: Removable Media Status
                                         ;       Notification feature set
                                         ;       support
  ata_wSecurityStatus       DW ?         ; 0100: Security status
  ata_wVendorSpec1          DW 31 DUP(?) ; 0102: Vendor specific
  ata_wCFAPowerMode         DW ?         ; 0140: CFA power mode
  ata_wCFAReserved2         DW 15 DUP(?) ; 0142: Reserved for assignment by
                                         ;       the CompactFlash Association
  ata_wReserved5            DW 79 DUP(?) ; 0160: Reserved
  ata_wIntegrity            DW ?         ; 01FE: Integrity word
ATA_DEVICE_INFO ENDS

;*******************************************************************************
; Блок информации, передаваемый по ATA-команде идентификации пакетного
; устройства IDENTIFY PACKET DEVICE (A1h)
;*******************************************************************************
ATAPI_DEVICE_INFO STRUC
  atapi_wGenConfig          DW ?         ; 0000: General configuration
                                         ;        15-14  10 = ATAPI device
                                         ;               11 = Reserved
                                         ;          13   Reserved
                                         ;         12-8  Field indicates command
                                         ;               packet set used by device
                                         ;               05 = CD-ROM
                                         ;           7   1 = removable media device
                                         ;          6-5  00 = Device shall set
                                         ;                    DRQ to one within
                                         ;                    3 ms of receiving
                                         ;                    PACKET command
                                         ;               01 = Obsolete
                                         ;               10 = Device shall set
                                         ;                    DRQ to one within
                                         ;                    50 microseconds
                                         ;                    of receiving
                                         ;                    PACKET command
                                         ;               11 = Reserved
                                         ;          4-3  Reserved
                                         ;           2   Incomplete response
                                         ;          1-0  00 = 12 byte command
                                         ;                    packet
                                         ;               01 = 16 byte command
                                         ;                    packet
                                         ;               1x = Reserved
  atapi_wReserved1          DW ?         ; 0002: Reserved
  atapi_wSpecConfig         DW ?         ; 0004: Specific configuration
  atapi_wReserved2          DW 7 DUP(?)  ; 0006: Reserved
  atapi_sSerialNumber       DB 20 DUP(?) ; 0014: Serial number
  atapi_wReserved3          DW 3 DUP(?)  ; 0028: Reserved
  atapi_sFirmwareRev        DB 8 DUP(?)  ; 002E: Firmware revision
  atapi_sModelNumber        DB 40 DUP(?) ; 0036: Model number
  atapi_wReserved4          DW 2 DUP(?)  ; 005E: Reserved
  atapi_wCapabilities       DW ?         ; 0062: Capabilities
  atapi_wReserved5          DW ?         ; 0064: Reserved
  atapi_wNotUsed1           DW 2 DUP(?)  ; 0066: Obsolete
  atapi_wFieldValidity      DW ?         ; 006A: Field validity
  atapi_wReserved6          DW 9 DUP(?)  ; 006C: Reserved
  atapi_wMultiWordDMA       DW ?         ; 007E: Multiword DMA transfer
  atapi_wAdvancedPIO        DW ?         ; 0080: PIO transfer modes supported
  atapi_wMinDMACycle        DW ?         ; 0082: Minimum Multiword DMA transfer
                                         ;       cycle time per word
  atapi_wRecDMACycle        DW ?         ; 0084: Device recommended
                                         ;       Multiword DMA cycle time
  atapi_wMinPIOCycle        DW ?         ; 0086: Minimum PIO transfer cycle
                                         ;       time without flow control
  atapi_wMinPIOCyclewIORDY  DW ?         ; 0088: Minimum PIO transfer
                                         ;       cycle time with IORDY
  atapi_wReserved7          DW 2 DUP(?)  ; 008A: Reserved
  atapi_wPACKETBusRlseTime  DW ?         ; 008E: PACKET to bus release time
  atapi_wSERVICEBusRlseTime DW ?         ; 0090: SERVICE to bus release time
  atapi_wReserved8          DW 2 DUP(?)  ; 0092: Reserved
  atapi_wQueueDepth         DW ?         ; 0096: Queue depth
  atapi_wReserved9          DW 4 DUP(?)  ; 0098: Reserved
  atapi_wMajorVerNum        DW ?         ; 00A0: Major version number
  atapi_wMinorVerNum        DW ?         ; 00A2: Minor version number
  atapi_wCommandSet1        DW ?         ; 00A4: Command set supported
  atapi_wCommandSet2        DW ?         ; 00A6: Command set supported
  atapi_wCommandSetExt      DW ?         ; 00A8: Command set/feature
                                         ;       supported extension
  atapi_wCommandSetEnabled1 DW ?         ; 00AA: Command set/feature enabled
  atapi_wCommandSetEnabled2 DW ?         ; 00AC: Command set/feature enabled
  atapi_wCommandSetDefault  DW ?         ; 00AE: Command set/feature default
  atapi_wUDMAModes          DW ?         ; 00B0: Ultra DMA modes
  atapi_wReqTimeSecErase    DW ?         ; 00B2: Time required for security
                                         ;       erase unit completion
  atapi_wReqTimeEnhSecErase DW ?         ; 00B4: Time required for Enhanced
                                         ;       security erase completion
  atapi_wReserved10         DW 2 DUP(?)  ; 00B6: Reserved
  atapi_wHWResetResults     DW ?         ; 00BA: Hardware reset results
  atapi_wReserved11         DW 32 DUP(?) ; 00BC: Reserved
  atapi_wATAPIByteCount0Bhv DW ?         ; 00FC: ATAPI byte count = 0 behavior
  atapi_wRemMediaStatNotif  DW ?         ; 00FE: Removable Media Status
                                         ;       Notification feature set support
  atapi_wSecurityStatus     DW ?         ; 0100: Security status
  atapi_wVendorSpec1        DW 31 DUP(?) ; 0102: Vendor specific
  atapi_wCFAReserved2       DW 16 DUP(?) ; 0140: Reserved for assignment by
                                         ;       the CompactFlash Association
  atapi_wReserved12         DW 79 DUP(?) ; 0160: Reserved
  atapi_wIntegrity          DW ?         ; 01FE: Integrity word
ATAPI_DEVICE_INFO ENDS
