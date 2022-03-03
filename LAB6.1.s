
;Archivo: Prelab6.s
;Dispositivo: PIC16F887
;Autor: Jimena de la Rosa
;Compilador: pic-as (v2.30). MPLABX v5.40
;Programa: Prelab 6
;Hardware: LEDs en el puerto A y led intermitente en el PORTB
;Creado: 27 FEB, 2022
;Ultima modificacion: 03 MAR, 2022
    
PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT UDATA_BANK0,global,class=RAM,space=1,delta=1,noexec
  
  GLOBAL  SEGUNDOS, CONT, CONTU, CONTD, DISPLAY
    SEGUNDOS: DS 1 ;SE NOMBRA UNA VARIABLE DE CONTADOR DE 4 BITS
    CONT:     DS 1  
    CONTU:    DS 1
    CONTD:    DS 1
    DISPLAY:  DS 2
    BANDERAS: DS 1


; -------------- MACROS --------------- 
; Macro para reiniciar el valor del TMR0
; Recibe el valor a configurar en TMR_VAR
RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM
    
; Macro para reiniciar el valor del TMR1
; Recibe el valor a configurar en TMR1_H y TMR1_L
RESET_TMR1 MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H	    ; Literal a guardar en TMR1H
    MOVWF   TMR1H	    ; Guardamos literal en TMR1H
    MOVLW   TMR1_L	    ; Literal a guardar en TMR1L
    MOVWF   TMR1L	    ; Guardamos literal en TMR1L
    BCF	    TMR1IF	    ; Limpiamos bandera de int. TMR1
    ENDM
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1

PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN	; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   T0IF	    ; Interrupcion de TMR0?
    CALL    INT_TMR0
    BTFSC   TMR1IF	    ; Interrupcion de TMR1?
    CALL    INT_TMR1
    BTFSC   TMR2IF	    ; Interrupcion de TMR2?
    CALL    INT_TMR2
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
  
; ------ SUBRUTINAS DE INTERRUPCIONES ------
INT_TMR0:
    RESET_TMR0 252	    ; Reiniciamos TMR0 para 2ms
    CALL    MOSTRAR_VALOR	; Mostramos valor en hexadecimal en los displays
    RETURN
    
INT_TMR1:
    RESET_TMR1 0x0B, 0xCD   ; Reiniciamos TMR1 para 1000ms
    INCF    SEGUNDOS	    ; Incremento en la variable segundos
    MOVF    SEGUNDOS, W
    MOVWF   PORTA	    ;se muestra la variable en el puerto 
    CALL    UNIDADES
    CALL    REINICIAR
    RETURN
    
INT_TMR2:
    BCF	    TMR2IF	    ; Limpiamos bandera de interrupcion de TMR1
    DECFSZ  CONT, 1
    RETURN
    
    MOVLW   10   ;SE DEJA EN 10 EL CONTADOR
    MOVWF   CONT
    BTFSC   PORTB, 0
    GOTO    APAGAR
    GOTO    ENCENDER; LED intermitente en PORTB
    
    APAGAR:	;SE APAGA EL LED
    BCF PORTB,0
    RETURN
    
    ENCENDER:   ;SE ENCIENDE EL LED
    BSF PORTB,0
    RETURN
    
UNIDADES:
    INCF CONTU  ;SE INCREMENTA EL CONTADOR DE UNIDADES
    MOVF CONTU, W; se mueve el valor del contador a W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
    GOTO DECENAS ;SE DIRIJE A DECENAS
    
DECENAS:   
    CLRF   CONTU ;SE LIMPIA EL CONTADOR DE UNIDADES
    INCF CONTD	    ;SE INCREMENTA EL CONTADOR DE DECENAS
    MOVF CONTD, W; se mueve el valor del contador a W
    SUBLW 6; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
    CLRF   CONTD ;SE LIMPIA EL CONTADOR DE DECENAS
    RETURN
    
 REINICIAR:
    MOVF SEGUNDOS, W; se mueve el valor del contador a W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
    MOVLW   0; se dejan los conatdores en cero
    MOVWF   CONTU
    MOVWF   CONTD
    RETURN
    
    

PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
;------------- CONFIGURACION ------------
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR0	    ; Configuración de TMR0
    CALL    CONFIG_TMR1	    ; Configuración de TMR1
    CALL    CONFIG_TMR2	    ; Configuración de TMR2
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    CALL    SET_DISPLAY		; Guardamos los valores a enviar en PORTC para mostrar valor en he
    GOTO    LOOP	    
    
;------------- SUBRUTINAS ---------------
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 01
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BCF	    OSCCON, 4	    ; IRCF<2:0> -> 100 1MHz
    RETURN
    
