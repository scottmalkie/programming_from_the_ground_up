# PURPOSE: Program to illustrate how functions work
#          This program will compute the value of 2^3 + 5^2
#

# Everything in the main program is stored in registers
# So the data section doesn't have anything.
.section .data

.section .text
.globl _start

_start:
  pushl $0x2	    # push second argument
  pushl $0x2        # push first argument
  call power	    # call the function
  addl $0x8, %esp   # move the stack pointer back 2 longs  

  pushl %eax	    # save the first answer onto the stack before
                    # calling the next function

  pushl $0x2        # push second argument
  pushl $0x3        # push first argument
  call power        # call the function
  addl $0x8, %esp   # move the stack pointer back 2 longs
  
  popl %ebx         # the second answer is already in %eax
                    # we saved the first answer onto the stack
                    # so now we just pop it out to %ebx
                    
  addl %eax, %ebx   # add the two answers together
                    # answer is stored in destination
  
  movl $0x1, %eax   # syscall for exit
  int $0x80         # call the kernel
  
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
#          %ebx holds the base number
#          %ecx holds the exponent
#          -0x4(%ebp) holds the current result
#          %eax is used for temporary storage
#

.type power, @function
power:
  pushl %ebp              # save old base pointer
  movl %esp, %ebp         # make stack pointer the base pointer
  
  subl $0x4, %esp         # get room for our local storage
  
  movl 0x8(%ebp), %ebx    # put first argument in %ebx
  movl 0xC(%ebp), %ecx    # put second argument in %ecx
  movl %ebx, -0x4(%ebp)   # store current result
  
power_loop_start:
  cmpl $0x1, %ecx         # compare exponent to 1, we are done if so
  je end_power            # end and return initial value
  movl -0x4(%ebp), %eax   # move the current result into %eax
  imull %ebx, %eax        # multiply the current result by the base number
  movl %eax, -0x4(%ebp)   # store the current result
  decl %ecx               # decrease the power
  jmp power_loop_start    # run for the next power
 
end_power:
  movl -0x4(%ebp), %eax   # return value goes in %eax
  movl %ebp, %esp         # restore the stack pointer
  popl %ebp               # restore the base pointer
  ret

