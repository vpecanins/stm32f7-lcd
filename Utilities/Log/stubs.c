// Shitty stubs for the compiler not to complain about shit

#include <sys/types.h>
#include <errno.h>
#include "lcd_log.h"

int _write(int fd, const void *buffer, unsigned int count)
{
    unsigned int i;

    for (i = 0; i < count; i++) {
        fputc(((char *)buffer)[i], 0);
    }

    return count;
}

int _read(int fd, void *buffer, unsigned int count)
{
    unsigned int i;

    for (i = 0; i < count; i++) {
        ((char *)buffer)[i] = 0;
    }

    return count;
}

int _close(int fd)
{
    return -1;
}

int _fstat(int fd, void *buffer)
{
    return -1;
}

int _isatty(int fd)
{
    return -1;
}

long _lseek(int fd, long offset, int origin)
{
    return -1;
}

void _exit(int status)
{
}

caddr_t
_sbrk(int incr)
{
   extern char _Heap_Begin; /* Defined by the linker. */
    extern char _Heap_Limit; /* Defined by the linker. */
    static char* current_heap_end;
    char* current_block_address;

    if (current_heap_end == 0)
        current_heap_end = &_Heap_Begin;

    current_block_address = current_heap_end;

    // Need to align heap to word boundary, else will get
    // hard faults on Cortex-M0. So we assume that heap starts on
    // word boundary, hence make sure we always add a multiple of
    // 4 to it.
    incr = (incr + 3) & (~3); // align value to 4
    if (current_heap_end + incr > &_Heap_Limit)
    {
        // Some of the libstdc++-v3 tests rely upon detecting
        // out of memory errors, so do not abort here.
#if 0
        extern void abort (void);
        _write (1, "_sbrk: Heap and stack collision\n", 32);
        abort ();
#else
        // Heap has overflowed
        errno = ENOMEM;
        return (caddr_t) - 1;
#endif
    }

    current_heap_end += incr;

    return (caddr_t) current_block_address;
}
