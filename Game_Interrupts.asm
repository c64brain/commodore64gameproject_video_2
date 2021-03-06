;===============================================================================
; SETUP RASTER INTERRUPT REQUESTS
;===============================================================================

InitRasterIRQ
        sei                     ; stop all interrupts
        lda PROC_PORT
        
        lda #$7f                ; disable cia #1 generating timer irqs
        sta INT_CONTROL         ; which are used by the system to flash cursor, etc.

        lda #$01                ; tell the VIC we want to generate raster irqs
                                ; Note - by directly writing #$01 and not setting bits
                                ; we are also turning off sprite/sprite sprite/background
                                ; and light pen interrupts.

;===============================================================================
; ENABLE MASK INTERRUPT
;===============================================================================
        sta VIC_INTERRUPT_CONTROL ; $D01A (53274)

        lda #$10                ; number of the rasterline we want the IRQ to occur at
        sta VIC_RASTER_LINE     ; we used this for WaitFrame, remember? Reading gives the current
                                ; raster line, writing sets the line for a raster interrupt to occur

                                ; The raster counter goes from 0-312, so we need to set the
                                ; most significant bit (MSB)

                                ; The MSB for setting the raster line is bit 7 of $D011 - this
                                ; is also VIC_SCREEN_CONTROL, that sets the height of the screen,
                                ; if it's turned on, text or bitmap mode, and other things.
                                ; so we could easily use this 'short' method
                                
                                ; But doing things properly and only setting the bits we want is a
                                ; good practice to get into.
                                ; also we now have the option of turning the screen on when we want
                                ; to - like after everything is set up

        lda VIC_SCREEN_CONTROL  ; Fetch the VIC_SCREEN_CONTROL - $D011 (53265)
        and #%01111111          ; mask the surrounding bits
                                ; in this case, it's cleared
        sta VIC_SCREEN_CONTROL
                                ; set the irq vector to point to our routine
        lda #<IrqTopScreen
        sta $0314
        lda #>IrqTopScreen
        sta $0315
                                ; Acknowlege any pending cia timer interrupts
                                ; just to be 100% safe
        lda $dc0d
        lda $dd0d

        cli                     ; turn interrupts back on
        rts

;===============================================================================
; TOP SCREEN INTERRUPT
;===============================================================================

; Raster line 16

#region "IrqTopScreen"
IrqTopScreen
        sei                    ; acknowledge VIC irq
        lda $D019
        sta $D019 
                               ; install glitch irq
        lda #<IrqGlitchCatcher
        sta $0314
        lda #>IrqGlitchCatcher
        sta $0315

        lda #191
        sta $D012
@start
        lda CURRENT_SCREEN + 1          ; Hi byte of the current screen
        cmp #>SCREEN2_MEM               ; compare to start of Screen2
        beq @screen2

;===============================================================================
; SET CHARACTER SET 1 AND 2
;===============================================================================
        lda #%00000010                  ; Set VIC to Screen0, Charset 1
        sta VIC_MEMORY_CONTROL          ; $D018 (53272)
        jmp @scroll

@screen2
        lda #%00010010                  ; Set VIC to Screen1, Charset 1
        sta VIC_MEMORY_CONTROL

;===============================================================================
; VERTICAL SCREEN SCROLLING
;===============================================================================
@scroll
        lda VIC_SCREEN_CONTROL_Y        ; Take the current values - $D011 (53265)
        and #%11111000                  ; mask out the scroll values
        ora SCROLL_COUNT_Y              ; or in the scroll count (bits 0-2 - y scroll value)
        sta VIC_SCREEN_CONTROL_Y        ; save the updated info in the registers

;===============================================================================
; HORIZONTAL FINE SCROLLING
;===============================================================================
        lda VIC_SCREEN_CONTROL_X        ; Take the current values -$D016 (53270)
        and #%11111000                  ; mask out the lower 4 bits (screen cols and scroll)
        ora SCROLL_COUNT_X              ; Or in the scroll count (bits 0-2 - x scroll value)
        sta VIC_SCREEN_CONTROL_X        ; Save the updated info
        
        ;------------------------------------------------------ TIMERS AND SYSTEM UPDATES
