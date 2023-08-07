; GITLIT LED driver by DevonPQ
;---------------------------------------------

(import "pkg::floatlib@://vesc_packages/float/float.vescpkg" 'floatlib)
(load-native-lib floatlib)
;(import "PCA9685_v1.0b.lisp" 'pca9685)
;(import "pkg::pca9685@://vesc_packages/lib_pca9685/pca9685.vescpkg" 'pca9685)
;(import "pkg::pca9685@C:/Users/Devon/OneDrive/Documents/GitHub/vesc_pkg/lib_pca9685/pca9685.vescpkg" 'pca9685)
(import "C:/Users/Devon/OneDrive/Documents/GitHub/vesc_pkg/lib_pca9685/pca9685.lisp" 'pca9685)
(eval-program (read-program pca9685))

; Extension ext-float-dbg
;(idx):description                   ;(idx):description
;(1):setpoint                        ;(10):diff_time
;(2):float_setpoint                  ;(11):loop_overshoot
;(3):atr_filtered_current            ;(12):filtered_loop_overshoot
;(4):float_atr                       ;(13):filtered_diff_time
;(5):last_pitch_angle - pitch_angle  ;(14):integral
;(6):motor_current                   ;(15):integral * float_conf.ki
;(7):erpm                            ;(16):integral2
;(8):abs_erpm                        ;(17):0
;(9):loop_time_seconds               ;default:0

;PIN MAPPINGS
;FWD
; pin[0] Front-WHT
; pin[4] Front-RD

;REV
; pin[8] Rear-WHT
; pin[12] Rear-RD

;*** USER DEFS SECTION ***
; App unique id
;(def uid 815)
; Control rates
(def rate 5) ;HZ
(def sw-delay 0.2)

; Dim levels
(def dim-on 1.0)
(def dim-off 0.0)

; PCA9685 I2C Address:
;(def #i2c-addr 0x40)

;***END USER DEFS

(def lit-state 1) ; on/off
(def last-dir 0)  ; 1==fwd -1==rev
(def curr-dir 0)  ; 1==fwd -1==rev
(def binders 0)
(def pitch 0)
(def switch-last 0)
(def erpm (round (ext-float-dbg 7)))
(def abs-erpm (round (ext-float-dbg 8)))
(def torque-sign 1)

;(define p-rate 0)
;(define p-last (ext-float-dbg 5))
;(define p-filtered 0)
;(defun p-filter (val sample)
;    (- val (* 0.2 (- val sample)))
;)

;(define t-last (systime))
;(define it-rate 0)
;(define it-rate-filter 0)
;(defun t-filter (val sample)
;    (- val (* 0.01 (- val sample)))
;)

(def ebb `(
    (0 ,dim-on)
    (4 ,dim-off)
    (8 ,dim-off)
    (12 ,dim-on)
))

(def flow `(
    (0 ,dim-off)
    (4 ,dim-on)
    (8 ,dim-on)
    (12 ,dim-off)
))

(def fade '(
    (0 0.0)
    (4 0.0)
    (8 0.0)
    (12 0.0)
))

(def temp-fade '(
    (0 0.0)
    (4 0.0)
    (8 0.0)
    (12 0.0)
))

(defun sign (x) (if (> x 0) 1 (- 1)))

(defun fade-forward () {
            ;(var steps 8)
            (var steps 16)
            (var inc (/ 1.0 steps))
            
            (looprange s 0 steps
                {                
                    ;(yield 50)
                    (if (< (* inc s) dim-on)
                        {
                            (setix (ix fade 0) 1  (* inc s))
                            ;(setix (ix fade 1) 1  (- 1.0 (* inc s)))
                            ;(setix (ix fade 2) 1  (- 1.0 (* inc s)))
                            (setix (ix fade 1) 1  0.0)
                            (setix (ix fade 2) 1  0.0)
                            (setix (ix fade 3) 1  (* inc s))
                            (write-duty-cycle fade)
                            (sleep 0.02)
                        }
                        (break t)
                    )
                }
            )
            ;(yield 50)
            ;(write-duty-cycle ebb)
})

(defun fade-reverse () {
            ;(var steps 8)
            (var steps 16)
            (var inc (/ 1.0 steps))
            
            (looprange s 0 steps
                {
                    ;(yield 50)
                    (if (< (* inc s) dim-on)                
                        { 
                            ;(setix (ix fade 0) 1  (- 1.0 (* inc s)))
                            (setix (ix fade 0) 1 0.0)
                            (setix (ix fade 1) 1 (* inc s))
                            (setix (ix fade 2) 1 (* inc s))
                            ;(setix (ix fade 3) 1 (- 1.0 (* inc s)))
                            (setix (ix fade 3) 1 0.0)
                            (write-duty-cycle fade)
                            (sleep 0.02)
                        }
                        (break t)
                    )
                }
            )
            ;(yield 50)
            ;(write-duty-cycle flow)
})

(defun init-git-lit () {
            (var res (pca9685-init nil nil))
            (var freq 1526)
            (var extclk 0)
            (var outne0 0)
            (var outne1 0)
            (var outdrv  1)
            (var inverted 0)
            (var och 0)
            (var ai 1)
            (var state (eeprom-read-i 9))
            (var dim (eeprom-read-f 10))
            
        (if (= res 1)
            {
                (set-auto-inc ai)
                (set-pwm-freq freq)
                (set-ext-clk extclk)
                (set-outne outne0 outne1)                      
                (set-outdrv  outdrv)
                (set-inverted inverted)
        
                ; Initial state of lights off 
                (all-off)
                
                (if (= state nil)
                    (setq lit-state 1)
                    (setq lit-state state)
                )
                (if (= dim nil)
                    (setq dim-on 1.0)
                    (setq dim-on dim)
                )                
            }
            (print "Init Failed")
        )
})

(defun tx-gitlit-data()
    ;(send data to QML  '( (float magic number = 101) (gitlit msg type = 815) ,lit-state ,dim-on))
    (send-data '(101 815 ,lit-state ,dim-on))
)

(defun update-output () {
        (var cnt 0)
        (loopforeach c fade
            {
                (if (> (ix c 1) 0.0) 
                    (setix (ix temp-fade cnt) 1 dim-on)
                    nil
                )
                (setq cnt (+ cnt 1))
            }
        )
        (write-duty-cycle temp-fade)
})

(defun set-output (force-it) {
    ;(print (str-merge "is-sleeping " is-sleeping))
    (if (= lit-state 0) (all-off)
    (if (or (not-eq curr-dir last-dir) (= force-it 1))
        (if (not (is-sleeping))
            {
                (let (
                        (d (fn (dir)
                                {
                                    (if (= dir 0)
                                        {
                                            ;(if (=binders 1) (progn 'blink brakes fwd!))
                                            ;(print "set-fwd Dir=0")
                                            ;(define local-dir dir)
                                            ;(write-duty-cycle ebb)
                                            (fade-forward)
                                            
                                           
                                    } nil)
                                    (if (< dir 0)
                                        {
                                            ;(if (= binders -1) (progn 'blink brakes reverse!))
                                            ;(print "set-rev Dir=-1")
                                            ;(define local-dir dir)
                                            ;(write-duty-cycle flow)
                                            (fade-reverse)
                                    } nil)
                                    (if (> dir 0)
                                        {
                                            ;(if (= binders 1) (progn 'blink brakes fwd!))
                                            ;(print "set-fwd Dir=1")
                                            ;(define local-dir dir)
                                            ;(write-duty-cycle ebb)
                                            (fade-forward)
                                    } nil)
                        }))
                    )
                    (d curr-dir)
                )
            }
            {
                ;(print "i2c-restore")
                (i2c-restore)
                (sleep 0.1)
                (wakeup)
            }
        )
        nil
    ))
})

; This is received from the QML-program
; data
; byte[0]: UUID
; byte[1]: CMD Index
; byte[2]: val
;(defun proc-data (data)
;    {
;        (if (= (bufget-u8 data 0) 815) ; uuid
;        {
;            (var cmd (bufget-u8 data 1))
;            (var val (bufget-u8 data 2))
;            (cond 
;                ((= cmd 0)
;                    (setq lit-state val)  ; on-off state
;                )
;                ((= cmd 1)
;                    (setq dim-on val) ; dim 0.0-1.0
;                )
;            )
;        }
;        nil)
;    }
;)

(defun led-thd () {
        (print "led-thd")
        (loopwhile t
             
            {
                (setq pitch (round (rad2deg (ix (get-imu-rpy) 1))))
                (setq erpm (round (ext-float-dbg 7)))
                (setq abs-erpm (round (ext-float-dbg 8)))
                (setq torque-sign (sign (ext-float-dbg 3)))
                
                ; Loop rate measurement
                ;(setq it-rate (/ 1.0 (secs-since t-last)))
                ;(setq t-last (systime))
                ;(setq it-rate-filter (t-filter it-rate-filter it-rate))
                
                ; Pitch rate measurement
                ;(setq p-rate t-last)
                ;(setq p-last (ext-float-dbg 5))
                ;(setq p-filtered (p-filter p-filtered p-last))
                
                ;Braking hard???
                (if (and (> abs-erpm 2500.0) (not-eq torque-sign (sign erpm)) (> (abs pitch) 10.0))
                (setq binders 1) (setq binders 0))
                
                ;Direction
                (if (> (secs-since switch-last) sw-delay)
                    (cond
                        ((< abs-erpm 100.0)
                            {
                                (setq last-dir curr-dir)
                                (setq curr-dir 1)
                                (set-output 0)
                                (setq switch-last (systime))
                        })
                        ((> erpm 500.0)
                            {
                                (setq last-dir curr-dir)
                                (setq curr-dir 1)
                                (set-output 0)
                                (setq switch-last (systime))
                        })
                        ((< erpm -500.0)
                            {
                                (setq last-dir curr-dir)
                                (setq curr-dir -1)
                                (set-output 0)
                                (setq switch-last (systime))
                        })                          
                    ) nil
                )
                    
                ;(sleep (- (/ 1.0 #rate) (#it-rate-filter))) ;Needs testing
                (sleep (/ 1.0 rate)) ;otherwise
        })
})

(defun store-state() {
    (if (not-eq (eeprom-read-i 9) lit-state)
        (eeprom-store-i 9 lit-state)
        nil
    )
    (if (not-eq (eeprom-read-f 10) dim-on)
        (eeprom-store-f 10 dim-on)
        nil
    )
})

(defun event-handler ()
    {
        (recv 
            ;((event-data-rx . (? data)) (proc-data data))
            (event-shutdown (store-state))
            (_ nil))
        (event-handler)
})

(init-git-lit)

; Sleep after boot to wait for IMU to settle
;(if (< (secs-since 0) 5) (sleep 5) nil)

(loopwhile (is-sleeping)
    {
        (init-git-lit)
        (sleep 1.0)
    }
)

(event-register-handler (spawn 30 event-handler))
;(event-enable 'event-data-rx)
(event-enable 'event-shutdown)

;Use this instead of event-shutdown if you dont have a on/off switch
;(defun voltage-monitor ()
;    (progn
;        (if (< (get-vin) vin-min)
;            (store-state)
;        )
;        (sleep 0.01)
;))

;(spawn 30 voltage-monitor)

(tx-gitlit-data)
(free-heap)
(spawn 100 led-thd)