; Configuramos el TMR0 para obtener un retardo de 2ms
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BCF	    PS0		    ; PS<2:0> -> 110 prescaler 1 : 128
    
    BANKSEL TMR0	    ; Cambiamos a banco 00
    MOVLW   252
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN 
    
CONFIG_TMR1:
    BANKSEL T1CON	    ; Cambiamos a banco 00
    BCF	    TMR1GE	    ; TMR1 siempre cuenta
    BSF	    T1CKPS1	    ; prescaler 1:4
    BCF	    T1CKPS0
    BCF	    T1OSCEN	    ; LP deshabilitado
    BCF	    TMR1CS	    ; Reloj interno
    BSF	    TMR1ON	    ; Prendemos TMR1
    
    RESET_TMR1 0x0B, 0xCD   ; Reiniciamos TMR1 para 1s
    RETURN
    
CONFIG_TMR2:
    BANKSEL PR2		    ; Cambiamos a banco 01
    MOVLW   49		    ; Valor para interrupciones cada 50ms
    MOVWF   PR2		    ; Cargamos litaral a PR2
    
    BANKSEL T2CON	    ; Cambiamos a banco 00
    BSF	    T2CKPS1	    ; prescaler 1:16
    BSF	    T2CKPS0
    
    BSF	    TOUTPS3	    ; postscaler 1:16
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    
    BSF	    TMR2ON	    ; prendemos TMR2
    RETURN
    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	    ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISC	    ; PORTD como salida
    CLRF    TRISA	    ; PORTA como salida
    BCF     TRISB,0	    ; PORTB como salida
    BCF     TRISD,0         ; PORTB como salida
    BCF     TRISD,1
    BANKSEL PORTD
    CLRF    PORTB	    ; Apagamos PORTB
    CLRF    PORTA	    ; Apagamos PORTA
    CLRF    PORTC	    ; Apagamos PORTC
    CLRF    SEGUNDOS        ;SE LIMPIA LA VARIABLE
    MOVLW   10		    ;SE DEJA EN 10 EL CONTADOR
    MOVWF   CONT
    CLRF    BANDERAS       ;SE LIMPIA LA VARIABLE
    CLRF    CONTU          ;SE LIMPIA LA VARIABLE
    CLRF    CONTD          ;SE LIMPIA LA VARIABLE
    CLRF    DISPLAY        ;SE LIMPIA LA VARIABLE
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1	    ; Cambiamos a banco 01
    BSF	    TMR1IE	    ; Habilitamos interrupciones de TMR1
    BSF	    TMR2IE	    ; Habilitamos interrupciones de TMR2
    
    BANKSEL INTCON	    ; Cambiamos a banco 00
    BSF	    PEIE	    ; Habilitamos interrupciones de perifericos
    BSF	    GIE		    ; Habilitamos interrupciones
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    BCF	    TMR1IF	    ; Limpiamos bandera de TMR1
    BCF	    TMR2IF	    ; Limpiamos bandera de TMR2
    RETURN
 
SET_DISPLAY:
    MOVF    CONTD, W		; Movemos nibble bajo a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY		; Guardamos en display
    
    MOVF    CONTU, W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+1		; Guardamos en display+1
    RETURN

MOSTRAR_VALOR:
    BCF	    PORTD, 0		; Apagamos display de nibble alto
    BCF	    PORTD, 1		; Apagamos display de nibble bajo
    BTFSC   BANDERAS, 0		; Verificamos bandera
    GOTO    DISPLAY_1		;  

    DISPLAY_0:			
	MOVF    DISPLAY, W	; Movemos display a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 1	; Encendemos display de nibble bajo
	BSF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
    RETURN
    DISPLAY_1:
	MOVF    DISPLAY+1, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 0	; Encendemos display de nibble bajo
	BCF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
    RETURN

ORG 200H
TABLA:
    CLRF PCLATH
    BSF  PCLATH, 1
    ANDLW 0X0F; SE ASEGURA QUE SOLO EXISTAN 4 BITS
    ADDWF PCL
    RETLW 10111111B; 01000000B 0
    RETLW 10000110B;01111001B 1
    RETLW 11011011B; 00100100B;2
    RETLW 11001111B ;00110000B;3
    RETLW 11100110B ;00011001B;4
    RETLW 11101101B ;00010010B;5
    RETLW 11111101B ;00000010B;6
    RETLW 10000111B ;01111000B;7
    RETLW 11111111B ;00000000B;8
    RETLW 11101111B ;00010000B;9
    RETLW 11110111B ;00001000B;A
    RETLW 11111100B ;00000011B;B
    RETLW 10111001B ;01000110B;C
    RETLW 11011110B ;00100001B;D
    RETLW 11111001B ;00000110B;E
    RETLW 11110001B ;00001110B;F
    
END

    
