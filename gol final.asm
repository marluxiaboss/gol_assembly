    ;;    game state memory location
    .equ CURR_STATE, 0x1000              ; current game state
    .equ GSA_ID, 0x1004                     ; gsa currently in use for drawing
    .equ PAUSE, 0x1008                     ; is the game paused or running
    .equ SPEED, 0x100C                      ; game speed
    .equ CURR_STEP,  0x1010              ; game current step
    .equ SEED, 0x1014              ; game seed
    .equ GSA0, 0x1018              ; GSA0 starting address
    .equ GSA1, 0x1038              ; GSA1 starting address
    .equ SEVEN_SEGS, 0x1198             ; 7-segment display addresses
    .equ CUSTOM_VAR_START, 0x1200 ; Free range of addresses for custom variable definition
    .equ CUSTOM_VAR_END, 0x1300
    .equ LEDS, 0x2000                       ; LED address
    .equ RANDOM_NUM, 0x2010          ; Random number generator address
    .equ BUTTONS, 0x2030                 ; Buttons addresses

    ;; states
    .equ INIT, 0
    .equ RAND, 1
    .equ RUN, 2

    ;; constants
    .equ N_SEEDS, 4
    .equ N_GSA_LINES, 8
    .equ N_GSA_COLUMNS, 12
    .equ MAX_SPEED, 10
    .equ MIN_SPEED, 1
    .equ PAUSED, 0x00
    .equ RUNNING, 0x01

; BEGIN:main
main:
	addi sp, zero, LEDS #initialize stack pointer¨
	addi sp, sp, -4
   	stw ra, 0(sp)
	call reset_game
   	ldw ra, 0(sp)
	addi sp, sp, 4

	addi sp, sp, -4
   	stw ra, 0(sp)
	call get_input
   	ldw ra, 0(sp)
	addi sp, sp, 4
	add s6, zero, v0
	addi s7, zero, 0 #s7 is done var
	inner_loop:
	add a0, s6, zero
	addi sp, sp, -4
   	stw ra, 0(sp)
	call select_action
   	ldw ra, 0(sp)
	addi sp, sp, 4

	add a0, s6, zero
	addi sp, sp, -4
   	stw ra, 0(sp)
	call update_state
   	ldw ra, 0(sp)
	addi sp, sp, 4
	
	
	addi sp, sp, -4
   	stw ra, 0(sp)
	call update_gsa
   	ldw ra, 0(sp)
	addi sp, sp, 4
	
	addi sp, sp, -4
   	stw ra, 0(sp)
	call mask
   	ldw ra, 8(sp)
	addi sp, sp, 4
	
	addi sp, sp, -4
   	stw ra, 0(sp)
	call draw_gsa
   	ldw ra, 0(sp)
	addi sp, sp, 4


	addi sp, sp, -4
   	stw ra, 0(sp)
	call wait
   	ldw ra, 0(sp)
	addi sp, sp, 4
	
	addi sp, sp, -4
   	stw ra, 0(sp)
	call decrement_step
   	ldw ra, 0(sp)
	addi sp, sp, 4

	
	add s7, zero, v0

	addi sp, sp, -4
   	stw ra, 0(sp)
	call get_input
   	ldw ra, 0(sp)
	addi sp, sp, 4
	
	add s6, zero, v0
	beq s7, zero, inner_loop
	jmpi main 
; END:main	
; BEGIN:clear_leds
    clear_leds:
   	 stw zero, 0x2000(zero)
   	 stw zero, 0x2004(zero)
   	 stw zero, 0x2008(zero)
   	 ret
 ; END:clear_leds
	
; BEGIN:set_pixel
set_pixel:
	addi t0, zero, 1
	#on place selon y et on shift de 8*(x mod 4)
	sll t0, t0, a1
	add t1, zero, a0
	#faire un custom modulo 4 qui prend entre 0 a 11 : trois cas 1) compris entre 0 et 3 ...
	addi t3, zero, 4
	addi t4, zero, 8
	#use a stack pointer or register s here!
	bge t1, t4, case_3
	bge t1, t3, case_2
	bge t1, zero, case_1
	continue:
	add t1, zero, v0 #t1 contains x mod 4
	#srli t1, t1, 2 #t1 contains x mod 4
	slli t2, t1, 3 #t2 contains 8*t1
	sll  t0, t0, t2 #shift y de (8*(x mod 4)) = t2
	slli t5, t5, 2 #according to our case t5 is either 0,1 or 2 and we mutiply by 4 to have correct address


	ldw t6, LEDS(t5) #previous pixel set
	or t0, t6,t0 #concatenation of previous pixel set and the pixel we want to set here

	stw  t0, LEDS(t5) #store our created word at correct location according to x mod 4
	ret
; END:set_pixel

case_1:
	add v0, a0, zero #nombre entre 0 et 3 modulo 4
	add t5, zero, zero
	jmpi continue
case_2: #nombre entre 4 et 7 modulo 4
	addi v0, a0, -4
	addi t5, zero, 1
	jmpi continue
