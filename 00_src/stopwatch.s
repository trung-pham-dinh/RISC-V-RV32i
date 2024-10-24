.data
    LED_ADDRESS: .word 0x7000 # LED control is memory-mapped to this address
    SWITCH_ADDRESS: .word 0x700F # Assume switch input is memory-mapped to this address
    CYCLES_PER_SECOND: .word 50000000 # 50 million cycles per second at 50MHz

.text
.globl main

main:
    # Initialize
    li t0, 0           # t0 will store our count (hundredths of a second)
    lw t6, CYCLES_PER_SECOND # t6 will store cycles per second

loop:
    # Delay for 1/100th of a second (500,000 cycles at 50MHz)
    li t2, 500000
delay_loop:
    addi t2, t2, -1
    bnez t2, delay_loop

    # Check switch position
    lw t1, SWITCH_ADDRESS
    andi t1, t1, 1     # Using the least significant bit of the switch

    beqz t1, count_down
    # Count up
    addi t0, t0, 1
    j update_display

count_down:
    # Count down, but don't go below zero
    beqz t0, update_display
    addi t0, t0, -1

update_display:
    # Ensure count doesn't exceed 99:99.99 
    li t1, 9999
    blt t0, t1, display
    mv t0, t1

display:
    # Convert to BCD (6 digits: MM:SS.CC)
    mv a0, t0
    
    # Minutes (0-99)
    li t1, 6000  # 60 seconds * 100
    div t2, a0, t1
    rem a0, a0, t1
    
    # Seconds (0-59)
    li t1, 100
    div t3, a0, t1
    rem a0, a0, t1
    
    # Centiseconds (0-99)
    mv t4, a0
    
    # Combine all digits
    slli t2, t2, 24  # Minutes
    slli t3, t3, 16  # Seconds
    slli t4, t4, 8   # Centiseconds
    or t5, t2, t3
    or t5, t5, t4

    # Output to LEDs 
    lw t1, LED_ADDRESS
    sw t5, 0(t1)

    j loop