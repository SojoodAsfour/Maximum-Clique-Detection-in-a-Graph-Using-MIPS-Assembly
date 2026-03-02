#Sara Kafena - 1210420 sec 1
#Sojood Nazih Asfour - 1230298 sec 1

# ========================================
# Data Section
# ========================================
.data

# Program Messages
welcomeMessage: 	.asciiz "Welcome to our program (Maximum Clique Detection in a Graph)\n"
fileInput:      	.asciiz "\nEnter the input file name/path please\n"
fileError:      	.asciiz "\nThe file you entered is wrong or invalid!\n"        
outputFileName: 	.asciiz "output.txt"
invalidMatrix:  	.asciiz "\nError: Invalid adjacency matrix format!\n"
matrixValid:    	.asciiz "\nAdjacency matrix is valid!\n"
emptyError:     	.asciiz "\nError: Empty file\n"
invalidError:   	.asciiz "\nError: Invalid matrix format\n"
tooLargeError:  	.asciiz "\nError: Graph from your file is too large!\n"
done:           	.asciiz "Matrix loaded successfully\n"
analysis:       	.asciiz "\n\nAnalyzing matrix............\n\n"
newline:        	.asciiz "\n"

# Character constants for parsing
terminate:      	.byte '\n'
terminate1:     	.byte '\r'
whitespace: 		.byte ' '
newtab: 		.byte '\t'
zeroassci:		.byte '0'
nineassci:		.byte '9'
minusSign:		.byte '-'

# Memory buffers and arrays
.align 2
fileName:       	.space 256
matrixBuff:     	.space 1024      # Smaller buffer for 5x5 matrix
matrix:         	.space 100       # 5x5 adjacency matrix (25 words = 100 bytes)
outputResults:  	.space 2048 
buffer:         	.space 32

# Configuration and counters
MAX_VERTICES:   	.word 5          # Maximum 5 vertices
maxSize:        	.word 0          # size of max clique
numVertices:    	.word 0   
stringLength:   	.word 0

# Maximum clique storage
.align 2
maxClique:      	.space 20        # Array to store vertices in max clique (max 5 vertices)

# Output messages for clique results
cliqueMsg1:     	.asciiz "=== Maximum Clique Detection ===\n"
cliqueMsg2:     	.asciiz "Maximum clique size: "
cliqueMsg3:     	.asciiz "\nVertices in maximum clique: "
space:          	.asciiz " "
noCliqueMsg:    	.asciiz "No clique found (size < 2)\n"
fileSavedMsg:   	.asciiz "\nThe Reults are Printed to the output file.\n"
fileErrorMsg:   	.asciiz "\nError: Could not create output file!\n"


# ========================================
# Text Section - Main Program
# ========================================
.text
.globl main

# ----------------------------------------
# Main function - Program entry point
# ----------------------------------------
main:
	# Print welcome message
	la $a0, welcomeMessage
	li $v0, 4
	syscall

	# Prompt for file name
	la $a0, fileInput
	li $v0, 4
	syscall	

	# Read file name from user
	la $a0, fileName
	li $a1, 256
	li $v0, 8
	syscall
	
	# Clean the input string
	jal cleanString
	
	# Read and validate the file
	jal readFile
	beqz $v0, exit_program    # if readFile failed, exit
	
	# Print buffer for testing
	jal printBuffer
	
	# Analyze the matrix buffer
	jal matrixAnalysis
	beqz $v0, exit_program    # if analysis failed, exit
	
	# Print the parsed matrix
	jal printMatrix
	
	# Find maximum clique
	jal findMaxClique
	
	# Write results to output file
	jal printResultsToFile

exit_program:
	li $v0, 10
	syscall

# ========================================
# String and Input Processing Functions
# ========================================

# ----------------------------------------
# cleanString: Remove newline and carriage return from fileName
# ----------------------------------------
cleanString:
	li $t0, 0

L1:
	lb $t1, fileName($t0)
	beqz $t1, L2 		# end of string
	
	# remove terminate (\n)
	lb $t2, terminate
	beq $t1, $t2, replace
	
	# remove terminate (\r)
	lb $t3, terminate1
	beq $t1, $t3, replace
	
	addi $t0, $t0, 1
	j L1
	
replace:
	sb $zero, fileName($t0)

L2:
	jr $ra

# ========================================
# File Input Functions
# ========================================

