
#import "common/lib/invoke-global.asm"
#import "chipset/lib/mos6510-global.asm"
#import "chipset/lib/cia-global.asm"
#import "chipset/lib/vic2-global.asm"
#import "playfield-meta.asm"

.segmentdef Code [start=$0810]
.file [name="./demo.prg", segments="Code", modify="BasicUpstart", _start=$0810]
.segment Code

.label CHARSET_MEM      = $C000
.label SCREEN_0_MEM     = $C800
.label SCREEN_1_MEM     = $CC00

start:
    // configure memory
    sei
    c64lib_disableCIAInterrupts()
    c64lib_configureMemory(c64lib.RAM_IO_RAM)
    cli
    // set up vic colours
    lda #BLACK
    sta c64lib.BORDER_COL
    lda #backgroundColour0
    sta c64lib.BG_COL_0
    lda #backgroundColour1
    sta c64lib.BG_COL_1
    lda #backgroundColour2
    sta c64lib.BG_COL_2
    // set up VIC bank (last one)
    c64lib_setVICBank(0)
    // set up VIC video mode (text multicolour)
    lda #%10010111
    sta c64lib.CONTROL_1
    lda #%00011000
    sta c64lib.CONTROL_2
    // copy charset
    c64lib_pushParamW(levelCharset)
    c64lib_pushParamW(CHARSET_MEM)
    c64lib_pushParamW(levelChasetEnd-levelCharset)
    jsr copy
    // set initial memory
    lda #%00100000
    sta c64lib.MEMORY_CONTROL

    lda #(8 + GREEN)
    jsr setColorRam

    lda #<SCREEN_0_MEM
    sta displayMap.dstAddress
    lda #>SCREEN_0_MEM
    sta displayMap.dstAddress+1

    ldy #176
    jsr displayMap
    jsr displayMap
    jsr displayMap
    jsr displayMap
    loop: jmp loop

copy:
    #import "common/lib/sub/copy-large-mem-forward.asm"

displayMap: {
        lda levelDataOffsets.lo, y
        sta srcAddress
        lda levelDataOffsets.hi, y
        sta srcAddress+1
        ldx #0
    colLoop:
        lda srcAddress:$ffff, x
        sta dstAddress:$ffff, x
        inx
        cpx #240
        bne colLoop

        clc
        lda dstAddress
        adc #240
        sta dstAddress
        lda dstAddress+1
        adc #0
        sta dstAddress+1
        
        iny
        iny
        iny
        iny
        iny
        iny
    rts
}

setColorRam: {
    ldx #0
    !:
        sta c64lib.COLOR_RAM, x
        sta c64lib.COLOR_RAM+250, x
        sta c64lib.COLOR_RAM+500, x
        sta c64lib.COLOR_RAM+750, x
        inx
        cpx #250
        bne !-
    rts
}

levelData:
    .import binary "playfield-map.bin"
levelDataEnd:
levelDataOffsets: .lohifill 200, levelData + 40*i
levelCharset:
    .import binary "playfield-charset.bin"
levelChasetEnd:
