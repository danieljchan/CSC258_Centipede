##################################################################### 
# 
# CSC258H Winter 2021 Assembly Final Project 
# University of Toronto, St. George 
# 
# Student: Daniel James Chan, 1006272383 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8    
# - Unit height in pixels: 8 
# - Display width in pixels: 256 
# - Display height in pixels: 256 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# Which milestone is reached in this submission? 
# 1, 2, 3 completed
# 
# Which approved additional features have been implemented? 
# none
# 
# Any additional information that the TA needs to know: 
# s to start/restart game
# j/k to move left/right
# x to shoot
# e to terminate program gracefully
# shoot centipede 3 times to win, get hit by flea to lose
# 
#####################################################################

.data
	displayAddress:	.word 0x10008000	# display address of the bitmap display
	bugLocation: .word 880			# starting location of the bug
	centipedLocation: .word 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 	# centipede segments start on locations 0-9
	centipedDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1	# centipede segments start facing right
	centipedHead: .word 1, 0, 0, 0, 0, 0, 0, 0, 0, 0	# only first segment of centipede is the head
	mushroomLocation: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 # spawn in locations 32-831
	mushroomLimit: .word 30 # 30 mushrooms to start
	dartLocation: .word -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1	# empty list for dart locations
	dartLimit: .word 30	# max 30 darts on the screen at once
	centipedHealth: .word 3	# centipede has 3 health, so it must be hit 3 times to die
	fleaLocation: .word 0	# flea's location, randomly generated later
	fleaDelay: .word 5	# flea's delay, when the game loop runs 5 times the fly moves once
	fleaDelayCounter: .word 5	# fly counter for the delay
	game_won: .word 0	# 1 if the game is won, 0 otherwise
.text 

Start_game_loop: # this loops at the beginning until 's' is pressed to start the game
	jal check_keystroke	# check if a key is pressed
	jal s_to_start		# display an 's' to be pressed 
	j Start_game_loop	# loop 

start_game:	# when the game starts, go here
	lw $a3, mushroomLimit	 # load a3 with the mushroomLimit
	la $a2, mushroomLocation # load the address of the mushroomLocation array into $a2
	
init_mushroom_loop:		 # initialize mushrooms
	# find a random mushroom location that doesn't already exist
	get_random_num:
	
	li $v0, 42   # for random int within a range
	li $a0, 0    # random value will be in $a0
	li $a1, 799  # max 799, we'll add 32 to this so mushrooms don't spawn on first row or blaster row
	syscall
	
	addi $a0, $a0, 32  # add 32 to this so mushrooms don't spawn on first row or blaster row
	
	## get x position of random num
	#li $t5, 0
	#rem $t5, $a0, 32 # $t5 is now the x position of random num
	
	# if random num is beside left or right wall, get new random num
	#beq $t5, 0, get_random_num
	#beq $t5, 31, get_random_num
	
	# if random num is already in the mushroom list, get new random num
		
		lw $t6, mushroomLimit	 # load $t6 with the mushroomLimit
		la $t8, mushroomLocation # load the address of the mushroomLocation array into $t8
		search_duplicate:
			lw $t7, 0($t8)			 
			beq $t7, $a0, get_random_num # if location $a0 already exists, get new random num

			addi $t8, $t8, 4	 # increment $t8 by one, to point to the next element in the array
			addi $t6, $t6, -1	 # decrement $t6 by 1
			bne $t6, $zero, search_duplicate # if $t6 isn't zero yet, loop 
			
	# now we have a random number that isn't a duplicate in mushroomLocation
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x2ff365	# $t3 stores the green colour code
	
	sw $a0, 0($a2)          # store the random number back into mushroomLocation
	
	li $t4, 0
	sll $t4, $a0, 2		# $t4 is the bias of the mushroom location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the mushroom location
	sw $t3, 0($t4)		# paint the mushroom with green
	
	addi $a2, $a2, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, init_mushroom_loop # if $a3 isn't zero yet, loop 
	
init_flea:	# initialize a random location for the flea to spawn
	li $v0, 42   # for random int within a range
	li $a0, 0    # random value will be in $a0
	li $a1, 24  # flea will spawn somewhere within 24 squares on the third last row
	syscall
	
	addi $a0, $a0, 931 # add 931 to the random number to bring it to the third last row
	
	la $t0, fleaLocation
	sw $a0, 0($t0)	# save the random number to fleaLocation
	
	
paint_blaster:	# paint where the bug spawns white
	lw $t1, bugLocation	# $t1 stores the blaster location
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0xffffff	# $t3 stores the white colour code
	
	li $t4, 0
	sll $t4, $t1, 2		# $t4 is the bias of the blaster location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the blaster location
	sw $t3, 0($t4)		# paint the blaster white
	
	

Main_game_loop:				# main game loop
	jal disp_centiped	# update screen
	jal check_keystroke	# take keystroke input

	li $v0, 32				# Sleep op code
	li $a0, 30				# Speed 
	syscall
	
	j Main_game_loop	# loop


# function to display a static centiped	
disp_centiped:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	 # load a3 with the loop count (10)
	la $a1, centipedLocation # load the address of the array into $a1
	la $a2, centipedDirection # load the address of the array into $a2
	la $a0, centipedHead # load the address of the array into $a0

