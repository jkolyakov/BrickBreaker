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
.eqv PADDLE_SIZE 8
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
BACKGROUND_COLOUR:
.word 0x000000
#TEST COLOR
RED:
	.word 0xff0000 #red

##############################################################################
# Mutable Data
##############################################################################
BALL:
    .word 1 #x position
    .word 10 #y position
    .word 1 # x direction (1 is right, -1 left)
    .word -1 # y direction (1 is down, -1 is up)
PADDLE:
    .word 12 #x position
    .word 24 #y position
    .word PADDLE_SIZE
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
    li $a2, PADDLE_SIZE
    jal draw_paddle               # Draws a white paddle at $a0
    
    li $a0, 18
    li $a1, 18
    jal get_location_address	#Gets the location address at (18, 18)
    
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, WHITE
    jal draw_ball               # Draws the ball at position $a0
    jal game_loop		#Jumps to the game loop

    
    
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
    
#Checks for keyboard input
keyboard_input:                     	# A key is pressed
    lw $a0, 4($t0)                  	# Load second word from keyboard
    beq $a0 0x61, move_left		# moves paddle left 1 unit
    beq $a0 0x64, move_right		# moves paddle right 1 unit
    beq $a0, 0x71, quit     		# Check if the key q was pressed
    beq $a0, 0x70, pause_game     	# Check if the key p was pressed
    b game_loop

erase_paddle:
	subi $sp, $sp, 4  # allocate 1 word on the stack
	sw $ra, 0($sp)      # save $ra 
    	jal get_location_address	#Gets the location address at (wherever the paddle is)
    	addi $a0, $v0, 0            # Put return value in $a0
   	la $a1, BACKGROUND_COLOUR 	#Changes the color of the paddle drawn to be the background color
    	li $a2, PADDLE_SIZE
    	
    	#Nested procedure so we need to restore the previous $ra
    	
    	jal draw_paddle       	        #Erases the paddle
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    	
    	jr $ra

move_left:
	la $t0, PADDLE 			#Gets paddle object
	lw $a0, 0($t0)			#Sets parameter 1 to x value
    	lw $a1, 4($t0)			#Sets parameter 2 to y value
	jal erase_paddle		#Erase helper function
    	
    	
    	la $t0, PADDLE 			#Gets paddle object
    	lw $a0, 0($t0)			#Sets parameter 1 to x value
    	lw $a1, 4($t0)			#Sets parameter 2 to y value
    	beq $a0, 1, skip_drawing_left 	#Catches if the paddle is at the edge
    	addi $a0, $a0, -1		#Moves x value left by 1
    	skip_drawing_left:
    	li $v1, 0			#resets the erase case
    	sw $a0, 0($t0)			#Updates x value
    	sw $a1, 4($t0)			#Updates y value
    	
    	jal get_location_address	#Gets the location address at (wherever the paddle is)
    	addi $a0, $v0, 0            # Put return value in $a0
    	la $a1, WHITE 	#Changes the color of the paddle drawn to be the background color
    	li $a2, PADDLE_SIZE
    	jal draw_paddle               # Draws the new paddle
	b game_loop			#Branches back to game loop

move_right:
	la $t0, PADDLE 			#Gets paddle object
	lw $a0, 0($t0)			#Sets parameter 1 to x value
    	lw $a1, 4($t0)			#Sets parameter 2 to y value
	jal erase_paddle		#Erase helper function
    	
    	
    	la $t0, PADDLE 			#Gets paddle object
    	lw $a0, 0($t0)			#Sets parameter 1 to x value
    	lw $a1, 4($t0)			#Sets parameter 2 to y value
    	beq $a0, 23, skip_drawing_right 	#Catches if the paddle is at the edge
    	addi $a0, $a0, 1		#Moves x value left by 1
    	skip_drawing_right:
    	li $v1, 0			#resets erase case
    	sw $a0, 0($t0)			#Updates x value
    	sw $a1, 4($t0)			#Updates y value
    	
    	jal get_location_address	#Gets the location address at (wherever the paddle is)
    	addi $a0, $v0, 0            # Put return value in $a0
    	la $a1, WHITE 	#Changes the color of the paddle drawn to be the background color
    	li $a2, PADDLE_SIZE
    	jal draw_paddle               # Draws the new paddle
	b game_loop			#Branches back to game loop	

