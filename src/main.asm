INCLUDE "globals.asm"
INCLUDE "memcpy.asm"
INCLUDE "hardwarectl.asm"
INCLUDE "interrupts.asm"
INCLUDE "sprites.asm"
INCLUDE "res/tiles.inc"
INCLUDE "res/gameplay_map.inc"

SECTION "Code Entry Point", ROM0
MainEntryPoint::
    ; Turn off LCD during initialization.
    call DisableLCD

    ; Save some power and turn off the audio.
    call DisableAudio

    ; We use a single set of tiles for the entire game, so we copy it at the start.
    ld de, Tiles
    ld hl, _VRAM
    ld bc, TilesEnd - Tiles
    call UnsafeMemCopy

    ; Also to the second bank of tile data.
    ld de, Tiles
    ld hl, _VRAM + $800
    ld bc, TilesEnd - Tiles
    call UnsafeMemCopy

    ; Make sure both sprites and bg use the same tile data.
    call SetTileDataBanks

    ; The tilemap is just for testing for now.
    ld de, GameplayTilemap
    ld hl, $9800
    ld bc, GameplayTilemapEnd - GameplayTilemap
    call UnsafeMemCopy

    ; Clear OAM.
    call ClearOAM
    call CopyOAMHandler
    call SetNumberSpritePositions

    ; Set up the palettes.
    ld a, PALETTE_REGULAR
    set_all_palettes

    ; Zero out the ram where needed.
    call InitializeVariables

    ; Set up the interrupt handlers.
    call InitializeLCDCInterrupt

    ; And turn the LCD back on before we start.
    call EnableLCD

    ; Make sure the first game loop starts just like all the future ones.
    wait_vblank
    wait_vblank_end


GameLoop::
    call GetInput
    call HandleTimers

    ; Handle gameplay here
    ; TODO

    ld a, 0
    call ApplyNext

    ld a, 4
    call ApplyHold

    ld hl, wSPRScore1
    ld de, hScore
    call ApplyNumbers

    ld hl, wSPRCLevel1
    ld de, hCLevel
    call ApplyNumbers

    ld hl, wSPRNLevel1
    ld de, hNLevel
    call ApplyNumbers

GameLoopEnd:
    wait_vblank
    call hOAMDMA
    call BlitField
    jp GameLoop



; *****************************************************************************
; *                                                                           *
; *  Functions                                                                *
; *                                                                           *
; *****************************************************************************
SECTION "Functions", ROM0
InitializeVariables:
    xor a, a
    ld [wLCDCCtr], a
    ld hl, wField
    ld bc, 10*22
    ld d, TILE_FIELD_EMPTY
    call UnsafeMemSet
    ld hl, hScore
    ld bc, (6*3)
    ld d, 0
    call UnsafeMemSet
    ret


BlitField:
    ; The first 14 rows can be blitted without checking for vram access.
    ld de, wField + (2*10)
    DEF row = 0
    REPT 14
        ld hl, FIELD_TOP_LEFT+(32*row)
        REPT 10
            ld a, [de]
            ld [hl+], a
            inc de
        ENDR
        DEF row += 1
    ENDR

    ; The last 6 rows need some care.
    REPT 6
        ld hl, FIELD_TOP_LEFT+(32*row)
        REPT 2
:           ldh a, [rSTAT]
            and STATF_LCD
            cp STATF_HBL
            jr z, :-
:           ldh a, [rSTAT]
            and STATF_LCD
            cp STATF_HBL
            jr nz, :-
            REPT 5
                ld a, [de]
                ld [hl+], a
                inc de
            ENDR
        ENDR
        DEF row += 1
    ENDR
    ret

GetInput:
    ret

HandleTimers:
    ld a, [wEvenFrame]
    inc a
    and 1
    ld [wEvenFrame], a
    ret