centiped_loop:	#iterate over the loops elements to draw each body in the centiped
	lw $t1, 0($a1)		 # load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		 # load a word from the centipedDirection array into $t5
	lw $t9, 0($a0)   	 # load a word from the centipedHead array into $t9
	#####
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	li $t4, -1
	beq $t1, $t4, end_centipede	# if centipede is dead, don't update it
	
	# check if the centipede is over a mushroom 
		lw $t4, mushroomLimit	 # load t4 with the mushroomLimit
		la $t6, mushroomLocation # load the address of the mushroomLocation array into $t8
	
		bug_on_mushroom_checker:
			lw $t7, 0($t6)		
			beq $t7, $t1, replace_mushroom # if bug is on a mushroom, replace mushroom by making the old bug location green

			addi $t6, $t6, 4	 # increment $t6 by one, to point to the next element in the array
			addi $t4, $t4, -1	 # decrement $t4 by 1
			bne $t4, $zero, bug_on_mushroom_checker # if $t4 isn't zero yet, loop 
			j end_bug_on_mushroom_checker # when the bug is not on any mushrooms, end

		replace_mushroom:
			li $t3, 0x2ff365	# $t3 stores the green colour code
	
	end_bug_on_mushroom_checker:
	
	li $t4, 0
	sll $t4,$t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the body with black (or green if old body location was also a mushroom)
	
	li $t3, 0xff0000        # $t3 now stores the red colour code
	lw $t6, 0($a1)		# load a new version of $a1
	
	bnez $t9, paint_head # if head is not equal to 0 (so it's 1), then we use turqoise to indicate it's a head
	j done_head
	paint_head:
		li $t3, 0x00ffef # t3 now stores the turquoise colour code
	done_head:
	
	## get x position of bug segment
	li $t7, 0
	rem $t7, $t6, 32 
	# $t7 is now the x position of bug segment	
	
	
	beq $t5, 1, move_right    # if the direction is 1, the segment moves right
			
	move_left:
		beq $t7, 0, turn_right	# if the x position of bug is by a left wall, turn right 
		
		
			### if $t6 is a mushroom location, turn_right 
			lw $t1, mushroomLimit	 # load t1 with the mushroomLimit
			la $t8, mushroomLocation # load the address of the mushroomLocation array into $t8
	
			left_mushroom_checker:
				lw $t9, 0($t8)		
				li, $t7, 0
				addi $t7, $t6, -1
				beq $t7, $t9, turn_right # if t6 - 1 is a mushroom location, turn right

				addi $t8, $t8, 4	 # increment $t8 by one, to point to the next element in the array
				addi $t1, $t1, -1	 # decrement $t1 by 1
				bne $t1, $zero, left_mushroom_checker # if $t1 isn't zero yet, loop 
		
		
		addi $t6, $t6, -1	# otherwise, if the left space isn't a mushroom, go one pixel left
		j end_move
	
		turn_right:
			bge $t6, 832, dont_go_down_right   # don't go past blaster's row
			addi $t6, $t6, 32 	# move pixel down 1
			dont_go_down_right:
			li $t5, 1		# load right direction
			sw $t5, 0($a2)		# save changed direction 
			j end_move	
	  			
	move_right:
		beq $t7, 31, turn_left	# if the x position of bug is by a right wall, turn left
		
		
			### if $t6 is a mushroom location, turn_right (use t1, t7, t8, t9)
			lw $t1, mushroomLimit	 # load t1 with the mushroomLimit
			la $t8, mushroomLocation # load the address of the mushroomLocation array into $t8
	
			right_mushroom_checker:
				lw $t9, 0($t8)		
				li, $t7, 0
				addi $t7, $t6, 1
				beq $t7, $t9, turn_left # if t6 + 1 is a mushroom location, turn left

				addi $t8, $t8, 4	 # increment $t8 by one, to point to the next element in the array
				addi $t1, $t1, -1	 # decrement $t1 by 1
				bne $t1, $zero, right_mushroom_checker # if $t1 isn't zero yet, loop 
		
		
		addi $t6, $t6, 1 	# go one pixel right 
		j end_move
	
		turn_left:
			bge $t6, 832, dont_go_down_left  # don't go past blaster's row
			addi $t6, $t6, 32 	# move pixel down 1
			dont_go_down_left:
			li $t5, -1		# load left direction
			sw $t5, 0($a2)		# save changed direction 
			j end_move
	
	end_move:
		sw $t6, 0($a1)		# save the new bug location
	
		sll $t4,$t6, 2		# $t4 is the bias of the new body location in memory (offset*4)
		add $t4, $t2, $t4	# $t4 is the address of the new bug location
		sw $t3, 0($t4)	        # paint the new bug location 	
	end_centipede:	
	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a0, $a0, 4 
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, centiped_loop
	
	### display darts ###
	
	la $t1, dartLocation	# load the address of dartLocation from memory in $t1
	lw $t3, dartLimit	# load the dartLimit in $t3 
	lw $t6, displayAddress  # $t6 stores the base address for display
	
	
	dart_loop:
		lw $t2, 0($t1)		# load the dart location itself in t2
		
		li $t4, -1		# -1 for empty dart
		bne $t2, $t4, update_dart	# if the dart location is not -1 (empty slot), update it
		j done_updating_dart		# otherwise we don't need to 
		
		update_dart:
		li $t7, 0x000000	# $t7 stores the colour black
	
		la $t8, bugLocation	# $t8 stores bugLocation address
		lw $t9, 0($t8)		# $t9 stores bugLocation itself
		beq $t2, $t9, dart_on_blaster	# if old dart location is on the blaster, repaint the blaster white
		j done_painting_old_dart	# otherwise skip
		
		dart_on_blaster:
		li $t7, 0xffffff	# the old dart location will be painted white
		done_painting_old_dart:
	
		li $t5, 0
		sll $t5,$t2, 2		# $t5 is the bias of the old dart location in memory (offset*4)
		add $t5, $t6, $t5	# $t5 is the address of the old dart location
		sw $t7, 0($t5)	        # paint the old dart location black
		
		addi $t2, $t2, -32   	# move the dart up one space
		
		ble $t2, -1, remove_dart		# if dart is less than equal to -1 (off the screen), remove it from dartLocation
		
		# check if new dart location is a centipede segment or mushroom t4, t5, t7, t8, t9
		
		li $t4, 10		# load centipede length 10 to $t4
		la $t7, centipedLocation		# load centipedLocation array to $a1
		
			dart_hit_centipede:
				lw $t5, 0($t7)			# load a word from the centipedLocation array into $t5
				beq $t5, $t2, centiped_hit	# if the dart and centipede are on the same pixel, the centipede is hit
			
				addi $t7, $t7, 4		# go to next element in centipedLocation array
				addi $t4, $t4, -1			# decrement $t4 by 1
				bne $t4, $zero, dart_hit_centipede	# if we didn't go through all centipede segments yet, loop
		
			lw $t4, mushroomLimit		# load mushroom limit to $t4
			la $t7, mushroomLocation		# load mushroom location array to $t7		
			
			dart_hit_mushroom:
				lw $t5, 0($t7)			# load a word from the mushroomLocation array into $t5
				beq $t5, $t2, mushroom_hit	# if the dart and mushroom are on the same pixel, the mushroom is hit
			
				addi $t7, $t7, 4		# go to next element in mushroomLocation array
				addi $t4, $t4, -1		# decrement $t4 by 1
				bne $t4, $zero, dart_hit_mushroom	# if we didn't go through all mushrooms yet, loop
			
		j paint_new_dart			# if nothing is hit, we update the dart

		centiped_hit:		# if the centipede is hit by a dart
			la $t8, centipedHealth	# $t8 is address of centipede's health
			lw $t9, 0($t8)		# $t9 is centipede's health itself
			addi $t9, $t9, -1	# subtract 1 from the centipede's health
			beq $t9, $zero, win	# if centipede is already at 0hp, win
			sw $t9, 0($t8)		# save new centipede health 
				
			j remove_dart	# remove the dart that hit the centipede
			
		mushroom_hit:		# if a mushroom is hit by a dart
		
			la $t9, ($t5) 	# $t5 and $t9 both contain location of dead mushroom
			
			li $t5, -1	# set mushroom to -1 (dead mushroom)
			sw $t5, 0($t7)	# save this to mushroomLocation
			
			li $t7, 0x000000	# $t7 stores the colour black
			
			sll $t8,$t9, 2		# $t8 is the bias of the dead mushroom location in memory (offset*4)
			add $t8, $t6, $t8	# $t8 is the address of the dead mushroom location
			sw $t7, 0($t8)	        # paint the dead mushroom location black	
			  
			j remove_dart
									
		remove_dart:
		li $t2, -1	# set dart location to -1
		j done_updating_dart
		
		paint_new_dart:
		li $t7, 0xfff44f	# $t7 stores the colour yellow
		
		li $t5, 0
		sll $t5,$t2, 2		# $t5 is the bias of the new dart location in memory (offset*4)
		add $t5, $t6, $t5	# $t5 is the address of the new dart location
		sw $t7, 0($t5)	        # paint the new dart location yellow		
		
		done_updating_dart:
		
		sw $t2, 0($t1) 		# save the new dart location in the array
		addi $t1,$t1, 4		# go to next element in dartLocation array
		addi $t3, $t3, -1	# decrement counter by 1
		bne $t3, $zero, dart_loop # while counter isn't 0, loop
		