case_3: #modulo 4 pour nombre entre 8 et 11
	addi v0, a0, -8
	addi t5, zero, 2
	jmpi continue 

; BEGIN:wait
wait:
  ldw t0, SPEED(zero)
  addi s0, zero, 1
  slli s0, s0, 19
  br wait_loop
  ret

; BEGIN:helper
wait_loop:
  sub s0, s0, t0
  bge s0, zero, wait_loop
  ret
; END:helper
; END:wait

; BEGIN:get_gsa
    get_gsa:
   	 addi t0, zero, 1
   	 slli t1, a0, 2
   	 ldw t2, GSA_ID(zero)
   	 beq t2, t0, get_gsa1
   	 ldw v0, GSA0(t1)
   	 ret

; BEGIN:helper
    get_gsa1:
   	 ldw v0, GSA1(t1)
   	 ret
; END:helper
    ; END:get_gsa

; BEGIN:set_gsa
set_gsa:
  	addi t0, zero, 1
  	slli t1, a1, 2
  	ldw t2, GSA_ID(zero)
   	beq t2, t0, set_gsa1
   	stw a0, GSA0(t1)
   	ret

; BEGIN:helper
    set_gsa1:
   	 stw a0, GSA1(t1)
   	 ret
; END:helper
    ; END:set_gsa
; BEGIN:draw_gsa
draw_gsa:
	addi sp, sp, -4
	stw ra, 0(sp)
	call clear_leds
	ldw ra, 0(sp)
	addi sp, sp, 4
	ldw t1, GSA_ID(zero)#t1 is gsa id flag
	
	addi s0, zero, 8 #end of loop_over_rows
	addi s1, zero, 12 #end of loop_over_columns
	bne t1, zero, draw_gsa1
	draw_gsa0: 
		addi t3, zero, 0 #counter for the rows ie coordinate y, it goes from 1 to 8 (every time we need this y coordinate we take t3-1)
		

		loop_over_rows0:
		bge t3, s0, end_loop
		addi t3, t3, 1 #counter y += 1
		addi t2, zero, 0 #counter for the column ie coordinate x, it goes from 0 to 11
		addi t6, t3, -1 #y - 1
		slli t6, t6, 2 #a gsa line corresponds to 1 word ! so we should jump in address by y*4!
		ldw t4, GSA0(t6)#the gsa row that should be printed on leds with the inner loop, should be right shifted for each inner iteration
		


		loop_over_columns0:
		bge t2, s1, loop_over_rows0
		andi t5, t4, 1 #t5 holds first bit of the gsa row 
		add a0, zero, t2 #setup for set_pixel, a0 is x coordinate
		addi a1, t3, -1 
		beq t5,zero, not_draw_pixel0 #comment faire un truc plus clean ici ? genre avoir un call de fonction plutot que un truc qui ne va pas le faire
		#LA IL FAUT UTILISER UN STACK POINTER POUR PROTEGER LES TEMPORARY (cf voir ce qui se passe si on le fait pas) notamment pour t4 car en fait set pixel va les modifier

		addi sp, sp, -36
		stw s1, 32(sp)
		stw s0, 28(sp)
		stw ra, 24(sp)
		stw t1, 20(sp)
		stw t2, 16(sp)
		stw t3, 12(sp)
		stw t4, 8(sp)
		stw t5, 4(sp)
		stw t6, 0(sp)
		#aussi ajouter le ra a push
		call set_pixel
		
		
		ldw t6, 0(sp)
		ldw t5, 4(sp)
		ldw t4, 8(sp)
		ldw t3, 12(sp)
		ldw t2, 16(sp)
		ldw t1, 20(sp)
		ldw ra, 24(sp)
		ldw s0, 28(sp)
		ldw s1, 32(sp)
		addi sp, sp, 36
		not_draw_pixel0:
		



		srai t4, t4, 1
		addi t2, t2, 1  #counter x += 1
		jmpi loop_over_columns0
	


	draw_gsa1:
		addi t3, zero, 0 #counter for the rows ie coordinate y, it goes from 1 to 8
		

		loop_over_rows1:
		bge t3, s0, end_loop
		addi t3, t3, 1 #counter y += 1
		addi t2, zero, 0 #counter for the column ie coordinate x, it goes from 0 to 11
		addi t6, t3, -1 #y - 1
		slli t6, t6, 2 #a gsa line corresponds to 1 word ! so we should jump in address by y*4!
		ldw t4, GSA1(t6)#the gsa row that should be printed on leds with the inner loop
		

		loop_over_columns1:
		bge t2, s1, loop_over_rows1
		andi t5, t4, 1 #t5 holds first bit of the gsa row
		add a0, zero, t2 #setup for set_pixel, a0 is x coordinate
		addi a1, t3, -1 #setup for set_pixel, a1 is y coordinate
		beq t5,zero, not_draw_pixel1



		addi sp, sp, -36
		stw s1, 32(sp)
		stw s0, 28(sp)
		stw ra, 24(sp)
		stw t1, 20(sp)
		stw t2, 16(sp)
		stw t3, 12(sp)
		stw t4, 8(sp)
		stw t5, 4(sp)
		stw t6, 0(sp)
	
		call set_pixel
		
		ldw t6, 0(sp)
		ldw t5, 4(sp)
		ldw t4, 8(sp)
		ldw t3, 12(sp)
		ldw t2, 16(sp)
		ldw t1, 20(sp)
		ldw ra, 24(sp)
		ldw s0, 28(sp)
		ldw s1, 32(sp)
		addi sp, sp, 36
		
		not_draw_pixel1:
		

		srai t4, t4, 1
		addi t2, t2, 1  #counter x += 1
		jmpi loop_over_columns1




	end_loop:
	ret
