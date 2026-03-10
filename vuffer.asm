##############################################################################
# PROGRAMA: BUFFER CIRCULAR CON FILTRO DE CARACTERES
# Funcionamiento: Durante 20 segundos, almacena solo letras mayúsculas (A-Z)
# en un buffer circular. Luego imprime el contenido y reinicia el ciclo.
# Utiliza el simulador de teclado de MARS (MMIO)
##############################################################################

.data
# Constantes
BUFFER_SIZE:   .word 256                # Tamaño del buffer circular
CICLO_TIEMPO:  .word 20000              # 20 segundos en milisegundos
POLL_DELAY:    .word 10                  # Delay entre lecturas (ms)

# Control de tiempo (simulado con contador)
tiempo_actual: .word 0                    # Contador de tiempo transcurrido
tiempo_objetivo: .word 20000              # Tiempo objetivo (20 segundos)

# Buffer circular
buffer:        .space 256                # Espacio para 256 caracteres
buffer_in:     .word 0                    # Índice de escritura
buffer_out:    .word 0                    # Índice de lectura
buffer_count:  .word 0                    # Número de elementos en buffer

# Mensajes
msg_inicio:    .asciiz "\n=== NUEVO CICLO DE 20 SEGUNDOS ===\n"
msg_instrucciones: .asciiz "Introduce letras mayúsculas (A-Z). Otros caracteres se descartan.\n"
msg_fin_ciclo: .asciiz "\n=== FIN DEL CICLO - CONTENIDO DEL BUFFER ===\n"
msg_contador:  .asciiz "Caracteres almacenados: "
msg_caracteres: .asciiz "\nCaracteres: "
msg_espacio:   .asciiz " "
msg_newline:   .asciiz "\n"
msg_buffer_vacio: .asciiz "[BUFFER VACIO - No se almacenaron mayusculas]\n"
msg_tecla_aceptada: .asciiz " [ACEPTADA] "
msg_tecla_rechazada: .asciiz " [RECHZADA] "
msg_tiempo:    .asciiz "Tiempo restante: "
msg_segundos:  .asciiz " segundos\n"
msg_sep:       .asciiz "----------------------------------------\n"
msg_continuar: .asciiz "\nPresiona Enter para continuar...\n"
msg_car_ascii: .asciiz "Caracter: "
msg_ascii_valor: .asciiz " (ASCII: "

# Para entrada/salida en MARS
controlador_teclado: .word 0xffff0000
datos_teclado:      .word 0xffff0004

.text
.globl main

##############################################################################
# PROGRAMA PRINCIPAL
##############################################################################
main:
    # Mostrar mensaje de inicio
    li $v0, 4
    la $a0, msg_inicio
    syscall
    
    li $v0, 4
    la $a0, msg_instrucciones
    syscall

ciclo_principal:
    # Inicializar nuevo ciclo
    jal inicializar_ciclo
    
    # Bucle de entrada de caracteres (20 segundos)
    jal bucle_entrada_caracteres
    
    # Mostrar resultados del ciclo
    jal mostrar_resultados
    
    # Esperar confirmación para continuar
    jal esperar_tecla
    
    # Repetir ciclo
    j ciclo_principal

##############################################################################
# INICIALIZAR NUEVO CICLO
##############################################################################
inicializar_ciclo:
    # Guardar registros
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Resetear buffer circular
    sw $zero, buffer_in
    sw $zero, buffer_out
    sw $zero, buffer_count
    
    # Resetear tiempo
    sw $zero, tiempo_actual
    
    # Limpiar buffer (opcional - para debug)
    la $t0, buffer
    li $t1, 0
    li $t2, 256
limpiar_buffer:
    beq $t1, $t2, fin_limpiar
    sb $zero, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j limpiar_buffer
fin_limpiar:
    
    # Restaurar registros
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# BUCLE DE ENTRADA DE CARACTERES (20 SEGUNDOS)
##############################################################################
bucle_entrada_caracteres:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

bucle_tiempo:
    # Verificar si han pasado 20 segundos
    jal verificar_tiempo
    bnez $v0, fin_bucle_tiempo
    
    # Leer teclado (no bloqueante)
    jal leer_teclado
    move $t0, $v0              # t0 = caracter leido (0 si no hay)
    
    # Si hay caracter, procesarlo
    beqz $t0, sin_caracter
    move $a0, $t0
    jal procesar_caracter
    
sin_caracter:
    # Pequeña pausa para evitar saturar el simulador
    li $a0, 1                  # 1ms de pausa
    jal pausa_milisegundos
    
    j bucle_tiempo

fin_bucle_tiempo:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# LEER TECLADO (NO BLOQUEANTE)
# Retorna: $v0 = caracter leído (0 si no hay caracter disponible)
##############################################################################
leer_teclado:
    # Guardar registros
    addi $sp, $sp, -8
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    
    # Leer controlador de teclado
    lw $t0, controlador_teclado
    lw $t1, 0($t0)
    
    # Verificar si hay caracter disponible (bit0 = 1)
    andi $t1, $t1, 1
    beqz $t1, no_hay_caracter
    
    # Leer el caracter
    lw $t0, datos_teclado
    lw $v0, 0($t0)
    j fin_leer_teclado
    
no_hay_caracter:
    li $v0, 0
    
fin_leer_teclado:
    # Restaurar registros
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    addi $sp, $sp, 8
    jr $ra

