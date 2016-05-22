# PURPOSE: This program converts an input file to an output file
#	   with all letters converted to uppercase.
#
# PROCESSING: 1) Open the input file
#	      2) Open the output file
#             3) While we're not at the end of the input file
#		a) read part of the file into our memory buffer
#		b) go through each byte of memory
#		   i) if the byte is a lower-case letter,
#		  ii) convert it to uppercase
#               c) write the memory buffer to output file

.section .data
# 32-bit syscall numbers
.equ SYS_OPEN, 0x5
.equ SYS_WRITE, 0x4
.equ SYS_READ, 0x3
.equ SYS_CLOSE, 0x6
.equ SYS_EXIT, 0x1

# options for open
.equ O_RDONLY, 0x0
.equ O_CREAT_WRONLY_TRUNC, 03101

# standard file descriptors
.equ STDIN, 0x0
.equ STDOUT, 0x1
.equ STDERR, 0x2

# system call interrupt
.equ LINUX_SYSCALL, 0x80

# EOF
.equ END_OF_FILE, 0x0

.section .bss
# buffer
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text
# stack positions
.equ ST_SIZE_RESERVE, 0x8
.equ ST_FD_IN, -0x4
.equ ST_FD_OUT, -0x8
.equ ST_ARGC, 0x0
.equ ST_ARGV_0, 0x4
.equ ST_ARGV_1, 0x8
.equ ST_ARGV_2, 0xC

.globl _start
_start:
  movl  %esp, %ebp		     # save the stack pointer
  subl $ST_SIZE_RESERVE, %esp        # allocate space for FDs on stack

open_files:
open_fd_in:
  movl $SYS_OPEN, %eax		     # open syscall
  movl ST_ARGV_1(%ebp), %ebx        # input filename into %ebx
  movl $O_RDONLY, %ecx		     # read-only flag
  movl $0666, %edx		     # not really necessary for reading
  int $LINUX_SYSCALL		     # call the kernel

store_fd_in:
  movl %eax, ST_FD_IN(%ebp)          # store the given file descriptor (from kernel)

open_fd_out:
  movl $SYS_OPEN, %eax               # open syscall
  movl ST_ARGV_2(%ebp), %ebx        # output filename into %ebx
  movl $O_CREAT_WRONLY_TRUNC, %ecx   # flags for writing to the file
  movl $0666, %edx		     # mode for new file (if created)	 

store_fd_out:
  movl %eax, ST_FD_OUT(%ebp)	     # store the given file descriptor (from kernel)

# main loop
# read into buffer
read_loop_begin:
  movl $SYS_READ, %eax               # read syscall
  movl ST_FD_IN(%ebp), %ebx          # get the input file descriptor
  movl $BUFFER_DATA, %ecx            # the location to read into
  movl $BUFFER_SIZE, %edx            # the size of the buffer
  int $LINUX_SYSCALL	             # size of buffer read is returned in %eax

# exit if we've reach the end
  cmpl $END_OF_FILE, %eax
  jle end_loop

# convert buffer to uppercase
continue_read_loop:
  pushl $BUFFER_DATA		     # location of buffer
  pushl %eax			     # size of the buffer
  call convert_to_upper
  popl %eax			     # get the size back
  addl $0x4, %esp                    # restore esp

# write buffer to output file
  movl %eax, %edx		     # size of the buffer
  movl $SYS_WRITE, %eax	             # write syscall
  movl ST_FD_OUT(%ebp), %ebx         # file to use
  movl $BUFFER_DATA, %ecx	     # location of the buffer
  int $LINUX_SYSCALL		     # size of buffer written returned in %eax

# continue the loop
  jmp read_loop_begin

end_loop:
# close files
  movl $SYS_CLOSE, %eax		     # close syscall
  movl ST_FD_OUT(%ebp), %ebx         # output file fd
  int $LINUX_SYSCALL                 # call the kernel

  movl $SYS_CLOSE, %eax              # close syscall
  movl ST_FD_IN(%ebp), %ebx          # input file fd
  int $LINUX_SYSCALL                 # call the kernel

# exit
  movl $SYS_EXIT, %eax		     # exit syscall
  movl $0x0, %ebx		     # exit code 0 -> exit cleanly
  int $LINUX_SYSCALL                 # call the kernel

# PURPOSE: This function actually does the conversion 
#          to upper case for a block of memory
#
# INPUT: The first parameter is the location of the block of memory to convert.
#        The second parameter is the length of that buffer
#
# OUTPUT: The function overwrites the current buffer with the uppercased version.
#
# VARIABLES:
#	%eax - beginning of buffer
#       %ebx - length of buffer
#       %edi - current buffer offset
#       %cl  - current byte being examined (lowest part of %ecx)
#

## constants ##
# lower boundary of search
.equ LOWERCASE_A, 'a'
# upper boundary of search
.equ LOWERCASE_Z, 'z'
# conversion
.equ UPPER_CONVERSION, 'A' - 'a'

# stack manipulation
.equ ST_BUFFER_LEN, 0x8            # length of buffer
.equ ST_BUFFER, 0xC                # actual buffer

convert_to_upper:
  pushl %ebp		           # standard preamble (push base pointer to stack)
  movl  %esp, %ebp                 # standard preamble (copy stack pointer to %ebp)

  movl ST_BUFFER(%ebp), %eax       # first argument, location of buffer
  movl ST_BUFFER_LEN(%ebp), %ebx   # second argument, size of buffer
  movl $0x0, %edi	           # start with the first byte (0)
  
  cmpl $0x0, %ebx                  # if buffer size is 0, exit
  je end_convert_loop

convert_loop:
  movb (%eax, %edi, 0x1), %cl      # get the current byte
  cmpb $LOWERCASE_A, %cl           # compare to lower bound
  jl next_byte
  cmpb $LOWERCASE_Z, %cl           # compare to upper bound
  jg next_byte

  addb $UPPER_CONVERSION, %cl      # if between bounds, convert to upper
  movb %cl, (%eax, %edi, 0x1)      # and store it back

next_byte:
  incl %edi			   # next byte
  cmpl %edi, %ebx  	           # compare against buffer length
  jne convert_loop		   # keep going

end_convert_loop:
  movl $0x0, %eax	           # return 0 on success
  movl %ebp, %esp		   # standard return (restore stack pointer)
  popl %ebp	                   # standard return (pop base pointer off stack)
  ret
 