; END:draw_gsa

    ; BEGIN:random_gsa
random_gsa:
   	 addi s0, zero, 0
   	 addi s1, zero, 0
    	 addi t0, zero, N_GSA_LINES
   	 addi t1, zero, N_GSA_COLUMNS
   	 jmpi loop_over_pixel
   	 ret

    ; BEGIN:helper
    loop_over_pixel:
   	 beq s1, t1, loop_over_line
   	 ldw t3, RANDOM_NUM(zero)
   	 andi t3, t3, 1
   	 slli s3, s3, 1
   	 beq t3, zero, set_0
   	 bne t3, zero, set_1
   	 ret
    
    set_0:
   	 addi s3, s3, 0
   	 addi s1, s1, 1
   	 jmpi loop_over_pixel
   	 ret

    set_1:
   	 addi s3, s3, 1
   	 addi s1, s1, 1
   	 jmpi loop_over_pixel
   	 ret

    loop_over_line:
   	 xor s1, s1, s1
   	 add a0, zero, s3
   	 add a1, zero, s0

     addi sp, sp, -20
	 stw ra, 16(sp)
   	 stw s0, 12(sp)
   	 stw s1, 8(sp)
   	 stw t0, 4(sp)
   	 stw t1, 0(sp)
   	 call set_gsa
   	 ldw t1, 0(sp)
   	 ldw t0, 4(sp)
   	 ldw s1, 8(sp)
   	 ldw s0, 12(sp)
	 ldw ra, 16(sp)
	 addi sp, sp, 20

   	 addi s0, s0, 1
   	 blt s0, t0, loop_over_pixel
   	 ret
    
    ; END:helper
    ; END:random_gsa


; BEGIN:change_speed
change_speed:
   	 ldw t0, SPEED(zero)
   	 beq a0, zero, check_increment
   	 bne a0, zero, check_decrement
   	 ret
    
    ; BEGIN:helper
    check_increment:
   	 addi t1, zero, MAX_SPEED
   	 blt t0, t1, increment
   	 ret

    check_decrement:
   	 addi t1, zero, MIN_SPEED
   	 addi t1, t1, 1
   	 bge t0, t1, decrement
   	 ret

    increment:
   	 addi t0, t0, 1
   	 stw t0, SPEED(zero)
   	 ret
    
    decrement:
   	 addi t0, t0, -1
   	 stw t0, SPEED(zero)
   	 ret


    ; END:helper
    ; END:change_speed

; BEGIN:pause_game
 pause_game:
   	 ldw t0, PAUSE(zero)
   	 beq t0, zero, play
   	 bne t0, zero, pause
   	 ret

    ; BEGIN:helper
    play:
   	 addi t1, zero, 1
   	 stw t1, PAUSE(zero)
   	 ret

    pause:
	addi t1, zero, 0
   	 stw t1, PAUSE(zero)
   	 ret


    ; END:helper
    ; END:pause_game

; BEGIN:change_steps
   change_steps:
   	 ldw s0, CURR_STEP(zero)
	 addi s1, zero, 16
	 addi s2, zero, 256
   	 jmpi condition
   	 ret

    ; BEGIN:helper
    condition:
   	 bne a0, zero, units
   	 bne a1, zero, tens
   	 bne a2, zero, hundreds
   	 stw s0, CURR_STEP(zero)
   	 ret

    units:
   	 xor a0, a0, a0 #reset to 0
    	 andi s3, s0, 15
	 addi s3, s3, 0x0001
    	 bge s3, s1, carry_tens
	 andi s0, s0, 0x0FF0
	 add s0, s0, s3
   	 jmpi condition
   	 ret

    tens:
   	 xor a1, a1, a1 #reset to 0
	 srli s3, s0, 4
     	 andi s3, s3, 15
	 addi s3, s3, 0x0001
    	 bge s3, s1, carry_hundreds
	 andi s0, s0, 0x0F0F
	 slli s3, s3, 4
	 add s0, s0, s3
   	 jmpi condition
   	 ret
    
    hundreds:
   	 addi s0, s0, 0x0100
   	 xor a2, a2, a2 #reset to 0
    	 andi s0, s0, 4095
   	 jmpi condition
   	 ret

    carry_tens:
   	 andi s0, s0, 0x0FF0
   	 addi s0, s0, 0x0010
   	 jmpi condition
   	 ret

    carry_hundreds:
   	 andi s0, s0, 0x0F0F
   	 addi s0, s0, 0x0100
   	 jmpi condition
   	 ret


    ; END:helper
    ; END:change_steps
