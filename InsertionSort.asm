Insertion_Sort:
.data
	input: .asciiz "input.txt" 
	output: .asciiz "output.txt"
	input_buffer: .space 100000 #buffer of 100000
	output_buffer: .space 100000 #buffer of 100000
	array: .word 0:1000 #array[1000]
	#error strings
	readErrorMsg: .asciiz "\nError in reading file\n"
	openErrorMsg: .asciiz "\nError in opening file\n"
.text
main:
jal readFile
la $s1,input_buffer #s1: addr of input_buffer
li $s0,0 #s0: size
ReadSizeLoop:	lb $t0, 0($s1) #load byte
		addi $t1,$t0,-13 #check carriage return (ascii is 13)
		beq $t1,$0,exitReadSize #finish reading size
		addi $t0,$t0,-48 #for number
		mul $s0,$s0,10 #multiply 10
		add $s0,$s0,$t0 #add
		addi $s1,$s1,1 #next digit
		j ReadSizeLoop #loop
exitReadSize:
addi $s1,$s1,2 #ignore the new line (ascii 15), get to the first number
la $s2,array #s2 addr of array
move $s3,$s2 #s3=s2, store addr of array for latter use
li $t1,0 #t1: iterator, bien dem
#remind: s0 contains size
InputArrayLoop:	sub $t2,$s0,$t1
		beq $t2,$0,ExitInputArray
		li $t5,0 #t5:so dang duoc doc

ReadNumberLoop:	lb $t3,0($s1)
		beq $t3,$0,ExitReadNumberLoop #null, exit - which means last element
		addi $t4,$t3,-32 #check space
		beq $t4,$0,ExitReadNumberLoop
		addi $t3,$t3,-48 #convert ascii to number
		mul $t5,$t5,10
		add $t5,$t5,$t3
		addi $s1,$s1,1
		j ReadNumberLoop
ExitReadNumberLoop:
		sw $t5,0($s2) #store array[i]
		addi $s2,$s2,4 #next
		addi $s1,$s1,1 #next element in input buffer
		addi $t1,$t1,1
		j InputArrayLoop #loop

ExitInputArray:
#CODE FOR SORTING. $s0=size of array, $s3:addr of array
move $a0,$s0
move $a1,$s3
jal InsertionSort
#CODE FOR SORTING

#Now the array is stored
#Convert array to output_buffer, remind: s0 contains size, s3 contains array addr
addi $s0,$s0,-1 #easy for coding
la $a1,output_buffer #a1 addr of output_buffer
li $t0,0
ConvertArrayLoop:
		sub $t1,$t0,$s0
		beq $t1,$0,ExitConvertArray
		lw $a0,0($s3)#a0 = array[i]
		addi $s3,$s3,4#move to next element
		jal IntToString #when finish this function, a1 will contain the addr next to last element inserted
		li $t2,32 #blank char
		sb $t2,0($a1)
		addi $a1,$a1,1
		addi $t0,$t0,1
		j ConvertArrayLoop
ExitConvertArray:
addi $s0,$s0,1 #restore back
lw $a0,0($s3)
jal IntToString
li $t2,0#null terminate
sb $t2,0($a1)
#OUTPUT ON SCREEN 
la $a0,output_buffer
li $v0,4
syscall
##
jal outputFile

#exit program
li $v0,10
syscall

##### END PROGRAM #####



### HELPER FUNCTION FOR TESTING ###
PrintArray:
li $t6,0
la $t7,array
PrintLoop:
		sub $t8,$s0,$t6
		beq $t8,$0,ExitLoop
		lw $a0,0($t7)
		addi $t7,$t7,4
		li $v0,1
		syscall
		addi $t6,$t6,1
		j PrintLoop
ExitLoop:
jr $ra
### FUNCTION ###

#READ FILE
readFile:
	
	addi $sp,$sp,-4
	sw $ra,0($sp)
	jal openFile
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
openFile:
	#Open file for for reading purposes
	li $v0, 13          #syscall 13 - open file
	la $a0, input    #passing in file name
	li $a1, 0               #set to read mode
	li $a2, 0               #mode is ignored
	syscall
	bltz $v0, openError     #if $v0 is less than 0, there is an error found
	move $s0, $v0           #else save the file descriptor

	#Read input from file
	li $v0, 14          #syscall 14 - read filea
	move $a0, $s0           #sets $a0 to file descriptor
	la $a1, input_buffer          #stores read info into buffer
	li $a2, 100000            #hardcoded size of buffer
	syscall             
	bltz $v0, readError     #if error it will go to read error

	#li $v0, 4		#print string
	#la $a0, buffer
	#syscall

	#Close the file 
	li   $v0, 16       # system call for close file
	move $a0, $s0      # file descriptor to close
	syscall            # close file
	jr $ra

