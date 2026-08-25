default rel

section .data
    rose_0 db "                  ", 0
    rose_1 db " ⠀⠀⠀⠀⠀⢠⢄⡠⡄        ", 0
    rose_2 db "⠀⠀⠀⠀⠀⢰⠃⠀⢀⡆⠀       ", 0
    rose_3 db "⠀⡤⠔⠒⠢⢼⡀⢀⡀⢀⡧⠔⠒⠢⢤   ", 0
    rose_4 db " ⡂ ⠀⠀⠀⠀⠑⣘⣁⠊⣀⠀⠀⠘⡄  ", 0
    rose_5 db "⠀⠑⠤⣀⣀⡠⠭⡧⡼⠩⠅⣀⣀⠤⠊   ", 0
    rose_6 db "⠀⠀  ⡔⠁⢀⠞⢀⡇⠓⢀⠈⠳⡀   ", 0
    rose_7 db "  ⠀ ⢰⡁⠀⠀ ⡸⢣⠀⠀⠀⡇   ", 0
    rose_8 db "⠀ ⠀⠀⠉⠧⠔⠊⠀⠀⠙⠲⠴⠉⠁   ", 0

    red       db 27, "[31m", 0
    reset     db 27, "[0m", 0
    newline_char   db 10, 0

    user_lbl  db "  User:    ", 0
    host_lbl  db "  Host:    ", 0
    kern_lbl  db "  Kernel:  ", 0
    cpu_lbl   db "  CPU:     ", 0
    mem_lbl   db "  Memory:  ", 0
    de_lbl    db "  DE:      ", 0
    shl_lbl   db "  Shell:   ", 0
    init_lbl  db "  Init:    ", 0

    path_host db "/proc/sys/kernel/hostname", 0
    path_kern db "/proc/sys/kernel/osrelease", 0
    path_cpu  db "/proc/cpuinfo", 0
    path_mem  db "/proc/meminfo", 0
    path_init_comm db "/proc/1/comm", 0
    path_openrc_check db "/run/openrc", 0
    openrc_name db "OpenRC", 0

    cpu_target db "model name", 0
    mem_total_target db "MemTotal", 0
    mem_avail_target db "MemAvailable", 0
    mem_divider db " / ", 0
    mem_suffix db " MB", 10, 0
    env_de_target db "XDG_CURRENT_DESKTOP=", 0
    env_shell_target db "SHELL=", 0

section .bss
    buffer resb 4096
    num_buf resb 32
    total_mem resq 1
    avail_mem resq 1

section .text
    global _start

_start:
    mov rbp, rsp

    ; --- User ---
    mov rsi, rose_0
    call print_rose_line
    mov rsi, user_lbl
    call print_string
    call print_user_name

    ; --- Host ---
    mov rsi, rose_1
    call print_rose_line
    mov rsi, host_lbl
    call print_string
    mov rdi, path_host
    call print_file_content

    ; --- Kernel ---
    mov rsi, rose_2
    call print_rose_line
    mov rsi, kern_lbl
    call print_string
    mov rdi, path_kern
    call print_file_content

    ; --- CPU ---
    mov rsi, rose_3
    call print_rose_line
    mov rsi, cpu_lbl
    call print_string
    mov rdi, path_cpu
    mov rsi, cpu_target
    call print_filtered_line

    ; --- Memory ---
    mov rsi, rose_4
    call print_rose_line
    mov rsi, mem_lbl
    call print_string
    call print_mem_in_mb

    ; --- DE ---
    mov rsi, rose_5
    call print_rose_line
    mov rsi, de_lbl
    call print_string
    call print_de_name

    ; --- SH ---
    mov rsi, rose_6
    call print_rose_line
    mov rsi, shl_lbl
    call print_string
    call print_shell_name

    ; --- Init ---
    mov rsi, rose_7
    call print_rose_line
    mov rsi, init_lbl
    call print_string
    call print_init_system

    ; --- HUETA ---
    mov rsi, rose_8
    call print_rose_line
    call print_newline

    mov rax, 60
    xor rdi, rdi
    syscall

print_init_system:
    mov rax, 4
    mov rdi, path_openrc_check
    mov rsi, buffer
    syscall

    test rax, rax
    jnz .check_proccomm

    mov rsi, openrc_name
    jmp .do_print

.check_proccomm:
    mov rax, 2
    mov rdi, path_init_comm
    xor rsi, rsi
    syscall
    test rax, rax
    js .unknown
    mov rdi, rax
    mov rax, 0
    mov rsi, buffer
    mov rdx, 64
    syscall
    push rax
    mov rax, 3
    syscall
    pop rdx

    test rdx, rdx
    jle .unknown
    mov rcx, 0
.find_nl:
    cmp byte [buffer + rcx], 10
    je .found_nl
    cmp byte [buffer + rcx], 0
    je .found_nl
    inc rcx
    cmp rcx, rdx
    jl .find_nl
.found_nl:
    mov byte [buffer + rcx], 0
    mov rsi, buffer

.do_print:
    call print_string
    call print_newline
    ret

.unknown:
    mov rsi, .unk_str
    call print_string
    call print_newline
    ret
    .unk_str db "unknown", 0

print_shell_name:
    mov rcx, [rbp]
    lea rsi, [rbp + 8 + rcx*8 + 8]
.next_env:
    mov rdi, [rsi]
    test rdi, rdi
    jz .unknown
    mov rbx, env_shell_target
    mov rdx, rdi
