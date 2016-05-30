# PURPOSE: This program reads an input file and displays it to STDOUT

.section .bss
.equ BUFFER_SIZE, 128
.lcomm BUFFER, BUFFER_SIZE

.section .data
# 32-bit syscall numbers
.equ SYS_OPEN, 0x5
.equ SYS_WRITE, 0x4
.equ SYS_READ, 0x3
.equ SYS_CLOSE, 0x6
.equ SYS_EXIT, 0x1

# options for open
.equ O_RDONLY, 0x0

# standard file descriptors
.equ STDIN, 0x0
.equ STDOUT, 0x1

# system call interrupt
.equ LINUX_SYSCALL, 0x80

# EOF
.equ END_OF_FILE, 0x0

# NEWLINE
NEWLINE:
.byte 0xA

.section .text
# stack positions
.equ ST_SIZE_RESERVE, 0xC
.equ ST_FD_IN, -0x4
.equ ST_ARGC, 0x0
.equ ST_ARGV_0, 0x4
.equ ST_ARGV_1, 0x8
.equ ST_ARGV_2, 0xC

.globl _start
_start:
  movl %esp, %ebp		             # save the stack pointer
  subl $ST_SIZE_RESERVE, %esp        # allocate space for FDs on stack

open_files:
open_fd_in:
  movl $SYS_OPEN, %eax		        # open syscall
  movl ST_ARGV_1(%ebp), %ebx        # input filename into %ebx
  movl $O_RDONLY, %ecx		        # read-only flag
  movl $0666, %edx		            # not really necessary for reading
  int $LINUX_SYSCALL		        # call the kernel

store_fd_in:
  movl %eax, ST_FD_IN(%ebp)          # store the given file descriptor (from kernel)

# main loop
# read into buffer
read_loop_begin:
  movl $SYS_READ, %eax               # read syscall
  movl ST_FD_IN(%ebp), %ebx          # get the input file descriptor
  movl $BUFFER, %ecx                 # the location to read into
  movl $BUFFER_SIZE, %edx            # the size of the buffer
  int $LINUX_SYSCALL	             # size of buffer read is returned in %eax

# exit if we've reach the end
  cmpl $END_OF_FILE, %eax
  jle end_loop

# write buffer to output file
  movl $BUFFER_SIZE, %edx		 # size of the buffer
  movl $SYS_WRITE, %eax	         # write syscall
  movl $STDOUT, %ebx             # file to use
  movl $BUFFER, %ecx             # location of the buffer
  int $LINUX_SYSCALL		     # size of buffer written returned in %eax

# continue the loop
  jmp read_loop_begin

end_loop:
# add newline
  movl $0x1, %edx                # write one byte
  leal NEWLINE, %ecx             # load address of newline
  movl $STDOUT, %ebx             # writing to STDOUT
  movl $SYS_WRITE, %eax          # write syscall
  int $LINUX_SYSCALL             # call the kernel

# close files
  movl $SYS_CLOSE, %eax		     # close syscall
  movl ST_FD_IN(%ebp), %ebx      # input file fd
  int $LINUX_SYSCALL             # call the kernel

# exit
  movl $SYS_EXIT, %eax		     # exit syscall
  movl $0x0, %ebx		         # exit code 0 -> exit cleanly
  int $LINUX_SYSCALL             # call the kernel

