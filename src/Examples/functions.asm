####################### CSC258H1F Functions Worksheet #########################
######################## Bitmap Display Configuration #########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000
###############################################################################
.data
# The address of the bitmap display. Don't forget to configure and connect it!
ADDR_DSPL:
    .word 0x10008000

# An array of colours (from prior question)
MY_COLOURS:
	.word	0xff0000    # red
	.word	0x00ff00    # green
	.word	0x0000ff    # blue

.text
main:
    # TODO
    li $a0, 5
    li $a1, 12
    jal get_location_address_small
    
    addi $a0, $v0, 0
    la $a1, MY_COLOURS + 4
    li $a2, 4
    
    jal draw_line
    
exit:
	li 		$v0, 10
	syscall


# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
# TODO
	addi $sp, $sp, -12
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	# needs an epilogue since this is returning a value
	# get x, x*4
	sll $s0, $a0, 2
	# get y, y*128
	sll $s1, $a1, 7
	
	la $t0, ADDR_DSPL
	lw $t0, 0($t0)
	add $t0, $s0, $t0
	add $s2, $s1, $t0
	
	add $v0, $s2, $zero

	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	addi $sp, $sp, 12
	
	jr $ra

get_location_address_small:
	sll $a0, $a0, 2
	sll $a1, $a1, 7
	la $v0, ADDR_DSPL
	lw $v0, 0($v0)
	add $v0, $a0, $v0
	add $v0, $a1, $v0
	
	jr $ra

# draw_square(start, colour_address, size)
#   Draw a square that is size units wide and high on the display using the
#   colour at colour_address and starting from the start address
#
#   Preconditions:
#       - The start address can "accommodate" a size x size square
# TODO


# draw_line(start, colour_address, width) -> void
#   Draw a line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_line:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_line_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_line_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4        # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    j draw_line_loop
    
draw_line_epi:
    jr $ra