; BEGIN:increment_seed
  increment_seed:
   	 ldw t0, CURR_STATE(zero)
   	 addi t1, zero, INIT
   	 addi t2, zero, RAND
   	 beq t0, t1, init
   	 beq t0, t2, rand
	 ret

    ; BEGIN:helper
    init:
   	 ldw t3, SEED(zero)
   	 addi t3, t3, 1
   	 stw t3, SEED(zero)
	 addi t4, zero, N_SEEDS
	 beq t3, t4, rand
   	 slli t3, t3, 2
   	 ldw s2, SEEDS(t3)
   	 addi s0, zero, N_GSA_LINES
   	 add s1, zero, zero
   	 jmpi init_seed_loop
   	 ret

    init_seed_loop:
   	 ldw s3, 0(s2)
   	 add a0, zero, s3
   	 add a1, zero, s1
   	 
   	 addi sp, sp, -16
	 stw ra, 12(sp)
   	 stw s0, 8(sp)
   	 stw s1, 4(sp)
   	 stw s2, 0(sp)
   	 call set_gsa
   	 ldw s2, 0(sp)
   	 ldw s1, 4(sp)
   	 ldw s0, 8(sp)
	 ldw ra, 12(sp)
   	 addi sp, sp, 16

   	 addi s1, s1, 1
   	 addi s2, s2, 4
   	 blt s1, s0, init_seed_loop
   	 ret

    rand:
   	 addi sp, sp, -16
	 stw ra, 12(sp)
   	 stw s0, 8(sp)
   	 stw s1, 4(sp)
   	 stw s2, 0(sp)
   	 call random_gsa
   	 ldw s2, 0(sp)
   	 ldw s1, 4(sp)
   	 ldw s0, 8(sp)
	 ldw ra, 12(sp)
   	 addi sp, sp, 16
   	 ret




    ; END:helper
    ; END:increment_seed

	
; BEGIN:update_state	
update_state:
	#cf 3.7 and figure 7
	#init = 0,rand 1, run 2
	ldw t0, CURR_STATE(zero)
	addi t1, zero, RAND
	addi t2, zero, RUN
	addi s0, zero, N_SEEDS 
	ldw s1, SEED(zero)

	andi t3, a0, 1 #button 0
	srai a0, a0, 1
	andi t4, a0, 1 #button 1
	srai a0, a0, 1
	andi t5, a0, 1 #button 2
	srai a0, a0, 1
	andi t6, a0, 1 #button 3
	srai a0, a0, 1
	andi t7, a0, 1 #button 4
	beq t0, t1, rand_update_state
	beq t0, t2, run_update_state
	init_update_state:
	cmpeq s2, s1, s0
	and t3, s2, t3 
	bge t3, t1, next_state_rand
	bge t4, t1, next_state_run
	ret 
	rand_update_state:
	bge t4, t1, next_state_run
	ret
	run_update_state:
	bge t6, t1, next_state_init
	ret
	next_state_init:
	stw zero, CURR_STATE(zero)
	ret
	next_state_rand:
	stw t1, CURR_STATE(zero)
	ret
	next_state_run:
	stw t2, CURR_STATE(zero)
	ret

