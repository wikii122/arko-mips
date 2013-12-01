#####################################
# Wiktor Ślęczka
# Projekt MIPS
# Program counting Hamming's distance between two bitmaps, with intershifts.
# Bitmap specification - 64x64, 1bit.
#####################################
        .data
        .align	2
file1:		.space	600
file2:		.space	600

array:		.space 	900
prints:		.space	1200
minimum:	.space	4

filesize: 	.word		574

mask1:	.word	0x55555555		#01010101010101010101010101010101
mask2:	.word	0x33333333		#00110011001100110011001100110011
mask3:	.word	0xF0F0F0F		#00001111000011110000111100001111
mask4:	.word	0xFF00FF		#00000000111111110000000011111111
mask5:	.word	0xFFFF		#00000000000000001111111111111111

mask_hamming:	.word	0xFF00	#00000000000000001111111100000000
mask_byte:		.word	0xFF		#00000000000000000000000011111111

fail:		.asciiz		"[!]Failed to open file"
path1:   	.asciiz 	"obraz1.bmp"
path2: 	.asciiz 	"obraz2.bmp"

res1:		.asciiz		"hamming.txt"
res2:		.asciiz		"tablica.txt"
done:		.asciiz		"Done!"
        	.text
        	.globl  main
main:
	la	$a0	path1				# Load address of filename
	la	$a1	file1				# Load address of space for file
	lw	$a2	filesize			# Load size of read file
	jal	read_file				# Load file to specified memory address
	
	la	$a0	path2				# Load address of filename
	la	$a1	file2				# Load address of space for file
	lw	$a2	filesize			# Load size of read file
	jal	read_file				# Load file to specified memory address

	la	$a0	file1				# Load address of first file
	la	$a1	file2				# Load address of second file
	addiu	$a0	$a0	62			# Move to the interesting part of first file
	addiu	$a1	$a1	62			# Move to the interesting part of second file
	jal	counter_main			# Start counting
	la	$a0	array				# Array address for minimal
	li	$a1	225				# Size for minimal
	jal	minimal				# Find minimal hammings distance
	sw	$v0	minimum			# Save minimal value
	# Argument remain the same
	la	$a0	array
	li	$a1	225
	la	$a2	res2
	jal	save					# Save to file
	la	$a0	minimum
	li	$a1	1
	la	$a2	res1		
	jal	save					# Save minimal to file
	

	li	$v0	4				# Command to print
	la	$a0	done				# String to be printed
	syscall
exit:
	li 	$v0	10				# Load exit command
	syscall					# Exit
	
##########################	Population counter - $a0	- target,
popcount:
	move	$t1	$a0		# Load word to register
	lw	$t0	mask1	# Load first mask
	srl	$t2	$t1	1	# Bit shift one right
	and	$t3	$t0	$t1	# Apply mask
	and	$t4	$t0	$t2	# Apply mask to shifted
	addu	$t1	$t3	$t4	# Add results of applied masks
	lw	$t0	mask2	# Load second mask
	srl	$t2	$t1	2	# Bitshift by two right
	and	$t3	$t0	$t1	# Apply mask 
	and	$t4	$t0	$t2	# Apply mask to shifted
	addu	$t1	$t3	$t4	# Add results of applied masks
	lw	$t0	mask3	# Load third mask
	srl	$t2	$t1	4	# Bitshift by 4 right
	and	$t3	$t0	$t1	# Apply mask
	and	$t4	$t0	$t2	# Apply mask to shifted
	addu	$t1	$t3	$t4	# Add results of applied masks
	lw	$t0	mask4	# Load fourth mask
	srl	$t2	$t1	8	# Bitshift by 8 right
	and	$t3	$t0	$t1	# Apply mask
	and	$t4	$t0	$t2	# Apply mask o shifted
	addu	$t1	$t3	$t4	# Add results of applied masks
	lw	$t0	mask5	# Load fifth mask
	srl	$t2	$t1	16	# Bitshift by 16 right
	and	$t3	$t0	$t1	# Apply mask
	and 	$t4	$t0	$t2	# Apply mask to shifted
	addu	$t1	$t3	$t4	# Add results off applied masks
	move	$v0	$t1		# Move result to $v0
	jr	$ra			# Return
	
