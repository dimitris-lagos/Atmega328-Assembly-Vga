;
; vga_test.asm
;
; Created: 2/20/2016 6:44:02 PM
; Author : jimlkosmo
;


;Second try to output vga color from attiny2313 with interrupts.It worked!
.org 0
rjmp RESET ;reset 
.org OC1Aaddr
rjmp TIM1_COMPA ;isr for tc1 Compare Match A
.org OC1Baddr
rjmp TIM1_COMPB ;isr for tc1 Compare Match B
.org OC0Aaddr
rjmp TIM0_COMPA ;isr for tc0 Compare Match A

RESET:
sbi ddrb,4 ; HORIZONTAL SYNC PULSE  pin set as output [2]
sbi ddrb,3 ;red pin set as output
sbi ddrb,2 ;green  pin set as output
sbi ddrb,0 ;blue  pin set as output
sbi ddrb,1 ; VERTICAL SYNC PULSE  pin set as output
ldi r16,(1<<PORTB4); H_SYNC PIN HIGH
out PORTB,r16; [1]

;stack_pointer
ldi r16,ramend; [1]
out spl,r16; [1]

;setup interrupts
clr r16
ldi r16,(1<<COM1B0); Toggle in OC1B when Comp Match on OCR1B
out TCCR1A,r16
ldi r16,(1<<FOC1B)
out TCCR1C,r16
ldi r16,(1<<CS10 | 1<<WGM12) ;CTC on OCR1A Comp Match and set CLKin 
out TCCR1B,r16
ldi r16,(1<<OCIE1A | 1<<OCIE1B | 1<<OCIE0A) ;TC1 Output Comp Match Interrupt Enabled on A and B channel and TC0
out timsk,r16
ldi r16,high(635); Load Max for TC1
out ocr1ah,r16
ldi r16,low(635)
out ocr1al,r16
ldi r16,0
out tcnt1h,r16; clear tc1
out tcnt1l,r16
;ldi r16,10; load Compare Match interrupt value for TC0
;out OCR0A,r16
ldi r16,high(12); Load first toggle value for H_SYNC (13 clock pulses)
out ocr1bh,r16
ldi r16,low(12)
out ocr1bl,r16
ldi r16,0
out tcnt1h,r16; clear tc1
out tcnt1l,r16
ldi r18,10; Load r18 with the first value of vsync toggle
ldi r19,44 ;[1] load r19 with the value of the first visible line
ldi r20,0 ;[1]
ldi r21,low(126); load r21,r22 with the value of the first visible pixel
ldi r22,high(126)
clr r28
clr r16
clr r29
ldi r16,(1<<CS01); Start tc0 with prescaler clk/8
out TCCR0B,r16
ldi r16,1
out GTCCR,r16
sei; interrupts globally enabled



main:
nop
nop
rjmp main


TIM1_COMPA:
ldi r16,low(12); Load first toggle value for H_SYNC (13 clock pulses) [1]
out ocr1bl,r16;[1]
ldi r16,12; load Compare Match interrupt value for TC0
out OCR0A,r16;[1]
in r16,sreg ; SAVE STATUS REGISTER [1]
push r16;[2]
ldi r16,3
out TCNT0,r16
ldi r16,1
out GTCCR,r16
adiw r29:r28,1 ;[2] V_SYNC counter++
ldi r17,0 ;[1]
cp r18,r28 ;[1]
cpc r17,r29 ;[1]
breq vsync_toggle ;[1/2] If we got 10 or 12 lines
ldi r16,low(524) ;[1] [6]
ldi r17,high(524) ;[1]
cp r16,r28 ;[1]
cpc r17,r29 ;[1]
breq cls_vsync ;[1/2] If we got 525 lines
cont:
pop r16 ;[2] RESTORE sreg
out sreg,r16 ;10
reti ;[4] return operation to software

TIM1_COMPB:
;in r16,sreg ; SAVE STATUS REGISTER [1]
;push r16;[2]
ldi r16,low(87); Load second toggle value for H_SYNC (13+76 clock pulses)
out ocr1bl,r16
;pop r16 ;[2] RESTORE sreg
;out sreg,r16 ;1
reti ;[4] return operation to software

TIM0_COMPA:
in r16,sreg ; SAVE STATUS REGISTER [1]
push r16;[2]
ldi r16,21 ; reset TCNT0 ????????????
out TCNT0,r16
ldi r16,1
out GTCCR,r16
ldi r16,44; Are we in vertical area?
ldi r17,0 ;[1]
cp r28,r16 ;[1]
cpc r29,r17 ;[1]
brlo no_colour
ldi r16,81; load Compare Match interrupt value for TC0
out OCR0A,r16
in r16,PORTB; [1]
ldi r17,(1<<PORTB0 | 1<<PORTB2 | 1<<PORTB3);[1] we got colour
eor r16,r17;[1]
out PORTB,r16;[1]
cont2:;[4]
pop r16 ;[2] RESTORE sreg
out sreg,r16 ;[1]
reti;

no_colour:;[7]
in r16,PORTB; [1]
cbr r16,(1<<PORTB0 | 1<<PORTB2 | 1<<PORTB3);[1] clear the colour output
out PORTB,r16;[1]
rjmp cont2;[2]



vsync_toggle:;[7]
;in r16,PORTB; white space
;ldi r17,(1<<PORTB1)
;eor r16,r17
;out PORTB,r16
sbi PINB,1;toggle v_sync
ldi r18,12 ;set r18 with 12
rjmp cont

cls_vsync:
ldi r18,10 ;set r18 with 10
ldi r28,0; reset v_sync counter
ldi r29,0
rjmp cont
