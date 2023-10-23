;PCA9685 Driver Library

; Note:
; increase on tick & decrease off tick dims intensity
; increase off tick & decrease on tick increases intensity

; To move code to flash memory and free up space on the heap
; @const-start
;    ##CODE HERE
; @const-end
; This can be used only together with the incremental reader (such as read-eval-program).

; I2C Address: 1+A5+A4+A3+A2+A1+A0+RW
(define #DEV-ADDR 0x40) ; Default PCA9685 I2C Slave Address

; CONST
;(define FREQUENCY-OSCILLATOR 25000000) ; Int. osc. frequency in datasheet
;(define osc-freq FREQUENCY-OSCILLATOR)
(define lv-freq 1000)
(define buf (array-create 5))
(define data-buf (array-create 4))

@const-start

; Registers
(define REG-MODE1 0x00)
(define REG-MODE2 0x01)
(define REG-LED0-ON-L 0x06)
(define REG-ALL-LED-ON-L 0xFA)

; 16-Byte Table 
(define #gamma-tab '(
    0 11 49 119 224 365 545 766 1027 1331 1678 2070 2506 2989 3518 4095
))

; 8-Byte Table
;(define #gamma-tab '(
;        0 57 260 635 1196 1953 2917 4095
;))

;(defun read-u8 (reg len)
;    {
;            (var buf (array-create len))
;            (var read-val 0u8)
;        
;            (i2c-tx-rx #DEV-ADDR (list reg) buf)
;            (setq read-val (bufget-u8 rbuf 0))
;            (free buf)
;            read-val
;})

(defun write-u8 (reg val)
    { 
        ;(print (str-merge "write-u8 " (str-from-n reg "REG:0x%02x ") (str-from-n val "VAL:0x%02x")))
        (i2c-tx-rx #DEV-ADDR (list reg val))
    }
)

(defun write-data (ch data)
    {
        ;(var buf (array-create 5))  
        (if (or (= (buflen data) 0) (> (buflen data) 4)) 
            nil 
            {
                (bufclear buf)
                ;(print-data data)
                (bufset-u8 buf 0 ch)
                (bufcpy buf 1 data 0 4)
                (i2c-tx-rx #DEV-ADDR buf)
            }
        )
        ;(free buf)
})

(defun set-i2c-address (addr)
    (setq #DEV-ADDR addr)
)

(defun reset ()
    { 
        ;(all-off)
        ;(i2c-tx-rx #DEV-ADDR (list REG-MODE1 0x00 0x6))
        (i2c-tx-rx #DEV-ADDR (list REG-MODE1 0x6))
    }
)

;MODE 1 Functions
;#############################################################
(defun set-sleep () 
    {
            ;(var buf (array-create 1))
        
            ; Read the current state of the mode 1 register.
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1) buf)
            ;(print (str-from-n (bufget-u8 rsbuf 0) "M1 = 0x%02x"))
            ; Don't write the restart bit back and set the sleep bit.
            (bufset-bit buf 4 1)
            ;(print (str-from-n (bufget-u8 rsbuf 0) "M1 = 0x%02x"))
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1 (bufget-u8 buf 0)))
            
            ;(free buf)
            ;(print "asleep")
            (yield 1000)
})

(defun set-auto-inc (enable) 
    {
            ;(var buf (array-create 1))
        
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1) buf)
            (if (= enable 1) (bufset-bit buf 5 1) (bufset-bit buf 5 0))
            (write-u8 REG-MODE1 (bufget-u8 buf 0))
            ;(free buf)
})

(defun set-ext-clk (enable) 
    {
            ;(var buf (array-create 1))        
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1) buf)
            (if (= enable 1) (bufset-bit buf 6 1) (bufset-bit buf 6 0))
            (write-u8 REG-MODE1 (bufget-u8 buf 0))
            ;(free buf)
        
})

;#############################################################

;MODE 2 Functions
;#############################################################

