# PURPOSE: Program to illustrate how functions work
#          This program will compute the value of 2^3 + 5^2
#

# Everything in the main program is stored in registers
# So the data section doesn't have anything.
.section .data

.section .text
.globl _start

_start:
  pushq $0x2	    # push second argument
  pushq $0x2        # push first argument
  call power	    # call the function
  addq $0x10, %rsp  # move the stack pointer back 2 quads -> 16 bytes  

  pushq %rax	    # save the first answer onto the stack before
                    # calling the next function

  pushq $0x2        # push second argument
  pushq $0x3        # push first argument
  call power        # call the function
  addq $0x10, %rsp  # move the stack pointer back 2 quads -> 16 bytes
  
  popq %rbx         # the second answer is already in %eax
                    # we saved the first answer onto the stack
                    # so now we just pop it out to %ebx
                    
  addq %rax, %rbx   # add the two answers together
                    # answer is stored in destination
  
  movq $0x3c, %rax  # syscall for exit
  syscall           # call the kernel
  
# PURPOSE: This function is used to compute the value
#         of a number raised to a power.
#
# INPUT: First argument - the base number
#        Second argument - the power to raise it to
#
# OUTPUT: Will give the result as a return value
#
# NOTES: Only supports positive integer exponents
#
# VARIBLES:
#          %rbx holds the base number
#          %rcx holds the exponent
#          -0x8(%rbp) holds the current result
#          %rax is used for temporary storage
#

.type power, @function
power:
  pushq %rbp              # save old base pointer
  movq %rsp, %rbp         # make stack pointer the base pointer
  
  subq $0x8, %rsp         # get room for our local storage
  
  movq 0x10(%rbp), %rbx   # put first argument in %rbx
  movq 0x18(%rbp), %rcx   # put second argument in %rcx
  movq %rbx, -0x8(%rbp)   # store current result
  
power_loop_start:
  cmpq $0x1, %rcx         # compare exponent to 1, we are done if so
  je end_power            # end and return initial value
  movq -0x8(%rbp), %rax   # move the current result into %rax
  imulq %rbx, %rax        # multiply the current result by the base number
  movq %rax, -0x8(%rbp)   # store the current result
  decq %rcx               # decrease the power
  jmp power_loop_start    # run for the next power
 
end_power:
  movq -0x8(%rbp), %rax   # return value goes in %rax
  movq %rbp, %rsp         # restore the stack pointer
  popq %rbp               # restore the base pointer
  ret

