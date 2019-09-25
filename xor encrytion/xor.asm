# File Read/Write, simple message encryption using XOR
# Nov 27, 2018

# $s2 = null char
# $s3 = new line char
# $t0 = src/dst file path for replacing new line char

# $s0 = src plaintext
# s1 = message
# $t0 = char from src plaintext 
# $t1 = char from message
# $s7 = file descriptor


.data

SRC_PROMPT:          .asciiz     "Enter Source File Path: "
DST_PROMPT:          .asciiz     "Enter Destination File Path: "
PASS_PROMPT:         .asciiz     "Enter message: "

SRC_BUFFER:          .space      500    # source file path for open and read
DST_BUFFER:          .space      500    # destination file path for open and write

PASS_BUFFER:         .space      500    # message

SRC_TEXT_BUFFER:     .space      500    # source file text
DST_TEXT_BUFFER:     .space      500    # encrypted text

O_ERROR:             .asciiz     "Error opening file" 
W_ERROR:             .asciiz     "Error writing file" 
R_ERROR:             .asciiz     "Error reading file"



.text
.globl main

main:	# program start

    # load hex code for null char
    li $s2, 0x0
    # load hex code for new line char
    li $s3, 0xa
    
    jal GET_USER_STRINGS

    jal GET_PLAIN_TEXT

    # load addresses of the src plaintext and message
 strings
    la $s0, SRC_TEXT_BUFFER
    la $s1, PASS_BUFFER
    la $s4, DST_TEXT_BUFFER

    
XOR:

        # get char of plaintext
        lb $t0, 0($s0)

        # if at end of plain text -> start writing to Destination File
        beq $t0, $s2, WRITE_DST

        #get char of message
    
        lb $t1, 0($s1)

    null_check:
        
        # if message
     char does not equal null char -> check if new line char    
        bne $t1, $s2, new_line_check

        # if it does equal null char -> go to start of message
    
        la $s1, PASS_BUFFER
        lb $t1, 0($s1)

        # jump to check if next char is null char
        j null_check

    new_line_check:

        # if message
     char does not equal new line char -> start xor'ing
        bne $t1, $s3, skip
        # if it does equal new line -> go to next message
     char
        addiu $s1, $s1, 1
        lb $t1, 0($s1)

        # jump to check if next char is null char or new line char
        j null_check

    skip:

        # xor the plain text char and message
     char
        xor $t0, $t0, $t1
        # store the char in same spot as the plain text char
        sb $t0, 0($s4)

        # get the next char of both the plain text and message
    
        addiu $s0, $s0, 1
        addiu $s1, $s1, 1
        addiu $s4, $s4, 1
    
        # keep repeating until at and of plaintext
        j XOR



WRITE_DST:

    # open Destination File
    la $a0, DST_BUFFER
    li $a1, 0x1
    li $a2, 0x0
    li $v0, 13
    syscall

    # throw file open fail exception
    beq $v0, -1, OPEN_ERROR

    # save file descriptor
    move $s7, $v0

    # write buffer to Destination File
    move $a0, $s7
    la $a1, DST_TEXT_BUFFER
    la $a2, 500
    li $v0, 15
    syscall

    # throw file write fail exception
    beq $v0, -1, WRITE_ERROR

    # close the Destination File
    move $a0, $s7
    li $v0, 16
    syscall

    j exit

    

GET_USER_STRINGS:   

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Get Source Path
    la $a0, SRC_PROMPT
    li $v0, 4
    syscall

    la $a0, SRC_BUFFER
    li $a1, 500
    li $v0, 8
    syscall

    la $t0, SRC_BUFFER

    jal STR_PARSE_LOOP

    # Get Destination Path
    la $a0, DST_PROMPT
    li $v0, 4
    syscall

    la $a0, DST_BUFFER
    li $a1, 500
    li $v0, 8
    syscall

    la $t0, DST_BUFFER

    jal STR_PARSE_LOOP

    #Get message

    la $a0, PASS_PROMPT
    li $v0, 4
    syscall

    la $a0, PASS_BUFFER
    li $a1, 500
    li $v0, 8
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    # jump back to main
    jr $ra

STR_PARSE_LOOP:

        lb $t1, 0($t0)
        beq $t1, $0, str_parse_loop_exit

        bne $t1, $s3, str_parse_loop_skip
        sb $0, 0($t0)

        j str_parse_loop_exit

    str_parse_loop_skip:

        addiu $t0, $t0, 1
        j STR_PARSE_LOOP

    str_parse_loop_exit:

        jr $ra

GET_PLAIN_TEXT:

    # open src file
    la $a0, SRC_BUFFER
    li $a1, 0x00
    li $a2, 0x00
    li $v0, 13
    syscall

    # throw file open fail exception
    beq $v0, -1, OPEN_ERROR

    # save file descriptor
    move $s7, $v0

    # get plain text from src file and store it in buffer
    move $a0, $s7
    la $a1, SRC_TEXT_BUFFER
    li $a2, 500
    li $v0, 14
    syscall

    # throw file read fail exception
    beq $v0, -1, READ_ERROR

    #close the src file
    move $a0, $s7
    li $v0, 16
    syscall

    # jump back to main
    jr $ra

OPEN_ERROR:	 

    la $a0, O_ERROR
    li $v0,4 
    syscall 

    j exit 
    
WRITE_ERROR:  
    
    la $a0, W_ERROR 
    li $v0,4 
    syscall 

    j exit 

READ_ERROR:	
     
    la $a0, R_ERROR 
    li $v0,4
    syscall 

    j exit



exit:   # program terminate
    li $v0, 10		
    syscall