#Quits the game
quit:
	li $v0, 10                      # Quit gracefully
	syscall
	
#Pauses the game
pause_game:
	b pause_loop 			#puts the game into the pause loop
		
#Special input procedure that only checks for quitting and unpausing the game
pause_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, quit     # Check if the key q was pressed
    beq $a0, 0x70, game_loop     # Check if the key p was pressed whcih then unpauses the game and goes back to game loop
    b pause_loop

pause_loop: #The game is not running during this loop
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # unpauses if p is pressed
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, pause_input      # If first word 1, key is pressed
    b pause_loop
	

check_collision:
	subi $sp, $sp, 4  			# allocate 1 word on the stack
	sw $ra, 0($sp)      			# save $ra 
	jal check_sides
	jal check_vertical
	jal check_diagonal
	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer
	jr $ra
    	
check_sides:
	subi $sp, $sp, 4  			# allocate 1 word on the stack
	sw $ra, 0($sp)      			# save $ra 
    	la $t0, BALL 				#Gets ball object
	lw $t1, 0($t0)				#loads $t1 to x pos
    	lw $a1, 4($t0)				#loads $a1 to y pos
    	lw $t3, 8($t0)				#loads the x direction into $t3
    	add $a0, $t1,$t3			#Stores the next x location of the ball
    	jal get_location_address		#Gets location of the unit directly to the right/left of the ball
    	
    	#gets color of unit to the side of the ball
    	lw $t1, 0($v0)
    	
    	
    	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer		
    										
    	la $t2, BACKGROUND_COLOUR		
    	lw $t2, 0($t2)
    	
    	beq $t1,$t2, skip_sides	#jumps back to check collision if the side of the ball is not a collidable color
    	#ELSE the ball needs to change its x direction and check if a brick needs to break
    	
    	la $t0, BALL 				#Gets ball object
    	lw $t3, 8($t0)				#loads the x direction into $t3
    	li $t1, -1				#sets register to -1
    	mult $t3, $t1				#multiplies -1 and the current x direction
    	mflo $t3				#gets the 32 low bits of the multiplication
    	sw $t3, 8($t0)				#stores the negative of the balls x direction to the ball 
    	
   	subi $sp, $sp, 4  			# allocate 1 word on the stack
	sw $ra, 0($sp)      			# save $ra 
	
    	addi $a0, $v0, 0 #Loads the address where collision happened into $a0
    	jal break_brick
    	
    	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer
    	
skip_sides:
    	jr $ra
    	
check_vertical:
	subi $sp, $sp, 4  			# allocate 1 word on the stack
	sw $ra, 0($sp)      			# save $ra 
    	la $t0, BALL 				#Gets ball object
	lw $a0, 0($t0)				#Sets parameter 1 to x value
    	lw $t1, 4($t0)				#Sets parameter 2 to y value
    	lw $t3, 12($t0)				#loads the y direction into $t3
    	add $a1, $t1,$t3			#Stores the next y location of the ball
    	jal get_location_address		#Gets location of the unit directly to the right/left of the ball
    	
    	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer
    	

    	
    	
    	#gets color of unit to the upper and lower sides of the ball
    	lw $t1, ($v0)				#gets color of unit next to the top/bottom of the ball			
    	la $t2, BACKGROUND_COLOUR		
    	lw $t2, 0($t2)
    	
    	beq $t1, $t2, skip_vertical	#jumps back to check collision if the side of the ball is not a collidable color
    	#ELSE the ball needs to change its x direction
    	
    	la $t0, BALL 				#Gets ball object
    	lw $t3, 12($t0)				#loads the y direction into $t3
    	li $t1, -1				#sets register to -1
    	mult $t3, $t1				#multiplies -1 and the current y direction
    	mflo $t3				#gets the 32 low bits of the multiplication
    	sw $t3, 12($t0)				#stores the negative of the balls x direction to the ball 
    	
    	addi $a0, $v0, 0 #Loads the address where collision happened into $a0
    	jal break_brick
    	
    	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer
    	
skip_vertical:
    	jr $ra  
    	
    	  	