# display flea
	lw $t0, fleaDelayCounter	# if flea delay counter is 0, move flea
	bne $t0, $zero, flea_done	# otherwise, don't move flea


	la $t0, fleaLocation	# load flea location to address to $t0
	la $t1, bugLocation 	# load bug location address to $t1
	lw $t2, 0($t0)		# laod actual flea location to $t2
	lw $t3, 0($t1)		# load actual bug location to $t3
	
	lw $t4, displayAddress  # $t4 stores the base address for display
	li $t5, 0x000000	# $t5 stores the black colour code
	
	bne $t2, $t3, old_flea_not_on_blaster	# if the old flea and bug location are not the same, the old flea's location is black
	li $t5, 0xffffff			# otherwise it is white
	
	old_flea_not_on_blaster:
	# paint old location of flea black, or white if it was the bug location
		sll $t6,$t2, 2		# $t6 is the bias of the old flea location in memory (offset*4)
		add $t6, $t4, $t6	# $t6 is the address of the old flea location
		sw $t5, 0($t6)	        # paint the old flea location black 
		
	# find new random location for flea
	find_new_flea_location:
	
	lw $t2, 0($t0)
	
	li $v0, 42   # for random int within a range
	li $a0, 0    # random value will be in $a0
	li $a1, 8  # max 7, since the flea can move in 8 (0-7) directions
	syscall
	
	# dependint on what $a0 holds (0-7), go a direction
	li $t7, 0
	beq $a0, $t7, flea_n	
	
	li $t7, 1
	beq $a0, $t7, flea_ne	
	
	li $t7, 2
	beq $a0, $t7, flea_e	
	
	li $t7, 3
	beq $a0, $t7, flea_se	

	li $t7, 4
	beq $a0, $t7, flea_s	
	
	li $t7, 5
	beq $a0, $t7, flea_sw	
	
	li $t7, 6
	beq $a0, $t7, flea_w	
	
	j flea_nw		
	
	# depending on the direction, the new flea location moves 1 pixel in that direction
	flea_n:
	addi $t2, $t2, -32
	j check_new_flea_location
	
	flea_ne:
	addi $t2, $t2, -31
	j check_new_flea_location
	
	flea_e:
	addi $t2, $t2, 1
	j check_new_flea_location
		
	flea_se:
	addi $t2, $t2, 33
	j check_new_flea_location
		
	flea_s:
	addi $t2, $t2, 32
	j check_new_flea_location
		
	flea_sw:
	addi $t2, $t2, 31
	j check_new_flea_location	
	
	flea_w:
	addi $t2, $t2, -1
	j check_new_flea_location
	
	flea_nw:
	addi $t2, $t2, -33
	j check_new_flea_location
	
		
	# make sure new random location is in boundaries and is not the centipede or a mushroom
	check_new_flea_location:
	
	rem $t7, $t2, 32 	# $t7 stores the x location of the new flea location
	beq $t7, 0, find_new_flea_location  # make sure flea is not on left wall
	beq $t7, 31, find_new_flea_location 	# make sure flea is not on right wall
	bge $t2, 959, find_new_flea_location	# make sure flea is not on bottom of screen
	ble $t2, 831, find_new_flea_location	# make sure flea is not on a top boundary
	
	li $t5, 10
	la $t6, centipedLocation
	flea_on_centiped:	# iterate through each centipede segment, if the flea will be on the centipede find a new flea location
		lw $t8, 0($t6)
		beq $t8, $t2, find_new_flea_location	# make sure flea is not on centipede
		addi $t6, $t6, 4
		addi $t5, $t5, -1
		bne $t5, $zero, flea_on_centiped
	
	lw $t5, mushroomLimit
	la $t6, mushroomLocation
	flea_on_mushroom:	# iterate through each mushroom, if the flea will be on a mushroom find a new flea location
		lw $t8, 0($t6)
		beq $t8, $t2, find_new_flea_location	# make sure flea is not on mushroom
		addi $t6, $t6, 4
		addi $t5, $t5, -1
		bne $t5, $zero, flea_on_mushroom	
			
		
	# paint new location of flea
	li $t5, 0x1184e8	# $t5 stores the blue colour code
	
	# paint new location of flea blue
	sll $t6,$t2, 2		# $t6 is the bias of the new flea location in memory (offset*4)
	add $t6, $t4, $t6	# $t6 is the address of the new flea location
	sw $t5, 0($t6)	        # paint the new flea location blue 
		
	# save new location of flea
	sw $t2, 0($t0)
	
	# if flea and blaster are in the same location, go to end game loop
	beq $t2, $t3, End_game_loop
	
	# set the fly delay counter to fly delay +1
	la $t0, fleaDelayCounter
	lw $t1, fleaDelay
	addi $t1, $t1, 1
	sw $t1, 0($t0)
	
	# subtract 1 from the fly delay counter
	flea_done:
	la $t0, fleaDelayCounter
	lw $t1, 0($t0)
	addi $t1, $t1, -1
	sw $t1, 0($t0)	

	flea_finish:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


### key input ###

# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

		
# function to get the input key 
	
get_keyboard_input:	# checks if a key is 
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j	# j was pressed
	beq $t2, 0x6B, respond_to_k	# k was pressed
	beq $t2, 0x78, respond_to_x	# s was pressed
	beq $t2, 0x73, respond_to_s	# x was pressed
	beq $t2, 0x65, respond_to_e	# e was pressed
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	beq $t1, 864, skip_movement_j 	# prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the right
skip_movement_j:
	sw $t1, 0($t0)		# save the bug location

	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 895, skip_movement_k #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement_k:
	sw $t1, 0($t0)		# save the bug location

	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 3
	
	lw $t0, bugLocation	# load the bugLocation from memory in $t0
	la $t1, dartLocation	# load the address of dartLocation from memory in $t1
	lw $t3, dartLimit	# load the dartLimit in $t3 
	li $t4, -1		# -1 for empty dart
	
	find_empty_dart:
		lw $t2, 0($t1)		# load the dart location itself in t2
		
		beq $t2, $t4, make_new_dart
		
		addi $t1,$t1, 4
		addi $t3, $t3, -1
		bne $t3, $zero, find_empty_dart
	
	j finish_init_dart
	
	make_new_dart:
	la $t5, 0($t0)	# t5 is the bug location, which will be the location where the dart spawns
	sw $t5, 0($t1) 	# save the new dart location to the empty dart location in the array 
	
	lw $t6, displayAddress  # $t6 stores the base address for display
	li $t7, 0xfff44f	# $t7 stores the colour yellow
		
	sll $t8,$t5, 2		# $t8 is the bias of the new dart location in memory (offset*4)
	add $t8, $t6, $t8	# $t8 is the address of the new dart location
	sw $t7, 0($t8)	        # paint the new dart location yellow	
	
	finish_init_dart:
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 4
	
	# set bug location to 880
	la $t0, bugLocation
	li $t1, 880
	sw $t1, 0($t0)
	
	# set centipede's health to 3
	la $t0, centipedHealth
	li $t1, 3
	sw $t1, 0($t0)
	
	# set flea's delay counter to equal the flea delay
	la $t0, fleaDelayCounter
	lw $t1, fleaDelay
	sw $t1, 0($t0)
	
	# set game_won to 0
	la $t0, game_won
	li $t1, 0
	sw $t1, 0($t0)

	# set each centipede segment to location 9, 8, ..., 1, 0
	li $t0, 9
	la $t1, centipedLocation
	init_centipedLocation:
		sw $t0, 0($t1)
		
		addi $t1, $t1, 4
		addi $t0, $t0, -1
		bne $t0, -1, init_centipedLocation
		
	# set each centipede segment's direction to 1
	li $t0, 10
	la $t1, centipedDirection
	li $t2, 1
	init_centipedDirection:
		sw $t2, 0($t1)
		
		addi $t1, $t1, 4
		addi $t0, $t0, -1
		bne $t0, $zero, init_centipedDirection
	
	# set the first centipede segment as the head, all the others are not
	li $t0, 9
	la $t1, centipedHead
	li $t2, 1
	sw $t2, 0($t1)
	addi $t1, $t1, 4
	li $t2, 0
	init_centipedHead:
		sw $t2, 0($t1)
		
		addi $t1, $t1, 4
		addi $t0, $t0, -1
		bne $t0, $zero, init_centipedHead
	
	# set all mushroom locations as 0
	lw $t0, mushroomLimit
	la $t1, mushroomLocation
	li $t2, 0
	set_mushrooms_to_zero:
		sw $t2, 0($t1)
		
		addi $t1, $t1, 4
		addi $t0, $t0, -1
		bne $t0, $zero, set_mushrooms_to_zero
	
	# set all dart locations as -1
	lw $t0, dartLimit
	la $t1, dartLocation
	li $t2, -1
	init_dartLocation:
		sw $t2, 0($t1)
		
		addi $t1, $t1, 4
		addi $t0, $t0, -1
		bne $t0, $zero, init_dartLocation
		
	# paint the whole screen black	
	jal paint_whole_screen_black	
	
	# jump back to the top and start the game
	j start_game
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_e: 
	j Exit	# e to terminate the program gracefully
	