##############################################################################
# PROCESAR CARACTER
# Parámetro: $a0 = caracter a procesar
##############################################################################
procesar_caracter:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    move $s0, $a0              # Guardar caracter
    
    # Mostrar caracter recibido (opcional - para debug)
    # li $v0, 11
    # move $a0, $s0
    # syscall
    
    # Verificar si es letra mayúscula (A-Z: 65-90)
    li $s1, 65                  # 'A'
    blt $s0, $s1, descartar
    li $s1, 90                  # 'Z'
    bgt $s0, $s1, descartar
    
    # Es mayúscula - almacenar en buffer
    move $a0, $s0
    jal almacenar_en_buffer
    
    # Mostrar mensaje de aceptación
    # li $v0, 4
    # la $a0, msg_tecla_aceptada
    # syscall
    j fin_procesar
    
descartar:
    # Carácter no es mayúscula - mostrar mensaje
    # li $v0, 4
    # la $a0, msg_tecla_rechazada
    # syscall
    nop
    
fin_procesar:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

##############################################################################
# ALMACENAR EN BUFFER CIRCULAR
# Parámetro: $a0 = caracter a almacenar
##############################################################################
almacenar_en_buffer:
    addi $sp, $sp, -12
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    
    # Verificar si buffer está lleno
    lw $t0, buffer_count
    lw $t1, BUFFER_SIZE
    beq $t0, $t1, buffer_lleno
    
    # Calcular posición de escritura
    la $t2, buffer
    lw $t1, buffer_in
    add $t2, $t2, $t1
    
    # Almacenar caracter
    sb $a0, 0($t2)
    
    # Actualizar índice de escritura
    addi $t1, $t1, 1
    lw $t0, BUFFER_SIZE
    bne $t1, $t0, no_wrap_in
    li $t1, 0
no_wrap_in:
    sw $t1, buffer_in
    
    # Incrementar contador
    lw $t0, buffer_count
    addi $t0, $t0, 1
    sw $t0, buffer_count
    
buffer_lleno:
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    addi $sp, $sp, 12
    jr $ra

##############################################################################
# VERIFICAR TIEMPO
# Retorna: $v0 = 1 si han pasado 20 segundos, 0 en caso contrario
##############################################################################
verificar_tiempo:
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    # Incrementar tiempo actual (simulación)
    lw $t0, tiempo_actual
    addi $t0, $t0, 1           # Incremento de 1ms por cada llamada
    sw $t0, tiempo_actual
    
    # Comparar con tiempo objetivo
    lw $t0, tiempo_objetivo
    lw $t1, tiempo_actual
    li $v0, 0
    blt $t1, $t0, tiempo_no_cumplido
    li $v0, 1
    sw $zero, tiempo_actual    # Resetear tiempo para próximo ciclo
    
tiempo_no_cumplido:
    lw $t0, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# PAUSA EN MILISEGUNDOS
# Parámetro: $a0 = milisegundos a esperar
##############################################################################
pausa_milisegundos:
    addi $sp, $sp, -8
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    
    # Obtener tiempo inicial
    lw $t0, tiempo_actual
    add $t1, $t0, $a0
    
pausa_loop:
    lw $t0, tiempo_actual
    blt $t0, $t1, pausa_loop
    
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    addi $sp, $sp, 8
    jr $ra

##############################################################################
# MOSTRAR RESULTADOS DEL CICLO
##############################################################################
mostrar_resultados:
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    # Mensaje de fin de ciclo
    li $v0, 4
    la $a0, msg_fin_ciclo
    syscall
    
    # Verificar si buffer está vacío
    lw $s0, buffer_count
    beqz $s0, buffer_vacio
    
    # Mostrar contador
    li $v0, 4
    la $a0, msg_contador
    syscall
    
    li $v0, 1
    move $a0, $s0
    syscall
    
    li $v0, 4
    la $a0, msg_newline
    syscall
    la $a0, msg_caracteres
    syscall
    
    # Preparar para impresión
    lw $s1, buffer_out         # Índice de lectura
    li $s2, 0                   # Contador de impresos
    
imprimir_siguiente:
    beq $s2, $s0, fin_impresion
    
    # Calcular dirección de lectura
    la $t0, buffer
    add $t0, $t0, $s1
    lb $a0, 0($t0)
    
    # Imprimir caracter
    li $v0, 11
    syscall
    
    # Imprimir espacio
    li $v0, 4
    la $a0, msg_espacio
    syscall
    
    # Actualizar índice de lectura
    addi $s1, $s1, 1
    lw $t0, BUFFER_SIZE
    bne $s1, $t0, no_wrap_out
    li $s1, 0
no_wrap_out:
    
    addi $s2, $s2, 1
    j imprimir_siguiente
    
buffer_vacio:
    li $v0, 4
    la $a0, msg_buffer_vacio
    syscall
    
fin_impresion:
    li $v0, 4
    la $a0, msg_newline
    syscall
    la $a0, msg_sep
    syscall
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

##############################################################################
# ESPERAR TECLA (ENTER PARA CONTINUAR)
##############################################################################
esperar_tecla:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Mostrar mensaje
    li $v0, 4
    la $a0, msg_continuar
    syscall
    
esperar_loop:
    # Leer teclado
    jal leer_teclado
    move $t0, $v0
    
    # Esperar hasta que sea Enter (13 = CR, 10 = LF)
    li $t1, 10
    beq $t0, $t1, fin_esperar
    li $t1, 13
    beq $t0, $t1, fin_esperar
    
    # Pequeña pausa
    li $a0, 10
    jal pausa_milisegundos
    j esperar_loop
    
fin_esperar:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# FUNCIÓN PARA CONFIGURAR Y EJECUTAR EL PROGRAMA EN MARS
##############################################################################
# Instrucciones para usar en MARS:
# 1. Tools -> Keyboard and Display MMIO Simulator
# 2. Conectar a MIPS
# 3. Ejecutar el programa
# 4. Escribir en la ventana "Keyboard" del simulador
##############################################################################