; END:update_state
; BEGIN:select_action
select_action:
	ldw t0, CURR_STATE(zero)
	addi s0 , zero, 1 #button pressed
	addi t1, zero, RAND
	addi t2, zero, RUN

	
	andi t3, a0, 1 #button 0
	srai a0, a0, 1
	andi t4, a0, 1 #button 1
	srai a0, a0, 1
	andi t5, a0, 1 #button 2
	srai a0, a0, 1
	andi t6, a0, 1 #button 3
	srai a0, a0, 1
	andi t7, a0, 1 #button 4

	beq t0, t1, rand_state
	beq t0, t2, run_state
	
	init_state:
	beq t3, s0, increment_seed_action
	beq t4, s0, pause_game_action
	add a0, zero, t7
	add a1, zero, t6
	add a2, zero, t5

	addi sp,sp, -40 
	stw t7, 36(sp)
	stw t6, 32(sp)
	stw t5, 28(sp)
	stw t4, 24(sp)
	stw t3, 20(sp)
	stw t2, 16(sp)
	stw t1, 12(sp)
	stw t0, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call change_steps
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw t0, 8(sp)
	ldw t1, 12(sp)
	ldw t2, 16(sp)
	ldw t3, 20(sp)
	ldw t4, 24(sp)
	ldw t5, 28(sp)
	ldw t6, 32(sp)
	ldw t7, 36(sp)
	addi sp, sp, 40
	ldw t1, CURR_STEP(zero)
	addi t2, zero, 12
	addi t5, zero, 0
	show_steps1:
	andi t3, t1, 15 #t3 holds 4 lsb of current_state(the number we want on seven_seg)
	slli t3, t3, 2 #we have to do *4 to load correct font data
	ldw t4, font_data(t3)
	stw t4, SEVEN_SEGS(t2)
	srli t1, t1, 4 #we prepare t1 for next byte
	addi t2, t2, -4
	bne t2, t5, show_steps1
	ret
	
	
	rand_state:
	beq t3, s0, random_gsa_action
	beq t4, s0, pause_game_action
	add a0, zero, t7
	add a1, zero, t6
	add a2, zero, t5

	addi sp,sp, -40 
	stw t7, 36(sp)
	stw t6, 32(sp)
	stw t5, 28(sp)
	stw t4, 24(sp)
	stw t3, 20(sp)
	stw t2, 16(sp)
	stw t1, 12(sp)
	stw t0, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call change_steps
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw t0, 8(sp)
	ldw t1, 12(sp)
	ldw t2, 16(sp)
	ldw t3, 20(sp)
	ldw t4, 24(sp)
	ldw t5, 28(sp)
	ldw t6, 32(sp)
	ldw t7, 36(sp)
	addi sp, sp, 40
	ldw t1, CURR_STEP(zero)
	addi t2, zero, 12
	addi t5, zero, 0
	show_steps0:
	andi t3, t1, 15 #t3 holds 8 lsb of current_state(the number we want on seven_seg)
	slli t3, t3, 2 #we have to do *4 to load correct font data
	ldw t4, font_data(t3)
	stw t4, SEVEN_SEGS(t2)
	srli t1, t1, 4 #we prepare t1 for next byte
	addi t2, t2, -4
	bne t2, t5, show_steps0
	ret

	run_state:
	beq t3, s0, pause_game_action
	beq t4, s0, increase_speed_action
	beq t5, s0, decrease_speed_action
	beq t6, s0, reset_game_action
	beq t7, s0, random_gsa_action
	ret
	increment_seed_action:
	addi sp,sp, -4
	stw ra, 0(sp)
	call increment_seed
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	
	random_gsa_action:
	addi sp,sp, -4
	stw ra, 0(sp)
	call random_gsa
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

	increase_speed_action:
	addi a0, zero, 0
	addi sp,sp, -4 
	stw ra, 0(sp)
	call change_speed
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	decrease_speed_action:
	addi a0, zero, 1
	addi sp,sp, -40 
	stw t7, 36(sp)
	stw t6, 32(sp)
	stw t5, 28(sp)
	stw t4, 24(sp)
	stw t3, 20(sp)
	stw t2, 16(sp)
	stw t1, 12(sp)
	stw t0, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call change_speed
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw t0, 8(sp)
	ldw t1, 12(sp)
	ldw t2, 16(sp)
	ldw t3, 20(sp)
	ldw t4, 24(sp)
	ldw t5, 28(sp)
	ldw t6, 32(sp)
	ldw t7, 36(sp)
	addi sp, sp, 40
	ret
	pause_game_action:
	addi sp,sp, -40 
	stw t7, 36(sp)
	stw t6, 32(sp)
	stw t5, 28(sp)
	stw t4, 24(sp)
	stw t3, 20(sp)
	stw t2, 16(sp)
	stw t1, 12(sp)
	stw t0, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call pause_game
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw t0, 8(sp)
	ldw t1, 12(sp)
	ldw t2, 16(sp)
	ldw t3, 20(sp)
	ldw t4, 24(sp)
	ldw t5, 28(sp)
	ldw t6, 32(sp)
	ldw t7, 36(sp)
	addi sp, sp, 40
	ret
	reset_game_action:
	addi sp, sp, -4
	stw ra, 0(sp)
	call reset_game
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	
	
; END:select_action
; BEGIN:cell_fate	
cell_fate:
	addi t0, zero, 2 # 2 = neigbours => stasis for alive cell in next step
	addi t1, zero, 3 # 3 = neigbours => statis for alive cell and reproduction for dead cells
	addi t5, zero, 4
	bne a1, zero, cell_alive
	
	cell_dead:
	cmpeq v0, a0, t1 # 3 neighbours
	ret 

	cell_alive:
	cmpeq t2, a0, t0 # 2 neigbours
	cmpeq t3, a0, t1 # 3 neighbours
	cmplt t4, a0, t5
	or v0, t2, t3 
	and v0, v0, t4
	ret
