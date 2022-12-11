;
; author: SevenSignBits
;
; as per the System-V ABI, registers are allocated in the order:
;   rdi, rsi, rdx, rcx, r8, r9
;

global process_main

extern bzero
extern malloc ; *shudder* dynamic memory management
extern free   ; ...

section .data
align 16

section .bss
align 16
    first_char_addr: resb 8
    end_char_addr:   resb 8
    row_len:         resb 8
    col_len:         resb 8
    final_score:     resb 8

section .text

align 16
search_to_top:
    ; rdi : start address
    mov al, byte [rdi] ; first char height
    sub rdi, qword [row_len] ; "advance" to previous row
  search_top_loop:
    mov sil, byte [rdi] ; get current char
    cmp sil, al         ; compare to current highest tree
    jge search_top_exit_early
    mov eax, 1
    ret

    

  search_top_continue:
    sub rdi, qword [row_len]         ; advance to previous row
    cmp rdi, qword [first_char_addr] ; compare to beginning of data
    jge search_top_loop ; loop as long as we havent gone too far
    xor eax, eax
    ret

align 16
search_to_bottom:
    ; rdi : start address
    mov al, byte [rdi] ; first char height
    add rdi, qword [row_len] ; advance to next row
  search_bottom_loop:
    mov sil, byte [rdi] ; get current char
    cmp sil, al         ; compare to current highest tree
    jl search_bottom_continue
    ; current height is >= existing
    mov rax, 1
    ret
  search_bottom_continue:
    add rdi, qword [row_len]         ; advance to next row
    cmp rdi, qword [first_char_addr] ; compare to end of data
    jl search_bottom_loop ; loop as long as we havent gone too far
    xor eax, eax
    ret



align 16
process_main:
    ; rdi : const char*
    ; rsi : #rows
    ; rdx : #columns

    push rbp
    mov rbp, rsp

    push r12 ; some preserved registers
    push r13
    push r14
    push r15

    sub rsp, 16

    mov qword [first_char_addr], rdi ; store beginning of array
    mov qword [row_len], rdx   ; store row_len (#cols)
    mov qword [col_len], rsi   ; store col_len (#rows)
    mov qword [final_score], 0 ; zero final score

    mov rax, rsi              ; setup mul, #rows
    mul rdx                   ; rdx:rax = rax * #cols
    add rax, rdi                   ; now points one past last char
    mov qword [end_char_addr], rax ; store in central location

    mov r12, 1               ; y start
    mov r13, qword [col_len] ; y end
    dec r13
  mp_y_loop:

    mov r14, 1               ; x start
    mov r15, qword [row_len] ; x end
    dec r15
  mp_x_loop:

    mov byte [rsp + 8], 0

    mov rax, r12        ; load current y
    mul qword [row_len] ; rax = y * row_len
    add rax, r14        ; rax = y*rowlen + x
    add rax, qword [first_char_addr]
    mov qword [rsp + 0], rax ; store on stack

    mov rdi, qword [rsp + 0]
    call search_to_top
    or byte [rsp + 8], al
    mov rdi, qword [rsp + 0]
    call search_to_bottom
    or byte [rsp + 8], al

    movzx rax, byte [rsp + 8]
    add qword [final_score], rax

  mp_end_inner_loop:
    inc r14
    cmp r14, r15
    jl mp_x_loop

    inc r12 ; increment y counter
    cmp r12, r13
    jl mp_y_loop

    ; clean up after ourselves
    add rsp, 16

    pop r15 ; restore preserved registers
    pop r14
    pop r13
    pop r12

    ; return final score
    mov rax, qword [final_score]

    mov rsp, rbp
    pop rbp
    ret
