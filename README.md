# stm32f7-lcd

Simple use of BSP libraries for drawing to the LCD.

Use printf() function to print data in the LCD. For this:

C standard syscalls must be redirected, this is done in Utils/Log/syscalls.c

Must be compiled with -lc -lg -nostartfiles, for this the startup asm file
must be modified.