; END:cell_fate
; BEGIN:find_neighbours
find_neighbours:
	add t4, zero, zero #initialize t4 as 0( 0 will be number of neighbours)
	add t6, a0, zero # t6 holds value x
	add a0, a1, zero
	
	addi sp, sp, -4
	stw ra, 0(sp)
	call get_gsa 
	ldw ra, 0(sp)
	addi sp, sp, 4
	 	
	add s0, v0, zero #yth row GSA

	addi t0, a1, 1
	addi t7, zero, 8
	beq t0, t7, modulo8
	continue_mod8:
	add a0, t0, zero
	
	addi sp, sp, -12
	stw s0, 8(sp)
	stw t0, 4(sp)
	stw ra, 0(sp)
	call get_gsa
	ldw ra, 0(sp)
	ldw t0, 4(sp)
	ldw s0, 8(sp)
	addi sp, sp, 12
	
	add s1, v0, zero #s1 has y+1th row of current gsa
	
	addi t7, zero, -1 #t7 holds -1(for comparison
	addi t1, a1, -1
	beq t1, t7, neg_modulo7 
	continue_mod7: #t1 is y - 1 mod 7
	add a0, t1, zero 
	
	addi sp, sp, -20
	stw s1, 16(sp)
	stw s0, 12(sp)
	stw t1, 8(sp)
	stw t0, 4(sp)
	stw ra, 0(sp)
	call get_gsa
	ldw ra, 0(sp)
	ldw t0, 4(sp)
	ldw t1, 8(sp)
	ldw s0, 12(sp)
	ldw s1, 16(sp)
	addi sp, sp, 20
	
	
	add s2, v0, zero #s2 has y-1th row of current gsa
	
	addi t2, t6, -1
	beq t2, t7, neg_modulo11 # t2 = x - 1 mod11
	continue_mod11:
	sra t3, s1, t2
	andi t3, t3, 1 #t3 has cell at x-1, y+1 , t3 will hold current neighbour we are considering every time
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	sra t3, s1, t6
	andi t3, t3, 1 #t3 has cell at x, y+1
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	
	addi t5, t6, 1 #t5 holds x + 1 mod 11
	addi s4, zero, 12
	beq t5, s4,pos_modulo12
	continue_pos_mod12:
	sra t3, s1, t5
	andi t3, t3, 1 # t3 has cell at x + 1, y + 1
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	
	sra t3, s2, t2
	andi t3, t3, 1 #t3 has cell at x -1, y -1
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	sra t3, s2, t6
	andi t3, t3, 1 #t3 has cell at x, y - 1
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	sra t3, s2, t5
	andi t3, t3, 1 # t5 has cell at x + 1, y - 1
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	
	sra t3, s0, t2
	andi t3, t3, 1 #t3 has cell at x-1, y
	add t4, t4, t3 # number of neighbour + 1 if neighbour alive
	sra t3, s0, t5
	andi t3, t3, 1 #t3 has cell at x+1, y
	add t4, t4, t3
	sra t3, s0, t6
	andi t3, t3, 1 #t3 has cell at x, y
	#add t4, t4, t3 
	
	add v0, t4, zero
	add v1, t3, zero
	
	ret
  	modulo8:
	add t0, zero, zero
	jmpi continue_mod8
	neg_modulo7:
	addi t1, zero, 7
	jmpi continue_mod7
	
	neg_modulo11:
	addi t2, zero, 11
	jmpi continue_mod11
	pos_modulo12:
	add t5, zero,zero
	jmpi continue_pos_mod12