# ----------------------------------------
# readFile: Open and read the input file into matrixBuff
# Returns: $v0 = 1 on success, 0 on failure
# ----------------------------------------
readFile:
	# Save return address
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Open file
	la $a0, fileName
	li $a1, 0
	li $v0, 13
	syscall
	bltz $v0, file_not_found
	move $t0, $v0  # save file descriptor

	
	# Read file content
	move $a0, $t0
	la $a1, matrixBuff
	li $a2, 1024
	li $v0, 14
	syscall
	bltz $v0, file_not_found
	beqz $v0, empty_file_error	# If bytes read = 0, file is empty

	# Close file
	move $a0, $t0
	li $v0, 16
	syscall

	# Print success message
	la $a0, done
	li $v0, 4
	syscall
	
	# Restore and return success
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	li $v0, 1               # return success
	jr $ra
	
# ----------------------------------------
# empty_file_error: Handle empty file error
# ----------------------------------------
empty_file_error:
	la $a0, emptyError
	li $v0, 4
	syscall
	
	jal writeErrorToFile
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	li $v0, 0
	jr $ra

# ----------------------------------------
# file_not_found: Handle file not found error
# ----------------------------------------
file_not_found:
	la $a0, fileError
	li $v0, 4
	syscall
	
	jal writeErrorToFile
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	li $v0, 0               # return failure
	jr $ra

# ========================================
# Matrix Analysis Functions
# ========================================

# ----------------------------------------
# matrixAnalysis: Parse the matrix buffer into adjacency matrix
# Returns: $v0 = 1 on success, 0 on failure
# ----------------------------------------
matrixAnalysis:
	addi $sp, $sp, -28
	sw $ra, 24($sp)
	sw $s0, 20($sp)         # buffer pointer
	sw $s1, 16($sp)         # vertex count
	sw $s2, 12($sp)         # row counter
	sw $s3, 8($sp)          # column counter
	sw $s4, 4($sp)          # temp value
	sw $s5, 0($sp)          # saved data start pointer
	
	# Print analysis message
	la $a0, analysis
	li $v0, 4
	syscall
	
	la $s0, matrixBuff
	
	# Skip first line (header with column numbers)
	move $t0, $s0
	
skip_first_line:
	lb $t1, 0($t0)
	beqz $t1, fail_operation
	
	# Check for newline
	lb $t2, terminate
	beq $t1, $t2, found_newline
	
	lb $t2, terminate1
	beq $t1, $t2, found_newline
	
	# Validate only digits, spaces, and tabs are allowed
	lb $t2, whitespace
	beq $t1, $t2, skip_first_valid
	
	lb $t2, newtab
	beq $t1, $t2, skip_first_valid
	
	lb $t2, zeroassci
	blt $t1, $t2, invalid_matrix_format    # Invalid character
	
	lb $t2, nineassci
	bgt $t1, $t2, invalid_matrix_format    # Invalid character
	
skip_first_valid:
	addi $t0, $t0, 1
	j skip_first_line
	
found_newline:
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	
	lb $t2, terminate
	beq $t1, $t2, skip_extra_newline
	
	lb $t2, terminate1
	beq $t1, $t2, skip_extra_newline
	
	j start_counting
	
skip_extra_newline:
	addi $t0, $t0, 1
	
start_counting:
	move $s5, $t0  # Save start position of data rows in $s5
	
	# Count number of data rows
	li $s1, 0      # vertex count
	move $t0, $s5  # Use temporary pointer for counting
	
count_rows:
	lb $t1, 0($t0)
	beqz $t1, done_counting
	
	# Skip whitespace at start
	lb $t2, whitespace
	beq $t1, $t2, count_skip_char
	
	lb $t2, newtab
	beq $t1, $t2, count_skip_char
	
	lb $t2, terminate
	beq $t1, $t2, count_skip_char
	
	lb $t2, terminate1
	beq $t1, $t2, count_skip_char
	
	# Found start of a row - increment count
	addi $s1, $s1, 1
	
	# Skip to end of this row
skip_to_eol:
	lb $t1, 0($t0)
	beqz $t1, done_counting
	
	lb $t2, terminate
	beq $t1, $t2, found_eol
	
	lb $t2, terminate1
	beq $t1, $t2, found_eol
	
	addi $t0, $t0, 1
	j skip_to_eol
	
found_eol:
	addi $t0, $t0, 1
	j count_rows
	
count_skip_char:
	addi $t0, $t0, 1
	j count_rows
	
