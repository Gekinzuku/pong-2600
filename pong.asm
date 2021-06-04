;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pong
;   James Danielson, GeekyLink
;
;   Help from Kirk Israel's Moving Dot demo
;   Also help from Nukey Shay for tip on improving display kernel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    processor 6502
    include vcs.h
    include macro.h
    org $F000

BallY = $80 ; Ypos of the ball
VisibleBallLine = $81 ; Line of the ball
BallX = $82 ; Ball X

; Player lines
Player0Line = $83
Player1Line = $84

; Paddle Y
Paddle0Y = $85;
Paddle1Y = $86;


;;; Directions
VDire = #$88 ; Vertical
HDire = #$89 ; Horizontal

;;; Score kinda...
P0Score = #$8A
P1Score = #$8B


;;; Score to play to
PlayToScore = #$8C
ScoreSet = #$8D
SelectReleased = #$8E

Start
    SEI 
    CLD     
    LDX #$FF
    TXS
    LDA #0
    ;;; Clears memory
ClearMem 
    STA 0,X     
    DEX     
    BNE ClearMem
    
    LDA #1
    STA PlayToScore
    STA SelectReleased
    
    LDA #0
    STA ScoreSet
    
SetupVars
    
    LDA PlayToScore
    STA P0Score
    STA P1Score

    LDA #$50
    STA BallY   ; Sets first Y pos for ball
    
    LDA #$80
    STA BallX ; Sets ball's first X, only used for comparing really
    
    ; Sets top value for Paddle 0 and 1
    LDA #$3A
    STA Paddle0Y ; 0
    STA Paddle1Y ; 1
    
    LDA #$10
    STA HDire ; Sets first H direction
    
    LDA #$06
    STA VDire ; Sets first V direction
    
    LDA #$00
    STA COLUBK  ; Background color
    
    LDA #$0E
    STA COLUP0  ; Player and Missle 0
    STA COLUP1  ; Player and Missle 1

    LDA #%00100111  ; Load size for missle and paddle
    STA NUSIZ0      ; Sets the size for Player and Missle 0
    STA NUSIZ1      ; Sets the size for Player and Missle 1
    
;;; Sets the ball's first spot
    STA WSYNC
    LDX #12
PositionLoop        
    dex
        bne PositionLoop
    STA RESM0

MainLoop
    LDA  #2
    STA  VSYNC  
    STA  WSYNC  
    STA  WSYNC  
    STA  WSYNC  
    LDA  #43    
    STA  TIM64T 
    LDA #0      
    STA  VSYNC  
    
;;; Score setter
;;; This only runs once, and when it does 
;;; it skips the rest of the code
    LDA ScoreSet
    BNE SkipStartUp ; Only run this the first time
        LDA #%00000010 ; Select button
        BIT SWCHB
        BNE SkipChangeScore ; Skips down if button not pressed
        
        LDX #1
        CPX SelectReleased
        BEQ DoneWithChangeScore ; Used to see if the reset button has been released
            STX SelectReleased ; Used to keep the select button running a ton
            INC PlayToScore ; Increases the score limit
            LDX #20
            CPX PlayToScore
            BNE DoneWithChangeScore ; If the score is greater than 20
                LDA #1
                STA PlayToScore ; Reset it to 1
DoneWithChangeScore
    LDA PlayToScore ; Make sure the paddle's are the right size
    STA P0Score     ; So that the player can see how large they are
    STA P1Score
    JMP WaitForVblankEnd ; Displays the screen
SkipChangeScore
    LDA #0
    STA SelectReleased ; This is used so we can tell the switch was released
    JMP WaitForVblankEnd ; Displays the screen
SkipStartUp 
    
;;; Checks if a player won. If they did then disable everthing
;;; Makes it only possible for one player to win

;;; Sees if Player 0 won
    LDA P0Score
    BNE SkipP0Win
        STA HMM0
        LDA #$72
        STA COLUBK
        JMP WaitForVblankEnd
SkipP0Win

;;; Sees if Player 1 won
    LDA P1Score
    BNE SkipP1Win
        STA HMM0
        LDA #$D2
        STA COLUBK
        JMP WaitForVblankEnd