Exit:
	li $v0, 10		# terminate the program gracefully
	syscall


win: 	# if the game is won, set game_won to 1 and go the end game loop
	la $t0, game_won
	li $t1, 1
	sw $t1, 0($t0)
	j End_game_loop	# jump to the end game loop

End_game_loop: # end game loop that plays when the game has been won or lost
	lw $t0, game_won
	beq $t0, 1, display_won	 # if game_won is 1, display the 'win!' message
	jal lost_game		# otherwise display the 'u lose' message
	j displayed_loss
		
	display_won:
		jal win_game 	# display the 'win!' message
		
	displayed_loss:	
	jal check_keystroke	# take keystroke input
	j End_game_loop # loop

s_to_start: # draw 's'	
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	lw $t0, displayAddress
	addi $t0, $t0, 1796	# start near the middle of the screen
	li $t1, 0x04d9ff	# $t1 stores the light blue colour
	#draw s
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 184($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 320($t0)
	sw $t1, 448($t0)
	sw $t1, 568($t0)
	sw $t1, 572($t0)
	sw $t1, 576($t0)
	jr $ra
						
win_game: # draw 'win!'
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# draw w
	lw $t0, displayAddress
	addi $t0, $t0, 1828	# start near the middle of the screen
	li $t1, 0x04d9ff	# $t1 stores the light blue colour
	sw $t1, 0($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 396($t0)
	sw $t1, 16($t0)
	sw $t1, 144($t0)
	sw $t1, 272($t0)
	sw $t1, 400($t0)
	#draw i
	sw $t1, 24($t0)
	sw $t1, 280($t0)
	sw $t1, 408($t0)
	#draw n
	sw $t1, 32($t0)
	sw $t1, 160($t0)
	sw $t1, 288($t0)
	sw $t1, 416($t0)
	sw $t1, 164($t0)
	sw $t1, 296($t0)
	sw $t1, 44($t0)
	sw $t1, 172($t0)
	sw $t1, 160($t0)
	sw $t1, 300($t0)
	sw $t1, 428($t0)
	#draw !
	sw $t1, 52($t0)
	sw $t1, 180($t0)
	sw $t1, 436($t0)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

lost_game:	# draw 'u lose'
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# draw u
	lw $t0, displayAddress
	addi $t0, $t0, 1816	# start drawing near the middle of the screen
	li $t1, 0x04d9ff	# $t1 stores light blue colour
	sw $t1, 0($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	sw $t1, 12($t0)
	sw $t1, 140($t0)
	sw $t1, 268($t0)
	sw $t1, 396($t0)
	sw $t1, 524($t0)
	#draw l
	sw $t1, 24($t0)
	sw $t1, 152($t0)
	sw $t1, 280($t0)
	sw $t1, 408($t0)
	sw $t1, 536($t0)
	sw $t1, 540($t0)
	sw $t1, 544($t0)
	#draw o
	sw $t1, 168($t0)
	sw $t1, 172($t0)
	sw $t1, 176($t0)
	sw $t1, 296($t0)
	sw $t1, 304($t0)
	sw $t1, 424($t0)
	sw $t1, 428($t0)
	sw $t1, 432($t0)
	#draw s
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 184($t0)
	sw $t1, 312($t0)
	sw $t1, 316($t0)
	sw $t1, 320($t0)
	sw $t1, 448($t0)
	sw $t1, 568($t0)
	sw $t1, 572($t0)
	sw $t1, 576($t0)
	#draw e
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	sw $t1, 200($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 336($t0)
	sw $t1, 456($t0)
	sw $t1, 584($t0)
	sw $t1, 588($t0)
	sw $t1, 592($t0)
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
paint_whole_screen_black: 	# goes through every pixel and paints it black
				# this code was generated in python so I wouldn't have to manually write each line
			
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, displayAddress
	li $t1, 0x000000
sw $t1, 0($t0)
sw $t1, 4($t0)
sw $t1, 8($t0)
sw $t1, 12($t0)
sw $t1, 16($t0)
sw $t1, 20($t0)
sw $t1, 24($t0)
sw $t1, 28($t0)
sw $t1, 32($t0)
sw $t1, 36($t0)
sw $t1, 40($t0)
sw $t1, 44($t0)
sw $t1, 48($t0)
sw $t1, 52($t0)
sw $t1, 56($t0)
sw $t1, 60($t0)
sw $t1, 64($t0)
sw $t1, 68($t0)
sw $t1, 72($t0)
sw $t1, 76($t0)
sw $t1, 80($t0)
sw $t1, 84($t0)
sw $t1, 88($t0)
sw $t1, 92($t0)
sw $t1, 96($t0)
sw $t1, 100($t0)
sw $t1, 104($t0)
sw $t1, 108($t0)
sw $t1, 112($t0)
sw $t1, 116($t0)
sw $t1, 120($t0)
sw $t1, 124($t0)
sw $t1, 128($t0)
sw $t1, 132($t0)
sw $t1, 136($t0)
sw $t1, 140($t0)
sw $t1, 144($t0)
sw $t1, 148($t0)
sw $t1, 152($t0)
sw $t1, 156($t0)
sw $t1, 160($t0)
sw $t1, 164($t0)
sw $t1, 168($t0)
sw $t1, 172($t0)
sw $t1, 176($t0)
sw $t1, 180($t0)
sw $t1, 184($t0)
sw $t1, 188($t0)
sw $t1, 192($t0)
sw $t1, 196($t0)
sw $t1, 200($t0)
sw $t1, 204($t0)
sw $t1, 208($t0)
sw $t1, 212($t0)
sw $t1, 216($t0)
sw $t1, 220($t0)
sw $t1, 224($t0)
sw $t1, 228($t0)
sw $t1, 232($t0)
sw $t1, 236($t0)
sw $t1, 240($t0)
sw $t1, 244($t0)
sw $t1, 248($t0)
sw $t1, 252($t0)
sw $t1, 256($t0)
sw $t1, 260($t0)
sw $t1, 264($t0)
sw $t1, 268($t0)
sw $t1, 272($t0)
sw $t1, 276($t0)
sw $t1, 280($t0)
sw $t1, 284($t0)
sw $t1, 288($t0)
sw $t1, 292($t0)
sw $t1, 296($t0)
sw $t1, 300($t0)
sw $t1, 304($t0)
sw $t1, 308($t0)
sw $t1, 312($t0)
sw $t1, 316($t0)
sw $t1, 320($t0)
sw $t1, 324($t0)
sw $t1, 328($t0)
sw $t1, 332($t0)
sw $t1, 336($t0)
sw $t1, 340($t0)
sw $t1, 344($t0)
sw $t1, 348($t0)
sw $t1, 352($t0)
sw $t1, 356($t0)
sw $t1, 360($t0)
sw $t1, 364($t0)
sw $t1, 368($t0)
sw $t1, 372($t0)
sw $t1, 376($t0)
sw $t1, 380($t0)
sw $t1, 384($t0)
sw $t1, 388($t0)
sw $t1, 392($t0)
sw $t1, 396($t0)
sw $t1, 400($t0)
sw $t1, 404($t0)
sw $t1, 408($t0)
sw $t1, 412($t0)
sw $t1, 416($t0)
sw $t1, 420($t0)
sw $t1, 424($t0)
sw $t1, 428($t0)
sw $t1, 432($t0)
sw $t1, 436($t0)
sw $t1, 440($t0)
sw $t1, 444($t0)
sw $t1, 448($t0)
sw $t1, 452($t0)
sw $t1, 456($t0)
sw $t1, 460($t0)
sw $t1, 464($t0)
sw $t1, 468($t0)
sw $t1, 472($t0)
sw $t1, 476($t0)
sw $t1, 480($t0)
sw $t1, 484($t0)
sw $t1, 488($t0)
sw $t1, 492($t0)
sw $t1, 496($t0)
sw $t1, 500($t0)
sw $t1, 504($t0)
sw $t1, 508($t0)
sw $t1, 512($t0)
sw $t1, 516($t0)
sw $t1, 520($t0)
sw $t1, 524($t0)
sw $t1, 528($t0)
sw $t1, 532($t0)
sw $t1, 536($t0)
sw $t1, 540($t0)
sw $t1, 544($t0)
sw $t1, 548($t0)
sw $t1, 552($t0)
sw $t1, 556($t0)
sw $t1, 560($t0)
sw $t1, 564($t0)
sw $t1, 568($t0)
sw $t1, 572($t0)
sw $t1, 576($t0)
sw $t1, 580($t0)
sw $t1, 584($t0)
sw $t1, 588($t0)
sw $t1, 592($t0)
sw $t1, 596($t0)
sw $t1, 600($t0)
sw $t1, 604($t0)
sw $t1, 608($t0)
sw $t1, 612($t0)
sw $t1, 616($t0)
sw $t1, 620($t0)
sw $t1, 624($t0)
sw $t1, 628($t0)
sw $t1, 632($t0)
sw $t1, 636($t0)
sw $t1, 640($t0)
sw $t1, 644($t0)
sw $t1, 648($t0)
sw $t1, 652($t0)
sw $t1, 656($t0)
sw $t1, 660($t0)
sw $t1, 664($t0)
sw $t1, 668($t0)
sw $t1, 672($t0)
sw $t1, 676($t0)
sw $t1, 680($t0)
sw $t1, 684($t0)
sw $t1, 688($t0)
sw $t1, 692($t0)
sw $t1, 696($t0)
sw $t1, 700($t0)
sw $t1, 704($t0)
sw $t1, 708($t0)
sw $t1, 712($t0)
sw $t1, 716($t0)
sw $t1, 720($t0)
sw $t1, 724($t0)
sw $t1, 728($t0)
sw $t1, 732($t0)
sw $t1, 736($t0)
sw $t1, 740($t0)
sw $t1, 744($t0)
sw $t1, 748($t0)
sw $t1, 752($t0)
sw $t1, 756($t0)
sw $t1, 760($t0)
sw $t1, 764($t0)
sw $t1, 768($t0)
sw $t1, 772($t0)
sw $t1, 776($t0)
sw $t1, 780($t0)
sw $t1, 784($t0)
sw $t1, 788($t0)
sw $t1, 792($t0)
sw $t1, 796($t0)
sw $t1, 800($t0)
sw $t1, 804($t0)
sw $t1, 808($t0)
sw $t1, 812($t0)
sw $t1, 816($t0)
sw $t1, 820($t0)
sw $t1, 824($t0)
sw $t1, 828($t0)
sw $t1, 832($t0)
sw $t1, 836($t0)
sw $t1, 840($t0)
sw $t1, 844($t0)
sw $t1, 848($t0)
sw $t1, 852($t0)
sw $t1, 856($t0)
sw $t1, 860($t0)
sw $t1, 864($t0)
sw $t1, 868($t0)
sw $t1, 872($t0)
sw $t1, 876($t0)
sw $t1, 880($t0)
sw $t1, 884($t0)
sw $t1, 888($t0)
sw $t1, 892($t0)
sw $t1, 896($t0)
sw $t1, 900($t0)
sw $t1, 904($t0)
sw $t1, 908($t0)
sw $t1, 912($t0)
sw $t1, 916($t0)
sw $t1, 920($t0)
sw $t1, 924($t0)
sw $t1, 928($t0)
sw $t1, 932($t0)
sw $t1, 936($t0)
sw $t1, 940($t0)
sw $t1, 944($t0)
sw $t1, 948($t0)
sw $t1, 952($t0)
sw $t1, 956($t0)
sw $t1, 960($t0)
sw $t1, 964($t0)
sw $t1, 968($t0)
sw $t1, 972($t0)
sw $t1, 976($t0)
sw $t1, 980($t0)
sw $t1, 984($t0)
sw $t1, 988($t0)
sw $t1, 992($t0)
sw $t1, 996($t0)
sw $t1, 1000($t0)
sw $t1, 1004($t0)
sw $t1, 1008($t0)
sw $t1, 1012($t0)
sw $t1, 1016($t0)
sw $t1, 1020($t0)
sw $t1, 1024($t0)
sw $t1, 1028($t0)
sw $t1, 1032($t0)
sw $t1, 1036($t0)
sw $t1, 1040($t0)
sw $t1, 1044($t0)
sw $t1, 1048($t0)
sw $t1, 1052($t0)
sw $t1, 1056($t0)
sw $t1, 1060($t0)
sw $t1, 1064($t0)
sw $t1, 1068($t0)
sw $t1, 1072($t0)
sw $t1, 1076($t0)
sw $t1, 1080($t0)
sw $t1, 1084($t0)
sw $t1, 1088($t0)
sw $t1, 1092($t0)
sw $t1, 1096($t0)
sw $t1, 1100($t0)
sw $t1, 1104($t0)
sw $t1, 1108($t0)
sw $t1, 1112($t0)
sw $t1, 1116($t0)
sw $t1, 1120($t0)
sw $t1, 1124($t0)
sw $t1, 1128($t0)
sw $t1, 1132($t0)
sw $t1, 1136($t0)
sw $t1, 1140($t0)
sw $t1, 1144($t0)
sw $t1, 1148($t0)
sw $t1, 1152($t0)
sw $t1, 1156($t0)
sw $t1, 1160($t0)
sw $t1, 1164($t0)
sw $t1, 1168($t0)
sw $t1, 1172($t0)
sw $t1, 1176($t0)
sw $t1, 1180($t0)
sw $t1, 1184($t0)
sw $t1, 1188($t0)
sw $t1, 1192($t0)
sw $t1, 1196($t0)
sw $t1, 1200($t0)
sw $t1, 1204($t0)
sw $t1, 1208($t0)
sw $t1, 1212($t0)
sw $t1, 1216($t0)
sw $t1, 1220($t0)
sw $t1, 1224($t0)
sw $t1, 1228($t0)
sw $t1, 1232($t0)
sw $t1, 1236($t0)
sw $t1, 1240($t0)
sw $t1, 1244($t0)
sw $t1, 1248($t0)
sw $t1, 1252($t0)
sw $t1, 1256($t0)
sw $t1, 1260($t0)
sw $t1, 1264($t0)
sw $t1, 1268($t0)
sw $t1, 1272($t0)
sw $t1, 1276($t0)
sw $t1, 1280($t0)
sw $t1, 1284($t0)
sw $t1, 1288($t0)
sw $t1, 1292($t0)
sw $t1, 1296($t0)
sw $t1, 1300($t0)
sw $t1, 1304($t0)
sw $t1, 1308($t0)
sw $t1, 1312($t0)
sw $t1, 1316($t0)
sw $t1, 1320($t0)
sw $t1, 1324($t0)
sw $t1, 1328($t0)
sw $t1, 1332($t0)
sw $t1, 1336($t0)
sw $t1, 1340($t0)
sw $t1, 1344($t0)
sw $t1, 1348($t0)
sw $t1, 1352($t0)
sw $t1, 1356($t0)
sw $t1, 1360($t0)
sw $t1, 1364($t0)
sw $t1, 1368($t0)
sw $t1, 1372($t0)
sw $t1, 1376($t0)
sw $t1, 1380($t0)
sw $t1, 1384($t0)
sw $t1, 1388($t0)
sw $t1, 1392($t0)
sw $t1, 1396($t0)
sw $t1, 1400($t0)
sw $t1, 1404($t0)
sw $t1, 1408($t0)
sw $t1, 1412($t0)
sw $t1, 1416($t0)
sw $t1, 1420($t0)
sw $t1, 1424($t0)
sw $t1, 1428($t0)
sw $t1, 1432($t0)
sw $t1, 1436($t0)
sw $t1, 1440($t0)
sw $t1, 1444($t0)
sw $t1, 1448($t0)
sw $t1, 1452($t0)
sw $t1, 1456($t0)
sw $t1, 1460($t0)
sw $t1, 1464($t0)
sw $t1, 1468($t0)
sw $t1, 1472($t0)
sw $t1, 1476($t0)
sw $t1, 1480($t0)
sw $t1, 1484($t0)
sw $t1, 1488($t0)
sw $t1, 1492($t0)
sw $t1, 1496($t0)
sw $t1, 1500($t0)
sw $t1, 1504($t0)
sw $t1, 1508($t0)
sw $t1, 1512($t0)
sw $t1, 1516($t0)
sw $t1, 1520($t0)
sw $t1, 1524($t0)
sw $t1, 1528($t0)
sw $t1, 1532($t0)
sw $t1, 1536($t0)
sw $t1, 1540($t0)
sw $t1, 1544($t0)
sw $t1, 1548($t0)
sw $t1, 1552($t0)
sw $t1, 1556($t0)
sw $t1, 1560($t0)
sw $t1, 1564($t0)
sw $t1, 1568($t0)
sw $t1, 1572($t0)
sw $t1, 1576($t0)
sw $t1, 1580($t0)
sw $t1, 1584($t0)
sw $t1, 1588($t0)
sw $t1, 1592($t0)
sw $t1, 1596($t0)
sw $t1, 1600($t0)
sw $t1, 1604($t0)
sw $t1, 1608($t0)
sw $t1, 1612($t0)
sw $t1, 1616($t0)
sw $t1, 1620($t0)
sw $t1, 1624($t0)
sw $t1, 1628($t0)
sw $t1, 1632($t0)
sw $t1, 1636($t0)
sw $t1, 1640($t0)
sw $t1, 1644($t0)
sw $t1, 1648($t0)
sw $t1, 1652($t0)
sw $t1, 1656($t0)
sw $t1, 1660($t0)
sw $t1, 1664($t0)
sw $t1, 1668($t0)
sw $t1, 1672($t0)
sw $t1, 1676($t0)
sw $t1, 1680($t0)
sw $t1, 1684($t0)
sw $t1, 1688($t0)
sw $t1, 1692($t0)
sw $t1, 1696($t0)
sw $t1, 1700($t0)
sw $t1, 1704($t0)
sw $t1, 1708($t0)
sw $t1, 1712($t0)
sw $t1, 1716($t0)
sw $t1, 1720($t0)
sw $t1, 1724($t0)
sw $t1, 1728($t0)
sw $t1, 1732($t0)
sw $t1, 1736($t0)
sw $t1, 1740($t0)
sw $t1, 1744($t0)
sw $t1, 1748($t0)
sw $t1, 1752($t0)
sw $t1, 1756($t0)
sw $t1, 1760($t0)
sw $t1, 1764($t0)
sw $t1, 1768($t0)
sw $t1, 1772($t0)
sw $t1, 1776($t0)
sw $t1, 1780($t0)
sw $t1, 1784($t0)
sw $t1, 1788($t0)
sw $t1, 1792($t0)
sw $t1, 1796($t0)
sw $t1, 1800($t0)
sw $t1, 1804($t0)
sw $t1, 1808($t0)
sw $t1, 1812($t0)
sw $t1, 1816($t0)
sw $t1, 1820($t0)
sw $t1, 1824($t0)
sw $t1, 1828($t0)
sw $t1, 1832($t0)
sw $t1, 1836($t0)
sw $t1, 1840($t0)
sw $t1, 1844($t0)
sw $t1, 1848($t0)
sw $t1, 1852($t0)
sw $t1, 1856($t0)
sw $t1, 1860($t0)
sw $t1, 1864($t0)
sw $t1, 1868($t0)
sw $t1, 1872($t0)
sw $t1, 1876($t0)
sw $t1, 1880($t0)
sw $t1, 1884($t0)
sw $t1, 1888($t0)
sw $t1, 1892($t0)
sw $t1, 1896($t0)
sw $t1, 1900($t0)
sw $t1, 1904($t0)
sw $t1, 1908($t0)
sw $t1, 1912($t0)
sw $t1, 1916($t0)
sw $t1, 1920($t0)
sw $t1, 1924($t0)
sw $t1, 1928($t0)
sw $t1, 1932($t0)
sw $t1, 1936($t0)
sw $t1, 1940($t0)
sw $t1, 1944($t0)
sw $t1, 1948($t0)
sw $t1, 1952($t0)
sw $t1, 1956($t0)
sw $t1, 1960($t0)
sw $t1, 1964($t0)
sw $t1, 1968($t0)
sw $t1, 1972($t0)
sw $t1, 1976($t0)
sw $t1, 1980($t0)
sw $t1, 1984($t0)
sw $t1, 1988($t0)
sw $t1, 1992($t0)
sw $t1, 1996($t0)
sw $t1, 2000($t0)
sw $t1, 2004($t0)
sw $t1, 2008($t0)
sw $t1, 2012($t0)
sw $t1, 2016($t0)
sw $t1, 2020($t0)
sw $t1, 2024($t0)
sw $t1, 2028($t0)
sw $t1, 2032($t0)
sw $t1, 2036($t0)
sw $t1, 2040($t0)
sw $t1, 2044($t0)
sw $t1, 2048($t0)
sw $t1, 2052($t0)
sw $t1, 2056($t0)
sw $t1, 2060($t0)
sw $t1, 2064($t0)
sw $t1, 2068($t0)
sw $t1, 2072($t0)
sw $t1, 2076($t0)
sw $t1, 2080($t0)
sw $t1, 2084($t0)
sw $t1, 2088($t0)
sw $t1, 2092($t0)
sw $t1, 2096($t0)
sw $t1, 2100($t0)
sw $t1, 2104($t0)
sw $t1, 2108($t0)
sw $t1, 2112($t0)
sw $t1, 2116($t0)
sw $t1, 2120($t0)
sw $t1, 2124($t0)
sw $t1, 2128($t0)
sw $t1, 2132($t0)
sw $t1, 2136($t0)
sw $t1, 2140($t0)
sw $t1, 2144($t0)
sw $t1, 2148($t0)
sw $t1, 2152($t0)
sw $t1, 2156($t0)
sw $t1, 2160($t0)
sw $t1, 2164($t0)
sw $t1, 2168($t0)
sw $t1, 2172($t0)
sw $t1, 2176($t0)
sw $t1, 2180($t0)
sw $t1, 2184($t0)
sw $t1, 2188($t0)
sw $t1, 2192($t0)
sw $t1, 2196($t0)
sw $t1, 2200($t0)
sw $t1, 2204($t0)
sw $t1, 2208($t0)
sw $t1, 2212($t0)
sw $t1, 2216($t0)
sw $t1, 2220($t0)
sw $t1, 2224($t0)
sw $t1, 2228($t0)
sw $t1, 2232($t0)
sw $t1, 2236($t0)
sw $t1, 2240($t0)
sw $t1, 2244($t0)
sw $t1, 2248($t0)
sw $t1, 2252($t0)
sw $t1, 2256($t0)
sw $t1, 2260($t0)
sw $t1, 2264($t0)
sw $t1, 2268($t0)
sw $t1, 2272($t0)
sw $t1, 2276($t0)
sw $t1, 2280($t0)
sw $t1, 2284($t0)
sw $t1, 2288($t0)
sw $t1, 2292($t0)
sw $t1, 2296($t0)
sw $t1, 2300($t0)
sw $t1, 2304($t0)
sw $t1, 2308($t0)
sw $t1, 2312($t0)
sw $t1, 2316($t0)
sw $t1, 2320($t0)
sw $t1, 2324($t0)
sw $t1, 2328($t0)
sw $t1, 2332($t0)
sw $t1, 2336($t0)
sw $t1, 2340($t0)
sw $t1, 2344($t0)
sw $t1, 2348($t0)
sw $t1, 2352($t0)
sw $t1, 2356($t0)
sw $t1, 2360($t0)
sw $t1, 2364($t0)
sw $t1, 2368($t0)
sw $t1, 2372($t0)
sw $t1, 2376($t0)
sw $t1, 2380($t0)
sw $t1, 2384($t0)
sw $t1, 2388($t0)
sw $t1, 2392($t0)
sw $t1, 2396($t0)
sw $t1, 2400($t0)
sw $t1, 2404($t0)
sw $t1, 2408($t0)
sw $t1, 2412($t0)
sw $t1, 2416($t0)
sw $t1, 2420($t0)
sw $t1, 2424($t0)
sw $t1, 2428($t0)
sw $t1, 2432($t0)
sw $t1, 2436($t0)
sw $t1, 2440($t0)
sw $t1, 2444($t0)
sw $t1, 2448($t0)
sw $t1, 2452($t0)
sw $t1, 2456($t0)
sw $t1, 2460($t0)
sw $t1, 2464($t0)
sw $t1, 2468($t0)
sw $t1, 2472($t0)
sw $t1, 2476($t0)
sw $t1, 2480($t0)
sw $t1, 2484($t0)
sw $t1, 2488($t0)
sw $t1, 2492($t0)
sw $t1, 2496($t0)
sw $t1, 2500($t0)
sw $t1, 2504($t0)
sw $t1, 2508($t0)
sw $t1, 2512($t0)
sw $t1, 2516($t0)
sw $t1, 2520($t0)
sw $t1, 2524($t0)
sw $t1, 2528($t0)
sw $t1, 2532($t0)
sw $t1, 2536($t0)
sw $t1, 2540($t0)
sw $t1, 2544($t0)
sw $t1, 2548($t0)
sw $t1, 2552($t0)
sw $t1, 2556($t0)
sw $t1, 2560($t0)
sw $t1, 2564($t0)
sw $t1, 2568($t0)
sw $t1, 2572($t0)
sw $t1, 2576($t0)
sw $t1, 2580($t0)
sw $t1, 2584($t0)
sw $t1, 2588($t0)
sw $t1, 2592($t0)
sw $t1, 2596($t0)
sw $t1, 2600($t0)
sw $t1, 2604($t0)
sw $t1, 2608($t0)
sw $t1, 2612($t0)
sw $t1, 2616($t0)
sw $t1, 2620($t0)
sw $t1, 2624($t0)
sw $t1, 2628($t0)
sw $t1, 2632($t0)
sw $t1, 2636($t0)
sw $t1, 2640($t0)
sw $t1, 2644($t0)
sw $t1, 2648($t0)
sw $t1, 2652($t0)
sw $t1, 2656($t0)
sw $t1, 2660($t0)
sw $t1, 2664($t0)
sw $t1, 2668($t0)
sw $t1, 2672($t0)
sw $t1, 2676($t0)
sw $t1, 2680($t0)
sw $t1, 2684($t0)
sw $t1, 2688($t0)
sw $t1, 2692($t0)
sw $t1, 2696($t0)
sw $t1, 2700($t0)
sw $t1, 2704($t0)
sw $t1, 2708($t0)
sw $t1, 2712($t0)
sw $t1, 2716($t0)
sw $t1, 2720($t0)
sw $t1, 2724($t0)
sw $t1, 2728($t0)
sw $t1, 2732($t0)
sw $t1, 2736($t0)
sw $t1, 2740($t0)
sw $t1, 2744($t0)
sw $t1, 2748($t0)
sw $t1, 2752($t0)
sw $t1, 2756($t0)
sw $t1, 2760($t0)
sw $t1, 2764($t0)
sw $t1, 2768($t0)
sw $t1, 2772($t0)
sw $t1, 2776($t0)
sw $t1, 2780($t0)
sw $t1, 2784($t0)
sw $t1, 2788($t0)
sw $t1, 2792($t0)
sw $t1, 2796($t0)
sw $t1, 2800($t0)
sw $t1, 2804($t0)
sw $t1, 2808($t0)
sw $t1, 2812($t0)
sw $t1, 2816($t0)
sw $t1, 2820($t0)
sw $t1, 2824($t0)
sw $t1, 2828($t0)
sw $t1, 2832($t0)
sw $t1, 2836($t0)
sw $t1, 2840($t0)
sw $t1, 2844($t0)
sw $t1, 2848($t0)
sw $t1, 2852($t0)
sw $t1, 2856($t0)
sw $t1, 2860($t0)
sw $t1, 2864($t0)
sw $t1, 2868($t0)
sw $t1, 2872($t0)
sw $t1, 2876($t0)
sw $t1, 2880($t0)
sw $t1, 2884($t0)
sw $t1, 2888($t0)
sw $t1, 2892($t0)
sw $t1, 2896($t0)
sw $t1, 2900($t0)
sw $t1, 2904($t0)
sw $t1, 2908($t0)
sw $t1, 2912($t0)
sw $t1, 2916($t0)
sw $t1, 2920($t0)
sw $t1, 2924($t0)
sw $t1, 2928($t0)
sw $t1, 2932($t0)
sw $t1, 2936($t0)
sw $t1, 2940($t0)
sw $t1, 2944($t0)
sw $t1, 2948($t0)
sw $t1, 2952($t0)
sw $t1, 2956($t0)
sw $t1, 2960($t0)
sw $t1, 2964($t0)
sw $t1, 2968($t0)
sw $t1, 2972($t0)
sw $t1, 2976($t0)
sw $t1, 2980($t0)
sw $t1, 2984($t0)
sw $t1, 2988($t0)
sw $t1, 2992($t0)
sw $t1, 2996($t0)
sw $t1, 3000($t0)
sw $t1, 3004($t0)
sw $t1, 3008($t0)
sw $t1, 3012($t0)
sw $t1, 3016($t0)
sw $t1, 3020($t0)
sw $t1, 3024($t0)
sw $t1, 3028($t0)
sw $t1, 3032($t0)
sw $t1, 3036($t0)
sw $t1, 3040($t0)
sw $t1, 3044($t0)
sw $t1, 3048($t0)
sw $t1, 3052($t0)
sw $t1, 3056($t0)
sw $t1, 3060($t0)
sw $t1, 3064($t0)
sw $t1, 3068($t0)
sw $t1, 3072($t0)
sw $t1, 3076($t0)
sw $t1, 3080($t0)
sw $t1, 3084($t0)
sw $t1, 3088($t0)
sw $t1, 3092($t0)
sw $t1, 3096($t0)
sw $t1, 3100($t0)
sw $t1, 3104($t0)
sw $t1, 3108($t0)
sw $t1, 3112($t0)
sw $t1, 3116($t0)
sw $t1, 3120($t0)
sw $t1, 3124($t0)
sw $t1, 3128($t0)
sw $t1, 3132($t0)
sw $t1, 3136($t0)
sw $t1, 3140($t0)
sw $t1, 3144($t0)
sw $t1, 3148($t0)
sw $t1, 3152($t0)
sw $t1, 3156($t0)
sw $t1, 3160($t0)
sw $t1, 3164($t0)
sw $t1, 3168($t0)
sw $t1, 3172($t0)
sw $t1, 3176($t0)
sw $t1, 3180($t0)
sw $t1, 3184($t0)
sw $t1, 3188($t0)
sw $t1, 3192($t0)
sw $t1, 3196($t0)
sw $t1, 3200($t0)
sw $t1, 3204($t0)
sw $t1, 3208($t0)
sw $t1, 3212($t0)
sw $t1, 3216($t0)
sw $t1, 3220($t0)
sw $t1, 3224($t0)
sw $t1, 3228($t0)
sw $t1, 3232($t0)
sw $t1, 3236($t0)
sw $t1, 3240($t0)
sw $t1, 3244($t0)
sw $t1, 3248($t0)
sw $t1, 3252($t0)
sw $t1, 3256($t0)
sw $t1, 3260($t0)
sw $t1, 3264($t0)
sw $t1, 3268($t0)
sw $t1, 3272($t0)
sw $t1, 3276($t0)
sw $t1, 3280($t0)
sw $t1, 3284($t0)
sw $t1, 3288($t0)
sw $t1, 3292($t0)
sw $t1, 3296($t0)
sw $t1, 3300($t0)
sw $t1, 3304($t0)
sw $t1, 3308($t0)
sw $t1, 3312($t0)
sw $t1, 3316($t0)
sw $t1, 3320($t0)
sw $t1, 3324($t0)
sw $t1, 3328($t0)
sw $t1, 3332($t0)
sw $t1, 3336($t0)
sw $t1, 3340($t0)
sw $t1, 3344($t0)
sw $t1, 3348($t0)
sw $t1, 3352($t0)
sw $t1, 3356($t0)
sw $t1, 3360($t0)
sw $t1, 3364($t0)
sw $t1, 3368($t0)
sw $t1, 3372($t0)
sw $t1, 3376($t0)
sw $t1, 3380($t0)
sw $t1, 3384($t0)
sw $t1, 3388($t0)
sw $t1, 3392($t0)
sw $t1, 3396($t0)
sw $t1, 3400($t0)
sw $t1, 3404($t0)
sw $t1, 3408($t0)
sw $t1, 3412($t0)
sw $t1, 3416($t0)
sw $t1, 3420($t0)
sw $t1, 3424($t0)
sw $t1, 3428($t0)
sw $t1, 3432($t0)
sw $t1, 3436($t0)
sw $t1, 3440($t0)
sw $t1, 3444($t0)
sw $t1, 3448($t0)
sw $t1, 3452($t0)
sw $t1, 3456($t0)
sw $t1, 3460($t0)
sw $t1, 3464($t0)
sw $t1, 3468($t0)
sw $t1, 3472($t0)
sw $t1, 3476($t0)
sw $t1, 3480($t0)
sw $t1, 3484($t0)
sw $t1, 3488($t0)
sw $t1, 3492($t0)
sw $t1, 3496($t0)
sw $t1, 3500($t0)
sw $t1, 3504($t0)
sw $t1, 3508($t0)
sw $t1, 3512($t0)
sw $t1, 3516($t0)
sw $t1, 3520($t0)
sw $t1, 3524($t0)
sw $t1, 3528($t0)
sw $t1, 3532($t0)
sw $t1, 3536($t0)
sw $t1, 3540($t0)
sw $t1, 3544($t0)
sw $t1, 3548($t0)
sw $t1, 3552($t0)
sw $t1, 3556($t0)
sw $t1, 3560($t0)
sw $t1, 3564($t0)
sw $t1, 3568($t0)
sw $t1, 3572($t0)
sw $t1, 3576($t0)
sw $t1, 3580($t0)
sw $t1, 3584($t0)
sw $t1, 3588($t0)
sw $t1, 3592($t0)
sw $t1, 3596($t0)
sw $t1, 3600($t0)
sw $t1, 3604($t0)
sw $t1, 3608($t0)
sw $t1, 3612($t0)
sw $t1, 3616($t0)
sw $t1, 3620($t0)
sw $t1, 3624($t0)
sw $t1, 3628($t0)
sw $t1, 3632($t0)
sw $t1, 3636($t0)
sw $t1, 3640($t0)
sw $t1, 3644($t0)
sw $t1, 3648($t0)
sw $t1, 3652($t0)
sw $t1, 3656($t0)
sw $t1, 3660($t0)
sw $t1, 3664($t0)
sw $t1, 3668($t0)
sw $t1, 3672($t0)
sw $t1, 3676($t0)
sw $t1, 3680($t0)
sw $t1, 3684($t0)
sw $t1, 3688($t0)
sw $t1, 3692($t0)
sw $t1, 3696($t0)
sw $t1, 3700($t0)
sw $t1, 3704($t0)
sw $t1, 3708($t0)
sw $t1, 3712($t0)
sw $t1, 3716($t0)
sw $t1, 3720($t0)
sw $t1, 3724($t0)
sw $t1, 3728($t0)
sw $t1, 3732($t0)
sw $t1, 3736($t0)
sw $t1, 3740($t0)
sw $t1, 3744($t0)
sw $t1, 3748($t0)
sw $t1, 3752($t0)
sw $t1, 3756($t0)
sw $t1, 3760($t0)
sw $t1, 3764($t0)
sw $t1, 3768($t0)
sw $t1, 3772($t0)
sw $t1, 3776($t0)
sw $t1, 3780($t0)
sw $t1, 3784($t0)
sw $t1, 3788($t0)
sw $t1, 3792($t0)
sw $t1, 3796($t0)
sw $t1, 3800($t0)
sw $t1, 3804($t0)
sw $t1, 3808($t0)
sw $t1, 3812($t0)
sw $t1, 3816($t0)
sw $t1, 3820($t0)
sw $t1, 3824($t0)
sw $t1, 3828($t0)
sw $t1, 3832($t0)
sw $t1, 3836($t0)
sw $t1, 3840($t0)
sw $t1, 3844($t0)
sw $t1, 3848($t0)
sw $t1, 3852($t0)
sw $t1, 3856($t0)
sw $t1, 3860($t0)
sw $t1, 3864($t0)
sw $t1, 3868($t0)
sw $t1, 3872($t0)
sw $t1, 3876($t0)
sw $t1, 3880($t0)
sw $t1, 3884($t0)
sw $t1, 3888($t0)
sw $t1, 3892($t0)
sw $t1, 3896($t0)
sw $t1, 3900($t0)
sw $t1, 3904($t0)
sw $t1, 3908($t0)
sw $t1, 3912($t0)
sw $t1, 3916($t0)
sw $t1, 3920($t0)
sw $t1, 3924($t0)
sw $t1, 3928($t0)
sw $t1, 3932($t0)
sw $t1, 3936($t0)
sw $t1, 3940($t0)
sw $t1, 3944($t0)
sw $t1, 3948($t0)
sw $t1, 3952($t0)
sw $t1, 3956($t0)
sw $t1, 3960($t0)
sw $t1, 3964($t0)
sw $t1, 3968($t0)
sw $t1, 3972($t0)
sw $t1, 3976($t0)
sw $t1, 3980($t0)
sw $t1, 3984($t0)
sw $t1, 3988($t0)
sw $t1, 3992($t0)
sw $t1, 3996($t0)
sw $t1, 4000($t0)
sw $t1, 4004($t0)
sw $t1, 4008($t0)
sw $t1, 4012($t0)
sw $t1, 4016($t0)
sw $t1, 4020($t0)
sw $t1, 4024($t0)
sw $t1, 4028($t0)
sw $t1, 4032($t0)
sw $t1, 4036($t0)
sw $t1, 4040($t0)
sw $t1, 4044($t0)
sw $t1, 4048($t0)
sw $t1, 4052($t0)
sw $t1, 4056($t0)
sw $t1, 4060($t0)
sw $t1, 4064($t0)
sw $t1, 4068($t0)
sw $t1, 4072($t0)
sw $t1, 4076($t0)
sw $t1, 4080($t0)
sw $t1, 4084($t0)
sw $t1, 4088($t0)
sw $t1, 4092($t0)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