done_counting:
	# Check if n is valid
	beqz $s1, fail_operation
	la $t0, MAX_VERTICES
	lw $t0, 0($t0)
	bgt $s1, $t0, num_of_vartices_very_large
	
	# Store number of vertices globally
	la $t0, numVertices
	sw $s1, 0($t0)
	
	# IMPORTANT: Reset buffer pointer to start of data ($s5)
	move $s0, $s5
	
	# Parse each row of the adjacency matrix
	li $s2, 0               # row counter = 0
	
row_loop:
	bge $s2, $s1, analysis_success
	
	# Skip row index (first number in line)
	move $a0, $s0
	jal skip_number
	move $s0, $v0
	
	# Read vertices values for this row
	li $s3, 0               # col count = 0

col_loop:
	bge $s3, $s1, check_row_end
	
	# Check if next character is a digit before parsing
	move $t9, $s0
	
skip_ws_before_num:
	lb $t8, 0($t9)
	lb $t7, whitespace
	beq $t8, $t7, skip_ws_next
	lb $t7, newtab
	beq $t8, $t7, skip_ws_next
	j check_digit
	
skip_ws_next:
	addi $t9, $t9, 1
	j skip_ws_before_num
	
check_digit:
	lb $t7, zeroassci
	blt $t8, $t7, invalid_matrix_format
	lb $t7, nineassci
	bgt $t8, $t7, invalid_matrix_format
	
	# Parse next number	
	move $a0, $s0
	jal num_analysis
	move $s4, $v0 		# value
	move $s0, $v1		# update pointer

	# Validate value is 0 or 1
	bltz $s4, invalid_matrix_value
	bgt $s4, 1, invalid_matrix_value
	
	# Store in matrix[i][j]
	# &matrix[i][j] = &matrix + (i * COLS + j) * Element_size
	# offset = (row * MAX_VERTICES + col) * 4
	la $t0, MAX_VERTICES
	lw $t0, 0($t0)
	mul $t1, $t0, $s2
	add $t1, $t1, $s3
	sll $t1, $t1, 2
	la $t2, matrix
	add $t2, $t2, $t1
	sw $s4, 0($t2)
	
	addi $s3, $s3, 1        # col++
	j col_loop

check_row_end:
	# Check if there are extra numbers in this row
	move $t0, $s0
	
skip_spaces_check:
	lb $t1, 0($t0)
	beqz $t1, next_row
	
	# Check for newline
	lb $t2, terminate
	beq $t1, $t2, next_row
	
	lb $t2, terminate1
	beq $t1, $t2, next_row
	
	# Check for space/tab
	lb $t2, whitespace
	beq $t1, $t2, skip_spaces_check_next
	
	lb $t2, newtab
	beq $t1, $t2, skip_spaces_check_next
	
	# Check if it's a digit (extra number = error!)
	la $t2, zeroassci
	lb $t2, 0($t2)
	blt $t1, $t2, next_row
	
	la $t2, nineassci
	lb $t2, 0($t2)
	bgt $t1, $t2, next_row
	
	# Found extra number - invalid!
	j invalid_matrix_format

skip_spaces_check_next:
	addi $t0, $t0, 1
	j skip_spaces_check
	
next_row:
	addi $s2, $s2, 1        # row++
	j row_loop

# ----------------------------------------
# Analysis result handlers
# ----------------------------------------
analysis_success:
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28
	li $v0, 1
	jr $ra

invalid_matrix_value:
	la $a0, invalidMatrix
	li $v0, 4
	syscall
	
	jal writeErrorToFile
	
	j fail_operation

invalid_matrix_format:
	la $a0, invalidError
	li $v0, 4
	syscall
	
	jal writeErrorToFile
	
	j fail_operation
	
num_of_vartices_very_large:
	la $a0, tooLargeError
	li $v0, 4
	syscall
	
	jal writeErrorToFile
	
	j fail_operation
	
fail_operation:
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28
	li $v0, 0
	jr $ra
	
# ========================================
# Parsing Helper Functions
# ========================================

# ----------------------------------------
# countVertices: Count numbers in first line
# $a0 = buffer pointer
# Returns: $v0 = count, $v1 = pointer to next line
# ----------------------------------------
countVertices:
	li $v0, 0        # count = 0
	move $t0, $a0    # current position 

