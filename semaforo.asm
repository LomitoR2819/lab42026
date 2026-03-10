.data
    # Mensajes para los estados del semáforo
    msg_verde:          .asciiz "Semáforo en verde esperando pulsador\n"
    msg_verde_pulsado:  .asciiz "Pulsador activado. En 20 segundos el semáforo cambiará a amarillo\n"
    msg_amarillo:       .asciiz "Semáforo en amarillo. En 10 segundos el semáforo cambiará a rojo\n"
    msg_rojo:           .asciiz "Semáforo en rojo. En 30 segundos el semáforo cambiará a verde\n"
    espacio: 		.asciiz "\n"
    
    # Mensaje para solicitar entrada
    prompt:             .asciiz "Presione 's' para cambiar de estado (o cualquier otra tecla para salir): "
    
    # Variables de tiempo (en segundos)
    tiempo_verde:       .word 20
    tiempo_amarillo:    .word 10
    tiempo_rojo:        .word 30
    
    # Caracter de entrada
    input_char:         .space 2

.text
.globl main

main:
    # Estado inicial: verde
    li $s0, 0           # $s0 = estado (0:verde, 1:amarillo, 2:rojo)
    li $s1, 0           # $s1 = pulsador activado (0:no, 1:si)

loop_principal:
    # Mostrar mensaje según el estado
    beq $s0, 0, estado_verde
    beq $s0, 1, estado_amarillo
    beq $s0, 2, estado_rojo
    
estado_verde:
    # Mostrar mensaje de estado verde
    la $a0, msg_verde
    li $v0, 4
    syscall
    
    # Verificar si ya se pulsó el interruptor
    beq $s1, 1, esperar_verde
    
    # Solicitar entrada del usuario
    la $a0, prompt
    li $v0, 4
    syscall
    
    # Leer caracter
    li $v0, 12
    syscall
    sb $v0, input_char
    
    # Verificar si se presionó 's'
    lb $t0, input_char
    li $t1, 's'
    bne $t0, $t1, salir
    
    # Activar pulsador
    li $s1, 1
    
    # Mostrar mensaje de cambio programado
    la $a0, espacio
    li $v0, 4
    syscall
    la $a0, msg_verde_pulsado
    li $v0, 4
    syscall
    
esperar_verde:
    # Esperar 20 segundos (simulado con un bucle)
    lw $a0, tiempo_verde
    jal simular_tiempo
    
    # Cambiar a amarillo
    li $s0, 1
    li $s1, 0
    j loop_principal

estado_amarillo:
    # Mostrar mensaje de estado amarillo
    la $a0, msg_amarillo
    li $v0, 4
    syscall
    
    # Esperar 10 segundos
    lw $a0, tiempo_amarillo
    jal simular_tiempo
    
    # Cambiar a rojo
    li $s0, 2
    j loop_principal

estado_rojo:
    # Mostrar mensaje de estado rojo
    la $a0, msg_rojo
    li $v0, 4
    syscall
    
    # Esperar 30 segundos
    lw $a0, tiempo_rojo
    jal simular_tiempo
    
    # Cambiar a verde
    li $s0, 0
    j loop_principal

# Función para simular el paso del tiempo
simular_tiempo:
    # $a0 contiene los segundos a esperar
    li $v0, 32          # Servicio de espera (sleep)
    mul $a0, $a0, 1000  # Convertir segundos a milisegundos
    syscall
    jr $ra

salir:
    # Terminar el programa
    li $v0, 10
    syscall