.check_match:
    mov al, [rbx]
    test al, al
    jz .found
    cmp al, [rdx]
    jne .skip
    inc rbx
    inc rdx
    jmp .check_match
.skip:
    add rsi, 8
    jmp .next_env
.found:
    mov rsi, rdx
    call print_string
    call print_newline
    ret
.unknown:
    mov rsi, .unk_str
    call print_string
    call print_newline
    ret
    .unk_str db "n/a", 0

print_de_name:
    mov rcx, [rbp]
    lea rsi, [rbp + 8 + rcx*8 + 8]
.next_env:
    mov rdi, [rsi]
    test rdi, rdi
    jz .unknown
    mov rbx, env_de_target
    mov rdx, rdi
.check_match:
    mov al, [rbx]
    test al, al
    jz .found
    cmp al, [rdx]
    jne .skip
    inc rbx
    inc rdx
    jmp .check_match
.skip:
    add rsi, 8
    jmp .next_env
.found:
    mov rsi, rdx
    call print_string
    call print_newline
    ret
.unknown:
    mov rsi, .unk_str
    call print_string
    call print_newline
    ret
    .unk_str db "n/a", 0

print_mem_in_mb:
    mov rax, 2
    mov rdi, path_mem
    xor rsi, rsi
    syscall
    mov rdi, rax
    mov rax, 0
    mov rsi, buffer
    mov rdx, 4096
    syscall

    mov rsi, buffer
    mov rdx, mem_total_target
    call find_value
    shr rax, 10             ; KB -> MB
    mov [total_mem], rax
    mov rsi, buffer
    mov rdx, mem_avail_target
    call find_value
    shr rax, 10             ; KB -> MB
    mov [avail_mem], rax
    mov rax, [total_mem]
    sub rax, [avail_mem]
    call print_number
    mov rsi, mem_divider
    call print_string
    mov rax, [total_mem]
    call print_number
    mov rsi, mem_suffix
    call print_string
    ret
find_value:
.next_line:
    mov rdi, rdx
    mov rbx, rsi
.match:
    mov al, [rdi]
    test al, al
    jz .found
    cmp al, [rbx]
    jne .skip_line
    inc rdi
    inc rbx
    jmp .match
.skip_line:
    inc rsi
    cmp byte [rsi], 0
    je .not_found
    cmp byte [rsi-1], 10
    jne .skip_line
    jmp .next_line
.found:
    inc rbx
    cmp byte [rbx], ':'
    je .found
    cmp byte [rbx], ' '
    je .found
    xor rax, rax
    xor rcx, rcx
.atoi:
    mov cl, [rbx]
    cmp cl, '0'
    jb .exit
    cmp cl, '9'
    ja .exit
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rbx
    jmp .atoi
.exit:
    ret
.not_found:
    xor rax, rax
    ret
print_number:
    mov rdi, num_buf + 31
    mov byte [rdi], 0
    mov rbx, 10
.itoa:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .itoa
    mov rsi, rdi
    call print_string
    ret
print_user_name:
    mov rcx, [rbp]
    lea rsi, [rbp + 8 + rcx*8 + 8]
.next_env:
    mov rdi, [rsi]
    test rdi, rdi
    jz .unknown
    cmp dword [rdi], 'USER'
    jne .skip
    cmp byte [rdi+4], '='
    je .found
.skip:
    add rsi, 8
    jmp .next_env
.found:
    add rdi, 5
    mov rsi, rdi
    call print_string
    call print_newline
    ret
.unknown:
    mov rsi, .unk_str
    call print_string
    call print_newline
    ret
    .unk_str db "unknown", 0

print_rose_line:
    push rsi
    mov rsi, red
    call print_string
    pop rsi
    call print_string
    mov rsi, reset
    call print_string
    ret

print_string:
    push rsi
    xor rdx, rdx
.count:
    cmp byte [rsi + rdx], 0
    je .do_print
    inc rdx
    jmp .count
.do_print:
    mov rax, 1
    mov rdi, 1
    syscall
    pop rsi
    ret

print_newline:
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline_char]
    mov rdx, 1
    syscall
    ret

print_file_content:
    mov rax, 2
    xor rsi, rsi
    syscall
    mov rdi, rax
    mov rax, 0
    mov rsi, buffer
    mov rdx, 64
    syscall
    mov rdx, rax
    dec rdx
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    syscall
    call print_newline
    ret

print_filtered_line:
    push rsi
    mov rax, 2
    xor rsi, rsi
    syscall
    mov rdi, rax
    mov rax, 0
    mov rsi, buffer
    mov rdx, 4096
    syscall
    mov r8, rax
    pop rsi
    mov r9, buffer
.find_loop:
    mov r10, rsi
    mov r11, r9
.match_char:
    mov al, [r10]
    test al, al
    jz .found_sep
    cmp al, [r11]
    jne .next_line
    inc r10
    inc r11
    jmp .match_char
.next_line:
    inc r9
    dec r8
    jz .done_filter
    cmp byte [r9-1], 10
    jne .next_line
    jmp .find_loop
.found_sep:
    cmp byte [r9], ':'
    je .print_val
    inc r9
    jmp .found_sep
.print_val:
    inc r9
.strip_space:
    cmp byte [r9], ' '
    jne .start_print
    inc r9
    jmp .strip_space
.start_print:
    mov rsi, r9
    xor rdx, rdx
.count_len:
    inc rdx
    cmp byte [rsi+rdx], 10
    jne .count_len
    mov rax, 1
    mov rdi, 1
    syscall
    call print_newline
.done_filter:
    ret
