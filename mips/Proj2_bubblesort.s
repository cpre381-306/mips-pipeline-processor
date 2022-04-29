	.data

Arr:	.word	1,3,2,5,4,0,7,6

	.text

	.globl main

main:
	li $t1, 8		# get size of array

loop_main:
	subi $a1, $t1, 1	# depends on t1 after initial run (PROBLEM)

	ble $a1, $0, end	# depends on subi 

	la $a0, Arr		# depends on a0 (no worry)
	li $t2, 0		# depends on t2 (no worry)
	jal loop		# set ra (no issue)
	beq $t2, $0, end	# depends on t2(no worry)
	subi $t1, $t1, 1	# depends on t1(no worry)
	j loop_main		# (no issue)
V include 2 stalls

loop:
^include one stall
	lw $s1, 0($a0)		# depends on a0(2 blocks away) wait for JAL(?)(PROBLEM)
^if stall included, no issue should arise	
	lw $s2, 4($a0)		# depends on a0 (JAL?)(PROBLEM)
^need 3(?) stalls
	bgt $s1, $s2, swap	# depends on s1 and s2(PROBLEM)

next:
	addiu $a0, $a0, 4	# depends on a0 (no worry)
	subiu $a1, $a1, 1	# depends on a1(no worry)
^need 3(?) stalls
	bgt $a1, $0, loop	# dpends on a1 (PROBLEM)

	jr $ra			# go to jal(no issue)

swap:
	sw $s1, 4($a0)		# depends on a0(no issue)
	sw $s2, 0($a0)		# depends on a0(no issue)
	li $t2, 1		# depends on t2(no issue)
	j next			# (no issue)

end:
	li $v0, 10
	syscall
	halt
