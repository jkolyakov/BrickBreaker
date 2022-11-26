################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Jacob Kolyakov, 1008050733
# Student 2: Jefferson Liu, 1008237720
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
.eqv BALL_SIZE 2
    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
BRICK_COLOURS:
    .word 0xff0000 #red
    .word 0x00ff00 #green
    .word 0x0000ff #blue
GRAY:
.word 0x808080 #gray
WHITE:
.word 0xffffff #white
BACKGROUND:
.word 0x000000



##############################################################################
# Mutable Data
##############################################################################
BALL:
    .word 100
    .word 100
    .word BALL_SIZE
##############################################################################
# Code
##############################################################################
.text
.globl main
	# Run the Brick Breaker game.
main: #SO FAR: Draws a full static game scree
    la $a0, ADDR_DSPL   #Put starting address as the address
    lw $a0, 0($a0)
    la $a1, GRAY
    li $a2, 32			# 32 units of height for the walls
    jal draw_walls               # Draw the walls as gray
    
    la $a0, ADDR_DSPL      #Put starting address as the address
    lw $a0, 0($a0)
    la $a1, GRAY
    li $a2, 30			# 30 because the first and last pixels were drawn by the wall
    jal draw_ceiling               # Draw ceiling as gray
    
    li $a0, 0
    li $a1, 5
    jal get_location_address 	#Gets the location address at (0,5)
    
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, BRICK_COLOURS
    li $a2, 30
    jal draw_bricks               # Draws 3 rows of bricks at $a0
    
    li $a0, 12
    li $a1, 24
    jal get_location_address	#Gets the location address at (12,24)
    
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, WHITE
    li $a2, 8
    jal draw_paddle               # Draws a white paddle at $a0
    
    li $a0, 18
    li $a1, 18
    jal get_location_address	#Gets the location address at (18, 18)
    
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, WHITE
    jal draw_ball               # Draws the ball at position $a0
    
exit:
	li 		$v0, 10
	syscall
    
    
    
# draw_walls(start, colour_address, height) -> void
#   Draw 2 walls on either side with length units vertically down the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of height units
draw_walls:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each units at the beginning and end of the line
    li $t1, 0                   # i = 0
draw_walls_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_walls_epi  # if not, then done

        sw $t0, 0($a0)          # Paint left wall unit with colour
        sw $t0, 124($a0)	# Paint right wall unit with colour
        addi $a0, $a0,128       # Go to next wall height

    addi $t1, $t1, 1            # i = i + 1
    b draw_walls_loop

draw_walls_epi:
    jr $ra
    

# draw_ceiling(start, colour_address, width) -> void
#   Draws the ceiling with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_ceiling:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each unit of the ceiling in the line
    li $t1, 0                   # i = 0
draw_ceiling_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_ceiling_epi  # if not, then done

        sw $t0, 4($a0)          # Paint unit with colour
        addi $a0, $a0, 4       # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    b draw_ceiling_loop

draw_ceiling_epi:
    jr $ra
    
    
# draw_bricks(start, colour_address, width) -> void
#   Draw 3 lines of bricks with width units horizontally across the display using the
#   colours at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_bricks:
    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_bricks_loop:
    lw $t0, 0($a1)              # colour = *colour_address[0]

    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_bricks_epi  # if not, then done

        sw $t0, 4($a0)          # Paint unit below with colour
        lw $t0, 4($a1)              # colour = *colour_address[1]
        
        sw $t0, 132($a0)          # Paint unit below with colour
        lw $t0, 8($a1)              # colour = *colour_address[2]
        
        sw $t0, 260($a0)          # Paint unit with colour
        addi $a0, $a0, 4       # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    b draw_bricks_loop

draw_bricks_epi:
    jr $ra
    
    
# draw_paddle(start, colour_address, width) -> void
#   Draw a paddle (line) with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_paddle:
    lw $t0, 0($a1)              # colour = *colour_address
    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_paddle_loop:

    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_paddle_epi  # if not, then done
        
        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4       # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    b draw_paddle_loop

draw_paddle_epi:
    jr $ra
    
    
# draw_ball(start, colour_address) -> void
#   Draw a 1 unit ball on the display using the
#   colour at colour_address at the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_ball:
    lw $t0, 0($a1)              # colour = *colour_address    
    sw $t0, 0($a0)          # Paint unit with colour
    j draw_ball_epi	    # End function
    
draw_ball_epi:
    jr $ra
    
# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
    # Each unit is 4 bytes. Each row has 32 units (128 bytes)
	sll 	$a0, $a0, 2				# x = x * 4
	sll 	$a1, $a1, 7             # y = y * 128

    # Calculate return value
	la 		$v0, ADDR_DSPL 			# res = address of ADDR_DSPL
        lw      $v0, 0($v0)             # res = address of (0, 0)
	add 	$v0, $v0, $a0			# res = address of (x, 0)
	add 	$v0, $v0, $a1           # res = address of (x, y)

    jr $ra

    

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop
