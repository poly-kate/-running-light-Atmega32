.CSEG
.ORG 0x0000
rjmp start

; Прерывания кнопок.
.org INT0addr ;смена режима
rjmp EXT_INT0
.org INT1addr
rjmp EXT_INT1

;прерывание таймера
.org OVF0addr ;для вывода на 7индикатор
rjmp TIM0_OVF

.org OVF1addr
rjmp TIM1_OVF

.org $020; АЦП
rjmp ADC_C

.def step = r16 ;1
.def ba = r22 ;базовые значения
.def bb = r23
.def bc = r24
.def mode = r25 ;2 режима - работа/настройка
.def param = r27 ;3 параметра - b0, b1, b2
.def NumovfTim0 = r30
.def temp = r31

.macro seg
cpi R21, @0
brne @1
ldi R21, @2
jmp detf_exit
.endm

.macro outp
ldi temp, @1
out @0, temp
.endm

start:

ldi mode, LOW(RAMEND)
out SPL, mode
ldi mode, HIGH(RAMEND)
out SPH, mode

; Инициализация
ldi mode,0b01111110 ;pd7
out TCCR2, mode
ldi mode,0x00
out TCNT2, mode

ldi R16, 0b00101001
out TCCR1A, R16
ldi R16, 0b00101001
out TCCR1B, R16
outp OCR1AH, 0x00
outp OCR1AL, 0x00
;---------------------------------
ldi NumovfTim0, 0 ; счетчик
;-----------------------------

ldi ba, 0b00000001; По переполнению
out TCCR0, ba
ldi mode, 252
out OCR0, mode
ldi ba, 0b01000001; Разрешение прерываний
out TIMSK, ba
;-----------------------------
ldi ba, 14
ldi bb, 2
ldi bc, 0
ldi mode, 0
mov r10, mode
ldi mode, 0
mov r11, mode
mov r12, mode

ldi mode, 0b00001111
out MCUCR, mode
ldi mode, 0b11000000
out GICR, mode

LDI R16, 0b00100101
;LDI R16, 0b01100101
out ADMUX, R16 ; АЦП

ldi mode, 0 ;режим работы
ldi param, 0 ;первый параметр
ser r18
out DDRB, r18
out DDRC, r18
ldi r18, 0b11011111
out DDRA, r18
ldi r18, 0b10010000
out DDRD, r18
sei

main:

cpi mode, 0;выбор режима работы
breq workmode
rjmp settingmode
;====================================
workmode:
out PORTA, ba
out PORTB, bb
out PORTC, bc
mov r10, bb
;-----------------------------
call DELAY
;-------------------------------
;сдвиг светодиодов
bst bc, 7
mov r26, r22

lsl ba
bld ba, 0
bst r26, 7
mov r26, bb
lsl bb
bld bb, 0
bst r26, 7
lsl bc
bld bc, 0
rjmp main

;========================================
;НАСТРОЙКА
;========================================
settingmode:
cpi mode, 0
breq main ;выход, если не режим настройки (сменился)
;вывод на 2 первых индикатора имени параметра и точки (b0.)

cpi NumovfTim0, 64
brlo outfirst
cpi NumovfTim0, 128
brlo outsecond
cpi NumovfTim0, 192
brlo outthird
jmp outforth
JMP settingmode

outfirst:
ldi r28, 0b01111100 ;'b'
ldi r29, 0x8 ;first indicator
jmp output
;-----------------------------------------
outsecond:
ldi r29, 0x4 ;second indicator
cpi param, 0
breq zero
cpi param, 1
breq one
cpi param, 2
breq two

zero:
ldi r28, 0b10111111 ;'0'
jmp output

one:
ldi r28, 0b10000110 ;'1'
jmp output

two:
ldi r28, 0b11011011 ;'2'
jmp output
;----------------------------------------
outthird: ; Вывод на 3 индикатор.
cpi param, 0
breq zero1
cpi param, 1
breq one1
cpi param, 2
breq two1

zero1:
mov r20, ba
jmp end1

one1:
mov r20, bb
jmp end1

two1:
mov r20, bc
jmp end1

end1: nop
ldi R19, 0
call seg_ind
mov R28, R19
ldi R29, 0x2
jmp output
;---------------------------------------
outforth: ; Вывод на 4 индикатор.
cpi param, 0
breq zero2
cpi param, 1
breq one2
cpi param, 2
breq two2

zero2:
mov r20, ba
jmp end2

