.MODEL SMALL
.386
.STACK 100H

.DATA 
    buf DB 7, ?, 7 DUP(?)
    number DW 0 
    sign DB 0
    remainder DW 0
    divisor DW 0
    formula_message DB ' 35x^2-2x+1,        x<=0',13,10
    DB ' (36x^2-17x+1)/x,   0<x<=6',13,10
    DB ' 1250/x,            x>6',13,10,'$'
    input_message DB "Enter an integer number: $" 
    result_message DB "Result: $" 
    run_message DB "Do you want to continue? (y/n): $" 
    error_run_message DB "Invalid input. Ending program...$" 
    empty_input_message DB "Empty input$" 
    invalid_input_message DB "Invalid input$" 
    overflow_input_message DB "Overflow input$" 
    overflow_calc_message DB "Calculation overflow! Result is too large.$"

.CODE
MAIN PROC FAR
    MOV AX, @DATA 
    MOV DS, AX

main_loop:
    MOV sign, 0
    CALL input_number
    JC ask_rerun

    CALL OPERATIONS
    JC ask_rerun

    CALL print_number

ask_rerun:
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

OPERATIONS PROC NEAR
    CMP sign, 1
    JNE skip_negation
    NEG number
    JMP case2
skip_negation:
    CMP number, 6
    JA case3
    CMP number, 0
    JG case1
    JLE case2

calc_overflow:
    MOV AH, 9
    LEA DX, overflow_calc_message
    INT 21h
    STC
    RET

case1:
;   (36x^2-17x+1)/x (0<x<=6)
    MOV sign, 0
    MOV AX, [number]
    MOV CX, AX
    MUL CX
    JC calc_overflow

    MOV BX, 36
    MUL BX
    JC calc_overflow
    PUSH AX

    MOV AX, [number]
    MOV BX, 17
    MUL BX
    JC calc_overflow

    POP BX
    SUB BX, AX
    JC calc_overflow

    ADD BX, 1
    JC calc_overflow

    MOV AX, BX
    XOR DX, DX
    MOV BX, [number]
    DIV BX
    JC calc_overflow
    MOV number, AX 

    MOV remainder, DX
    MOV divisor, BX

    CLC
    RET

case2:
;   35x^2-2x+1 (x<=0)
    MOV AX, [number]
    MOV CX, AX
    IMUL CX
    JO calc_overflow

    MOV BX, 35
    MUL BX
    JC calc_overflow
    PUSH AX

    MOV AX, [number]
    MOV BX, 2
    IMUL BX
    JO calc_overflow

    POP BX
    SUB BX, AX
    JO calc_overflow

    ADD BX, 1
    JO calc_overflow
    MOV number, BX 

    MOV remainder, 0

    CLC
    RET

case3:
;   1250 / x (x>6)
    MOV AX, 1250
    XOR DX, DX
    MOV BX, [number]
    DIV BX
    JC calc_overflow
    MOV number, AX 

    MOV remainder, DX
    MOV divisor, BX

    CLC
    RET

OPERATIONS ENDP

input_number PROC NEAR
    MOV number, 0

    MOV AH, 9
    LEA DX, formula_message
    INT 21H

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
    
    CMP sign, 1
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
    STC
    RET

sign_plus:
    INC SI
    JMP convert_loop

sign_minus:
    MOV sign, 1
    INC SI
    JMP convert_loop

invalid_input:
    MOV AH, 9
    LEA DX, invalid_input_message
    INT 21h
    STC
    RET

overflow_input:
    MOV AH, 9
    LEA DX, overflow_input_message
    INT 21h
    STC
    RET

end_convertation:
    CLC
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

    CMP remainder, 0    
    JE end_print        

    MOV AL, '.'         
    INT 29h

    MOV CX, 4 ; число знаків після коми           
    
fraction_loop:
    MOV AX, remainder
    MOV BX, 10
    MUL BX             

    MOV BX, divisor
    DIV BX             

    PUSH DX             
    
    ADD AL, '0'         
    INT 29h             

    POP DX              
    MOV remainder, DX   

    CMP remainder, 0    
    JE end_print       

    LOOP fraction_loop  

end_print:
    RET
print_number ENDP
END main