; END:find_neighbours
; BEGIN:update_gsa
update_gsa:
	ldw t0, PAUSE(zero)
	beq t0, zero, game_paused

	ldw s1, GSA_ID(zero)#s1 holds current GSA used(0 or 1)
	bne s1, zero, addr_gsa1
	addi s4, zero, 1 #s4 hold gsa_id of the one not being used
	addi s2, zero, GSA0
	
	continue_update_gsa:
	addi t0, zero, 8 # limit for y coordinate
	addi s0, zero, 0 #s0 holds limit for x coordinate
	addi t1, zero, 0 #t1 holds y coordinate
	loop_over_rows:
	bge t1, t0, end_loop_update_gsa
	add a0, t1, zero
	
	addi sp,sp, -48 
	stw t5, 44(sp)
	stw t4, 40(sp)
	stw t3, 36(sp)
	stw t2, 32(sp)
	stw t1, 28(sp)
	stw t0, 24(sp)
	stw s4, 20(sp)
	stw s3, 16(sp)
	stw s2, 12(sp)
	stw s1, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call get_gsa
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	ldw s3, 16(sp)
	ldw s4, 20(sp)
	ldw t0, 24(sp)
	ldw t1, 28(sp)
	ldw t2, 32(sp)
	ldw t3, 36(sp)
	ldw t4, 40(sp)
	ldw t5, 44(sp)
	addi sp, sp, 48
	
	add t2, v0, zero #t2 holds current gsa row we are considering
	addi t3, zero, 11 # t3 holds x coordinate, en fait il faut loop en commencant avec x = 11
	addi t4, zero, 0 #t4 will hold the yth row for the new GSA that we will first store in the other GSA
	#ldw t4, s2(zero) #t4 holds the yth row for the GSA not used on s'en fout de load, on veut juste store
	addi t1, t1, 1 #y+=1 
	loop_over_columns:
	addi t1, t1, -1 #y is shifted by +1 because of the counter, we have to make it -1 to operate with it
	
	add a0, t3, zero
	add a1, t1, zero
	addi sp,sp, -48 
	stw t5, 44(sp)
	stw t4, 40(sp)
	stw t3, 36(sp)
	stw t2, 32(sp)
	stw t1, 28(sp)
	stw t0, 24(sp)
	stw s4, 20(sp)
	stw s3, 16(sp)
	stw s2, 12(sp)
	stw s1, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call find_neighbours
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	ldw s3, 16(sp)
	ldw s4, 20(sp)
	ldw t0, 24(sp)
	ldw t1, 28(sp)
	ldw t2, 32(sp)
	ldw t3, 36(sp)
	ldw t4, 40(sp)
	ldw t5, 44(sp)
	addi sp, sp, 48
	
	add a0, v0, zero
	add a1, v1, zero
	addi sp,sp, -48 
	stw t5, 44(sp)
	stw t4, 40(sp)
	stw t3, 36(sp)
	stw t2, 32(sp)
	stw t1, 28(sp)
	stw t0, 24(sp)
	stw s4, 20(sp)
	stw s3, 16(sp)
	stw s2, 12(sp)
	stw s1, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call cell_fate
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	ldw s3, 16(sp)
	ldw s4, 20(sp)
	ldw t0, 24(sp)
	ldw t1, 28(sp)
	ldw t2, 32(sp)
	ldw t3, 36(sp)
	ldw t4, 40(sp)
	ldw t5, 44(sp)
	addi sp, sp, 48
	
	
	add t4, t4, v0
	slli t4, t4, 1 #we add the next state in the new gsa row for the cell we consider and make room for the next bit
	
	#slli t5, t1, 2 #we have to multiply y by 4 to have the correct address for storing the gsa row 
	stw s4, GSA_ID(zero) #we have to change GSA ID to be able to use set_gsa on the other gsa(not the current one)
	add a0, zero, t4 #setup for set_gsa
	add a1, zero, t1
	addi sp,sp, -48 
	stw t5, 44(sp)
	stw t4, 40(sp)
	stw t3, 36(sp)
	stw t2, 32(sp)
	stw t1, 28(sp)
	stw t0, 24(sp)
	stw s4, 20(sp)
	stw s3, 16(sp)
	stw s2, 12(sp)
	stw s1, 8(sp)
	stw s0, 4(sp)
	stw ra, 0(sp)
	call set_gsa
	ldw ra, 0(sp)
	ldw s0, 4(sp)
	ldw s1, 8(sp)
	ldw s2, 12(sp)
	ldw s3, 16(sp)
	ldw s4, 20(sp)
	ldw t0, 24(sp)
	ldw t1, 28(sp)
	ldw t2, 32(sp)
	ldw t3, 36(sp)
	ldw t4, 40(sp)
	ldw t5, 44(sp)
	addi sp, sp, 48
	
	stw s1, GSA_ID(zero)#change back gsa id to current gsa




	addi t3, t3, -1 #x -= 1
	addi t1, t1, 1
	beq t3, zero, loop_over_rows
	#slli t4, t4, 1
	jmpi loop_over_columns
	
	addr_gsa1:
	addi s4, zero, 0 #s4 holds the GSA not being used
	addi s2, zero, GSA1 #s2 hold GSA address we should use
	jmpi continue_update_gsa 
	
	end_loop_update_gsa:
	#nor t6, s1, s1
	#addi t6, zero, 1
	stw s4, GSA_ID(zero)
	ret
	game_paused:
	ret
; END:update_gsa
; BEGIN:mask
    mask:
   	 ldw t0, CURR_STATE(zero)
   	 addi t1, zero, RAND
   	 addi s0, zero, N_GSA_LINES
   	 add s1, zero, zero
   	 beq t0, t1, random_mask
   	 ldw t2, SEED(zero)
   	 slli t2, t2, 2
   	 ldw s2, MASKS(t2)
   	 jmpi loop_over_lines
   	 ret

    ; BEGIN:helper
    random_mask:
   	 addi t2, zero, N_SEEDS
   	 slli t2, t2, 2
   	 ldw s2, MASKS(t2)
   	 jmpi loop_over_lines
   	 ret

    loop_over_lines:
   	 add a0, zero, s1

   	 addi sp, sp, -16
	 stw ra, 12(sp)
   	 stw s0, 8(sp)
   	 stw s1, 4(sp)
   	 stw s2, 0(sp)
   	 call get_gsa
   	 ldw s2, 0(sp)
   	 ldw s1, 4(sp)
   	 ldw s0, 8(sp)
	 ldw ra, 12(sp)
   	 addi sp, sp, 16

   	 
   	 ldw s3, 0(s2)
   	 and a0, v0, s3
   	 add a1, zero, s1

   	 addi sp, sp, -16
	 stw ra, 12(sp)
   	 stw s0, 8(sp)
   	 stw s1, 4(sp)
   	 stw s2, 0(sp)
   	 call set_gsa
   	 ldw s2, 0(sp)
   	 ldw s1, 4(sp)
   	 ldw s0, 8(sp)
	 ldw ra, 12(sp)
   	 addi sp, sp, 16


   	 addi s1, s1, 1
   	 addi s2, s2, 4
   	 blt s1, s0, loop_over_lines
   	 ret


    ; END:helper
    ; END:mask
; BEGIN:get_input
get_input:
	addi t0, zero, BUTTONS
	ldw t1, 4(t0)
	
	add v0, zero, t1
	stw zero, 4(t0)
	ret