#############################	READ FILE TO MEMORY - a0 - file name; a1 - memory address; a2 - size
read_file:
	move	$t1	$a1				#save register a1
	move	$t2	$a2				#save register a2
	move	$t0	$a0
	
	li	$v0 	13				#load open file address
	move	$a0	$t0
	li	$a1	0				# flag read
	li	$a2	0				# r--r--r-- mode
	syscall					# file descriptor at $v0
	move	$a0	$v0				# Move file descriptor to $a0
	
	beq	$a0	-1	failed			# if file was not read, exit
	
	li	$v0	14				# file read command
	la 	$a1	($t1)				# memory buffer
	move	$a2	$t2				# size to be read
	syscall					# Read the file
	beq 	$zero	$v0 	failed			# If no data was read, exit
	li 	$v0 	16   				#system call for file_close 
	# File descriptor at $a0
	syscall 
	
	jr	$ra					# Return jump
	
failed:
	li	$v0	4				# Command to print
	la	$a0	fail				# String to be printed
	syscall
	j	exit

############################# Counter count hamming's distance
counter_main:
# Prologue
	addi	$sp 	$sp 	-32			# Move stack pointer
	sw   	$s0 	($sp)				# Push to stack
	sw   	$s1 	4($sp)			
	sw   	$s2 	8($sp)			
	sw   	$s3 	12($sp)		
	sw   	$s4 	16($sp)			
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$ra	28($sp)		
	
	li	$s2	64				# Load loop counter for rows (columns to be specific, as bmp has top-bottom structure) +1
	move	$s0	$a0				# Copy address of file 1
	move	$s1	$a1				# Copy address of file 2
counter_loop1:
	move	$a0	$s0				# Move address of file1
	move	$a1	$s1				# Move address of file2
	la	$a2	array				# Load array address
	addiu $s0	$s0	8			# Move to next line
	addiu	$s1	$s1	8
	jal	counter_vertical
	addiu	$s2	$s2	-1			# Decrement loop counter
	bnez	$s2	counter_loop1		# Finish if loop1 counter == 0
# Epilogue	
	lw   	$s0 	($sp)				# Pop to stack
	lw   	$s1 	4($sp)			
	lw   	$s2 	8($sp)			
	lw   	$s3 	12($sp)			
	lw   	$s4 	16($sp)
	lw	$s5	20($sp)	
	lw	$s6	24($sp)	
	lw	$ra	28($sp)			
	addi	$sp 	$sp 	32			# Move stack pointer
	jr	$ra					# Return
	
counter_vertical:
	addi	$sp 	$sp 	-32			# Move stack pointer
	sw   	$s0 	($sp)				# Push to stack
	sw   	$s1 	4($sp)			
	sw   	$s2 	8($sp)			
	sw   	$s3 	12($sp)		
	sw   	$s4 	16($sp)			
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$ra	28($sp)

	addiu	$s0	$a0	-56			# Set file1 start at -7 lines
	move	$s1	$a1				# file2
	move	$s2	$a2				# array
	li	$s3	15				# Set loop counter
	la	$s4	file1
	addiu	$s4	$s4	61
	addiu	$s5	$s4	512
cv_loop:
	blt	$s0	$s4	cv_continue		# Continue
	bgt	$s0	$s5	cv_continue		
	move	$a0	$s0				# Set arguments
	move	$a1	$s1
	move	$a2	$s2
	jal	counter_row
cv_continue:
	addiu	$s0	$s0	8			# Move to next row
	addiu	$s2	$s2	60			# Move to next line result position
	addiu	$s3	$s3	-1			# Decrement loop counter
	bnez	$s3	cv_loop			# Continue
	
	lw   	$s0 	($sp)				# Pop to stack
	lw   	$s1 	4($sp)			
	lw   	$s2 	8($sp)			
	lw   	$s3 	12($sp)			
	lw   	$s4 	16($sp)
	lw	$s5	20($sp)	
	lw	$s6	24($sp)	
	lw	$ra	28($sp)			
	addi	$sp 	$sp 	32			# Move stack pointer
	jr	$ra
	
counter_row:
	addi	$sp 	$sp 	-32			# Move stack pointer
	sw   	$s0 	($sp)				# Push to stack
	sw   	$s1 	4($sp)			
	sw   	$s2 	8($sp)			
	sw   	$s3 	12($sp)		
	sw   	$s4 	16($sp)			
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$ra	28($sp)
	
	move	$s0	$a0				# Move argument
	move	$s1	$a1
	move	$s2	$a2
	li	$s3	7				# Set loop counter
cr_loop:
	move	$a0	$s0				# Load arguments
	move	$a1	$s1
	move	$a2	$s2
	jal	counter_byte
	addiu	$s0	$s0	1			# Next byte
	addiu	$s1	$s1	1
	addiu	$s3	$s3	-1			# Decrement loop counter
	bnez	$s3	cr_loop

	move	$a0	$s0				# Load arguments
	move	$a1	$s1
	move	$a2	$s2
	jal	counter_last_byte

	lw   	$s0 	($sp)				# Pop to stack
	lw   	$s1 	4($sp)			
	lw   	$s2 	8($sp)			
	lw   	$s3 	12($sp)			
	lw   	$s4 	16($sp)
	lw	$s5	20($sp)	
	lw	$s6	24($sp)	
	lw	$ra	28($sp)			
	addi	$sp 	$sp 	32			# Move stack pointer
	jr	$ra