;        jsr UpdateTImers                   ; Update our timers and automatic systems
        jsr ReadJoystick                   
;        jsr JoyButton
        ;-----------------------------------------------------------------------
        cli
        jmp $ea31

;===============================================================================
; IRQ GLITCHCATHER
;===============================================================================
        rts

; Raster line 191

#region "IRQGlitchCatcher"
IrqGlitchCatcher
        sei
                                ; acknowledge VIC irq
        lda $D019
        sta $D019
        
                                ; install scroller irq
        lda #<IrqScoreBoard
        sta $0314
        lda #>IrqScoreBoard
        sta $0315
        
                                 ; nr of rasterline we want the NEXT irq to occur at
        lda #249                 ; Scoreboard appears 8 raster lines after the glitch catcher
        sta $D012

;===============================================================================
; CHARACTER SET GENERATOR ROM: 22
;===============================================================================
@start   
;        lda #%00100000
        lda #%01100100                          ; Set VIC to Screen 6, Charset 2
        sta VIC_MEMORY_CONTROL                  ; $D018 - (53272)
;===============================================================================
; EXTENDED BACKGROUND MODE 
;===============================================================================
;        lda #%01010111                          ; Set Y to scroll 7 to force badline to every frame
;        sta VIC_SCREEN_CONTROL_Y                ; set extended background mode

;===============================================================================
; HORIZONTAL FINE SCROLLING
;===============================================================================
        lda #%11010000
        sta VIC_SCREEN_CONTROL_X                ; X scroll to 0 / multicolor on / 38 cols $D016 (53270)
                                                ; If you set multicolor AND extended background
;                                                ; you get an illegal mode that sets everything to
;                                                ; black
        cli
        jmp $ea31
#endregions
#endregion

; Raster line 249

IrqScoreBoard
        sei                                     ; acknowledge VIC irq
        lda VIC_MASK_IRQ                        ; $D019 - (53273)
        sta VIC_MASK_IRQ
        
                                                ; install scroller irq
        lda #<IrqTopScreen
        sta $0314
        lda #>IrqTopScreen
        sta $0315       
;                                               ; nr of rasterline we want the NEXT irq to occur at
        lda #$28
        sta VIC_RASTER_LINE                     ; $D012 - (53266)

;===============================================================================
; VERTICAL SCREEN SCROLLING
;===============================================================================
        lda #%00010000                          ; Restore to Y Scroll = 0
        sta VIC_SCREEN_CONTROL_Y                ; $D011 - (53265)
                                                
                                                ; Be aware that :
                                                ; bit #0-2 = vertical scroll
                                                ; bit #3 = screen height (0 = 24 rows)
                                                ; bit #4 = screen on/off
                                                ; bit #5 = text/bitmap (0 = text)
                                                ; bit #6 = extended background on/off
                                                ; bit #7 = read/write current raster line bit #8
                                                ; So '3' is the default vert scroll location
        cli
        jmp $ea31

        rts

;===============================================================================
; ADD YOUR FIRST INTERRUPT HERE
;===============================================================================

; Raster line 40  

YourInterrupt1
        sei                                     ; acknowledge VIC irq
        lda $D019
        sta $D019
        
                                                ; install scroller irq
        lda #<IrqTopScreen
        sta $0314
        lda #>IrqTopScreen
        sta $0315      
;                                               ; nr of rasterline we want the NEXT irq to occur at
        lda #55
        sta $D012

        ldx #64
bnd
        lda colbands,x
        nop
        nop     
        nop
        nop
        nop
        nop
        nop
        sta 53280
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        dex
        bne bnd
        lda #100
        sta $d012


@end_enemytimer
        cli
        jmp $ea31

VALUE byte 12
colbands byte 1,1,1,1,1,2,2,2,2,2
         byte 3,3,3,3,3,3,4,4,4,4,4,4
         byte 5,5,5,5,5,6,6,6,6,6
         byte 7,7,7,7,7,8,8,8,8,8
         byte 9,9,9,9,9,10,10,10,10,10
         byte 11,11,11,11,11
         byte 12,12,12,12,12
         byte 13,13,13,13,13