openError:
	la $a0, openErrorMsg
	li $v0, 4
	syscall
	jr $ra

readError:
	la $a0, readErrorMsg
	li $v0, 4
	syscall
	jr $ra
###
		
#WRITE FILE
outputFile:
# Open (for writing) a file that does not exist
  	li   $v0, 13       # system call for open file
  	la   $a0, output     # output file name
  	li   $a1, 1        # Open for writing (flags are 0: read, 1: write)
  	li   $a2, 0        # mode is ignored
  	syscall            # open a file (file descriptor returned in $v0)
  	move $s6, $v0      # save the file descriptor
# Write to file just opened
  	li   $v0, 15       # system call for write to file
  	move $a0, $s6      # file descriptor 
  	la   $a1, output_buffer   # address of buffer from which to write
  	li   $a2, 100000       # hardcoded buffer length
  	syscall            # write to file
# Close the file 
  	li   $v0, 16       # system call for close file
  	move $a0, $s6      # file descriptor to close
  	syscall            # close file
  	jr $ra
###
  	
  	  	  	
#HAM CHUYEN TUNG ELEMENT CUA ARRAY THANH STRING, CACH KHOANG
#$a0:int, #a1:addr of insert
IntToString:
addi $sp,$sp,-20
sw $ra,0($sp)
sw $t0,4($sp)
sw $t1,8($sp)
sw $t2,12($sp)
sw $t3,16($sp)
beq $a0,$0,ZeroCase #zero case, when a0=0
move $t0,$a0#t0: number
li $t1,0 #bien dem
CountDigit:	
		beq $t0,$0,ExitCountDigit
		addi $t1,$t1,1
		div $t0,$t0,10
		j CountDigit
ExitCountDigit:
addi $t1,$t1,-1
move $t0,$a0
li $t2,1
GetPower:	beq $t1,$0,StringLoop
		addi $t1,$t1,-1
		mul $t2,$t2,10
		j GetPower
StringLoop:	
		div $t3,$t0,$t2
		rem $t0,$t0,$t2
		addi $t3,$t3,48
		sb $t3,0($a1)
		addi $a1,$a1,1
		div $t2,$t2,10
		beq $t2,$0,ExitStringLoop
		j StringLoop

ZeroCase:
addi $a0,$a0,48
sb $a0,0($a1)
addi $a1,$a1,1
ExitStringLoop:
lw $ra,0($sp)
lw $t0,4($sp)
lw $t1,8($sp)
lw $t2,12($sp)
lw $t3,16($sp)
addi $sp,$sp,20
jr $ra

### INSERTION SORT ###
InsertionSort:#$a0:size, $a1: addr of array
addi $sp,$sp,-4
sw $ra,0($sp)
addi $t0,$0,1 #i=1
Loop1:	beq $t0,$a0,ExitInsertionSort#i==n exit
	sll $t3,$t0,2#t3=4i
	add $t3,$t3,$a1#t3=addr of array[i]
	lw $t3,0($t3)#t3=array[i], key=t3
	addi $t1,$t0,-1#j=i-1
	
Loop2:	slt $t2,$t1,$0#j<0
	bne $t2,$0,ExitLoop2#if yes
	sll $t2,$t1,2#t2=4j
	add $t6,$t2,$a1#t6=addr of array[j]
	lw $t4,0($t6)#t4=array[j]
	slt $t5,$t3,$t4#t5=key < array[j]
	beq $t5,$0,ExitLoop2#if no
	sw $t4,4($t6)#array[j+1]=t4=array[j]
	addi $t1,$t1,-1#j=j-1
	j Loop2
ExitLoop2:
	addi $t2,$t1,1
	sll $t2,$t2,2
	add $t2,$t2,$a1
	sw $t3,0($t2)#array[j+1]=key
	addi $t0,$t0,1
	j Loop1
ExitInsertionSort:
lw $ra,0($sp)
addi $sp,$sp,4
jr $ra
###