count_loop:
	lb $t1, 0($t0)   # load char
	beqz $t1, count_done

	# end of line?
	la $t2, terminate
	lb $t2, 0($t2)
	beq $t1, $t2, count_done

	la $t2, terminate1
	lb $t2, 0($t2)
	beq $t1, $t2, count_done

	# skip space
	la $t2, whitespace
	lb $t2, 0($t2)
	beq $t1, $t2, skip_count

	# skip tab
	la $t2, newtab
	lb $t2, 0($t2)
	beq $t1, $t2, skip_count

	# check if digit
	la $t2, zeroassci
	lb $t2, 0($t2)
	blt $t1, $t2, skip_count

	la $t2, nineassci
	lb $t2, 0($t2)
	bgt $t1, $t2, skip_count

	# found a number
	addi $v0, $v0, 1

skip_number_loop:
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	beqz $t1, count_done

	la $t2, terminate
	lb $t2, 0($t2)
	beq $t1, $t2, count_done

	la $t2, terminate1
	lb $t2, 0($t2)
	beq $t1, $t2, count_done

	# skip space/tab
	la $t2, whitespace
	lb $t2, 0($t2)
	beq $t1, $t2, count_loop

	la $t2, newtab
	lb $t2, 0($t2)
	beq $t1, $t2, count_loop

	j skip_number_loop

skip_count:
	addi $t0, $t0, 1
	j count_loop

count_done:
	# move to next line
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	la $t2, terminate
	lb $t2, 0($t2)
	beq $t1, $t2, count_skip_lf

	la $t2, terminate1
	lb $t2, 0($t2)
	beq $t1, $t2, count_skip_lf

	j count_set_return

count_skip_lf:
	addi $t0, $t0, 1

count_set_return:
	move $v1, $t0
	jr $ra
		
#----------------------------------------
# skip_number: Skip past a number and whitespace
# $a0 = buffer pointer
# Returns: $v0 = pointer after number
#---------------------------------------------------------
skip_number:
	move $t0, $a0
	# Skip leading whitespace
	
	# Skip leading whitespace
skip_whitespace1:
	lb $t1, 0($t0)
	beqz $t1, skip_done
	
	la $t2, whitespace 
	lb $t2, 0($t2)
	beq $t1, $t2, skip_whitespace1_next
	
	la $t2, newtab    
	lb $t2, 0($t2)
	beq $t1, $t2, skip_whitespace1_next
	
	la $t2, terminate
	lb $t2, 0($t2) 
	beq $t1, $t2, skip_whitespace1_next
	
	la $t2, terminate1   
	lb $t2, 0($t2) 
	beq $t1, $t2, skip_whitespace1_next
	
	j skip_digits
	
skip_whitespace1_next:
	addi $t0, $t0, 1
	j skip_whitespace1
	
skip_digits:
	lb $t1, 0($t0)
	beqz $t1, skip_done
	
	la $t2, zeroassci    
	lb $t2, 0($t2)
	blt $t1, $t2, skip_whitespace2
	
	la $t2, nineassci    
	lb $t2, 0($t2)
	bgt $t1, $t2, skip_whitespace2
	
	addi $t0, $t0, 1
	j skip_digits
	
skip_whitespace2:
	lb $t1, 0($t0)
	beqz $t1, skip_done
	
	la $t2, whitespace 
	lb $t2, 0($t2)
	beq $t1, $t2, skip_whitespace2_next
	
	la $t2, newtab    
	lb $t2, 0($t2)
	beq $t1, $t2, skip_whitespace2_next
	
	j skip_done 

skip_whitespace2_next:
	addi $t0, $t0, 1
	j skip_whitespace2	
	
skip_done:
	move $v0, $t0
	jr $ra	
	
#----------------------------------------
# analyse_number: Parse next integer from buffer
# $a0 = buffer pointer
# Returns: $v0 = parsed integer, $v1 = pointer after number
#------------------------------------------
num_analysis:
	move $t0, $a0
	li $v0, 0               # result = 0
	li $t3, 0               # negative flag
	
	# Skip leading whitespace
skip_wh:
	lb $t1, 0($t0)
	beqz $t1, analyse_done
	
	la $t2, whitespace 
	lb $t2, 0($t2)
	beq $t1, $t2, skip_wh_next
	
	la $t2, newtab    
	lb $t2, 0($t2)
	beq $t1, $t2, skip_wh_next
	
	la $t2, terminate
	lb $t2, 0($t2) 
	beq $t1, $t2, skip_wh_next
	
	la $t2, terminate1   
	lb $t2, 0($t2) 
	beq $t1, $t2, skip_wh_next
	
	j check_sign
	
skip_wh_next:
	addi $t0, $t0, 1
	j skip_wh
	
check_sign:
	lb $t1, 0($t0)	
	la $t2, minusSign   
	lb $t2, 0($t2)
	
	bne $t1, $t2, parse_digits
	li $t3, 1               # set negative flag
	addi $t0, $t0, 1
	
