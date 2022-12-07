;
; author: SevenSignBits
;
; as per the System-V ABI, registers are allocated in the order:
;   rdi, rsi, rdx, rcx, r8, r9
;

global process_chars
extern bzero

section .bss
    cmp_space: resb 256

section .text
align 16
process_chars:
    ; rdi : char string, null-terminated
    ; esi : num chars to test unique

    push rbp
    mov rbp, rsp

    sub rsp, 32 ; needs to remain 16-byte aligned because we call bzero
    mov qword [rsp + 0], rdi  ; store char ptr on stack
    mov qword [rsp + 16], rdi ; ... twice
    mov dword [rsp + 8], esi  ; store N on stack

  start:
    mov rdi, cmp_space ; bzero : string
    mov rsi, 256       ; bzero : size
    call bzero

    mov rdi, qword [rsp + 0]
    mov esi, dword [rsp + 8]
    xor eax, eax ; mark loop as "clean" to start

  write_cmp_loop:
    dec rsi ; decrement idx of current char to compare (we technically iterate backwards but it doesnt matter)
    lea r10, [rdi + rsi] ; address of input char
    mov r8b, byte [r10]  ; fetch input char
    movzx r8, r8b        ; zero-extend to 64 bits
    mov r9, cmp_space    ; base address of cmp array
    lea r10, [r9 + r8]   ; address of cmp array entry
    mov cl, byte [r10]   ; fetch cmp array entry
    cmp cl, 0            ; compare entry to zero
    je no_mark
    mov eax, 1 ; mark this loop as "dirty"
  no_mark:
    mov byte [r10], 1 ; update cmp array entry as used
    cmp esi, 0
    jne write_cmp_loop

    ; after the write-mark loop, test eax to see if the sequence was unique
    cmp eax, 0
    je loop_success ; exit early if loop was clean

    ; prepare for next loop
    inc qword [rsp + 0] ; advance input char pointer
    jmp start

  loop_success:
    ; this loop was fine
    mov rax, qword [rsp + 0] ; current offset from original char string
    mov esi, dword [rsp + 8] ; chunk size (implicitly zero extended to 64 bits)
    add rax, rsi ; 
    mov rsi, qword [rsp + 16] ; original char string address
    sub rax, rsi ; rax (return value) now has proper offset

  end_branch:
    mov rsp, rbp
    pop rbp
    ret
