STSEG SEGMENT PARA STACK "STACK"
    DB 64 DUP ("?")
STSEG ENDS

DSEG SEGMENT PARA PUBLIC "DATA"
    buf DB 7, ?, 7 DUP(?)
    number DW 0 
    input_message db "Enter an integer number [-10922..21845]: $" 
    result_message db "Result: $" 
    run_message db "Do you want to continue? (y/n): $" 
    error_run_message db "Invalid input. Ending program...$" 
    empty_input_message db "Empty input. Enter once again$" 
    invalid_input_message db "Invalid input$" 
    overflow_input_message db "Overflow input. Enter once again$" 
    overflow_calc_message db "Calculation overflow! Result is too large.$" 
DSEG ENDS

CSEG SEGMENT PARA PUBLIC "CODE"
MAIN PROC FAR
    ASSUME CS: CSEG, DS: DSEG, SS: STSEG
    PUSH DS 
    XOR AX, AX 
    PUSH AX 
    MOV AX, DSEG 
    MOV DS, AX 

main_loop:
    CALL input_number 
    CALL line 
    MOV AH, 9 
    LEA DX, run_message 
    INT 21h 
    
    MOV AH, 1 
    INT 21h 
    
    CMP AL, 'Y' 
    JE rerun 
    CMP AL, 'y' 
    JE rerun 
    CMP AL, 'N' 
    JE exit_program 
    CMP AL, 'n' 
    JE exit_program 
    
    CALL line 
    MOV AH, 9 
    LEA DX, error_run_message 
    INT 21h 
    JMP exit_program 

rerun:
    CALL line 
    JMP main_loop 

exit_program:
    MOV AH, 4CH 
    INT 21h 
    POP AX 
    POP DS 
    RETF 
MAIN ENDP

input_number PROC NEAR
    MOV number, 0
    MOV AH, 9
    LEA DX, input_message
    INT 21h
    
    LEA DX, buf
    MOV AH, 10
    INT 21h
    CALL line
    
    LEA SI, buf + 2
    XOR BX, BX
    XOR CX, CX
    MOV BL, [SI]
    
    CMP BL, 0DH
    JE empty_input
    CMP BL, '+'
    JE sign_plus
    CMP BL, '-'
    JE sign_minus
    JMP process_number

convert_loop:
    XOR BX, BX
    MOV BL, [SI]
    CMP BL, 0DH
    JE end_convertation

process_number:
    CMP BL, '0'
    JB invalid_input
    CMP BL, '9'
    JA invalid_input
    
    SUB BL, '0'
    MOV AX, 10
    MUL [number]
    JC overflow_input 

    ADD AX, BX
    JC overflow_input
    
    CMP CL, 1
    JNE save_number
    CMP AX, 8000h
    JA overflow_input
    
save_number:
    MOV number, AX
    INC SI
    JMP convert_loop

empty_input:
    MOV AH, 9
    LEA DX, empty_input_message
    INT 21h
    RET

sign_plus:
    INC SI
    JMP convert_loop

sign_minus:
    MOV CL, 1
    INC SI
    JMP convert_loop

invalid_input:
    MOV AH, 9
    LEA DX, invalid_input_message
    INT 21h
    RET

overflow_input:
    MOV AH, 9
    LEA DX, overflow_input_message
    INT 21h
    RET

end_convertation:
    CMP CL, 1
    JNE mul_number
    NEG number
    JMP imul_number

mul_number:
    MOV AX, [number]
    MOV CX, 3
    MUL CX
    MOV CL, 0
    JC calc_overflow
    JMP end_mul_number

imul_number:
    MOV AX, [number]
    MOV CX, 3
    IMUL CX
    MOV CL, 1
    JO calc_overflow 

end_mul_number:    
    MOV number, AX
    
    CALL print_number
    RET

calc_overflow:
    MOV AH, 9
    LEA DX, overflow_calc_message
    INT 21h
    RET

input_number ENDP

line PROC NEAR
    MOV AH, 2
    MOV DL, 13
    INT 21h
    MOV DL, 10
    INT 21h
    RET
line ENDP

print_number PROC NEAR
    MOV AH, 9 
    LEA DX, result_message
    INT 21h 

    MOV BX, number
    
    CMP CL, 1
    JNE m1

    MOV AL, '-'
    INT 29h
    NEG BX
m1:
    MOV AX, BX
    XOR CX, CX
    MOV BX, 10
m2:
    XOR DX, DX
    DIV BX
    ADD DX, '0'
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ m2
m3:
    POP AX
    INT 29h
    LOOP m3
    RET
print_number ENDP

CSEG ENDS
END main