parse_digits:
	lb $t1, 0($t0)
	beqz $t1, apply_sign
	
	# Check if digit
	lb $t1, 0($t0)	
	la $t2, zeroassci
	lb $t2, 0($t2)
	blt $t1, $t2, apply_sign
	
	lb $t1, 0($t0)	
	la $t2, nineassci
	lb $t2, 0($t2)
	bgt $t1, $t2, apply_sign
	
	# result = result * 10 + (char - '0')
	li $t4, 10
	mul $v0, $v0, $t4
	la $t2, zeroassci
	lb $t2, 0($t2)
	sub $t1, $t1, $t2
	add $v0, $v0, $t1
	
	addi $t0, $t0, 1
	j parse_digits

apply_sign:
	beqz $t3, analyse_done
	sub $v0, $zero, $v0

analyse_done:
	move $v1, $t0
	jr $ra
	
# ========================================
# Display Functions
# ========================================

# ----------------------------------------
# printBuffer: Print the raw matrix buffer
# ----------------------------------------
printBuffer:
	la $t0, matrixBuff
	
print_loop:
	lb $t1, 0($t0)
	beqz $t1, print_done
	li $v0, 11
	move $a0, $t1
	syscall
	addi $t0, $t0, 1
	j print_loop
	
print_done:
	jr $ra
	
# ----------------------------------------
# printMatrix: Print the parsed adjacency matrix
# ----------------------------------------
printMatrix:
	lw $t0, numVertices    
	li $t1, 0              

print_row:
	bge $t1, $t0, printdone
	li $t2, 0              

print_col:
	bge $t2, $t0, nextRow
	
	# Calculate matrix[i][j] address
	la $t3, MAX_VERTICES
	lw $t3, 0($t3)
	mul $t4, $t1, $t3
	add $t4, $t4, $t2
	sll $t4, $t4, 2
	la $t5, matrix
	add $t5, $t5, $t4
	lw $a0, 0($t5)
	
	# Print value
	li $v0, 1
	syscall

	# Print space
	li $a0, 32
	li $v0, 11
	syscall

	addi $t2, $t2, 1
	j print_col

nextRow:
	# Print newline
	li $a0, 10
	li $v0, 11
	syscall

	addi $t1, $t1, 1
	j print_row

printdone:
	jr $ra


#==========================================
# MAXIMUM CLIQUE DETECTION ALGORITHM
#==========================================

#----------------------------------------
# findMaxClique: Find maximum clique using brute force
# Checks all possible subsets and finds largest clique
#----------------------------------------
findMaxClique:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # current subset (bit mask)
    sw $s1, 8($sp)          # max possible subset value (2^n)
    sw $s2, 4($sp)          # numVertices
    sw $s3, 0($sp)          # current clique size
    
    # Initialize maxSize to 0
    la $t0, maxSize
    sw $zero, 0($t0)
    
    # Load number of vertices
    lw $s2, numVertices
    
    # Calculate 2^n using loop
    li $s1, 1
    li $t0, 0
    
power_loop:
    bge $t0, $s2, power_done
    sll $s1, $s1, 1
    addi $t0, $t0, 1
    j power_loop
    
power_done:
    # Try all subsets from 0 to 2^n - 1
    li $s0, 0               # current subset = 0
    
subset_loop:
    bge $s0, $s1, find_done # if subset >= 2^n, done
    
    # Check if current subset is a clique
    move $a0, $s0           # subset bit mask
    jal isClique
    
    beqz $v0, next_subset   # if not clique, skip
    
    # Count size of this clique
    move $a0, $s0
    jal countBits
    move $s3, $v0           # size of current clique
    
    # Check if this is larger than current max
    la $t0, maxSize
    lw $t1, 0($t0)
    ble $s3, $t1, next_subset  # if not larger, skip
    
    # New maximum found! Update maxSize and maxClique
    sw $s3, 0($t0)
    
    # Store vertices of this clique
    move $a0, $s0
    la $a1, maxClique
    jal storeClique
    
next_subset:
    addi $s0, $s0, 1
    j subset_loop
    
find_done:
    lw $ra, 16($sp)
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $s2, 4($sp)
    lw $s3, 0($sp)
    addi $sp, $sp, 20
    jr $ra

