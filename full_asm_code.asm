;
; Attiny2313 Vga.asm
;
; Created: 8/16/2019 7:57:10 PM
; Author : Jiml
;


;
; vga_test.asm
;
; Created: 2/20/2016 6:44:02 PM
; Author : jimlkosmo

;PB2 OC1B (Timer/Counter1 output compare match B output)
.DSEG ; Start data segment 
pointer: .BYTE 2 ; Reserve 2 bytes in SRAM
pointer2: .BYTE 12;

.CSEG
#define itemp r16 ;temp register for ivr
#define mtemp r23 ;temp register for main
#define zero r0; r0 will always be 0
#define one r1; r1 will always be 1
#define cycle_count r7; r7=5 is the number of cycles till the branch
#define mode_coutner r8;count on which from the 6 modes are we on
#define vtoggle r18 ;vsync toggle counter
#define visible_linel r4; r4=44 number of the first visible line
#define visible_lineh r0;high byte of 44 is 0
#define no_color ((0<<PORTC0)|(0<<PORTC1)|(0<<PORTC2)|(0<<PORTC3)|(0<<PORTC4)|(0<<PORTC5))
#define white ((1<<PORTC0)|(1<<PORTC1)|(1<<PORTC2)|(1<<PORTC3)|(1<<PORTC4)|(1<<PORTC5))
#define red 0b00000011
#define green 0b00001100
#define blue 0b00110000
#define yellow 0b00001111
#define magenda 0b00100011



.org 0
rjmp RESET ;reset 
.org INT0addr
rjmp PinChange
.org OC1Aaddr
rjmp TIM1_COMPA ;isr for tc1 Compare Match A (3 cycles each jump)
.org OC1Baddr
rjmp TIM1_COMPB ;isr for tc1 Compare Match B
.org OC0Aaddr
rjmp TIM0_COMPA ;isr for tc0 Compare Match A


RESET:
ldi r16,(0<<ISC00) | (1<<ISC01)
sts EICRA,r16;MCUCR for attiny2313(EICRA – External Interrupt Control Register A)
ldi r16,(1<<INT0);
out EIMSK,r16;GIMSK for attiny external interrupt int0 request enable(EIMSK – External Interrupt Mask Register)
;ldi r16,(1<<INTF0);
;sts EIFR,r16;EIFR – External Interrupt Flag Register<- Bit 0 – INTF0: External Interrupt Flag 0
cbi ddrd,2;ddrb,2 for attiny2313

ldi r30,low(draw)
ldi r31,high(draw)
sts pointer2, r30
sts (pointer2 +1), r31

ldi r30,low(draw_magenda)
ldi r31,high(draw_magenda)
sts pointer2 +2, r30
sts pointer2 + 3, r31

ldi r30,low(draw_red)
ldi r31,high(draw_red)
sts pointer2 + 4, r30
sts pointer2 + 5, r31

ldi r30,low(draw_green)
ldi r31,high(draw_green)
sts pointer2 + 6, r30
sts pointer2 + 7, r31

ldi r30,low(draw_blue)
ldi r31,high(draw_blue)
sts pointer2 + 8, r30
sts pointer2 + 9, r31

ldi r30,low(draw_white)
ldi r31,high(draw_white)
sts pointer2 + 10, r30
sts pointer2 + 11, r31


ldi r30,low(pointer2)
ldi r31,high(pointer2)
sts pointer, r30
sts pointer+1, r31

lds r30, pointer
lds r31, pointer + 1
ld r16, Z+
ld r17, Z

movw r31:r30, r17:r16


;Data Direction Register (DDR)
sbi ddrb,3 ; HORIZONTAL SYNC PULSE  pin set as output [2]
sbi ddrb,2 ; VERTICAL SYNC PULSE  pin set as output
sbi ddrc,5 ;blue1 pin set as output
sbi ddrc,4 ;blue0 pin set as output
sbi ddrc,3 ;green1  pin set as output
sbi ddrc,2 ;green0  pin set as output
sbi ddrc,1 ;red1  pin set as output
sbi ddrc,0 ;red0  pin set as output
sbi ddrb,0 ;test led
ldi r16,(1<<PORTB2); H_SYNC PIN HIGH
out PORTB,r16; [1]

;stack_pointer
ldi r16, low(RAMEND)
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16

