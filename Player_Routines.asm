;===============================================================================
; PLAYER SETUP
;===============================================================================

#region "Update Player"

PLAYER_RIGHT_CAP = $1c                      ; Sprite movement caps - at this point we don't
PLAYER_LEFT_CAP = $09                       ; Move the sprite, we scroll the screen
PLAYER_UP_CAP = $04                          
PLAYER_DOWN_CAP = $0F

;===============================================================================
; JOYSTICK TESTING
;===============================================================================

#region "JoystickReady"
JoystickReady

        lda SCROLL_MOVING               ; if moving is 'stopped' we can test joystick
        beq @joyready
                                        ; if it's moving but direction is stopped, we're 'fixing'
        lda SCROLL_DIRECTION
        bne @joyready

        lda #1                          ; Send code for joystick NOT ready for input
        rts

@joyready
        lda #SCROLL_STOP                ; reset scroll direction - if it needs to scroll
        sta SCROLL_DIRECTION            ; it will be updated

        lda #0                          ; send code for joystick ready
        rts

#endregion

;===============================================================================
; PLAYER WALKS TO THE RIGHT
;===============================================================================

#region "MovePlayerRight"
MovePlayerRight
        lda #0
        sta SCROLL_FIX_SKIP
        ;------------------------------------------ CHECK RIGHT MOVEMENT CAP
        clc                             ; clear carry flag because I'm paranoid
                                        ; Check against map edge
        lda MAP_X_POS                   ; load the current MAP X Position          
        cmp #54                         ; the map is 64 tiles wide, the screen is 10 tiles wide
        bne @scrollRight
 
        lda #1
        sta SCROLL_FIX_SKIP
        jmp @rightMove
        rts
        ;------------------------------------------ SCROLL RIGHT
                                        ; Pre-scroll check
@scrollRight
        lda #SCROLL_RIGHT               ; Set the direction for scroll and post scroll checks
        sta SCROLL_DIRECTION
        sta SCROLL_MOVING
        lda #0                          ; load 'clear code'
        rts                             ; TODO - ensure collision code is returned

        ;----------------------------------------- MOVE SPRITE RIGHT                                
@rightMove
        bne @rightDone

        lda #0                          ; move code 'clear'
@rightDone
        rts

#endregion

;===============================================================================
; PLAYER WALKS TO THE LEFT
;===============================================================================

#region "Move Player Left"
MovePlayerLeft
        lda #0                          ; Make sure scroll 'fix' is on
        sta SCROLL_FIX_SKIP
        ;---------------------------------------- CHECK MOVEMENT CAP ($07)

                                        ; Check for edge of map for scrolling
        lda MAP_X_POS                   ; Check for map pos X = 0
        bne @scrollLeft                 
                                        ; We're at the maps left edge
                                        ; So we revert to sprite movement once more

        bpl @leftMove                   ; so we could walk to the edge of screen
        rts

@scrollLeft
        lda #SCROLL_LEFT
        sta SCROLL_DIRECTION
        sta SCROLL_MOVING
        lda #0                          ; return 'clear code'
                                        ; TODO - return clear collision code
        rts
        ;---------------------------------------- MOVE THE PLAYER LEFT ONE PIXEL
@leftMove     
        lda #0                          ; move code 'clear'

#endregion

;===============================================================================
; PLAYER MOVES DOWN THE SCREEN
;===============================================================================

#region "Move Player Down"
MovePlayerDown
        lda MAP_Y_POS
        cmp #$1B
        bne @downScroll
        rts

@downScroll
        lda #SCROLL_DOWN
        sta SCROLL_DIRECTION
        sta SCROLL_MOVING
        lda #0                          ; return a clear collision code
        rts

#endregion

;===============================================================================
; PLAYER MOVES UP THE SCREEN
;===============================================================================

#region "MovePlayerUp"
MovePlayerUp
        lda MAP_Y_POS
        bne @upScroll
        clc
        rts