SkipP1Win

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sees which direction to move the ball ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDX #$5F    ; Loads the value to check
    CPX VDire   ; Checks it against VDire
    BEQ SkipMoveDown    ; If VDire != #$BF
        INC BallY ; Increase YPos
        JMP SkipVMoves  ; Skip over the decrease
SkipMoveDown            ; Else if Vdire == #$BF
    DEC BallY       ; Decrease Ypos
SkipVMoves              ; End of move check

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Start of keeping dot on screen ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Checks up and down
    LDX BallY ; Loads the Ypos first
    
    ;;; Check if it is going too far down
    CPX #$05
    BNE SKIPDOWNCHECK       ;If BallY < 10
        LDA #$06
        STA BallY   ; Resets it back a step
        STA VDire ; Stores the new vertical direction
SKIPDOWNCHECK       

    ;;; Check if it is going too far up
    CPX #$60
    BNE SKIPUPCHECK     ;If BallY > 192
        LDA #$5F
        STA BallY   ; Resets it back a step
        STA VDire ; Stores the new vertical direction
SKIPUPCHECK
    
    
;;;
;;; Collision
;;; 
    
    ;;; Checks Player 1
    LDA #%10000000
    BIT CXM0P       
    BEQ SkipP1Check     ; If not colliding try other
        JMP HandleChanges ; If it is colliding jump straight to changes
SkipP1Check

    ;;; Checks Player 0
    LDA #%01000000
    BIT CXM0P   
    BEQ NoCollision ; If not hit, then no collision at all

;;; Handle changing the direction
HandleChanges
        LDX #$10    ; Load up #$10 for comparing
        CPX HDire   ; Compare with HDire
        BEQ OtherChange     ; If HDire != #$10
            STX HDire       ; HDire = #$10
            JMP NoCollision ; Skip to end so that the other change doesn't affect it
OtherChange     ; Else if HDire == #$10
    LDX #$F0
    STX HDire   ; HDire = #$F0
NoCollision ; End of Collision

    LDX HDire
    BPL MoveRightX
        INC BallX
        JMP EndMoveX
MoveRightX
    DEC BallX
EndMoveX

    STX HMM0    ; Sets H movement for ball based on HDire
    STA CXCLR   ; Resets collision
    
    LDX BallX
    CPX #$98
    BEQ SwitchMe
    LDA BallX
    BNE EndSwitch
        DEC P1Score ; Makes P1's paddle smaller
        JMP HandleSwitchChanges
SwitchMe
    DEC P0Score ; Makes P0's paddle smaller
HandleSwitchChanges
        ;;; Resets the info
        LDA #$10
        STA HDire ; Move ball left
        LDA #$80
        STA BallX ; reset the BallX counter
        STA WSYNC ; Set up WSYNC for positioning
        LDX #12 ; Sets up time to wait
PositionLoop2 ; Waits for time to pass
    dex
        bne PositionLoop2
    STA RESM0 ; Resets the ball's X
EndSwitch   
    
;;;;;;;;;;;;;;;;;;;
;; Control Check ;;
;;;;;;;;;;;;;;;;;;;
    
;;; COntrols for paddle 1
    
    ;;; Up button
    LDA #%00000001  ; Up, P1
    BIT SWCHA 
    BNE SkipUp1             ; If up button is held
        INC Paddle1Y        ; Increase value in Paddle1Y
SkipUp1

;;; Down button
    LDA #%00000010 ; Down, P1
    BIT SWCHA 
    BNE SkipDown1           ; If down button is held
        DEC Paddle1Y        ; Decrease value in Paddle1Y
SkipDown1

;;; Controls for Paddle 0

    ;;; Up button
    LDA #%00010000  ; Up, P0
    BIT SWCHA 
    BNE SkipUp0             ; If up button is held
        INC Paddle0Y        ; Increase value in Paddle0Y
SkipUp0

;;; Down button
    LDA #%00100000 ; Down, P0
    BIT SWCHA 
    BNE SkipDown0           ; If down button is held
        DEC Paddle0Y        ; Decrease value in Paddle0Y