;setup interrupts
clr r16
;COM1B1:0 (are 2 bits in the Timer/Counter1 Control Register A – TCCR1A) control the Output Compare pin OC1B
ldi r16,(0<<COM1B1 | 1<<COM1B0); Toggle in OC1B when Comp Match on OCR1B
sts TCCR1A,r16
;FOC1B is the bit 6 of the Timer/Counter1 Control Register C – TCCR1C
;When writing a logical one to the FOC1A/FOC1B bit, an immediate compare match is forced on the Waveform Generation unit.
;The OC1A/OC1B output is changed according to its COM1x1:0 bits setting
ldi r16,(1<<FOC1B)
sts TCCR1C,r16
;CS10 is the bit 0 of the Timer/Counter1 Control Register B – TCCR1B
;WGM12 is the bit 3 of the Timer/Counter1 Control Register B – TCCR1B
ldi r16,(1<<CS10 | 1<<WGM12) ;CTC(Clear Timer on Compare match) on OCR1A Comp Match and set CLKin 
sts TCCR1B,r16
ldi r16,(1<<OCIE1A | 1<<OCIE1B) ;TC1 Output Comp Match Interrupt Enabled on A and B channel and TC0
sts timsk1,r16
ldi r16,high(632); Load Max for TC1
sts ocr1ah,r16
ldi r16,low(632)
sts ocr1al,r16
ldi r16,0
sts tcnt1h,r16; clear tc1
sts tcnt1l,r16
;TCNT1H and TCNT1L are the 2 registers containing the value of Timer/Counter1 
ldi r16,0
sts tcnt1h,r16; clear tc1
sts tcnt1l,r16
ldi r18,10; Load r18 with the first value of vsync toggle for VFP
ldi r16,44 ;[1] load r19 with the value of the first visible line
mov r4, r16
ldi r21,low(524); load r21,r22 with the value of the total lines (480 visible and 44 back and front porch)
ldi r22,high(524)
mov r2,r21
mov r3,r22
ldi r28,low(524); load r21,r22 with the value of the total lines (480 visible and 44 back and front porch)
ldi r29,high(524)
clr r0; r0 will always be 0
ldi r16,1
mov r1,r16; r1 will always be 1
ldi r16, 5
mov r7,r16
ldi r16, 6
mov r8,r16
clr r21
clr r22
clr r28
clr r16
clr r29
ldi r27,0b00111111
clr r20
sei; interrupts globally enabled



main:
nop
nop

rjmp main


visible_pixel:
pop r16
pop r16
sei
ldi r25,white
lds r23,tcnt1l ;[1]read at what pixel we are, only low byte needed cause we end here at <255 pixels
ldi r24, 114;[1]
sub r24,r23;[1]
sbrs r23,0;[1/2]skip next command if we are at even line
sbiw r24, 1;[2]
repeat:
subi r24,2;[1]
brpl repeat;[1/2]
ijmp

draw:
out PORTC, r25
DEC r25
BRPL draw
ldi r25,10
draw2:
out PORTC, r25
add r25,r7
nop
BRCC draw2
ldi r25,no_color
out PORTC, r25
rjmp main

draw_magenda:
ldi r25,magenda
out PORTC, r25
nop
rjmp main

draw_red:
ldi r25,red
out PORTC, r25
nop
rjmp main

draw_green:
ldi r25,green
out PORTC, r25
nop
rjmp main

draw_blue:
ldi r25,blue
out PORTC, r25
nop
rjmp main

draw_white:
ldi r25,white
out PORTC, r25
nop
rjmp main

;hsync toggle every 636 pixels@20mhz (would be 640@25.175mhz) aka every line 
TIM1_COMPA:;[4]
;push r16; save pre-ivr r16 data in the stack
ldi r16,low(12);[1] Load first toggle value for H_SYNC for the HFP (12 clock pulses@20mhz)
sts ocr1bl,r16;[1]
;ldi r16,no_color;[1] clear the colour output (clear only RGB pins) 
out PORTC,r0;[1]  
sbi GPIOR0,0; set bit0 of GPIOR0 to 1, as a flag
in r16,sreg ; SAVE STATUS REGISTER [1]
push r16;[2]
ldi r20, 0
;in r16,PORTB