#----------------------------------------
# isClique: Check if a subset forms a clique
# $a0 = subset (bit mask)
# Returns: $v0 = 1 if clique, 0 otherwise
#----------------------------------------
isClique:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # subset
    sw $s1, 8($sp)          # vertex i
    sw $s2, 4($sp)          # vertex j
    sw $s3, 0($sp)          # numVertices
    
    move $s0, $a0
    lw $s3, numVertices
    
    # If subset has less than 2 vertices, not a valid clique
    move $a0, $s0
    jal countBits
    blt $v0, 2, is_clique_no
    
    # Check all pairs of vertices in subset
    li $s1, 0               # i = 0
    
check_i:
    bge $s1, $s3, is_clique_yes
    
    # Check if vertex i is in subset
    li $t0, 1
    sllv $t0, $t0, $s1      # $t0 = 1 << i
    and $t1, $s0, $t0
    beqz $t1, next_i        # if vertex i not in subset, skip
    
    # Vertex i is in subset, check against all j > i
    addi $s2, $s1, 1        # j = i + 1
    
check_j:
    bge $s2, $s3, next_i
    
    # Check if vertex j is in subset
    li $t0, 1
    sllv $t0, $t0, $s2      # $t0 = 1 << j
    and $t1, $s0, $t0
    beqz $t1, next_j        # if vertex j not in subset, skip
    
    # Both i and j are in subset - check if edge exists
    move $a0, $s1           # vertex i
    move $a1, $s2           # vertex j
    jal hasEdge
    beqz $v0, is_clique_no  # if no edge, not a clique
    
next_j:
    addi $s2, $s2, 1
    j check_j
    
next_i:
    addi $s1, $s1, 1
    j check_i
    
is_clique_yes:
    li $v0, 1
    j isClique_done
    
is_clique_no:
    li $v0, 0
    
isClique_done:
    lw $ra, 16($sp)
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $s2, 4($sp)
    lw $s3, 0($sp)
    addi $sp, $sp, 20
    jr $ra

#----------------------------------------
# hasEdge: Check if edge exists between two vertices (in both directions)
# $a0 = vertex i
# $a1 = vertex j
# Returns: $v0 = 1 if edge exists in both directions, 0 otherwise
#----------------------------------------
hasEdge:

    # Save registers
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    # Check matrix[i][j]
    la $t0, MAX_VERTICES
    lw $t0, 0($t0)
    mul $t1, $a0, $t0       # i * MAX_VERTICES
    add $t1, $t1, $a1       # + j
    sll $t1, $t1, 2         # * 4
    la $t2, matrix
    add $t2, $t2, $t1
    lw $t3, 0($t2)          # load matrix[i][j]
    
    beqz $t3, hasEdge_no    # if matrix[i][j] = 0, no edge
    
    # Check matrix[j][i]
    la $t0, MAX_VERTICES
    lw $t0, 0($t0)
    mul $t1, $a1, $t0       # j * MAX_VERTICES
    add $t1, $t1, $a0       # + i
    sll $t1, $t1, 2         # * 4
    la $t2, matrix
    add $t2, $t2, $t1
    lw $t4, 0($t2)          # load matrix[j][i]
    
    beqz $t4, hasEdge_no    # if matrix[j][i] = 0, no edge
    
    # Both directions have edge
    li $v0, 1
    j hasEdge_done
    
hasEdge_no:
    li $v0, 0
    
hasEdge_done:
    lw $t0, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#----------------------------------------
# countBits: Count number of 1-bits in mask
# $a0 = bit mask
# Returns: $v0 = count
#----------------------------------------
countBits:
    li $v0, 0               # count = 0
    move $t0, $a0           # copy mask
    
count_bits_loop:
    beqz $t0, count_bits_done
    andi $t1, $t0, 1        # check last bit
    add $v0, $v0, $t1       # add to count
    srl $t0, $t0, 1         # shift right
    j count_bits_loop
    
count_bits_done:
    jr $ra

#----------------------------------------
# storeClique: Store vertices from bit mask into array
# $a0 = subset (bit mask)
# $a1 = array address
#----------------------------------------
storeClique:
    move $t0, $a0           # subset
    move $t1, $a1           # array address
    lw $t2, numVertices
    li $t3, 0               # vertex index
    
store_clique_loop:
    bge $t3, $t2, store_clique_done
    
    # Check if vertex is in subset
    li $t4, 1
    sllv $t4, $t4, $t3      # 1 << vertex
    and $t5, $t0, $t4
    beqz $t5, store_clique_next    # if not in subset, skip
    
    # Store vertex in array
    sw $t3, 0($t1)
    addi $t1, $t1, 4
    