@upScroll
        lda #SCROLL_UP
        sta SCROLL_DIRECTION
        sta SCROLL_MOVING
        rts

#endregion

;===============================================================================
; PLAYER REMAINS IDLE - Main Entry point of project
;===============================================================================

#region "Player State Idle"
PlayerStateIdle

        jsr JoystickReady
        beq @input
        rts                                     ; not ready for input, we return

;===============================================================================
; CHECK THE VERTICAL MOVEMENT
;===============================================================================
; Is Sprite moving to the Left?
;*******************************************************************************
@input 
        lda JOY_X                               ; horizontal movement
        beq @vertCheck                          ; check zero - ho horizontal input
        bmi @left                               ; negative = left
        
;===============================================================================
; SPRITE HAS MOVED TO THE RIGHT
;===============================================================================
@right
        jsr PlayerStateWalkRight
        rts

;===============================================================================
; SPRITE HAS MOVED TO THE LEFT
;=============================================================================== 
@left
        jsr PlayerStateWalkLeft
        rts

;===============================================================================
; CHECK IF JOYSTICK IS MOVING UP OR DOWN
;===============================================================================
@vertCheck
        lda JOY_Y                               ; check vertical joystick input
        beq @idle                                ; zero means no input
        bmi @up                                 ; negative means up
        bpl @down                               ; already checked for 0 - so this is positive

@idle
        rts

;===============================================================================
; SPRITE IS MOVING UP
;===============================================================================
@up
        jsr PlayerStateWalkUp
        rts

;===============================================================================
; SPRITE IS MOVING DOWN
;===============================================================================
@down
        jsr PlayerStateWalkDown
        rts

#endregion

;===============================================================================
; PLAYER STATE WALK RIGHT
;===============================================================================

#region "Player State Walking Right"
PlayerStateWalkRight                                     

;===============================================================================
; GET JOYSTICK TEST
;===============================================================================
        jsr JoystickReady
        beq @input                      ; Check creates the 'fix' pause for scroll resetting
        rts

;===============================================================================
; NO JOYSTICK MOVEMEMENT - SET TO IDLE
;===============================================================================
@input
        lda JOY_X
        bmi @idle                       ; if negative we are idling
        beq @idle

;===============================================================================
; SPRITE IS MOVING TO THE RIGHT
;===============================================================================
@right 
        ldx #0
        jsr MovePlayerRight             ; Move player one pixel across - A = move? 0 or 1

@idle
        rts

#endregion

;===============================================================================
; PLAYER STATE WALK LEFT
;===============================================================================

#region "Player State Walking Left"
PlayerStateWalkLeft
        jsr JoystickReady
        beq @input                      ; Check creates the 'fix' pause for scroll resetting
        rts

;===============================================================================
; GET JOYSTICK TEST
;===============================================================================
@input
        lda JOY_X
        bpl @idle                       ; if negative we are idling
        beq @idle

;===============================================================================
; SPRITE IS MOVING TO THE LEFT
;===============================================================================
@left
        ldx #0
        jsr MovePlayerLeft              ; Move player one pixel across - A = move? 0 or 1

@idle
        rts

#endregion

;===============================================================================
; PLAYER STATE WALK UP
;===============================================================================
PlayerStateWalkUp
        jsr JoystickReady
        beq @input                      ; Check creates the 'fix' pause for scroll resetting
        rts
@input  
        ldx #0
        jsr MovePlayerUp             ; Move player one pixel across - A = move? 0 or 1

@idle
        rts

#endregion

;===============================================================================
; PLAYER STATE WALK DOWN
;===============================================================================

PlayerStateWalkDown

        jsr JoystickReady
        beq @input                      ; Check creates the 'fix' pause for scroll resetting
        rts
@input  
        ldx #0
        jsr MovePlayerDown             ; Move player one pixel across - A = move? 0 or 1

@idle
        rts

#endregion
