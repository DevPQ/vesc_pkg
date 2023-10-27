; GITLIT LED driver by DevonPQ
;---------------------------------------------

(import "pkg::floatlib@://vesc_packages/float/float.vescpkg" 'floatlib)
(load-native-lib floatlib)

(import "pkg@../lib_pca9685/pca9685.vescpkg" 'pca9685)
(read-eval-program pca9685)

;(import "pkg::pca9685@://vesc_packages/lib_pca9685/pca9685.vescpkg" 'pca9685) ;from official vesc store
;(import "pkg@../lib_pca9685/pca9685.vescpkg" 'pca9685) ; From local dir as a .vescpackage
;(import "../lib_pca9685/pca9685.lisp" 'pca9685) ; From local dir as a .lisp file

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
(def gitlit-rate 5) ;HZ
(def gitlit-sw-delay 0.2)

; Dim level
(def gitlit-dim 1.0)

; PCA9685 I2C Address:
;(def #i2c-addr 0x40)

;***END USER DEFS

(def gitlit-state 1) ; on/off
(def gitlit-last-dir 0)  ; 1==fwd -1==rev
(def gitlit-curr-dir 0)  ; 1==fwd -1==rev
(def gitlit-binders 0)
(def gitlit-pitch 0)
(def gitlit-switch-last 0)
(def gitlit-torque-sign 1)
(def gitlit-erpm (round (ext-float-dbg 7)))
(def gitlit-abs-erpm (round (ext-float-dbg 8)))
;(def gitlit-erpm (round (get-rpm)))
;(def gitlit-abs-erpm (round (abs (get-rpm))))

(def gitlit-fade '(
    (0 0.0)
    (4 0.0)
    (8 0.0)
    (12 0.0)
))

(defun sign (x) (if (> x 0) 1 (- 1)))

(defun gitlit-batt-soc () {
    (var batt-per (to-float (get-batt)))
    (var lng-delay 1.0)
    (var sht-delay 0.25)
    
    (cond 
        ((>= batt-per 0.90)
            {
                (gitlit-red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 4 
                    {
                        (gitlit-white-on) 
                        (sleep sht-delay)
                        (all-off) 
                        (sleep sht-delay)  
                    }
                )
        })
        ((and (>= batt-per 0.75) (< batt-per 0.90))
            {
                (gitlit-red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 3 
                    {
                        (gitlit-white-on) 
                        (sleep sht-delay)
                        (all-off)
                        (sleep sht-delay)   
                    }
                )
        })
        ((and (>= batt-per 0.50) (< batt-per 0.75))
            {
                (gitlit-red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 2 
                    {
                        (gitlit-white-on) 
                        (sleep sht-delay)
                        (all-off)
                        (sleep sht-delay)   
                    }
                )
        })
        ((and (>= batt-per 0.25) (< batt-per 0.5))
            {
                (gitlit-red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 1 
                    {
                        (gitlit-white-on) 
                        (sleep sht-delay)
                        (all-off)  
                        (sleep sht-delay) 
                    }
                )
        })
        ((< batt-per 0.25)
            {
                (gitlit-red-on);red start
                (sleep lng-delay)
                (all-off)
                (sleep lng-delay)
                (looprange b 0 4 
                    {
                        (gitlit-red-on) 
                        (sleep sht-delay)
                        (all-off) 
                        (sleep sht-delay)  
                    }
                )
        })
    )
        
})

(defun gitlit-red-on (){
        (setix (ix gitlit-fade 0) 1  1.0);red
        (setix (ix gitlit-fade 1) 1  0.0);white
        (setix (ix gitlit-fade 2) 1  1.0);red
        (setix (ix gitlit-fade 3) 1  0.0);white
        (write-duty-cycle gitlit-fade)
})

(defun gitlit-white-on (){
        (setix (ix gitlit-fade 0) 1  0.0);red
        (setix (ix gitlit-fade 1) 1  1.0);white
        (setix (ix gitlit-fade 2) 1  0.0);red
        (setix (ix gitlit-fade 3) 1  1.0);white
        (write-duty-cycle gitlit-fade)
})

(defun gitlit-fade-forward () {
    (var steps 16)
    (var inc (/ 1.0 steps))
            
    (looprange s 0 steps
        {               
            (if (< (* inc s) gitlit-dim)
                {
                    (setix (ix gitlit-fade 0) 1  (* inc s))
                    (setix (ix gitlit-fade 1) 1  0.0)
                    (setix (ix gitlit-fade 2) 1  0.0)
                    (setix (ix gitlit-fade 3) 1  (* inc s))
                    (write-duty-cycle gitlit-fade)
                    (sleep 0.02)
                }
                (break t)
            )
        }
    )
})

(defun gitlit-fade-reverse () {
    (var steps 16)
    (var inc (/ 1.0 steps))
            
    (looprange s 0 steps
        {
            (if (< (* inc s) gitlit-dim)                
                { 
                    (setix (ix gitlit-fade 0) 1 0.0)
                    (setix (ix gitlit-fade 1) 1 (* inc s))
                    (setix (ix gitlit-fade 2) 1 (* inc s))
                    (setix (ix gitlit-fade 3) 1 0.0)
                    (write-duty-cycle gitlit-fade)
                    (sleep 0.02)
                }
                (break t)
            )
        }
    )
})

(defun gitlit-init () {
    (var res (pca9685-init nil nil))
    (var freq 1526)
    (var extclk 0)
    (var outne0 0)
    (var outne1 0)
    (var outdrv  1)
    (var inverted 0)
    (var och 0)
    (var ai 1)
    (var state (eeprom-read-i 127))
            
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
                        (setq gitlit-state 1)
                        (setq gitlit-state 0)
                    )
                    (setq gitlit-dim (* 0.1 (to-float (bits-dec-int state 8 4))))
                }
                {
                    (eeprom-store-i 127 0x00000A01)
                    (setq gitlit-state 1)
                    (setq gitlit-dim 1.0)
                }
            )
        }
        (print "Init Failed")
    )
})