; END:get_input
; BEGIN:decrement_step
decrement_step:
	ldw t6, PAUSE(zero) #t6 = 0 if game is paused, and 1 if running
	addi t0, zero, RUN #t0 holds 2 = RUN
	ldw t7, CURR_STATE(zero) #t7 is current state
	cmpeq t2, t7, t0 # if current state = RUN then 1 else 0
	and t5, t6, t2 #if(current_state = RUN) and game RUNNING then 1 
	bne t5, zero, decrement_run

	continue_decrement_step:
	ldw t1, CURR_STEP(zero)
	addi t2, zero, 12
	addi t5, zero, 0

	show_steps:
	andi t3, t1, 15 #t3 holds 8 lsb of current_state(the number we want on seven_seg)
	slli t3, t3, 2 #we have to do *4 to load correct font data
	ldw t4, font_data(t3)
	stw t4, SEVEN_SEGS(t2)
	srli t1, t1, 4 #we prepare t1 for next byte
	addi t2, t2, -4
	beq t2, t5, decrement_step_return_0
	jmpi show_steps
	decrement_run:
	ldw t1, CURR_STEP(zero)
	beq t1, zero, decrement_step_return_1
	addi t1, t1, -1
	stw t1, CURR_STEP(zero)
	jmpi continue_decrement_step
	decrement_step_return_1:
	stw zero, CURR_STATE(zero)
	addi v0, zero,1 
	ret
	decrement_step_return_0:
	addi v0, zero, 0
	ret

; END:decrement_step
; BEGIN:reset_game
reset_game:
	#addi sp, sp, -4
	#stw ra, 0(sp)
	#call clear_leds
	#ldw ra, 0(sp)
	#addi sp, sp, 4
	addi t0, zero, 1 #current step
	addi t1, zero, 12
	stw t0, CURR_STEP(zero)
	slli t0, t0, 2
	ldw t2, font_data(t0)
	stw t2, SEVEN_SEGS(t1) #show 1 on seven seg
	ldw t2, font_data(zero)
	addi t1, zero, 8
	stw t2, SEVEN_SEGS(t1)
	addi t1, zero, 4
	stw t2, SEVEN_SEGS(t1)
	addi t1, zero, 0
	stw t2, SEVEN_SEGS(t1)
	stw zero, SEED(zero)
	stw zero, GSA_ID(zero)
	add t3, zero, zero #y coordinate
	addi t4, zero , 8 #limit for y  coordinate

	reset_loop_over_rows: #GSA to seed 0
	beq t3, t4, continue_reset
	slli t5, t3, 2 
	ldw t6, seed0(t5)
	add a0, zero, t6
	add a1, zero, t3
	addi sp,sp, -32
	stw t6, 28(sp)
	stw t5, 24(sp)
	stw t4, 20(sp)
	stw t3, 16(sp)
	stw t2, 12(sp)
	stw t1, 8(sp)
	stw t0, 4(sp)
	stw ra, 0(sp)
	call set_gsa
	ldw ra, 0(sp)
	ldw t0, 4(sp)
	ldw t1, 8(sp)
	ldw t2, 12(sp)
	ldw t3, 16(sp)
	ldw t4, 20(sp)
	ldw t5, 24(sp)
	ldw t6, 28(sp)
	addi sp, sp, 32
	addi t3, t3, 1 #y += 1
	jmpi reset_loop_over_rows
	continue_reset:
	addi t4, zero, 1
	stw zero, PAUSE(zero)
	stw t4, SPEED(zero)
	#stw zero, CURR_STATE(zero)
	ret
; END:reset_game


font_data:
    .word 0xFC ; 0
    .word 0x60 ; 1
    .word 0xDA ; 2
    .word 0xF2 ; 3
    .word 0x66 ; 4
    .word 0xB6 ; 5
    .word 0xBE ; 6
    .word 0xE0 ; 7
    .word 0xFE ; 8
    .word 0xF6 ; 9
    .word 0xEE ; A
    .word 0x3E ; B
    .word 0x9C ; C
    .word 0x7A ; D
    .word 0x9E ; E
    .word 0x8E ; F

seed0:
    .word 0xC00
    .word 0xC00
    .word 0x000
    .word 0x060
    .word 0x0A0
    .word 0x0C6
    .word 0x006
    .word 0x000

seed1:
    .word 0x000
    .word 0x000
    .word 0x05C
    .word 0x040
    .word 0x240
    .word 0x200
    .word 0x20E
    .word 0x000

seed2:
    .word 0x000
    .word 0x010
    .word 0x020
    .word 0x038
    .word 0x000
    .word 0x000
    .word 0x000
    .word 0x000

seed3:
    .word 0x000
    .word 0x000
    .word 0x090
    .word 0x008
    .word 0x088
    .word 0x078
    .word 0x000
    .word 0x000

    ;; Predefined seeds
SEEDS:
    .word seed0
    .word seed1
    .word seed2
    .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

MASKS:
    .word mask0
    .word mask1
    .word mask2
    .word mask3
    .word mask4