store_clique_next:
    addi $t3, $t3, 1
    j store_clique_loop
    
store_clique_done:
    jr $ra
    
#----------------------------------------
#Print maximum clique results on output.txt
#----------------------------------------

#----------------------------------------
# int_to_string: Convert integer to string
# Input: $s0 = integer value
# Uses: $t7 = current position in outputResults
#----------------------------------------

int_to_string:

	la $s1, buffer		# Load address of temporary buffer
	li $s2, 10		# Set divisor to 10 for decimal conversion
	move $t8, $zero		# counter 

	# Check if number is negative, positive, or 0
	blt $s0, 0, negative_num	# Branch if negative
	bgt $s0, 0, positive_num	# Branch if positive
	
	# Check if zero
	li $t9, '0'			# Load ASCII code for '0'
	sb $t9, outputResults($t7)	# Store '0' character in output
	addi $t7, $t7, 1		# Increment output position
	jr $ra				
    	
negative_num:
	
	#for nigative number add "-" sign
	li $t9, '-'			# Load ASCII code for minus sign
	sb $t9, outputResults($t7)	# Store '-' in output
	addi $t7, $t7, 1		# Increment output position
	li $t9, -1			# Load -1 to convert to positive
	mul $s0, $s0, $t9		# Make number positive
    	
positive_num:
	# Extract digits by repeated division by 10
	divu $s0, $s0, $s2		# Divide number by 10
	mflo $s3			# quotient
	mfhi $s4			# remainder
	addiu $s4, $s4, 48		# convert digit to ASCII
	addiu $t8, $t8, 1		# Increment digit counter
	sb $s4, 0($s1)			# Store digit in buffer
	addiu $s1, $s1, 1		# move to next buffer position
	bnez $s3, positive_num		# Continue if quotient is not zero

	# Reverse digits (they were extracted in reverse order)
	subi $t8, $t8, 1		# Set counter to last digit index
	
reverse_digits_loop:
	lb $s2, buffer($t8)		# Load digit from buffer 
	sb $s2, outputResults($t7)	# Store digit in output
	addiu $t7, $t7, 1		# Move output position forward
	subi $t8, $t8, 1		# Move buffer position backward
	bgez $t8, reverse_digits_loop	# Continue while counter >= 0
	jr $ra		
 
#----------------------------------------
# add_string: Add string to outputResults
# Input: $a0 = string address
# Uses: $t7 = current position
#----------------------------------------

add_string:
	move $t0, $a0		# source -> copy string address to $t0
	
add_str_loop:
	lb $t1, 0($t0)			# Load current character from source
	beqz $t1, add_str_done		# Exit if null terminator found
	sb $t1, outputResults($t7)	# Store character in output buffer
	addi $t0, $t0, 1		# move to next source character
	addi $t7, $t7, 1		# move to next output position
	j add_str_loop			# Continue loop
	
add_str_done: 
	jr $ra	
    	   	
#----------------------------------------
# result_to_string: Build complete results string
#----------------------------------------

result_to_string:
	# Save return address on stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $t7, $zero		# initialize output position to zero
	
	# Check if a valid clique exists (size >= 2)
	lw $t0, maxSize
	blt $t0, 2, add_no_clique	# If size < 2, no clique found
    	
    	# Add header
	la $a0, cliqueMsg1		
	jal add_string			
	
	# add "Maximum clique size: " (size label)
	la $a0, cliqueMsg2		
	jal add_string			
	
    	# add the size number
    	lw $s0, maxSize			
	jal int_to_string		
    	
    	#add new line
    	li $t1, '\n'			
	sb $t1, outputResults($t7)	
	addi $t7, $t7, 1		
	
    	# Add vertices label "Vertices in maximum clique: "
    	la $a0, cliqueMsg3		
	jal add_string			
    	
    	# add vertices
    	lw $t0, maxSize		# number of vertices 
    	la $t1, maxClique	# array address 
    	li $t2, 0		#counter 
    	
add_vertices_loop:
	bge $t2, $t0, string_done	# Exit if all vertices printed
	
	lw $s0, 0($t1)			# Load current vertex number
	jal int_to_string		# Convert and add to output
	
	#add space
	li $t3, ' '			# Load space character
	sb $t3, outputResults($t7)	# Store space after vertex
	addi $t7, $t7, 1		# Increment position
	
	addi $t1, $t1, 4		# Move to next vertex (4 bytes)
	addi $t2, $t2, 1		# Increment counter
	
	j add_vertices_loop		# Continue loop
	
