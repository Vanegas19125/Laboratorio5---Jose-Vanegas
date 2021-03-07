;-------------------------------------------------------------------------------
    ;Archivo:	  main.s
    ;Dispositivo: PIC16F887
    ;Autor: José Vanegas
    ;Compilador: pic-as (v2.30), MPLABX V5.45
    ;
    ;Programa: Contador 8 Bits y Multiples Displays
    ;Hardware: Display 7 Seg, Push Buttom, Leds, Resistencias. 
    ;
    ;Creado: 02 mar, 2021
    ;Última modificación: 02 mar, 2021    
;-------------------------------------------------------------------------------

    PROCESSOR 16F887
    #include <xc.inc>
    
    
    CONFIG FOSC=INTRC_NOCLKOUT //Oscillador interno
    CONFIG WDTE=OFF	//WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=OFF	//PWRT enabled (espera de 72ms al iniciar)
    CONFIG MCLRE=OFF	//El pin de MCLR se utiliza como I/O
    CONFIG CP=OFF	//Sin proteccion de codigo
    CONFIG CPD=OFF	//Sin proteccion de datos

    CONFIG BOREN=OFF	//Sin reinicio cuando el voltaje de alimentacion baja 4v
    CONFIG IESO=OFF	//Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF	//Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=OFF	//programacion en bajo voltaje permitida
    
    CONFIG WRT=OFF	//Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V //Reinicio abajo de 4V, (BOR21v=2.1v)
    
   PSECT udata_shr ;common memory
	WTEMP: DS 1
	STATUS_TEMP: DS 1
	CONT_D1: DS 1
	CONT_D2: DS 1
	PORTB_ACTUAL: DS 1
	PORTB_ANTERIOR: DS 1
	DECENA: DS 1
	CENTENA: DS 1
	UNIDAD: DS 1
	VALPORTA: DS 1
 
 PSECT resVect, class=CODE, abs, delta=2
 ORG 0x00
 GOTO CONFIG_PROG
 
 ORG 0X04
 
 PUSH:
    MOVWF WTEMP
    SWAPF STATUS, W
    MOVWF STATUS_TEMP
    
    BTFSC INTCON, 2 ;VERFICAR OVERFLOW TIMER 0
    CALL ISRTMR0
    BTFSC INTCON, 0
    CALL ISR_CONTADOR
    
 POP:
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF WTEMP, F
    SWAPF WTEMP, W
    
    RETFIE
 
 TABLA7SEG: ;Tabla para pasar de binario a valor numerico en el display
       
    addwf PCL, F
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01100111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
 
 ISRTMR0:
    BCF INTCON, 2
    MOVLW 246
    MOVWF TMR0
    INCF CONT_D1, F
    INCF CONT_D2, F
    
    
    BCF PORTB, 2
    BCF PORTB, 3
    MOVF CONT_D1, W
    ADDWF PCL, F
    GOTO DISPLAY1
    GOTO DISPLAY2
 ;Subrutina para colocar el valor binario en hexadecimal en el primer display    
 DISPLAY1:
    MOVF PORTA, W
    ANDLW 00001111B
    CALL TABLA7SEG
    MOVWF PORTC
    BSF PORTB, 3
    GOTO SALIR
 ;Subrutina para colocar el valor binario en hexadecimal en el segundo display
 DISPLAY2:
    SWAPF PORTA, W
    ANDLW 00001111B
    CALL TABLA7SEG
    MOVWF PORTC
    BSF PORTB, 2
    MOVLW 255
    MOVWF CONT_D1
 ;subrutina para mostrar el valor decimal en los otros displays   
 SALIR: 
    BCF PORTB, 4
    BCF PORTB, 5
    BCF PORTB, 6
    MOVF CONT_D2, W
    ADDWF PCL, F
    GOTO DISPLAY3
    GOTO DISPLAY4
    GOTO DISPLAY5
 ;Subrutina para colocar el valor binario en unidad en el terecer display
 DISPLAY3:
    MOVF UNIDAD, W
    CALL TABLA7SEG
    MOVWF PORTD
    BSF PORTB, 6
    RETURN
 ;Subrutina para colocar el valor binario en decena en el segundo display
 DISPLAY4:
    MOVF DECENA, W
    CALL TABLA7SEG
    MOVWF PORTD
    BSF PORTB, 5
    RETURN
 ;Subrutina para colocar el valor binario en centena en el primer display
 DISPLAY5:
    MOVF CENTENA, W
    CALL TABLA7SEG
    MOVWF PORTD
    BSF PORTB, 4
    MOVLW 255
    MOVWF CONT_D2
    RETURN
     
 ISR_CONTADOR: ;Subrutina para el contador binario
    BCF INTCON, 0
    
    MOVF PORTB_ACTUAL,W
    MOVWF PORTB_ANTERIOR
    MOVF PORTB, W
    MOVWF PORTB_ACTUAL
    
    BTFSC PORTB_ANTERIOR, 0
    GOTO VERIFICAR
    BTFSC PORTB_ACTUAL, 0
    INCF PORTA, F
    
    
 VERIFICAR:
    BTFSC PORTB_ANTERIOR, 1
    RETURN
    BTFSC PORTB_ACTUAL, 1
    DECF PORTA, F
    RETURN
       
 CONFIG_PROG: ;Configuracion de los bits
    
    BSF STATUS, 5
    BSF STATUS, 6 ;Banco 3
    
    CLRF ANSEL
    CLRF ANSELH
    
    BSF STATUS, 5 ;Banco 1
    BCF STATUS, 6 ;Banco 1
    
    CLRF TRISA
    CLRF TRISC
    CLRF TRISD
    CLRF TRISB ;Puerto A,B,C,D como salidas
    
    BSF TRISB, 0
    BSF TRISB, 1 ;Bit 0 y 1 del puerto B como entrada
    
    BCF OPTION_REG, 7 ;Pull ups puerto B
    BCF OPTION_REG, 5 ;Clok interno
    BCF OPTION_REG, 3 ;Prescaler
    BSF OPTION_REG, 2 ;Prescaler a 256
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0
    
    BSF INTCON, 7 ;INTERRUPCION GLOBAL
    BSF INTCON, 5 ;INTERRUPCION TIMER0
    BSF INTCON, 3 ;INTERRUPCION DEL PUERTO B
    
    BSF IOCB, 0
    BSF IOCB, 1 ;ACTIVAR INTERRUPCION EN PIN RB0 Y RB1
    
    BCF STATUS, 5
    
    CLRF PORTA ;COLOCAR EN 0 puerto D
    CLRF PORTB ;COLOCAR EN 0 puerto D
    CLRF PORTC ;COLOCAR EN 0 puerto D
    CLRF PORTD ;COLOCAR EN 0 puerto D
    CLRF CONT_D1
    CLRF CONT_D2
    MOVLW 246 ;ASGINAMOS VALOR AL TIMER0
    MOVWF TMR0 ;MOVEMOS LA LITERAL AL TMR0, INTERRUPCION CADA 2.5 ms

    
LOOP:
    MOVF PORTA, W ;movemos el valor del puerto A a W
    MOVWF VALPORTA ;Movemos W a la variable VALPORTA
    CALL BINDEC ; Llamamos a la sub rutina que pasa de binario a decimal
    GOTO LOOP

;subrutina para pasar de binario a decimal   
BINDEC:
    BCF INTCON, 7
    CLRF CENTENA
    CLRF DECENA
    CLRF UNIDAD
    RESTCENT:
    MOVLW 100
    SUBWF VALPORTA, W
    BTFSS STATUS, 0
    GOTO RESTDEC
    MOVWF VALPORTA
    INCF CENTENA, F
    GOTO RESTCENT
    RESTDEC:
    MOVLW 10
    SUBWF VALPORTA, W
    BTFSS STATUS, 0
    GOTO RESTUNI
    MOVWF VALPORTA
    INCF DECENA, F
    GOTO RESTDEC
    RESTUNI:
    MOVF VALPORTA, W
    MOVWF UNIDAD
    BSF INTCON, 7
    RETURN
    
    
    
    
    


    

    
    
    
    
    
    
    