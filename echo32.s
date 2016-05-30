# PURPOSE: This program writes STDIN to STDOUT

.section .data
# 32-bit syscall numbers
.equ SYS_EXIT, 0x1
.equ SYS_READ, 0x3
.equ SYS_WRITE, 0x4

# standard file descriptors
.equ STDIN, 0x0
.equ STDOUT, 0x1

# system call interrupt
.equ LINUX_SYSCALL, 0x80

upper_a:
.byte  0x41
newline:
.byte  0xA
upper_b:
.byte  0x42

.section .bss
.equ BUFFER_SIZE, 128
.lcomm BUFFER, BUFFER_SIZE

.section .text
.globl _start
_start:

  movl $SYS_READ, %eax          # read syscall
  movl $STDIN, %ebx             # fd for stdin 
  leal BUFFER, %ecx             # argument into %ecx
  movl $BUFFER_SIZE, %edx       # newline should be 1 byte 
  int $LINUX_SYSCALL            # call the kernel

  movl $SYS_WRITE, %eax
  movl $STDOUT, %ebx
  leal BUFFER, %ecx
  movl $BUFFER_SIZE, %edx
  int $LINUX_SYSCALL

  movl $SYS_WRITE, %eax        # write syscall
  movl $STDOUT, %ebx           # fd for stdout
  leal newline, %ecx           # argument into %ecx
  movl $0x1, %edx              # newline should be 1 byte
  int $LINUX_SYSCALL           # call the kernel	 

exit:
  movl $SYS_EXIT, %eax         # exit syscall
  movl $0x0, %ebx              # exit code 0 -> exit cleanly
  int $LINUX_SYSCALL           # call the kernel

