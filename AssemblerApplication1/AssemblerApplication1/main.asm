//*******************************************************************************************************************************************************
// Universidad del Valle de Guatemala
// IE2023: Programación de Microcontroladores
// Autor: Juan Fer Maldonado 
// Contador de 4 bits con interrupciones de PIN.asm
// Descripción: PreLab 3, posee código para crear interrupiones de un contador de 4 bits.
// Hardware: ATMega328P
// Created: 10/02/2024 16:43:34
//*******************************************************************************************************************************************************
// Encabezado
//*******************************************************************************************************************************************************
.include "M328PDEF.inc"
.cseg
.org 0x00
	JMP Main
.org 0x0008
	JMP Int_PCMSK1
.org 0x0020
	JMP Time_overflow

Main:
//*******************************************************************************************************************************************************
// Configuración de la Pila
//*******************************************************************************************************************************************************
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17
//*******************************************************************************************************************************************************
// Configuración de MCU
//*******************************************************************************************************************************************************
SETUP:
	// Configuracion de reloj.
	LDI R19, 0      ; Contador del display de unidades de segundo (primer display)
	LDI R20, 0      ; Contador del display de decenas de segundo (segundo display)
	LDI R28, 0      ; Bandera para control del PB1 - sumar
	LDI R29, 0      ; Bandera para control del PB2 - restar
	D7Segmentos1: .DB 0b1000000, 0b1111001, 0b0100100, 0b0110000, 0b0011001, 0b0010010, 0b0000010, 0b1111000, 0b0000000, 0b0010000
	LDI R31,  (1 << CLKPCE)
	STS CLKPR, R31
	LDI R31, 0b0000_0100
	STS CLKPR, R31
	CALL Init_T0         ; Configuro el timer 0 a 1024 prescaler.
	//Configuracion de los I/O Ports
	//DDRB SOLO LO USAMOS PARA DECIRLE QUE ES SALIDA O ENTRADA.
	//         76543210
	LDI R26, 0
	LDI	R16, 0b00011111   ; Estoy asignando que los puertos PB del 5-0 son Salidas
	OUT	DDRB, R16
	LDI	R16, 0b11111111   ; Estoy asignando que los puertos PD de 7-0 son salidas.
	OUT	DDRD, R16
	LDI	R16, 0b00001100//0b00000000   ; Estoy asignando que los puertos PC de 3-2 son entradas.
	OUT	DDRC, R16
	LDI R17, 0b00000011  //0b00011111  ; Activo que los botones serán pullup, debido a que los pushbutton están conectados de PC1 - PC0
	OUT PORTC, R17
	LDI R18, 0            ; Inicializo mi contador para los leds.
	LDI R16, 0x00         ; Reinicio que los puertos RX y TX los manejaré yo.
	STS UCSR0B, R16

	CLR R16
	LDI R16, 0b00000010   ; Utilizo el registro de memoria para poder habilitar el registro de control de PCICR
	STS PCICR, R16        ; Escribo que la interrupción del pin vendrá de C.
	CLR R16
	LDI R16, 0b00000011   ; Establezco el registro de manera que pueda indicar el cambio del pin en PINC0 Y PINC1, donde están los PB.
	STS PCMSK1, R16       ; Indico que los pines están encendidos, entonces registrarán un cambio en el pin.
	//LDI R16, 99
	LDI R16, (1 << TOIE0)
	STS TIMSK0, R16      

	SEI                   ; Habilito las interrupciones globales.
	//LDI R16, 0

//*******************************************************************************************************************************************************
// Loop infinito
//*******************************************************************************************************************************************************
LOOP:
	//OUT PORTD, R16
	MOV R22, R20
	LDI ZH, HIGH(D7Segmentos1 << 1)  ; Defino donde termina el segmento de datos 1.
	LDI ZL, LOW(D7Segmentos1 << 1)   ; Defino donde inicia el segmento de datos 1.
	ADD ZL, R22                      ; Me desplazo R16 cantidades en el segmento de datos 1.
	LPM R23, Z                       ; Leo el dato en la posición Z del segmento de datos 1.

	LDI R24, 0b00001011              ; Apaga el bit del contador de unidades de segundos (primer display)
	OUT PORTC, R24

	OUT PORTD, R23

	MOV R16, R19		             ; Muevo el valor del display.
	LDI ZH, HIGH(D7Segmentos1 << 1)  ; Defino donde termina el segmento de datos 1.
	LDI ZL, LOW(D7Segmentos1 << 1)   ; Defino donde inicia el segmento de datos 1.
	ADD ZL, R16                      ; Me desplazo R16 cantidades en el segmento de datos 1.
	LPM R27, Z                       ; Leo el dato en la posición Z del segmento de datos 1.

	LDI R24, 0b00000111              ; Apaga el bit del contador de decenas de segundos (segundo display)
	OUT PORTC, R24

	OUT PORTD, R27  
	RJMP LOOP