adiw r29:r28,1 ;[2] V_SYNC counter++
sbic GPIOR0,1;[1/2]Skip if Bit1 in I/O Register is cleared (if we are already past 44th line)
rjmp cont2;[2]
cp visible_linel,r28 ;[1]
cpc visible_lineh,r29 ;[1]
breq visible_line
cp r18,r28 ;[1]
cpc r0,r29 ;[1]
breq vsync_toggle ;[1/2] If we got 10 or 12 lines (VSP 2 lines)
cont2:
cp r2,r28 ;[1] are we at line 525?
cpc r3,r29 ;[1]
breq cls_vsync ;[1/2] If we got 525 lines
cont:
pop r16 ;[2] RESTORE sreg
out sreg,r16 ;10
;pop r16; restore pre-ivr data from stack to r16
reti ;[4] return operation to software
visible_line:
sbi GPIOR0,1; set bit1 of GPIOR0 to 1, as a flag for first visible line
rjmp cont


;HSYNC HFP+HSP timmings
TIM1_COMPB:;[4]
;push r16; save pre-ivr r16 data in the stack
sbis GPIOR0,0;[1/2]Skip if Bit in I/O Register is set
rjmp check_line
in r16,sreg ; SAVE STATUS REGISTER [1]
push r16;[2]
ldi r16,low(87); Load second toggle value for H_SYNC (12+76 clock pulses@20mhz)
sts ocr1bl,r16;[1]
sts ocr1bh,r0
cbi GPIOR0,0; clear flag
pop r16 ;[2] RESTORE sreg
out sreg,r16 ;1
;pop r16; restore pre-ivr data from stack to r16
reti ;[4] return operation to software
check_line:
sbic GPIOR0,1;[1/2]Skip if Bit in I/O Register is cleared
rjmp visible_pixel
reti

;pop r16
;pop r16
;sei
;rjmp main




TIM0_COMPA:;[4]
in r16,sreg ; SAVE STATUS REGISTER [1]
push r16;[2]

pop r16 ;[2] RESTORE sreg
out sreg,r16 ;[1]
reti;




vsync_toggle:;[7]
sbi PINB,3;toggle v_sync
ldi r18,12 ;set r18 with 12
rjmp cont

cls_vsync:

ldi r18,10 ;set r18 with 10 (11 cycles for VFP)
ldi r28,0; reset v_sync counter
ldi r29,0

inc r9
mov r16,r9
cpi r16, 120
brlo debounce 

mov r9,r0
ldi r16,(1<<INTF0); clear pending int0 interrupts
out EIFR,r16
ldi r16,(1<<INT0);
out EIMSK,r16;GIMSK for attiny external interrupt int0 request enable(EIMSK – External Interrupt Mask Register)
debounce:
cbi GPIOR0,1; clear bit1 of flag register (44 line mark reset)
rjmp cont



PinChange:
in r16,sreg ; SAVE STATUS REGISTER [1]
push r16;[2]

dec r8
cp r8,r0
breq mode_reset
mode_cycle:
lds r30, pointer;$pointer holds the address of pointer2, so here we load the address of pointer2(load indirect)
lds r31, pointer + 1;$addresses are 16bit long so we store them in 2 consecutive 8bit sram locations
ld r5, Z+;$pointer2(stored in r31:r30->Z) holds the starting address of the draw function,(load indirect that function addr to r6:r5)
ld r6, Z;$addresses are 16bit long so we store them in 2 consecutive 8bit sram locations
adiw r31:r30, 1
sts pointer, r30
sts pointer+1, r31
mov r31, r6; now Z holds the address of the draw function
mov r30, r5
;ldi r16,1<<PORTB0;led for debugging purposes
;out PORTB, r16;led for debugging purposes

ldi r16,(1<<INTF0); clear pending int0 interrupts
out EIFR,r16
ldi r16,(0<<INT0);
out EIMSK,r16;GIMSK for attiny external interrupt int0 request enable(EIMSK – External Interrupt Mask Register)
pop r16 ;[2] RESTORE sreg
out sreg,r16 ;1
reti
mode_reset:
ldi r30,low(pointer2)
ldi r31,high(pointer2)
sts pointer, r30
sts pointer+1, r31
ldi r16,6
mov r8,r16
rjmp mode_cycle