check_diagonal:
	subi $sp, $sp, 4  			# allocate 1 word on the stack
	sw $ra, 0($sp)      			# save $ra 
    	la $t0, BALL 				#Gets ball object
	lw $a0, 0($t0)				#Sets parameter 1 to x value
    	lw $t1, 4($t0)				#Sets parameter 2 to y value
    	lw $t3, 12($t0)				#loads the y direction into $t3
    	add $a1, $t1,$t3			#Stores the next y location of the ball
    	lw $t3, 8($t0)				#Loads x direction into $t3
    	add $a0, $a0, $t3			#Stores teh next x location in $a0
    	jal get_location_address		#Gets location of the unit directly to the diagonal of the ball
    	
    	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer
    	

    	
    	
    	#gets color of unit to the upper and lower sides of the ball
    	lw $t1, ($v0)				#gets color of unit next to the top/bottom of the ball			
    	la $t2, BACKGROUND_COLOUR		
    	lw $t2, 0($t2)
    	
    	beq $t1, $t2, skip_vertical	#jumps back to check collision if the side of the ball is not a collidable color
    	#ELSE the ball needs to change its x direction
    	
    	la $t0, BALL 				#Gets ball object
    	lw $t3, 12($t0)				#loads the y direction into $t3
    	li $t1, -1				#sets register to -1
    	mult $t3, $t1				#multiplies -1 and the current y direction
    	mflo $t3				#gets the 32 low bits of the multiplication
    	sw $t3, 12($t0)				#stores the negative of the balls x direction to the ball 
    	
    	lw $t3, 8($t0)				#loads the y direction into $t3
    	mult $t3, $t1				#multiplies -1 and the current y direction
    	mflo $t3				#gets the 32 low bits of the multiplication
    	sw $t3, 8($t0)				#stores the negative of the balls x direction to the ball 
    	
    	addi $a0, $v0, 0 #Loads the address where collision happened into $a0
    	jal break_brick
    	
    	lw $ra, 0($sp)				#restores the $ra
    	addi $sp, $sp, 4			#restores the stack pointer
    	
skip_diagonal:
    	jr $ra  	
	

move_ball:
	la $t0, BALL 			#Gets ball object stores it in $t1
    	lw $t1, 0($t0)			#sets $t1 to x value
    	lw $t2, 4($t0)			#sets $t2 to y value
    	lw $t3, 8($t0)			#sets $t3 to x direction
    	lw $t4, 12($t0)			#sets $t4 to y direction
    	add $t5, $t1, $t3		#gets the next x pos
    	add $t6, $t2, $t4		#gets next y pos
    	sw $t5, 0($t0)
    	sw $t6, 4($t0)
    	jr $ra
    	

#break_brick(address) -> void
#Checks if pixel is a brick colour, if so erases the pixel
break_brick:
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	la $t0, BRICK_COLOURS
	lw $t3, 0($t0)
	lw $t2, 0($a0)
	beq $t3, $t2, erase_unit
	lw $t3, 4($t0)
	beq $t3, $t2, erase_unit
	lw $t3, 8($t0)
	beq $t3, $t2, erase_unit
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	jr $ra

#erase_unit(address) -> void
#Erases a pixel at a certain address
erase_unit:
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	la $t0, BACKGROUND_COLOUR
	lw $t0, 0($t0)
	sw $t0, 0($a0)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	jr $ra

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
    #NEED TO CHECK FOR COLLISION BEFORE DRAWING BALL
    jal check_collision
    
    la $t0, BALL 			#Gets ball object stores it in $t0
    lw $a0, 0($t0)			#sets $a0 to x value
    lw $a1, 4($t0)			#sets $a1 to y value
    beq $a1, 33, quit			#Lose when ball goes past 24 y 
    jal get_location_address	#Gets the location address at (18, 18)
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, BACKGROUND_COLOUR
    jal draw_ball
    
    jal move_ball			#Sets the new ball location
    la $t0, BALL 			#Gets ball object stores it in $t0
    lw $a0, 0($t0)			#sets $a0 to x value
    lw $a1, 4($t0)			#sets $a1 to y value
    jal get_location_address	#Gets the location address at (18, 18)
    addi $a0, $v0, 0            # Put return value in $a0
    la $a1, WHITE
    jal draw_ball
    
    li $a0, 100				#Stores 100 in first argument
    li $v0, 32				# pause for 100 milisec to make sure the ball doesnt go too fast
    syscall

    
    b game_loop
