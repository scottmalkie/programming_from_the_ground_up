#### assemble with as --32 and link with ld -melf_i386 ####
# PURPOSE - Given a number, this program computes the
#          factorial.  For example, the factorial of
#          3is3*2*1,or6. The factorial of
#          4 is 4 * 3 * 2 * 1, or 24, and so on.
#
# This program shows how to call a function recursively.
 
.section .data
# This program has no global data

.section .text
.globl _start
.globl factorial

# Main function starts here
_start:
  pushl $0x4         # push source number onto stack, for x! this number is x
  call factorial     # run the factorial function
  addl $0x4, %esp    # scrubs the parameter that was pushed onto the stack
  movl %eax, %ebx    # factorial returns answer into eax, we want in ebx for exit status
  movl $0x1, %eax    # syscall for exit()
  int $0x80 

# Factorial function starts here
.type factorial,@function
factorial:
  pushl %ebp             # push base pointer onto stack
  movl %esp, %ebp        # move stack pointer onto base pointer
  
  movl 0x8(%ebp), %eax   # move first argument from stack to eax
  cmpl $0x1, %eax        # 1! = 1, just return
  je end_factorial       # jump to exit, 1 is already in %eax
  decl %eax              # otherwise decrease value
  pushl %eax             # push it onto the stack
  call factorial         # recursive call to factorial
  movl 0x8(%ebp), %ebx   # reload first argument into ebx
  imull %ebx, %eax       # multiply first argument by result of last call
  
end_factorial:
  movl %ebp, %esp        # restore stack pointer from base pointer
  popl %ebp              # pop base pointer from stack
  ret 