(defun gitlit-data () {
    (var buffer (array-create 3))
    (var uid 88) ;uid (dec) 88 == (hex)0x58
    
    (bufclear buffer)
    (bufset-i8 buffer 0 uid)
    (bufset-i8 buffer 1 gitlit-state)
    (bufset-i8 buffer 2 (to-i (* gitlit-dim 10)))
       
    ;(send-data `(,uid ,gitlit-state ,gitlit-dim)) send data to QML
    (send-data buffer)
    (free buffer)
})

(defun gitlit-update-output () {
    (var cnt 0)
    (var loc-fade '(
        (0 0.0)
        (4 0.0)
        (8 0.0)
        (12 0.0)
    ))
    
    (loopforeach c gitlit-fade
        {
            (if (> (ix c 1) 0.0) 
                (setix (ix loc-fade cnt) 1 gitlit-dim)
                nil
            )
            (setq cnt (+ cnt 1))
        }
    )
    (write-duty-cycle loc-fade)
})

(defun gitlit-set-output (force-it) {
    ;(print (str-merge "is-sleeping " is-sleeping))
    (if (= gitlit-state 0) (all-off)
    (if (or (not-eq gitlit-curr-dir gitlit-last-dir) (= force-it 1))
        (if (not (is-sleeping))
            {
                (let (
                        (d (fn (dir)
                                {
                                    (if (= dir 0)
                                        {
                                            ;(if (=gitlit-binders 1) (progn 'blink brakes fwd!))
                                            ;(print "set-fwd Dir=0")
                                            (gitlit-fade-forward)
                                            
                                           
                                    } nil)
                                    (if (< dir 0)
                                        {
                                            ;(if (= gitlit-binders -1) (progn 'blink brakes reverse!))
                                            ;(print "set-rev Dir=-1")
                                            (gitlit-fade-reverse)
                                    } nil)
                                    (if (> dir 0)
                                        {
                                            ;(if (= gitlit-binders 1) (progn 'blink brakes fwd!))
                                            ;(print "set-fwd Dir=1")
                                            (gitlit-fade-forward)
                                    } nil)
                        }))
                    )
                    (d gitlit-curr-dir)
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

(defun gitlit-thd () {
    (print "gitlit-thd")
    (loopwhile t            
        {
            (setq gitlit-pitch (round (rad2deg (ix (get-imu-rpy) 1))))
            (setq gitlit-erpm (round (ext-float-dbg 7)))
            ;(setq gitlit-erpm (round (get-rpm)))
            (setq gitlit-abs-erpm (round (ext-float-dbg 8)))
            ;(setq gitlit-abs-erpm (round (abs (get-rpm))))
            (setq gitlit-torque-sign (sign (ext-float-dbg 3)))
            ;(setq gitlit-torque-sign (sign (get-current 1)))
                                
            ;Braking hard???
            (if (and (> gitlit-abs-erpm 2500.0) (not-eq gitlit-torque-sign (sign gitlit-erpm)) (> (abs gitlit-pitch) 10.0))
            (setq gitlit-binders 1) (setq gitlit-binders 0))
                
            ;Direction
            (if (> (secs-since gitlit-switch-last) gitlit-sw-delay)
                (cond
                    ((< gitlit-abs-erpm 100.0)
                        {
                            (setq gitlit-last-dir gitlit-curr-dir)
                            (setq gitlit-curr-dir 1)
                            (gitlit-set-output 0)
                            (setq gitlit-switch-last (systime))
                    })
                    ((> gitlit-erpm 500.0)
                        {
                            (setq gitlit-last-dir gitlit-curr-dir)
                            (setq gitlit-curr-dir 1)
                            (gitlit-set-output 0)
                            (setq gitlit-switch-last (systime))
                    })
                    ((< gitlit-erpm -500.0)
                        {
                            (setq gitlit-last-dir gitlit-curr-dir)
                            (setq gitlit-curr-dir -1)
                            (gitlit-set-output 0)
                            (setq gitlit-switch-last (systime))
                    })                          
                ) 
                nil
            )
            (sleep (/ 1.0 gitlit-rate))
        }
    )
})

(defun gitlit-store-state () {
    (var mem (to-i32 0))
    (var differs 0)

    (if (eq (eeprom-read-i 127) nil)
        (eeprom-store-i 127 0x00000A01)
        nil
    )
    (setq mem (eeprom-read-i 127))
    (if (= (bitwise-and mem 0x1) (to-i32 gitlit-state))
        nil
        {
            (setq differs 1)
            (setq mem (bits-enc-int mem 0 gitlit-state 1))
        }
    )
    (if (= (shr mem 8) (to-i32 (* gitlit-dim 10)))
        nil
        {
            (setq differs 1)
            (if (< gitlit-dim 0.1)
                (setq mem (bits-enc-int mem 8 0 4))
                (setq mem (bits-enc-int mem 8 (to-u (* gitlit-dim 10)) 4))
            )
        }
    )
       
    (if (= differs 1)
        {
            (eeprom-store-i 127 mem)
        }
        nil
    )
})

(gitlit-init)

(loopwhile (is-sleeping)
    {
        (gitlit-init)
        (sleep 1.0)
    }
)

(gitlit-batt-soc)
(gitlit-data)
(spawn 100 gitlit-thd)

