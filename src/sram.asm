; DMGTRIS
; Copyright (C) 2023 - Randy Thiemann <randy.thiemann@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.


IF !DEF(SRAM_ASM)
DEF SRAM_ASM EQU 1


INCLUDE "globals.asm"


SECTION "Persistent Globals", SRAM
rMagic:: ds 4
rCheck:: ds 6
rSwapABState:: ds 1
rRNGModeState:: ds 1
rRotModeState:: ds 1
rDropModeState:: ds 1
rSpeedCurveState:: ds 1
rAlways20GState:: ds 1
rSelectedStartLevel:: ds 2


SECTION "SRAM Functions", ROM0
InitializeSRAM:
    ; Set the magic id.
    ld a, SAVE_MAGIC_0
    ld [rMagic], a
    ld a, SAVE_MAGIC_1
    ld [rMagic+1], a
    ld a, SAVE_MAGIC_2
    ld [rMagic+2], a
    ld a, SAVE_MAGIC_3
    ld [rMagic+3], a

    ; Load defaults.
    ld a, BUTTON_MODE_NORM
    ld [rSwapABState], a
    ld [wSwapABState], a

    ld a, RNG_MODE_TGM3
    ld [rRNGModeState], a
    ld [wRNGModeState], a

    ld a, ROT_MODE_ARSTI
    ld [rRotModeState], a
    ld [wRotModeState], a

    ld a, DROP_MODE_SONIC
    ld [rDropModeState], a
    ld [wDropModeState], a

    ld a, SCURVE_DMGT
    ld [rSpeedCurveState], a
    ld [wSpeedCurveState], a

    ld a, HIG_MODE_OFF
    ld [rAlways20GState], a
    ld [wAlways20GState], a
    ; Falls through to the next label!


PartiallyInitializeSRAM:
    ; Save build data.
    ld a, LOW(__UTC_YEAR__)
    ld [rCheck], a
    ld a, __UTC_MONTH__
    ld [rCheck+1], a
    ld a, __UTC_DAY__
    ld [rCheck+2], a
    ld a, __UTC_HOUR__
    ld [rCheck+3], a
    ld a, __UTC_MINUTE__
    ld [rCheck+4], a
    ld a, __UTC_SECOND__
    ld [rCheck+5], a

    ; Set to the default start level.
    ld hl, sSpeedCurve
    ld a, l
    ldh [hStartSpeed], a
    ld [rSelectedStartLevel], a
    ld a, h
    ldh [hStartSpeed+1], a
    ld [rSelectedStartLevel+1], a
    ret


RestoreSRAM::
    ; Check if our SRAM is initialized at all.
    ; If not, we load all the defaults.
    ld a, [rMagic]
    cp a, SAVE_MAGIC_0
    jr nz, InitializeSRAM
    ld a, [rMagic+1]
    cp a, SAVE_MAGIC_1
    jr nz, InitializeSRAM
    ld a, [rMagic+2]
    cp a, SAVE_MAGIC_2
    jp nz, InitializeSRAM
    ld a, [rMagic+3]
    cp a, SAVE_MAGIC_3
    jp nz, InitializeSRAM

    ; If SRAM is initialized, we still need to check if it's for this exact build.
    ; If not, wipe data that is no longer valid.
    ld a, [rCheck]
    cp a, LOW(__UTC_YEAR__)
    jr nz, PartiallyInitializeSRAM
    ld a, [rCheck+1]
    cp a, __UTC_MONTH__
    jr nz, PartiallyInitializeSRAM
    ld a, [rCheck+2]
    cp a, __UTC_DAY__
    jr nz, PartiallyInitializeSRAM
    ld a, [rCheck+3]
    cp a, __UTC_HOUR__
    jr nz, PartiallyInitializeSRAM
    ld a, [rCheck+4]
    cp a, __UTC_MINUTE__
    jr nz, PartiallyInitializeSRAM
    ld a, [rCheck+5]
    cp a, __UTC_SECOND__
    jr nz, PartiallyInitializeSRAM

    ; SRAM is initialized and for this build, so we can load the data.
    ld a, [rSwapABState]
    ld [wSwapABState], a
    ld a, [rRNGModeState]
    ld [wRNGModeState], a
    ld a, [rRotModeState]
    ld [wRotModeState], a
    ld a, [rDropModeState]
    ld [wDropModeState], a
    ld a, [rSpeedCurveState]
    ld [wSpeedCurveState], a
    ld a, [rAlways20GState]
    ld [wAlways20GState], a

    ld a, [rSelectedStartLevel]
    ldh [hStartSpeed], a
    ld a, [rSelectedStartLevel+1]
    ldh [hStartSpeed+1], a
    ret


ENDC