//*******************************************************************************************************************************************************
// Subfunciones
//*******************************************************************************************************************************************************
Init_T0:
	LDI R16, 0                             ; Obtenido del video.
	OUT TCCR0A, R16                        ; Esto según la Datasheet en 15.9.1, trabaja en modo normal.
	LDI R16, (1 << CS02) | (1 << CS00)     ; Configuramos el prescaler según 15.9.2,  
	OUT TCCR0B, R16
	LDI R16, 100
	OUT TCNT0, R16
	RET
//*******************************************************************************************************************************************************
// Funciones de interrupción
//*******************************************************************************************************************************************************
Int_PCMSK1:
	//PUSH R19     ; Guardo el registro R16 en la pila
	IN R16, SREG ; Cargo el registro SREG a la posición R16.
	PUSH R16     ; Guardo el SREG en la pila.

	IN R21, PINC         ; Leo el PINC completo para evaluar si esta oprimido el boton o no PIN es para leer lo que hay en un puerto.
	SBRC R21, 0 //1		 ; Revisa si el bit 0 tiene 0 y salta omitiendo la siguiente instruccion si esta asi.
	LDI R28, 1           ; Asigno que mi bandera estará en 1.
	IN R21, PINC         ; Leo el PINC completo para evaluar si esta oprimido el boton o no PIN es para leer lo que hay en un puerto.
	SBRS R21, 0 //1		 ; Revisa si el bit 0 tiene 0 y salta omitiendo la siguiente instruccion si esta asi.
    RJMP Incrementa        
	RJMP Seguirdecrementa
Incrementa:
    CPI R28, 1           ; Si mi bandera esta encendida, entonces incremento mi contador con el PB1.
	BRNE Seguirdecrementa
	INC R18              ; Incremento mi contador de la lista de los leds.
	LDI R28, 0           ; Apago la bandera.
Seguirdecrementa:
	IN R21, PINC
	SBRC R21, 1          ; SI el PB2 esta en 0, entonces salto la instrucción de asignar la bandera  de R29 en 1.
	LDI R29, 1           ; Asigno la bandera en 1.
	IN R21, PINC         ; Leo el PINC completo para evaluar si esta oprimido el boton o no PIN es para leer lo que hay en un puerto.
	SBRS R21, 1 //1		 ; Revisa si el bit 0 tiene 0 y salta omitiendo la siguiente instruccion si esta asi.
    RJMP Decrementa
	RJMP Seguirmuestraled
Decrementa:
	CPI R29, 1           ; Comparo si la bandera esta encendida, si es asi, decrementa el contador de leds.
	BRNE Seguirmuestraled
	DEC R18              ; Decremento el contador de los leds.
    LDI R29, 0           ; Apago mi bandera.
Seguirmuestraled:
	OUT PORTB, R18       ; Muestro el contador en los leds.
	POP R16              ; Cargo el valor del SREG a R16 y luego lo asigno a SREG.
	OUT SREG, R16        
	RETI
Time_overflow:
	IN R16, SREG ; Cargo el registro SREG a la posición R16.
	PUSH R16     ; Guardo el SREG en la pila.

	SBI TIFR0, TOV0
	INC R26      ; Incremento un contador que me pondrá el tiempo que pase en m.
	CPI R26, 70  ; Entrará aproximadamente 70 veces y eso me dará un segundo y milésimas
	BRNE salir_int_timer  ; Si no completó las 70 vueltas, solo carga la bandera de SREG
	CLR R26       ; Limpio la posición R26.
	INC R19       ; incremento el contador de desplazamiento para el display de 7 segmentos de segundos
	CPI R19, 10   ; Si este ya cumplió con llegar a los 10 segundos, se reinicia.
	BRNE salir_int_timer ; Sale a cargar el SREG.
	LDI R19, 0    ; Si se cumplieron los 10 segundos, reincia el contador de segundos.
	INC R20       ; Incrementa el contador de décimas de segundo.
	CPI R20, 10   ; Si este llega a diez, reinicia el contador de décimas de segundo y el de unidades de segundo.
	BRNE salir_int_timer   ; Si no, continua normal.
	LDI R19, 0    ; Asigno mi contador de segundos en 0.
	LDI R20, 0    ; Asigno mi contador de decenas de segundo en 0. 

salir_int_timer:
	POP R16       ; Cargo las banderas del SREG al registro R16.
	OUT SREG, R16
	RETI