SkipDown0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Start of keeping paddle on screen ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Paddle 0
;;; Checks up and down
    LDX Paddle0Y ; Loads the Ypos first
    
    ;;; Check if it is going too far down
    CPX P0Score
    BNE SkipDownPaddle0Check        ;If Paddle0Y < 0
        INC Paddle0Y
SkipDownPaddle0Check        

    ;;; Check if it is going too far up
    CPX #$60
    BNE SkipUpPaddle0Check      ;If Paddle0Y > 96
        LDA #$5F
        STA Paddle0Y    ; Resets it back a step
SkipUpPaddle0Check


;;; Paddle 1
;;; Checks up and down
    LDX Paddle1Y ; Loads the Ypos first
    
    ;;; Check if it is going too far down
    CPX P1Score
    BNE SkipDownPaddle1Check        ;If Paddle1Y < 0
        INC Paddle1Y
SkipDownPaddle1Check        

    ;;; Check if it is going too far up
    CPX #$60
    BNE SkipUpPaddle1Check      ;If Paddle1Y > 96
        LDA #$5F
        STA Paddle1Y    ; Resets it back a step
SkipUpPaddle1Check

    
;;;;;;;;;;;;;;;;
;; WaitForVBL ;;
;;;;;;;;;;;;;;;;

WaitForVblankEnd
    LDA INTIM   
    BNE WaitForVblankEnd    
    LDY #95     
    STA WSYNC
    STA VBLANK      

    STA WSYNC   
    STA HMOVE ; Moves our stuff horizontally


;;; Loop to handle graphics
ScanLoop 
    STA WSYNC

    CPY BallY               ; Compare Y and BallY
    BNE SkipActivateBall    ; If BallY == Y
        LDA #4              ; Load #8
        STA VisibleBallLine ; Store #8 in line counter  
SkipActivateBall

;;; Turn off the ball
    LDA #0      
    STA ENAM0

    LDA VisibleBallLine     ; Load Ball line counter
    BEQ FinishBall          ; If BallLineCounter != 0
        LDA #2              ; Load #2
        STA ENAM0           ; Use it to activate ball
        DEC VisibleBallLine ; Decrease remaining lines for ball
FinishBall
    
    
;;; Sets height of Paddle 0
    CPY Paddle0Y        ; Compare Paddle Y
    BNE SkipPaddle0     ; If PaddleY == Y
        LDA P0Score
        STA Player0Line ; Store the height of paddle
SkipPaddle0

;;; Sets height of Paddle 1
    CPY Paddle1Y        ; Compare Paddle Y
    BNE SkipPaddle1     ; If PaddleY == Y
        LDA P1Score
        STA Player1Line ; Store the height of paddle
SkipPaddle1
    LDA #2
    STA WSYNC

    ;;; De-activates Player 0 and 1
    LDA #0
    STA GRP0 ; 0
    STA GRP1 ; 1

    LDX #2 ; Use for activating Player 0 and 1

;;; Paddle 0
    LDA Player0Line     ; Load the Paddle's line counter
    BEQ FinishPlayer0   ; If PaddleLineCounter != 0
        STX GRP0        ; Activate Paddle with LDX above
        DEC Player0Line ; Decrease lines left in paddle
FinishPlayer0

;;; Paddle 1
    LDA Player1Line     ; Load the Paddle's line counter
    BEQ FinishPlayer1   ; If PaddleLineCounter != 0
        STX GRP1        ; Activate Paddle with LDX above
        DEC Player1Line; Decrease lines left in paddle
FinishPlayer1

    DEY             ; Decrease Y
    BNE ScanLoop    ; Loop till Y == 0
    
    ;;; Kill remaining WSYNCs
    LDA #2      
    STA WSYNC   
    STA VBLANK  
    LDX #30
OverScanWait
    STA WSYNC
    DEX
    BNE OverScanWait
    
;;; If reset button is pushed, reset all the shit
    LDA #%00000001 ; Reset button
    BIT SWCHB 
    BNE SkipReset ; If Reset button is held
        LDA #1
        STA ScoreSet
        JMP SetupVars ; Jump back to setup
SkipReset
    JMP  MainLoop      
 
 ;;; System start to program start
    org $FFFC
    .word Start
    .word Start

