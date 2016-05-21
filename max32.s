
#PURPOSE:  This program finds the maximum number of a
#          set of data items.
#

#VARIABLES: The registers have the following uses:
#
# %edi - Holds the index of the data item being examined
# %ebx - Largest data item found
# %eax - Current data item
#
# The following memory locations are used:
#
# data_items - contains the item data.  A 0 is used
#              to terminate the data
#

.section .data
data_items:
  .long   0x3,0x67,0x34,0xDE,0x45,0x75,0x54,0x34,0x44,0x33,0x22,0x11,0x66,0x0

.section .text
.globl _start

_start:
  movl $0x0, %edi                     # move 0 into the index register
  movl data_items(,%edi,0x4), %eax    # .long ix 0x4 bytes each
  movl %eax, %ebx

start_loop:
  cmpl $0x0, %eax                     # compare eax to 0 (compare is backwards)
  je loop_exit                        # if it's equal exit
  incl %edi                           # increment the counter
  movl data_items(,%edi,0x4), %eax    # load the next long from data_items
  cmpl %ebx, %eax                     # compare eax to ebx
  jle start_loop                      # jump to loop beginning if smaller
  movl %eax, %ebx                     # if we get here, move eax to ebx as its bigger
  jmp start_loop                      # always jump to loop beginning

loop_exit:                            # %ebx is the status code for the exit system call
  movl $0x1, %eax                     # and it already has the maximum number
  int  $0x80