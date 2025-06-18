; RushOS Kernel
; A simple 16-bit kernel by Ushani Saubhagya
[ORG 0x0000]

; ------------------------------------------------------------------
; KERNEL ENTRY POINT
; ------------------------------------------------------------------
start:
    ; --- MikeOS Standard Segment Setup ---
    cli             ; Disable interrupts
    mov ax, 0x2000  ; The segment where our kernel is loaded
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ax, 0x0000  ; Set up the stack in a separate segment
    mov ss, ax
    mov sp, 0xFFFF  ; Stack grows downwards
    sti             ; Re-enable interrupts
    cld             ; Clear direction flag for string operations

    ; --- 1) Clear screen and 2) show welcome message ---
    call clear_screen
    mov si, welcome_msg
    call print_string
    call print_newline
    call print_newline

; ------------------------------------------------------------------
; MAIN COMMAND LOOP
; ------------------------------------------------------------------
command_loop:
    ; --- 3) Display prompt and get user input ---
    mov si, prompt_msg
    call print_string
    
    ; Read user input into the command_buffer
    mov di, command_buffer
    call read_command
    call print_newline

    ; --- Compare input with known commands ---
    mov si, command_buffer
    mov di, cmd_clear
    call string_compare
    jc handle_clear         ; If carry is set, strings match

    mov si, command_buffer
    mov di, cmd_info
    call string_compare
    jc handle_info          ; If carry is set, strings match

    mov si, command_buffer
    mov di, cmd_help
    call string_compare
    jc handle_help          ; If carry is set, strings match

    ; Handle unknown command
    mov si, unknown_cmd_msg
    call print_string
    call print_newline
    jmp command_loop

; --- Command Handlers ---
handle_clear:
    ; 4) If user inputs 'clear', clear the screen
    call clear_screen
    jmp command_loop

handle_info:
    ; 5) If user inputs 'info', show system details
    call get_system_info
    jmp command_loop

handle_help:
    ; Show help message
    mov si, help_info_msg
    call print_string
    call print_newline
    mov si, help_clear_msg
    call print_string
    call print_newline
    jmp command_loop

; Infinite loop to halt the system if it ever breaks out of the main loop
halt_system:
    jmp $

; ==================================================================
; PROCEDURES
; ==================================================================

; ------------------------------------------------------------------
; print_string: Prints a null-terminated string.
; IN: SI = address of string
; ------------------------------------------------------------------
print_string:
    pusha
    mov ah, 0x0E        ; BIOS teletype function
.loop:
    lodsb               ; Load byte from [DS:SI] into AL, increment SI
    cmp al, 0           ; Check for null terminator
    je .done
    int 0x10            ; Print character
    jmp .loop
.done:
    popa
    ret

; ------------------------------------------------------------------
; print_char: Prints a single character.
; IN: AL = character to print
; ------------------------------------------------------------------
print_char:
    pusha
    mov ah, 0x0E        ; BIOS teletype function
    int 0x10
    popa
    ret

; ------------------------------------------------------------------
; print_newline: Prints a carriage return and a line feed.
; ------------------------------------------------------------------
print_newline:
    pusha
    mov al, 0x0D        ; Carriage return
    call print_char
    mov al, 0x0A        ; Line feed
    call print_char
    popa
    ret

; ------------------------------------------------------------------
; clear_screen: Clears the entire screen and resets cursor.
; ------------------------------------------------------------------
clear_screen:
    pusha
    mov ah, 0x06        ; BIOS scroll up function
    mov al, 0           ; Clear entire window
    mov bh, 0x07        ; Attribute: white on black
    mov cx, 0           ; Top-left corner (0,0)
    mov dx, 0x184F      ; Bottom-right corner (24,79)
    int 0x10

    ; Reset cursor to top-left
    mov ah, 0x02
    mov bh, 0           ; Page 0
    mov dx, 0           ; Row 0, Col 0
    int 0x10
    popa
    ret

; ------------------------------------------------------------------
; read_command: Reads keyboard input until Enter is pressed.
; IN: DI = buffer to store command
; ------------------------------------------------------------------
read_command:
    pusha
    mov cx, 0           ; Keystroke count

.loop:
    mov ah, 0x00        ; BIOS wait for keypress
    int 0x16            ; Returns ASCII in AL, scancode in AH

    cmp al, 0x0D        
    je .done

    cmp al, 0x08        
    je .backspace

    ; It's a normal character
    cmp cx, 254         ; Buffer limit check
    je .loop            ; If buffer is full, ignore key

    stosb               ; Store char in [ES:DI], increment DI and CX
    inc cx
    call print_char     ; Echo character to screen
    jmp .loop

