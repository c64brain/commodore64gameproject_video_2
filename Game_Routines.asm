;===================================================================================================
;                                                                               CORE ROUTINES
;===================================================================================================
; Core routines for the framework                                             - Peter 'Sig' Hewett
;                                                                                            2016
;---------------------------------------------------------------------------------------------------
        ; Wait for the raster to reach line $f8 - if it's aleady there, wait for
        ; the next screen blank. This prevents mistimings if the code runs too fast
#region "WaitFrame"
WaitFrame
        lda VIC_RASTER_LINE             ; fetch the current raster line
        cmp #$F8                        ; wait here till l        
        beq WaitFrame           
        
@WaitStep2
        lda VIC_RASTER_LINE
        cmp #$F8
        bne @WaitStep2
        rts
#endregion        
        ;-------------------------------------------------------------------------------------------
        ; READ JOYSTICK 2
        ;-------------------------------------------------------------------------------------------
        ; Trying this a different way this time.  Rather than hitting the joystick registers then
        ; doing something every time - The results will be stored in JOY_X and JOY_Y with values
        ; -1 to 1 , with 0 meaning 'no input'
        ;-------------------------------------------------------------------------------------------
#region "ReadJoystick"

ReadJoystick
        lda #$00                        ; Reset JOY X and Y variables
        sta JOY_X
        sta JOY_Y
@testUp                                 ; Test for Up pressed
        lda checkup                     ; Mask for bit 0
        bit JOY_2                       ; test bit 0 for press
        bne @testDown
        lda #$FF                        ; set JOY_Y to -1 ($FF)
        sta JOY_Y
        jmp @testLeft                   ; Can't be up AND down

@testDown                               ; Test for Down
        lda checkdown                   ; Mask for bit 1
        bit JOY_2
        bne @testLeft
        lda #$01                        ; set JOY_Y to 1 ($01)
        sta JOY_Y
        rts
@testLeft                               ; Test for Left
        lda checkleft                   ; Mask for bit 2
        bit JOY_2
        bne @testRight
        lda #$FF
        sta JOY_X
        rts                             ; Can't be left AND right - no more tests

@testRight                              ; Test for Right
        lda checkright                  ; Mask for bit 3
        bit JOY_2
        bne @done
        lda #$01
        sta JOY_X
        rts   

@done                                   ; Nothing pressed
        rts

#endregion       

        ;-------------------------------------------------------------------------------------------
        ; COPY CHARACTER SET
        ;-------------------------------------------------------------------------------------------
        ; Copy the custom character set into the VIC Memory Bank (2048 bytes)
        ; ZEROPAGE_POINTER_1 = Source
        ; ZEROPAGE_POINTER_2 = Dest
        ;
        ; Returns A,X,Y and PARAM2 intact
        ;-------------------------------------------------------------------------------------------

ScrollMapScreen

#region "CopyChars"

CopyChars
        
        saveRegs

        ldx #$00                        ; clear X, Y, A and PARAM2
        ldy #$00
        lda #$00
        sta PARAM2
@NextLine

; CHAR_MEM = ZEROPAGE_POINTER_1
; LEVEL_1_CHARS = ZEROPAGE_POINTER_2

        lda (ZEROPAGE_POINTER_1),Y      ; copy from source to target
        sta (ZEROPAGE_POINTER_2),Y

        inx                             ; increment x / y
        iny                                     
        cpx #$08                        ; test for next character block (8 bytes)
        bne @NextLine                   ; copy next line
        cpy #$00                        ; test for edge of page (256 wraps back to 0)
        bne @PageBoundryNotReached

        inc ZEROPAGE_POINTER_1 + 1      ; if reached 256 bytes, increment high byte
        inc ZEROPAGE_POINTER_2 + 1      ; of source and target

@PageBoundryNotReached
        inc PARAM2                      ; Only copy 254 characters (to keep irq vectors intact)
        lda PARAM2                      ; If copying to F000-FFFF block
        cmp #255
        beq @CopyCharactersDone
        ldx #$00
        jmp @NextLine

@CopyCharactersDone

        restoreRegs

        rts
#endregion


checkup
        byte %0000001
checkdown
        byte %0000010

checkleft
        byte %0000100

checkright
        byte %0001000

;===================================================================================================
;  JOYSTICK
;===================================================================================================

JOY_X                                   ; current positon of Joystick(2)
        byte $00                        ; -1 0 or +1
JOY_Y
        byte $00                        ; -1 0 or +1
                                        ; holds 1 when a single press is made (button released)
