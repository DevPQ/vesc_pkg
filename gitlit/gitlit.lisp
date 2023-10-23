; GITLIT LED driver by DevonPQ
;---------------------------------------------

(import "pkg::floatlib@://vesc_packages/float/float.vescpkg" 'floatlib)
(load-native-lib floatlib)

;(import "pkg::pca9685@://vesc_packages/lib_pca9685/pca9685.vescpkg" 'pca9685)
(import "pkg@../lib_pca9685/pca9685.vescpkg" 'pca9685)
;(import "../lib_pca9685/pca9685.lisp" 'pca9685)
(read-eval-program pca9685)

; Switch Balance App to UART App
(if (= (conf-get 'app-to-use) 9) (conf-set 'app-to-use 3))

; Set firmware version:
(apply ext-set-fw-version (sysinfo 'fw-ver))

; Extension ext-float-dbg
;(ix):description
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
; FWD                   ; REV
; pin[0] Front-RD       ; pin[8] Rear-RD
; pin[4] Front-WHT      ; pin[12] Rear-WHT


;*** USER DEFS SECTION ***

; Control rates
(def rate 5) ;HZ
(def sw-delay 0.2)

; Dim level
(def dim-on 1.0)

; PCA9685 I2C Address:
;(def #i2c-addr 0x40)

;***END USER DEFS

(def lit-state 1) ; on/off
(def last-dir 0)  ; 1==fwd -1==rev
(def curr-dir 0)  ; 1==fwd -1==rev
(def binders 0)
(def pitch 0)
(def switch-last 0)
(def torque-sign 1)
(def erpm (round (ext-float-dbg 7)))
(def abs-erpm (round (ext-float-dbg 8)))
;(def erpm (round (get-rpm)))
;(def abs-erpm (round (abs (get-rpm))))

(def fade '(
    (0 0.0)
    (4 0.0)
    (8 0.0)
    (12 0.0)
))

;(def temp-fade '(
;    (0 0.0)
;    (4 0.0)
;    (8 0.0)
;    (12 0.0)
;))

(defun sign (x) (if (> x 0) 1 (- 1)))

(defun batt-level () {
    (var batt-per (to-float (get-batt)))
    (var lng-delay 1.0)
    (var sht-delay 0.25)
    
    (cond 
        ((>= batt-per 0.90)
            {
                (red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 4 
                    {
                        (white-on) 
                        (sleep sht-delay)
                        (all-off) 
                        (sleep sht-delay)  
                    }
                )
        })
        ((and (>= batt-per 0.75) (< batt-per 0.90))
            {
                (red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 3 
                    {
                        (white-on) 
                        (sleep sht-delay)
                        (all-off)
                        (sleep sht-delay)   
                    }
                )
        })
        ((and (>= batt-per 0.50) (< batt-per 0.75))
            {
                (red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 2 
                    {
                        (white-on) 
                        (sleep sht-delay)
                        (all-off)
                        (sleep sht-delay)   
                    }
                )
        })
        ((and (>= batt-per 0.25) (< batt-per 0.5))
            {
                (red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 1 
                    {
                        (white-on) 
                        (sleep sht-delay)
                        (all-off)  
                        (sleep sht-delay) 
                    }
                )
        })
        ((< batt-per 0.25)
            {
                (red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 4 
                    {
                        (red-on) 
                        (sleep sht-delay)
                        (all-off) 
                        (sleep sht-delay)  
                    }
                )
        })
    )
        
})

(defun red-on (){
        (setix (ix fade 0) 1  1.0);red
        (setix (ix fade 1) 1  0.0);white
        (setix (ix fade 2) 1  1.0);red
        (setix (ix fade 3) 1  0.0);white
        (write-duty-cycle fade)
})

(defun white-on (){
        (setix (ix fade 0) 1  0.0);red
        (setix (ix fade 1) 1  1.0);white
        (setix (ix fade 2) 1  0.0);red
        (setix (ix fade 3) 1  1.0);white
        (write-duty-cycle fade)
})

(defun fade-forward () {
    (var steps 16)
    (var inc (/ 1.0 steps))
            
    (looprange s 0 steps
        {               
            (if (< (* inc s) dim-on)
                {
                    (setix (ix fade 0) 1  (* inc s))
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
})

(defun fade-reverse () {
    (var steps 16)
    (var inc (/ 1.0 steps))
            
    (looprange s 0 steps
        {
            (if (< (* inc s) dim-on)                
                { 
                    (setix (ix fade 0) 1 0.0)
                    (setix (ix fade 1) 1 (* inc s))
                    (setix (ix fade 2) 1 (* inc s))
                    (setix (ix fade 3) 1 0.0)
                    (write-duty-cycle fade)
                    (sleep 0.02)
                }
                (break t)
            )
        }
    )
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
    (var state (eeprom-read-i 126))
            
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
                
            ; Read saved state of lights 
            (if (not-eq state nil)
                {
                    (if (= (bitwise-and state 0x1) 1)
                        (setq lit-state 1)
                        (setq lit-state 0)
                    )
                    (setq dim-on (* 0.1 (to-float (bits-dec-int state 8 4))))
                }
                {
                    (eeprom-store-i 126 0x00000A01)
                    (setq lit-state 1)
                    (setq dim-on 1.0)
                }
            )
        }
        (print "Init Failed")
    )
})

(defun git-lit-data () {
    (var buffer (array-create 3))
    (var uid 88) ;uid (dec) 88 == (hex)0x58
    
    (bufclear buffer)
    (bufset-i8 buffer 0 uid)
    (bufset-i8 buffer 1 lit-state)
    (bufset-i8 buffer 2 (to-i (* dim-on 10)))
       
    ;(send-data `(,uid ,lit-state ,dim-on)) send data to QML
    (send-data buffer)
    (free buffer)
})

(defun update-output () {
    (var cnt 0)
    (var loc-fade '(
        (0 0.0)
        (4 0.0)
        (8 0.0)
        (12 0.0)
    ))
    
    (loopforeach c fade
        {
            (if (> (ix c 1) 0.0) 
                (setix (ix loc-fade cnt) 1 dim-on)
                nil
            )
            (setq cnt (+ cnt 1))
        }
    )
    (write-duty-cycle loc-fade)
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
                                            (fade-forward)
                                            
                                           
                                    } nil)
                                    (if (< dir 0)
                                        {
                                            ;(if (= binders -1) (progn 'blink brakes reverse!))
                                            ;(print "set-rev Dir=-1")
                                            (fade-reverse)
                                    } nil)
                                    (if (> dir 0)
                                        {
                                            ;(if (= binders 1) (progn 'blink brakes fwd!))
                                            ;(print "set-fwd Dir=1")
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

(defun led-thd () {
    (print "led-thd")
    (loopwhile t            
        {
            (setq pitch (round (rad2deg (ix (get-imu-rpy) 1))))
            (setq erpm (round (ext-float-dbg 7)))
            ;(setq erpm (round (get-rpm)))
            (setq abs-erpm (round (ext-float-dbg 8)))
            ;(setq abs-erpm (round (abs (get-rpm))))
            (setq torque-sign (sign (ext-float-dbg 3)))
            ;(setq torque-sign (sign (get-current 1)))
                                
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
                ) 
                nil
            )
            (sleep (/ 1.0 rate))
        }
    )
})

(defun store-state () {
    (var mem (to-i32 0))
    (var differs 0)

    (if (eq (eeprom-read-i 126) nil)
        (eeprom-store-i 126 0x00000A01)
        nil
    )
    (setq mem (eeprom-read-i 126))
    (if (= (bitwise-and mem 0x1) (to-i32 lit-state))
        nil
        {
            (setq differs 1)
            (setq mem (bits-enc-int mem 0 lit-state 1))
        }
    )
    (if (= (shr mem 8) (to-i32 (* dim-on 10)))
        nil
        {
            (setq differs 1)
            (if (< dim-on 0.1)
                (setq mem (bits-enc-int mem 8 0 4))
                (setq mem (bits-enc-int mem 8 (to-u (* dim-on 10)) 4))
            )
        }
    )
       
    (if (= differs 1)
        {
            (eeprom-store-i 126 mem)
        }
        nil
    )
})

(init-git-lit)

(loopwhile (is-sleeping)
    {
        (init-git-lit)
        (sleep 1.0)
    }
)

(batt-level)
(git-lit-data)
(spawn 100 led-thd)

