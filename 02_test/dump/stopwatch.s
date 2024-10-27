.data
    LED_ADDRESS:        .word 0x7000     # LED display address
    BUTTON_ADDRESS:     .word 0x7016     # Button input address
    MAX_COUNT:          .word 595999     # Maximum value (99:59.99)
    MIN_COUNT:          .word 0          # Minimum value (00:00.00)
    
.text
.globl main

main:
    # Initialize registers for IDLE state
    li t0, 0           # t0 = counter (centiseconds), start at 00:00.00
    lw t1, MAX_COUNT   # Load maximum count value
    lw t2, MIN_COUNT   # Load minimum count value
    li s0, 0           # s0 = current state (0=IDLE, 1=COUNT_UP, 2=COUNT_DOWN, 3=STOP)
    li s1, 0           # s1 = previous button state

loop:
    # Read button states
    lw t3, BUTTON_ADDRESS
    andi t3, t3, 0xF   # Get states of all 4 buttons

    # Check for button presses (0 = pressed, 1 = not pressed)
    # Only process button if it wasn't pressed in previous iteration
    xor t4, t3, s1     # t4 = changed buttons
    and t4, t4, s1     # t4 = newly pressed buttons
    mv s1, t3          # Store current button state

    # Process button presses based on current state
    beqz t4, check_counting  # If no new button press, continue counting

    # Button 1 (COUNT UP) - 0001
    andi t5, t4, 1
    bnez t5, set_count_up

    # Button 2 (STOP) - 0010
    andi t5, t4, 2
    bnez t5, set_stop

    # Button 3 (COUNT DOWN) - 0100
    andi t5, t4, 4
    bnez t5, set_count_down

    # Button 4 (RESET) - 1000
    andi t5, t4, 8
    bnez t5, check_reset
    j check_counting

set_count_up:
    li s0, 1           # Set state to COUNT_UP
    j check_counting

set_stop:
    li s0, 3           # Set state to STOP
    j check_counting

set_count_down:
    beqz t0, check_counting  # Can't count down from zero
    li s0, 2           # Set state to COUNT_DOWN
    j check_counting

check_reset:
    li t5, 3
    bne s0, t5, check_counting  # Only reset if in STOP state
    li t0, 0           # Reset counter
    li s0, 0           # Go to IDLE state
    j display

check_counting:
    # Delay for 1/100th of a second (500,000 cycles at 50MHz)
    li t4, 500000
delay_loop:
    addi t4, t4, -1
    bnez t4, delay_loop

    # Update counter based on state
    li t4, 1
    beq s0, t4, count_up      # If state is COUNT_UP
    li t4, 2
    beq s0, t4, count_down    # If state is COUNT_DOWN
    j display                 # If IDLE or STOP, just display

count_up:
    beq t0, t1, display      # If at max, skip increment
    addi t0, t0, 1           # Increment counter
    j display

count_down:
    beq t0, t2, display      # If at min, skip decrement
    addi t0, t0, -1          # Decrement counter
display:
    # Convert counter (t0) to BCD for MM:SS.CC display
    mv a0, t0              # Copy counter to a0
    
    # Extract minutes (divide by 6000 using subtraction)
    li t3, 6000           # 60 seconds * 100
    li t4, 0              # t4 will store minutes
div_minutes:
    blt a0, t3, min_done
    sub a0, a0, t3
    addi t4, t4, 1
    j div_minutes
min_done:

    # Convert minutes to BCD
    mv t3, t4             # Copy minutes to t3
    li t4, 0              # t4 will store tens digit
    li t5, 10             # Divisor for BCD conversion
min_bcd:
    blt t3, t5, min_bcd_done
    sub t3, t3, t5
    addi t4, t4, 1
    j min_bcd
min_bcd_done:
    slli t4, t4, 4        # Shift tens digit
    or t4, t4, t3         # Combine digits
    mv t2, t4             # Store minutes BCD in t2

    # Extract seconds (divide by 100)
    li t3, 100
    li t4, 0              # t4 will store seconds
div_seconds:
    blt a0, t3, sec_done
    sub a0, a0, t3
    addi t4, t4, 1
    j div_seconds
sec_done:

    # Convert seconds to BCD
    mv t3, t4             # Copy seconds to t3
    li t4, 0              # t4 will store tens digit
sec_bcd:
    blt t3, t5, sec_bcd_done
    sub t3, t3, t5
    addi t4, t4, 1
    j sec_bcd
sec_bcd_done:
    slli t4, t4, 4        # Shift tens digit
    or t4, t4, t3         # Combine digits
    mv t3, t4             # Store seconds BCD in t3

    # Convert centiseconds to BCD
    mv t4, a0             # Copy centiseconds to t4
    li a0, 0              # a0 will store tens digit
csec_bcd:
    blt t4, t5, csec_bcd_done
    sub t4, t4, t5
    addi a0, a0, 1
    j csec_bcd
csec_bcd_done:
    slli a0, a0, 4        # Shift tens digit
    or t4, a0, t4         # Combine digits

    # Combine all digits for display
    slli t2, t2, 16       # Minutes
    slli t3, t3, 8        # Seconds
    or t5, t2, t3         # Combine minutes and seconds
    or t5, t5, t4         # Add centiseconds

    # Output to LEDs
    lw t6, LED_ADDRESS
    sw t5, 0(t6)

    j loop