add_no_clique:
	# No valid clique found
	la $a0, noCliqueMsg		
	jal add_string			
	
string_done:
	#add final new line
	li $t1, '\n'			
	sb $t1, outputResults($t7)	
	addi $t7, $t7, 1		
	
	#add null terminator
	sb $zero, outputResults($t7)	# Store null terminator
	
	# Save length
	sw $t7, stringLength		# Store total length of output string
	
	# Restore return address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#----------------------------------------
# printResultsToFile: Write results to file
#----------------------------------------

printResultsToFile:
	# Save return address on stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# Build the results string
	jal result_to_string		# Create complete output string
	
	# Get length
	lw $s0, stringLength		# Load length of string to write
	
	# Open file for writing
	la $a0, outputFileName		# Load output filename
	li $a1, 1			#write mode
	li $a2, 0
	li $v0, 13			
	syscall				
	
	bltz $v0, file_error_handler	# Check if file open failed
	move $t9, $v0			
	
	#write to the file
	move $a0, $t9			# file descriptor 
	la $a1, outputResults 		#string to write ( load output buffer)
	move $a2, $s0			# Length of string to write
	li $v0, 15			
	syscall				
	
	#close file
	move $a0, $t9			# Set file descriptor
	li $v0, 16			
	syscall				# Close the file
	
	#print sucess masseage
	la $a0, fileSavedMsg		
	li $v0, 4			
	syscall				
	
	# Restore return address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
		
file_error_handler:
	# Handle file open error
	la $a0, fileErrorMsg		
	li $v0, 4			
	syscall				
	
	# Restore return address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#----------------------------------------
# writeErrorToFile: Write error message to output file
# Assumes error message is already in $a0
#----------------------------------------

writeErrorToFile:
	# Save registers on stack
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)

	move $s1, $a0		# Save error message address
	
	# Calculate string length
	move $t0, $s1			# Copy message address
	li $t1, 0			# Initialize length counter
	
str_loop:
	lb $t2, 0($t0)			# Load current character
	beqz $t2, str_done		# Exit if null terminator
	addi $t1, $t1, 1		# Increment length
	addi $t0, $t0, 1		# Move to next character
	j str_loop			# Continue counting

str_done:	
	move $s0, $t1		# Save length in $s0
	
	# Open output file for writing
	la $a0, outputFileName		
	li $a1, 1			
	li $a2, 0			
	li $v0, 13			
	syscall				# Open file
	
	bltz $v0, write_error_done	# If file open failed, skip
	move $t9, $v0			# Save file descriptor
	
	#write errormessege to the file
	move $a0, $t9			# Set file descriptor
	move $a1, $s1 			#error massege
	move $a2, $s0			#length 
	li $v0, 15			
	syscall				# Write to file
	
	# Close file
	move $a0, $t9			
	li $v0, 16			
	syscall				# Close file
	
write_error_done:
	# Restore registers and return
	lw $ra, 8($sp)
	lw $s0, 4($sp)
	lw $s1, 0($sp)
	addi $sp, $sp, 12
	jr $ra
	
	
#----------------------------------------
# printResults: Print maximum clique results on terminal
#----------------------------------------
printResults:
    # Save return address on stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Print header
    la $a0, cliqueMsg1		
    li $v0, 4			
    syscall			
    
    # Check if we found a clique
    lw $t0, maxSize		
    blt $t0, 2, print_no_clique	# If size < 2, no valid clique
    
    # Print clique size
    la $a0, cliqueMsg2		
    li $v0, 4			
    syscall			
    
    lw $a0, maxSize		
    li $v0, 1			
    syscall			
    
    # Print vertices
    la $a0, cliqueMsg3		
    li $v0, 4			
    syscall			
    
    # Print each vertex in maxClique array
    lw $t0, maxSize         	# number of vertices to print
    la $t1, maxClique       	# array address
    li $t2, 0               	# counter 
    
print_vertex_loop:
    bge $t2, $t0, print_results_done	# Exit if all vertices printed
    
    # Load and print vertex
    lw $a0, 0($t1)		
    li $v0, 1			
    syscall			
    
    # Print space
    la $a0, space		
    li $v0, 4	
    syscall			
    
    addi $t1, $t1, 4        	
    addi $t2, $t2, 1        	
    j print_vertex_loop     	
    
print_no_clique:
    # No valid clique found
    la $a0, noCliqueMsg		
    li $v0, 4			
    syscall			
    
print_results_done:
    # Print newline
    la $a0, newline		
    li $v0, 4			
    syscall			
    
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