; Active LOW output enable input 'OE' pin
; param: bit0:OUTNE0 bit1:OUTNE1
; OUTNE[1:0]    LED outputs
;        00:    0 *default
;        01:    1 if OUTDRV=1, hi-z OUTDRV=0
;        00:    0 hi-z
;        00:    0 hi-z
(defun set-outne (bit0 bit1) 
     {
            ;(var buf (array-create 1))
            (if (or (not bit0) (not bit1) (> bit0 1) (< bit0 0) (> bit1 1) (< bit1 0))
                nil
                {
                    (bufclear buf)
                    (i2c-tx-rx #DEV-ADDR (list REG-MODE2) buf)
                    (bufset-bit buf 0 bit0) 
                    (bufset-bit buf 1 bit1)
                    (write-u8 REG-MODE2 (bufget-u8 buf 0))
                }
            )
            ;(free buf)
})

; param: outdrv= 1:totem pole  0:open drain
; Suggested configs
; bit2:outdrv  bit4:invrt
; 1= LEDs directly connected no ext driver (outdrv:0 invrt:1)
; 2= N-type Ext. driver used *DEFAULT (outdrv:1 invrt:0)
; 3= P-type Ext. driver used (outdrv:1 invrt:1)
(defun set-outdrv (outdrv) 
    {
            ;(var buf (array-create 1))
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE2) buf)
            (bufset-bit buf 2 outdrv)
            (write-u8 REG-MODE2 (bufget-u8 buf 0))
            ;(free buf)
})

; param: Outputs change on: 1=ACK 0=STOP
(defun set-och (ack) 
     {
            ;(var buf (array-create 1))
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE2) buf)
            (if (= ack 1) (bufset-bit buf 3 1) (bufset-bit buf 3 0))
            (write-u8 REG-MODE2 (bufget-u8 buf 0))
            ;(free buf)
})

; param: inverted= 1:output polarity is inverted
(defun set-inverted (inverted) 
     {
            ;(var buf (array-create 1))
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE2) buf)      
            (if (= inverted 1) (bufset-bit buf 4 1) (bufset-bit buf 4 0))
            (write-u8 REG-MODE2 (bufget-u8 buf 0))
            ;(free buf)
})
;###############################################################################

(defun is-sleeping ()
     {
            ;(var buf (array-create 1))
            (var sleeping 0)
            ; Read the current state of the mode 1 register.
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1) buf)
        
            ; Check if the sleeping bit is set.
            (setq sleeping (= (bits-dec-int (bufget-u8 buf 0) 4 1) 1))
            ;(free buf)
            sleeping
})

(defun wakeup () 
    {
            ;(var buf (array-create 1))
            (var awake 0)
        
            ;(print "wakeup")
            ; Read the current state of the mode 1 register.
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1) buf)
                
            (bufset-bit buf 4 0)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1 (bufget-u8 buf 0)))
            (yield 1000)
            (bufset-bit buf 7 1)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1 (bufget-u8 buf 0)))
            (bufclear buf)
            (i2c-tx-rx #DEV-ADDR (list REG-MODE1) buf)
            (yield 1000)
            (setq awake (bits-dec-int (bufget-u8 buf 0) 4 1))
            (setq awake (+ awake (bits-dec-int (bufget-u8 buf 0) 7 1)))
        
            ;(free buf)
            (= awake 0)
})

(defun set-pwm-freq (freq)
    {
            (var reg-prescale 0xFE)
            (var prescale 0x03)
            (var res false)
        
            ;(print "set prescale")
            (if (>= freq 1526) 
                (setq prescale 0x03)
                    (if (<= freq 24)
                        (setq prescale 0xFF)
                            (setq prescale 
                                (to-byte (floor (- (+ (/ 25000000 (* 4096.0 freq)) 0.5) 1))))))
                                        
            (set-sleep)
            ;(print (str-from-n prescale "0x%02x"))
            (setq lv-freq freq) 
            (setq res (write-u8 reg-prescale prescale))
            (wakeup)            
            res        
})

(defun set-pwm (channel on-t off-t)
     {
            ;(var data (array-create 4))
        
            (bufclear data-buf)
            (bufset-u8 data-buf 0 on-t)
            (bufset-u8 data-buf 1 (shr on-t 8))
            (bufset-u8 data-buf 2 off-t)
            (bufset-u8 data-buf 3 (shr off-t 8))
            (write-data channel data-buf)
            ;(free data)
})