counter_byte:
	addi	$sp 	$sp 	-32			# Move stack pointer
	sw   	$s0 	($sp)				# Push to stack
	sw   	$s1 	4($sp)			
	sw   	$s2 	8($sp)			
	sw   	$s3 	12($sp)		
	sw   	$s4 	16($sp)			
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$ra	28($sp)
	
	lw	$s6	mask_byte
	lb	$s0	($a0)				# Load given halfword, 
	and	$s0	$s0	$s6			# as two bytes, in reversed order,
	sll	$s0	$s0	8
	lb	$s1	($a1)				
	and	$s1	$s1	$s6			
	sll	$s1	$s1	8
	move	$s2	$a2				# Use of byte mask is required to 
	addiu	$a0	$a0	1			# workaround JVM bug, 
	addiu	$a1	$a1	1
	lb	$t0	($a0)
	and	$t0	$t0	$s6
	addu	$s0	$s0	$t0
	lb	$t0	($a1)
	and	$t0	$t0	$s6
	addu	$s1	$s1	$t0
	sll	$s0	$s0	8			# Initial movement
	li	$s3	8				# Set loop counter
	lw	$s4	mask_hamming
cb_loop1:
	srl	$s0	$s0	1			# Move one bit right
	move	$t0	$s0
	move	$t1	$s1
	and	$t0	$t0	$s4
	and	$t1	$t1	$s4
	xor	$a0	$t0	$t1			# Show different bits
	jal	popcount
	lw	$t4	($s2)				# Load prevoisly saved result
	addu	$t4	$t4	$v0			# Add result from popcount
	sw	$t4	($s2)
	addiu	$s2	$s2	4			# Move to next result
	addiu	$s3	$s3	-1			# Decrement loop counter
	bnez	$s3	cb_loop1
	li	$s3	7
cb_loop2:
	sll	$s1	$s1	1			# Move one bit right
	move	$t0	$s0
	move	$t1	$s1
	and	$t0	$t0	$s4
	and	$t1	$t1	$s4
	xor	$a0	$t0	$t1			# Show different bits
	jal	popcount
	lw	$t4	($s2)				# Load prevoisly saved result
	addu	$t4	$t4	$v0			# Add result from popcount
	sw	$t4	($s2)
	addiu	$s2	$s2	4			# Move to next result
	addiu	$s3	$s3	-1			# Decrement loop counter
	bnez	$s3	cb_loop2
	
	lw   	$s0 	($sp)				# Pop to stack
	lw   	$s1 	4($sp)			
	lw   	$s2 	8($sp)			
	lw   	$s3 	12($sp)			
	lw   	$s4 	16($sp)
	lw	$s5	20($sp)	
	lw	$s6	24($sp)	
	lw	$ra	28($sp)			
	addi	$sp 	$sp 	32			# Move stack pointer
	jr	$ra
counter_last_byte:
	addi	$sp 	$sp 	-32			# Move stack pointer
	sw   	$s0 	($sp)				# Push to stack
	sw   	$s1 	4($sp)			
	sw   	$s2 	8($sp)			
	sw   	$s3 	12($sp)		
	sw   	$s4 	16($sp)			
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$ra	28($sp)
	
	lw	$s6	mask_byte
	lb	$s0	($a0)				# Load bytes
	and	$s0	$s0	$s6
	lb	$s1	($a1)
	and	$s1	$s1	$s6
	move	$s2	$a2
	li	$s3	7
	sll	$s0	$s0	8
	sll	$s1	$s1	8
	lw	$s4	mask_hamming
clb_loop1:
	move	$t0	$s0
	move	$t1	$s1
	
	sllv	$t0	$t0	$s3			# Move by n left,
	srlv	$t1	$t1	$s3			# then by n right
	and	$t0	$t0	$s4			# Apply bit mask,
	and	$t1	$t1	$s4
	srlv	$t0	$t0	$s3			# And return by n right
	xor	$a0	$t1	$t0
	jal 	popcount
	lw	$t4	($s2)
	addu	$t4	$t4	$v0
	sw	$t4	($s2)
	addiu	$s2	$s2	4
	addiu	$s3	$s3	-1
	bnez	$s3	clb_loop1
