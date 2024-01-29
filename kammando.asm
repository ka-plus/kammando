/*
 * MIT License
 *
 * Copyright (c) 2024 Maciej Małecki, K&A+
 *
 * Music by Rob Hubbard
 * Graphics by Rory Green, Chris Harvey
 * Copyright (c) 1985 by Elite/Capcom
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "common/lib/invoke-global.asm"
#import "chipset/lib/mos6510-global.asm"
#import "chipset/lib/cia-global.asm"
#import "chipset/lib/vic2-global.asm"
#import "copper64/lib/copper64-global.asm"
#import "playfield-meta.asm"

.segmentdef Code [start=$0810]
.file [name="./demo.prg", segments="Code", modify="BasicUpstart", _start=$0810]
.segment Code

.var music = LoadSid("Commando.sid")

.label CHARSET_MEM      = $C000
.label SCREEN_0_MEM     = $C800
.label SCREEN_1_MEM     = $CC00
.label START_Y = 176
.label START_MAP_POSITION = START_Y * 40 + levelData

// shift content of the screen by one row downwards
.macro shiftScreen(from, to) {
    .for (var i = 24; i > 0; i--) {
            ldx #40
        loop:
            lda from + 40*(i - 1) - 1, x
            sta to + 40*i - 1, x
            dex
            bne loop
    }
    rts
}

// displays next row of the map at the top of the screen
.macro displayRow(to) {
        ldy posY
        lda levelDataOffsets.lo, y
        sta address
        lda levelDataOffsets.hi, y
        sta address+1
        ldx #0
    loop:
        lda address:$ffff, x
        sta to, x
        inx
        cpx #40
        bne loop
        rts
}

start:
    jmp continue
copperList:
    // raster IRQ table, uses Copper64, see: https://c64lib.github.io/#_copper_64
    c64lib_copperEntry(c64lib.IRQH_JSR, 100, <runEachFrame, >runEachFrame)
    c64lib_copperLoop()
continue:
    // configure memory
    sei
    c64lib_disableCIAInterrupts()
    c64lib_configureMemory(c64lib.RAM_IO_RAM)
    cli
    // set up VIC colours
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
    // copy music
    c64lib_pushParamW(musicData)
    c64lib_pushParamW(music.location)
    c64lib_pushParamW(music.size)
    jsr copy
    // display map
    c64lib_pushParamW(START_MAP_POSITION)
    c64lib_pushParamW(SCREEN_0_MEM)
    c64lib_pushParamW(40*24)
    jsr copy

    // set initial memory configuration for VIC-2
    lda #%00100000
    sta c64lib.MEMORY_CONTROL

    // fill up colour RAM with GREEN colour
    lda #(8 + GREEN)
    jsr setColorRam

    // initialize music player
    lda #0
    ldx #0
    ldy #0
    jsr music.init

    // start Copper 64 (handling raster IRQs)
    lda #<copperList
    sta $3
    lda #>copperList
    sta $4
    jsr startCopper

// infinite loop at the end of the program, nothing more do be done here, all is done in raster IRQ
loop: jmp loop

// this code is called once per frame, it is triggered by raster IRQ
runEachFrame: {
    // run music player
    jsr music.play
   
    // check if we need to scroll the screen
    lda posY
    beq end

    // scroll the screen, calculate scroll Y register value
    inc scrollY
    lda scrollY
    and #%00000111
    sta scrollY
    lda c64lib.CONTROL_1
    and #%11111000
    ora scrollY
    sta c64lib.CONTROL_1
    lda scrollY
    // check if we need to switch the screen
    cmp #7
    bne end

    lda page
    bne p1to0
p0to1:
    // switch the screen from page 0 to page 1
    jsr shift0to1
    jsr displayRow1
    lda c64lib.MEMORY_CONTROL
    and #%00001111
    ora #%00110000
    sta c64lib.MEMORY_CONTROL
    lda #1
    sta page
    dec posY
    jmp end
p1to0:
    // switch the screen from page 1 to page 0
    jsr shift1to0
    jsr displayRow0
    lda c64lib.MEMORY_CONTROL
    and #%00001111
    ora #%00100000
    sta c64lib.MEMORY_CONTROL
    lda #0
    sta page
    dec posY
end:
    rts
}

copy:
    #import "common/lib/sub/copy-large-mem-forward.asm"

shift0to1: shiftScreen(SCREEN_0_MEM, SCREEN_1_MEM)
shift1to0: shiftScreen(SCREEN_1_MEM, SCREEN_0_MEM)
displayRow0: displayRow(SCREEN_0_MEM)
displayRow1: displayRow(SCREEN_1_MEM)
startCopper: c64lib_startCopper($3, $5, List().add(c64lib.IRQH_JSR).lock())

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

// vars
page:       .byte 0
posY:       .byte START_Y
scrollY:    .byte 7

levelData:
    .import binary "playfield-map.bin"
levelDataEnd:
levelDataOffsets: .lohifill 200, levelData + 40*i
levelCharset:
    .import binary "playfield-charset.bin"
levelChasetEnd:
musicData:
    .fill music.size, music.getData(i)
musicDataEnd:
