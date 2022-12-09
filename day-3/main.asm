;
; author: SevenSignBits
;
; as per the System-V ABI, registers are allocated in the order:
;   rdi, rsi, rdx, rcx, r8, r9
;

global main_process

extern strlen
extern bzero

section .data
align 16
    priority_table: ; LUT for priority values
    pr0: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    pr1: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    pr2: db 0, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 0, 0, 0, 0, 0
    pr3: db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0

section .bss
align 16
    cmp_space: resb 128
    stdout_fptr: resb 8

section .text

align 16
write_chunk:
    ; rdi : char*
    ; rsi : length of chunk in bytes
    ; rdx : flag to mark with

    push rbp
    mov rbp, rsp

    mov r8, cmp_space       ; load compare space

  wc_loop:
    dec rsi

    movzx rcx, byte [rdi] ; load current char into cl
    inc rdi               ; advance char* to next char
    lea r9, [r8 + rcx]    ; load address of entry in cmp_array
    movzx r10, byte [r9]
    or r10, rdx      ; OR flag into cmp_array
    mov byte [r9], r10b

    cmp rsi, 0  ; check for end of loop
    jne wc_loop ; repeat if not zero

  wc_end_branch:
    mov rsp, rbp
    pop rbp
    ret


align 16
eval_priority:
    ; rdi : pointer to long int representing final score
    ; r10 : flag value to test against

    push rbp
    mov rbp, rsp

    mov r8, cmp_space      ; we're gonna want these readily available
    mov r9, priority_table ; ...

    mov rsi, 128 ; 128 entries in cmp_space
  ep_loop:
    dec rsi              ; decrement loop counter

    lea rdx, [r8 + rsi]   ; address of current cmp_space entry
    lea rcx, [r9 + rsi]   ; address of current priority_table entry
    movzx rdx, byte [rdx] ; cmp_space entry
    movzx rcx, byte [rcx] ; priority_table entry

    cmp rdx, r10 ; flag=r10 if char is present in all relevant chunks
    jne ep_dont_update
    add qword [rdi], rcx ; update score
    jmp ep_end_branch    ; exit early if score is updated
  ep_dont_update:

    cmp rsi, 0
    jne ep_loop

  ep_end_branch:
    mov rsp, rbp
    pop rbp
    ret


align 16
main_process:
    ; rdi : array of const char*

    push rbp
    mov rbp, rsp

    sub rsp, 80               ; space for temporaries while maintaining 16 byte alignment
    mov qword [rsp + 0], rdi  ; save input to stack, this one will be modified
    mov qword [rsp + 40], rdi ; save input again, need this one for second half
    mov qword [rsp + 48], rdi ; pointer to second answer
    mov qword [rsp + 32], 0   ; clear first-half score to zero
    mov qword [rsp + 56], 0   ; clear second-half score to zero
    mov qword [rsp + 64], rsi ; pointer to final answer

  mp_first_loop:
    mov rdi, cmp_space ; bzero : dest
    mov rsi, 128       ; bzero : size to zero out
    call bzero

    mov rdi, qword [rsp + 0] ; get current char**
    mov rdi, qword [rdi]     ; strlen : input string
    call strlen              ; RAX = strlen result

    mov rdi, qword [rsp + 0]
    mov rdi, qword [rdi] ; get current string again
    shr rax, 1           ; we need half of the total strlen
    mov qword [rsp + 8], rdi  ; store pointer to first half on stack
    add rdi, rax              ; advance pointer to second half of input string
    mov qword [rsp + 16], rdi ; store pointer to second half on stack
    mov qword [rsp + 24], rax ; store half-length on stack

    mov rdi, qword [rsp + 8] ; 1st arg = first chunk
    mov rsi, rax             ; 2nd arg = length
    mov rdx, 1               ; 3rd arg = flag
    call write_chunk

    mov rdi, qword [rsp + 16] ; 1st arg = second chunk
    mov rsi, qword [rsp + 24] ; 2nd arg = length
    mov rdx, 2                ; 3rd arg = flag
    call write_chunk

    lea rdi, [rsp + 32] ; pointer to long int score
    mov r10, 3          ; flag value = 3 for part 1, this is NOT SysV compliant
    call eval_priority

    add qword [rsp + 0], 8   ; advance char** input to next char*
    mov rdi, qword [rsp + 0] ; get new char** from stack
    mov rdi, qword [rdi]     ; current char*
    mov dil, byte [rdi]      ; first char
    cmp dil, 0       ; compare to zero
    jne mp_first_loop ; repeat if loop is not done yet

  mp_second_loop:
    mov rdi, cmp_space ; bzero : dest
    mov rsi, 128       ; bzero : size to zero out
    call bzero

    mov rdi, qword [rsp + 40] ; get current char**
    mov rdi, qword [rdi]      ; strlen : input string
    call strlen               ; RAX = strlen result
    mov rdi, qword [rsp + 40] ; 1st arg = first chunk
    mov rdi, qword [rdi]      ; ...
    mov rsi, rax              ; 2nd arg = chunk len
    mov rdx, 1                ; 3rd arg = flag value
    call write_chunk

    add qword [rsp + 40], 8   ; advance input pointer to next char*
    mov rdi, qword [rsp + 40] ; get current char**
    mov rdi, qword [rdi]      ; strlen : input string
    call strlen               ; RAX = strlen result
    mov rdi, qword [rsp + 40] ; 1st arg = first chunk
    mov rdi, qword [rdi]      ; ...
    mov rsi, rax              ; 2nd arg = chunk len
    mov rdx, 2                ; 3rd arg = flag value
    call write_chunk

    add qword [rsp + 40], 8   ; advance input pointer to next char*
    mov rdi, qword [rsp + 40] ; get current char**
    mov rdi, qword [rdi]      ; strlen : input string
    call strlen               ; RAX = strlen result
    mov rdi, qword [rsp + 40] ; 1st arg = first chunk
    mov rdi, qword [rdi]      ; ...
    mov rsi, rax              ; 2nd arg = chunk len
    mov rdx, 4                ; 3rd arg = flag value
    call write_chunk

    lea rdi, [rsp + 56] ; pointer to long int score
    mov r10, 7          ; flag value = 7 for part 2, not SysV compliant
    call eval_priority

    add qword [rsp + 40], 8   ; advance input pointer to next char*
    mov rdi, qword [rsp + 40] ; get current char**
    mov rdi, qword [rdi]      ; char*
    mov dil, byte [rdi]       ; first char
    cmp dil, 0                ; loop as long as we dont have a NULL-string
    jne mp_second_loop        ; ...

    mov rax, qword [rsp + 32] ; place first score in RAX
    mov rdi, qword [rsp + 56] ; current second score
    mov rsi, qword [rsp + 64] ; pointer to long int where second score needs to go
    mov qword [rsi], rdi      ; store final second score in final destination

  end_branch:
    mov rsp, rbp
    pop rbp
    ret