clb_loop2:
	move	$t0	$s0
	move	$t1	$s1
	
	srlv	$t0	$t0	$s3			# Move by n left,
	sllv	$t1	$t1	$s3			# then by n right
	and	$t0	$t0	$s4			# Apply bit mask,
	and	$t1	$t1	$s4
	srlv	$t1	$t1	$s3			# And return by n right
	xor	$a0	$t1	$t0
	jal 	popcount
	lw	$t4	($s2)
	addu	$t4	$t4	$v0
	sw	$t4	($s2)
	addiu	$s2	$s2	4
	addiu	$s3	$s3	1
	bne	$s3	8	clb_loop2
	
	lw   	$s0 	($sp)				# Pop to stack
	lw   	$s1 	4($sp)			
	lw   	$s2 	8($sp)			
	lw   	$s3 	12($sp)			
	lw   	$s4 	16($sp)
	lw	$s5	20($sp)	
	lw	$s6	24($sp)	
	lw	$ra	28($sp)			
	addi	$sp 	$sp 	32			# Move stack pointer
	jr	$ra
#############################	Minimal	$a0 - array;	$a1 - size
minimal:
	move	$t0	$a0				# Save arguments
	move	$t1	$a1				
	lw	$t2	($t0)
minimal_loop:
	lw	$t3	($t0)				# Load next integer
	bgt	$t3	$t2	minimal_no_switch	
	move	$t2	$t3				# Switch
minimal_no_switch:
	addiu	$t1	$t1	-1			# Decrement loop counter
	addiu	$t0	$t0	4			# increment address
	bnez	$t1	minimal_loop
	move	$v0	$t2				# Return value
	jr	$ra					# Return

############################# 	Save	$a0 - array; $a1 - size;	$a2 - name;
save:
	addi	$sp 	$sp 	-32			# Move stack pointer
	sw   	$s0 	($sp)				# Push to stack
	sw   	$s1 	4($sp)			
	sw   	$s2 	8($sp)			
	sw   	$s3 	12($sp)		
	sw   	$s4 	16($sp)			
	sw	$s5	20($sp)
	sw	$s6	24($sp)
	sw	$ra	28($sp)

	move	$s0	$a0				# Save arguments
	move	$s1	$a1
	move	$s2	$a2
	li	$s3	0				# Loop counter
	move	$t8	$s0
	la	$t7	prints
	li	$t9	0
save_loop:
	addiu $t9	$t9	1
	li	$s4	' '
	beq	$t9	15	new_line
save_ret:	
	lw	$t0	($s0)				# Convert to decimal 
	
	remu	$t1 	$t0	10
	subu	$t0	$t0	$t1
	
	remu	$t2	$t0	100
	subu	$t0	$t0	$t2
	divu	$t2	$t2	10
	
	remu	$t3	$t0	1000
	subu	$t0	$t0	$t3
	divu	$t3	$t3	100
	
	divu	$t4	$t0	1000
	
	addu	$t1	$t1	'0'
	addu	$t2	$t2	'0'
	addu	$t3	$t3	'0'
	addu	$t4	$t4	'0'
	
	bne	$t4	'0'	save_skip
	li	$t4	' '
	bne	$t3	'0'	save_skip
	li	$t3	' '
	bne	$t2	'0'	save_skip
	li	$t2	' '
save_skip:
	sb	$t4	0($t7)
	sb	$t3	1($t7)
	sb	$t2	2($t7)
	sb	$t1	3($t7)
	sb	$s4	4($t7)
	
	addiu	$s0	$s0	4
	addiu	$t7	$t7	5	
	addiu	$s3	$s3	1
	bne	$s3	$s1	save_loop
	sb	$zero	($t7)

	li	$v0	13				# Command for open file
	move	$a0	$s2				# File name
	li	$a1	1				# write mode
	syscall
	
	move	$a0	$v0				# Save file descriptor
	li	$v0	15				# Command to write to file
	la	$a1	prints				# Copy buffer address
	move	$a2	$s1				# Copy size
	sll	$a2	$a2	2			# Multiply size for times
	addu	$a2	$a2	$s1
	syscall
	
	li 	$v0 	16   				#system call for file_close 
	# File descriptor at $a0
	syscall 

	lw   	$s0 	($sp)				# Pop to stack
	lw   	$s1 	4($sp)			
	lw   	$s2 	8($sp)			
	lw   	$s3 	12($sp)			
	lw   	$s4 	16($sp)
	lw	$s5	20($sp)	
	lw	$s6	24($sp)	
	lw	$ra	28($sp)			
	addi	$sp 	$sp 	32			# Move stack pointer
	jr	$ra
	
new_line:
	li	$s4	'\n'				# Enter end of line
	li	$t9	0
	b 	save_ret
	