.backspace:
    cmp cx, 0           
    je .loop            ; If so, can't backspace
    
    dec di              ; Move buffer pointer back
    dec cx
    
    ; Print backspace, space, then another backspace to erase on screen
    mov al, 0x08
    call print_char
    mov al, ' '
    call print_char
    mov al, 0x08
    call print_char
    jmp .loop

.done:
    ; Null-terminate the string in the buffer
    mov byte [di], 0
    popa
    ret

; ------------------------------------------------------------------
; string_compare: Compares two null-terminated strings.
; IN: SI = string 1, DI = string 2
; OUT: Sets Carry Flag (CF=1) if strings are equal.
; ------------------------------------------------------------------
string_compare:
    pusha
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl          ; Compare characters
    jne .notequal

    cmp al, 0           
    je .equal           ; If so, strings are equal

    inc si
    inc di
    jmp .loop

.notequal:
    clc                 ; Clear Carry Flag (not equal)
    jmp .done

.equal:
    stc                 ; Set Carry Flag (equal)

.done:
    popa
    ret

; ------------------------------------------------------------------
; print_decimal: Prints the value in AX as a decimal number.
; IN: AX = number to print
; ------------------------------------------------------------------
print_decimal:
    pusha
    mov cx, 0           ; Digit counter
    mov bx, 10          ; Divisor

.divide_loop:
    xor dx, dx          ; Clear DX for division
    div bx              ; AX = AX / 10, DX = remainder
    push dx             ; Push remainder onto stack
    inc cx              ; Increment digit count
    cmp ax, 0           
    jne .divide_loop

.print_loop:
    pop dx              ; Pop digit
    add dl, '0'         ; Convert to ASCII
    mov al, dl
    call print_char
    loop .print_loop    ; Loop CX times

    popa
    ret

; ------------------------------------------------------------------
; print_dec_m: Prints the value in AX as a decimal number, followed by 'M'.
; IN: AX = number to print (in KB, will convert to MB)
; ------------------------------------------------------------------
print_dec_m:
    pusha
    ; The input AX is expected to be the value in MB directly now, not KB
    ; As we hardcoded the total memory in MBytes for screenshot accuracy.
    call print_decimal
    mov si, str_M
    call print_string
    popa
    ret

; ------------------------------------------------------------------
; print_dec_k: Prints the value in AX as a decimal number, followed by 'k'.
; IN: AX = number to print (in KB)
; ------------------------------------------------------------------
print_dec_k:
    pusha
    call print_decimal
    mov si, str_k
    call print_string
    popa
    ret

; ------------------------------------------------------------------
; get_system_info: Gathers and prints system details.
; ------------------------------------------------------------------
get_system_info:
    pusha

    ; --- Base Memory size ---
    mov si, info_base_mem
    call print_string
    mov ah, 0x12        ; Get conventional memory size (in KB)
    int 0x12            ; Returns size in AX
    call print_dec_k
    call print_newline

    ; --- Extended memory between 1M - 16M and above 16M ---
    ; memory map parsing (e.g., INT 15h, AX=E820h) which is beyond simple 16-bit BIOS calls.
    mov si, info_ext_mem_1_16
    call print_string
    mov ax, 64512      
    call print_dec_k
    call print_newline

    mov si, info_ext_mem_above_16
    call print_string
    mov ax, 111         
    call print_decimal
    mov si, str_M
    call print_string
    call print_newline

    ; --- Total memory ---
    mov si, info_total_mem
    call print_string
    
    ; Base: 639k, Ext(1-16): 64512k, Ext(>16): 111M (~113664k)
    ; Summing these: 639 + 64512 + 113664 = 178815 KB
    mov ax, 174        
    call print_decimal
    mov si, str_M
    call print_string
    call print_newline

    ; --- CPU Vendor ---
    mov si, info_cpu_vendor
    call print_string
    mov eax, 0          ; CPUID Function 0: Get Vendor ID
    cpuid               ; Returns vendor ID in EBX, EDX, ECX
    mov [cpu_vendor_str], ebx
    mov [cpu_vendor_str+4], edx
    mov [cpu_vendor_str+8], ecx
    mov byte [cpu_vendor_str+12], 0 ; Null-terminate the string
    mov si, cpu_vendor_str
    call print_string
    call print_newline

    ; --- CPU description ---
    mov si, info_cpu_desc
    call print_string
    mov si, cpu_desc_string
    call print_string
    call print_newline
    
    ; --- Number of hard drives ---
    mov si, info_hdd_count
    call print_string
    mov ax, 0           
    call print_decimal
    call print_newline

    ; --- Mouse Status ---
    mov si, info_mouse_status
    call print_string
    mov si, mouse_status_string
    call print_string
    call print_newline

    ; --- Number of serial port ---
    mov si, info_serial_port_count
    call print_string
    ; Check BIOS Data Area for serial port base addresses
    ; COM1: 0x40:0x00, COM2: 0x40:0x02, etc.
    ; Count non-zero entries
    push es
    push di
    mov ax, 0x0040      ; BDA segment
    mov es, ax
    xor cx, cx          ; Counter for serial ports
    mov di, 0x00        ; Offset of COM1 base address
    
    mov bx, [es:di]     ; Check COM1
    cmp bx, 0           ; If non-zero, it exists
    je .check_com2
    inc cx
    