;(defun get-pwm (ch-idx)
;     {
;            (var buf (array-create 4))
;            (var ch (+ (* ch-idx 4) REG-LED0-ON-L))
;            (var res ())
;            (if (> ch-idx 15) 
;                (setq ch REG-ALL-LED-ON-L) 
;                nil 
;            ) ;(define ch (+ (* ch-idx 4) REG-LED0-ON-L))
        
;            (i2c-tx-rx #DEV-ADDR (list ch) buf)
;            (setq res (map (fn (x) (bufget-u8 buf x)) (range 0 (+ (buflen buf) 1))))
;            (free buf)
;            res
;})

;Working
;(defun set-duty-cycle(channel duty)
;    {
;            (var ch (+ (* channel 4) REG-LED0-ON-L))
;            (var on-period 0)
;            (var on-tick 0)
;            (var off-tick 4096)                
;        
;            ;(print "set duty")
;            ;(print (to-float duty))
;            (if (> duty 1.0) (setq duty 1.0)
;                (if (< duty 0.0) (setq duty 0.0) nil))
;           
;            (if (= duty 0.0)
;                (set-pwm ch 0 4096) ; // Special value for always off
;                    (if (= duty 1.0)
;                        (set-pwm ch 4096 0) ; // Special value for always on
;                            { 
;                                (setq on-period (ix gamma-lup-tab-16 (round (* 15 duty))))                        
;                                ; Offset on and off times depending on channel to minimise current spikes.
;                                (setq on-tick (bitwise-and (if (= channel 0) 0 (- (* channel 256) 1)) 0xFFF))                                                               
;                                (setq off-tick (bitwise-and (+ on-period on-tick) 0xFFF))
;                                (set-pwm ch on-tick off-tick) 
;                            }))
;})

(defun write-duty-cycle(data)
    {
        ;(var ledn-buf (array-create 4))
        (loopforeach ch data
            {
                    (var offset (first ch))
                    (var chan (+ (* (first ch) 4) REG-LED0-ON-L))
                    (var duty (to-float (second ch)))
                    (var on-period 0)
                    (var on-tick 0)
                    (var off-tick 4096)
                    ;(print "write duty")
                    ;(print offset)
                    ;(print duty)
                    ;(bufclear ledn-buf)
                    (bufclear data-buf)
                    
                    (if (> duty 1.0) (setq duty 1.0)
                        (if (< duty 0.0) (setq duty 0.0) nil))
           
                    (if (= duty 0.0)
                        { 
                            (setq on-tick 0)
                            (setq off-tick 4096)
                        } ; // Special value for always off
                        (if (= duty 1.0)
                            { 
                                (setq on-tick 4096)
                                (setq off-tick 0)
                            } ; // Special value for always on
                            { 
                                (setq on-period (ix #gamma-tab (round (* 15 duty))))                        
                                ; Offset on and off times depending on channel to minimise current spikes.
                                (setq on-tick (bitwise-and (if (= offset 0) 0 (- (* offset 256) 1)) 0xFFF))                                                            
                                (setq off-tick (bitwise-and (+ on-period on-tick) 0xFFF))
                            }))
                    (bufset-u8 data-buf 0 on-tick)
                    (bufset-u8 data-buf 1 (shr on-tick 8))
                    (bufset-u8 data-buf 2 off-tick)
                    (bufset-u8 data-buf 3 (shr off-tick 8))
                    (write-data chan data-buf)
        })
    ;(free ledn-buf)
})

(defun all-off () 
    {
        (set-pwm REG-ALL-LED-ON-L 0 4096) ; // Special value for always off
        ;(print "All OFF")
    }
)

(defun all-on () 
    {
        (set-pwm REG-ALL-LED-ON-L 4096 0) ; // Special value for always on
        ;(print "All ON")
    }
)

(defun pca9685-init (pins i2caddr) 
    {
        (apply i2c-start (append '('rate-400k) pins))
        (sleep 0.005)
        (if (not-eq i2caddr nil) (set-i2c-address i2caddr) nil)
        (reset)
        (sleep 0.005)
        (set-auto-inc 1)
        1
})

@const-end

; This can be used to remove all init-code and free up the heap
;(defun free-heap ()
;    {
;        ;(undefine 'read-u8)
;        (undefine 'pca9685-init)
;        (undefine 'set-ext-clk)
;        (undefine 'set-pwm-freq)
;        (undefine 'set-outne)
;        (undefine 'set-och)
;        (undefine 'set-outdrv)
;        (undefine 'set-inverted)
;        ;(undefine 'fade-up)
;        ;(undefine 'fade-down)
;        ;(undefine set-i2c-address)
;        ;(undefine 'FREQUENCY-OSCILLATOR)
;        (undefine 'free-heap)
;        (gc)
;})