one2:
mov r20, bb
jmp end2

two2:
mov r20, bc
jmp end2

end2: nop
ldi R19, 0
rcall seg_ind
mov R28, R20
ldi R29, 0x1
jmp output

output:
out PORTC, R28
out PORTA, R29
call PWM
jmp settingmode
rjmp main
;=======================================
;ЧИСЛЕННОЕ ПРЕОБРАЗОВАНИЕ ДЛЯ 7СЕГМ ИНДИКАТОРА
;=======================================
seg_ind: ;r19-first r20-second изначально число хранится в r20, r19=0

mov r19, r20
lsr r19
lsr r19
lsr r19
lsr r19 ;r19 хранит старшие 4 бита

call perform
mov r10, r19
andi r20, 0b00001111 ;r20 хранит младшие 4 бита
mov r19, r20
call perform
mov r20, r19
mov r19, r10
endseg:
nop
ret

;===========================================
;СИМВОЛЬНЫЙ ЭКВИВАЛЕНТ
;===========================================
perform:
mov r21, r19
num0: seg 0x0, num1, 0b00111111
num1: seg 0x1, num2, 0b00000110
num2: seg 0x2, num3, 0b01011011
num3: seg 0x3, num4, 0b01001111
num4: seg 0x4, num5, 0b01100110
num5: seg 0x5, num6, 0b01101101
num6: seg 0x6, num7, 0b01111101
num7: seg 0x7, num8, 0b00000111
num8: seg 0x8, num9, 0b01111111
num9: seg 0x9, numA, 0b01101111
numA: seg 0xA, numB, 0b01110111
numB: seg 0xB, numC, 0b01111100
numC: seg 0xC, numD, 0b00111001
numD: seg 0xD, numE, 0b01011110
numE: seg 0xE, numF, 0b01111001
numF: seg 0xF, detf_exit, 0b01110001
detf_exit:
mov r19, r21
ret

;=======================================
;ПРЕРЫВАНИЯ
;========================================
EXT_INT0:;смена режима
cpi mode, 1
breq do1
rjmp else
do1: ;установлен режим настройки
ldi mode, 0
LDI R18, 0
out ADCSRA, R18 ; отключаем многоразовый АЦП
rjmp exit1
else: ;установлен режим работы-переключаем
ldi mode, 1
;LDI R18, 0b11101111
LDI R18, 0b11111111
out ADCSRA, R18 ; Включаем многоразовый АЦП
exit1: nop
reti
;---------------------------------------


EXT_INT1: ;смена парметра bo, b1, b2
cpi mode, 1;режим настройки
breq do2
reti
do2:
cpi param, 0
breq b1
cpi param, 1
breq b2
cpi param, 2
breq b0
b1: ldi param, 1
rjmp exit2
b2: ldi param, 2
rjmp exit2
b0: ldi param, 0
exit2:
reti
;=========================================

; Прерывание OVF0 - вывод на семисегментный индикатор
TIM0_OVF:
cpi mode, 1; Проверка, что мы находимся в режиме настройки.
brne tim2_exit
inc NumovfTim0
tim2_exit:
reti
;==========================================
ADC_C:
in temp, ADCH ;данные с АЦП в регистре ADCH
cpi param, 0 ;выбираем параметр на изменение
breq inc_ba
cpi param, 1
breq inc_bb
cpi param, 2
breq inc_bc
inc_ba:
mov ba, temp
rjmp ret_int
inc_bb:
mov bb, temp
rjmp ret_int
inc_bc:
mov bc, temp
rjmp ret_int
ret_int:
reti
;==========================================
PWM:
ldi R17, 0
out OCR1BH, R17
cpi param, 0 ;выбираем параметр на изменение
breq pwm_ba
cpi param, 1
breq pwm_bb
cpi param, 2
breq pwm_bc
pwm_ba:
out OCR1BL, ba
out ocr2, ba
rjmp pwm_end
pwm_bb:
out OCR1BL, bb
out ocr2, bb
rjmp pwm_end
pwm_bc:
out OCR1BL, bc
out ocr2, bc
rjmp pwm_end
pwm_end:
nop
ret

DELAY:
; Delay 3 200 000 cycles
; 400ms at 8.0 MHz
ldi r19, 17
mov r1, r19
ldi r20, 60
mov r2, r20
ldi r21, 204
mov r3, r21
L1: dec r3
brne L1
dec r2
brne L1
dec r1
brne L1
RET
