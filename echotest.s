# PURPOSE: This program echoes arguments to STDOUT
#
# PROCESSING: 1) Read the program arguments off of the call stack
#	          2) Write them individually to STDOUT

.section .data
# 32-bit syscall numbers
.equ SYS_EXIT, 0x1
.equ SYS_READ, 0x3
.equ SYS_WRITE, 0x4

# standard file descriptors
.equ STDIN, 0x0
.equ STDOUT, 0x1
.equ STDERR, 0x2

# system call interrupt
.equ LINUX_SYSCALL, 0x80

# EOF 
.equ END_OF_FILE, 0x0

# CHARACTERS
newline:
.byte 0xA

.section .text
# stack positions
.equ ST_SIZE_RESERVE, 0x10
.equ ST_ARGC, 0x4
.equ ST_ARGV_0, 0x4
.equ ST_ARGV_1, 0x8
.equ ST_ARGV_2, 0xC
.equ ST_ARGV_3, 0x10

.globl _start
_start:
  movl %esp, %ebp		            # save the stack pointer
  subl $ST_SIZE_RESERVE, %esp       # allocate space for FDs on stack

write_arg_1:
  movl $SYS_WRITE, %eax		        # write syscall
  movl $STDOUT, %ebx                # fd for stdout 
  movl ST_ARGV_1(%ebp), %ecx        # argument into %ecx
  movl $0x4, %edx		            # long is 4 bytes
  int $LINUX_SYSCALL		        # call the kernel
  movl $0x0, %edi
  jmp write_newline

write_newline:
  movl $SYS_WRITE, %eax             # write syscall
  movl $STDOUT, %ebx                # fd for stdout
  leal newline, %ecx                # write the newline
  movl $0x4, %edx                   # just the one byte
  int $LINUX_SYSCALL                # call the kernel
  cmpl $0x1, %edi                    # are we done?
  je exit                           # if so, exit

write_arg_2:
  movl $SYS_WRITE, %eax             # write syscall
  movl $STDOUT, %ebx                # fd for stdout
  movl ST_ARGV_2(%ebp), %ecx        # argument into %ecx
  movl $0x4, %edx                   # long is 4 bytes
  int $LINUX_SYSCALL		        # call the kernel	 
  movl $0x1, %edi                    # we're done now
  jmp write_newline

exit:
  xorl %edx, %ecx                   # zero out ecx
  xorl %edx, %edx                   # zero out edx
  movl $SYS_EXIT, %eax		        # exit syscall
  movl $0x0, %ebx		            # exit code 0 -> exit cleanly
  int $LINUX_SYSCALL                # call the kernel