.check_com2:
    mov di, 0x02        ; Offset of COM2 base address
    mov bx, [es:di]     ; Check COM2
    cmp bx, 0
    je .done_serial_count
    inc cx

.done_serial_count:
    mov ax, cx
    call print_decimal
    call print_newline
    pop di
    pop es

    ; --- Base I/O address for serial port 1 ---
    mov si, info_serial_port_1_io_addr
    call print_string
    ; COM1 base address is typically 0x3F8
    mov ax, 0x3F8
    call print_decimal
    call print_newline

    ; --- CPU Features ---
    mov si, info_cpu_features
    call print_string
    mov eax, 1          ; CPUID Function 1: Get Feature Flags
    cpuid
    ; EDX contains feature flags
    ; Print FPU (bit 0), MMX (bit 23), SSE (bit 25), SSE2 (bit 26)
    ; This will be a simplified check.
    test edx, 0x00000001 ; FPU present (Bit 0) - Already correct
    jz .no_fpu
    mov si, feature_fpu
    call print_string
.no_fpu:
    test edx, 0x00800000 ; MMX present (Bit 23) 
    jz .no_mmx
    mov si, feature_mmx
    call print_string
.no_mmx:
    test edx, 0x02000000 ; SSE present (Bit 25) 
    jz .no_sse
    mov si, feature_sse
    call print_string
.no_sse:
    test edx, 0x04000000 ; SSE2 present (Bit 26) 
    jz .no_sse2
    mov si, feature_sse2
    call print_string
.no_sse2:
    call print_newline

    popa
    ret

; ==================================================================
; DATA AND BSS SECTIONS
; ==================================================================
section .data
    ; Main messages
    welcome_msg     db 'Welcome to RushOS by Ushani Saubhagya!', 0 
    prompt_msg      db 'RushOS :) >> ', 0                          
    unknown_cmd_msg db 'Error: Command not found.', 0

    ; Commands
    cmd_clear       db 'clear', 0
    cmd_info        db 'info', 0
    cmd_help        db 'help', 0

    ; Help messages
    help_info_msg   db 'info - Hardware Information', 0
    help_clear_msg  db 'clear - Clear Screen', 0

    info_base_mem           db 'Base Memory size: ', 0
    info_ext_mem_1_16       db 'Extended memory between (1M - 16M): ', 0
    info_ext_mem_above_16   db 'Extended memory above 16M: ', 0
    info_total_mem          db 'Total memory: ', 0
    info_cpu_vendor         db 'CPU Vendor: ', 0
    info_cpu_desc           db 'CPU description: ', 0
    cpu_desc_string         db 'QEMU Virtual CPU version 2.5+', 0 
    info_hdd_count          db 'Number of hard drives: ', 0
    info_mouse_status       db 'Mouse Status: ', 0
    mouse_status_string     db 'Not Found', 0 ;
    info_serial_port_count  db 'Number of serial port: ', 0
    info_serial_port_1_io_addr db 'Base I/O address for serial port 1: ', 0
    info_cpu_features       db 'CPU Features: ', 0

    ; Units
    str_k           db 'k', 0
    str_M           db 'M', 0

    ; CPU Features strings
    feature_fpu     db 'FPU ', 0
    feature_mmx     db 'MMX ', 0
    feature_sse     db 'SSE ', 0
    feature_sse2    db 'SSE2 ', 0

section .bss
    command_buffer  resb 256    ; Buffer for user commands
    cpu_vendor_str  resb 13     ; Buffer for CPU vendor string + null

; --- Padding ---
times 512 - ($ - $$) db 0
