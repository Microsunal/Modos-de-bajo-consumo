;********************************************************************************************
;* Title: Ejemplo Modo wait
;********************************************************************************************
;* Author:  Johan Herrera, Iván Peñaranda - Universidad Nacional de Colombia
;*
;* Description: Ejemplo publicado para entender la interrupción por KBI
;*
;* Documentation: MC9S08QG8 family Data Sheet for register and bit explanations
;* HCS08 Family Reference Manual (HCS08RM1/D) for Instruction Set
;*
;* Include Files: none
;*
;* Assembler: Metrowerks Code Warrior 11.0.1
;*
;* Revision History:
;* Rev # Date Who Comments
;* ----- ----------- ------ --------------------------------------------
;* 1.0 15-May-19 Implementación inicial
;********************************************************************************************

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            

; export symbols
            XDEF _Startup, main, KBI_ISR
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on
            
            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack


; variable/data section
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definition

; code section
MyCode:     SECTION
main:
_Startup:
            LDHX   #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
            CLI         ; enable interrupts
            jsr   config

;-------------Rutina principal------------
mainLoop:
            NOP
            bset  3,PTBD      ;Vuelve uno el bit 3 del PTBD
            jsr   retardo     ;Retardo de 1 seg
            bclr  3,PTBD      ;Vuelve cero el bit 3 del PTBD
            jsr   retardo     ;Retardo de 1 seg
            BRA    mainLoop   ;Va a la etiqueta mainLoop

;--------------Configuración-------------
config:     lda   #%00000011
            sta   SOPT1       ;Se deshabilita el COP
            jsr   KBI_Config  ;Salta a la configuración del KBI
            mov   #$00,PTBD   ;Hace 0 los valores en los pines del puerto B
            mov   #%00011000,PTBDD ;Configura los pines 3 y 4 como salida
            rts
KBI_Config: bclr    KBISC_KBIE,KBISC ;Deshabilita KBI para evitar falsas interrupciones
            mov     #$00, KBISC      ;Se hace cero el registro de KBI para configurarlo limpiamente
            lda     #$03
            sta     PTAPE            ;Habilita resistencia pull-up en pin KBI 0
            mov     #$03,KBIPE       ;Habilita el pin KBI 0 para operar con la interrupción
            bset    KBISC_KBIE,KBISC  ;Habilita la interrupción KBI 
            bset    KBISC_KBACK,KBISC ;Limpia la badera de KBI evita anteriores int.
            rts            
;---------------Subrutinas---------------
debounce:   lda   #$ff        ;Carga el acumulador con el valor ff hex
db1:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$ff        ;Carga el acumulador con el valor ff hex
db2:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$01        ;Carga el acumulador con el valor 01 hex
db3:        dbnza db3         ;Resta el de a 1 al acumulador y va a 'rt3' hasta que sea 0, cuando continúa
            pula              ;Extrae el valor de la pila al acumulador
            dbnza db2         ;Resta el de a 1 al acumulador y va a 'rt2' hasta que sea 0, cuando continúa
            pula              ;Extrae el valor de la pila al acumulador
            dbnza db1         ;Resta el de a 1 al acumulador y va a 'rt1' hasta que sea 0, cuando continúa
            rts               ;Regresa al lugar de llamado del lable 'debounce'
            
retardo:    lda   #$ff        ;Carga el acumulador con el valor ff hex
rt1:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$ff        ;Carga el acumulador con el valor ff hex
rt2:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$0f        ;Carga el acumulador con el valor 0f hex
rt3:        dbnza rt3         ;Resta el de a 1 al acumulador y va a 'rt3' hasta que sea 0, cuando continúa
            pula              ;Extrae el valor de la pila al acumulador
            dbnza rt2         ;Resta el de a 1 al acumulador y va a 'rt2' hasta que sea 0, cuando continúa
            pula              ;Extrae el valor de la pila al acumulador
            dbnza rt1         ;Resta el de a 1 al acumulador y va a 'rt1' hasta que sea 0, cuando continúa
            rts               ;Regresa al lugar de llamado del lable 'retardo'
;--------------Interrupciones--------------------
   
KBI_ISR:    pshh
            jsr   debounce
            bset  KBISC_KBACK,KBISC ;Limpia la badera de KBI evita anteriores int.
            lda   PTAD 
            cbeqa #%00000001,wButton
            cbeqa #%00000010,uButton
wButton:    bclr  3,PTBD      ;Vuelve cero el bit 3 del PTBD
            bset  4,PTBD      ;Vuelve uno el bit 1 del PTBD
            wait
            jmp   finKBI
uButton:    bclr  4,PTBD      ;Vuelve cero el bit 4 del PTBD
            jmp   finKBI   
finKBI:     pulh
            rti               ;Regresa a la rutina principal
