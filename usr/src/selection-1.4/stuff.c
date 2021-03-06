/* implement copying and pasting in Linux virtual consoles */
/* Andrew Haylett, 14th December 1992 */

#include <unistd.h>
#include <stdio.h>
#include <termios.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <sys/kd.h>
#include <sys/ioctl.h>
#include <sys/time.h>

#include "mouse.h"

static const int SCALE = 10;
static const long CLICK_INTERVAL = 250;	/* msec */
static const char *console = "/dev/tty0";

typedef enum { character = 0, word = 1, line = 2 } sel_mode;

static void ms_error(void);
static int open_console(const int mode);
static void set_sel(const int xs, const int ys, const int xe,
                    const int ye, const sel_mode mode);
static void paste(void);
static long interval(const struct timeval *t1, const struct timeval *t2);
static void check_mode(void);

int
main(int argc, char *argv[])
{
    struct ms_event ev;
    struct winsize win;
    struct timeval tv1, tv2;
    int xs, ys, xe, ye, x1, y1, fd, clicks = 0;
    sel_mode mode;
    
    mouse_params(argc, argv);
    fd = open_console(O_RDONLY);
    ioctl(fd, TIOCGWINSZ, &win);
    close(fd);
    if (! win.ws_col || ! win.ws_row)
    {
    	fprintf(stderr, "selection: zero screen dimension, assuming 80x25.\n");
    	win.ws_col = 80;
    	win.ws_row = 25;
    }

    if (ms_init(win.ws_col * SCALE - 1, win.ws_row * SCALE - 1))
    {
    	perror("selection: ms_init()");
	exit(1);
    }

    gettimeofday(&tv1, (struct timezone *)NULL);

    while (1)
    {
	check_mode();
	if (get_ms_event(&ev))
	    ms_error();
	if (ev.ev_butstate == MS_BUTLEFT)
	{
	    ++clicks;
	    gettimeofday(&tv2, (struct timezone *)NULL);
	    xs = ev.ev_x / SCALE + 1;
	    ys = ev.ev_y / SCALE + 1;
	    if (interval(&tv1, &tv2) < CLICK_INTERVAL && clicks == 1)
	    {
	    	mode = word;
		set_sel(xs, ys, xs, ys, mode);
	    }
	    else if (interval(&tv1, &tv2) < CLICK_INTERVAL && clicks == 2)
	    {
	    	mode = line;
		set_sel(xs, ys, xs, ys, mode);
	    }
	    else
	    {
	    	mode = character;
		clicks = 0;
		do	/* wait for left button up */
		{
		    check_mode();
		    if (get_ms_event(&ev))
		    	ms_error();
		} while (ev.ev_butstate);
		x1 = y1 = 0;
		do	/* track start selection until left button down */
		{
		    xs = ev.ev_x / SCALE + 1;
		    ys = ev.ev_y / SCALE + 1;
		    if (xs != x1 || ys != y1)
		    {
			set_sel(xs, ys, xs, ys, mode);
			x1 = xs; y1 = ys;
		    }
		    check_mode();
		    if (get_ms_event(&ev))
		    	ms_error();
		} while (ev.ev_butstate != MS_BUTLEFT);
	    }
	    x1 = y1 = 0;
	    gettimeofday(&tv1, (struct timezone *)NULL);
	    do	/* track end selection until left button up */
	    {
		xe = ev.ev_x / SCALE + 1;
		ye = ev.ev_y / SCALE + 1;
		if (xe != x1 || ye != y1)
		{
		    set_sel(xs, ys, xe, ye, mode);
		    x1 = xe; y1 = ye;
		}
		check_mode();
		if (get_ms_event(&ev))
		    ms_error();
	    } while (ev.ev_butstate == MS_BUTLEFT);
	} else if (ev.ev_butstate == MS_BUTRIGHT)
	{	/* paste selection */
	    paste();
	    do	/* wait for right button up */
	    {
	    	check_mode();
		if (get_ms_event(&ev))
		    ms_error();
	    } while (ev.ev_butstate);
	    gettimeofday(&tv1, (struct timezone *)NULL);
	    clicks = 0;
	}
    }
}

static void
ms_error(void)
{
    perror("selection: get_ms_event()");
    exit(1);
}

/* We have to keep opening and closing the console because (a) /dev/tty0
   changed its behaviour at some point such that the current VC is fixed
   after the open(), rather than being re-evaluated at each write(), and (b)
   because we seem to lose our grip on /dev/tty? after someone logs in if
   this is run from /etc/rc. */

static int
open_console(const int mode)
{
    int fd;

    if ((fd = open(console, mode)) < 0)
    {
    	perror("selection: open_console()");
    	exit(1);
    }
    return fd;
}

/* mark selected text on screen. */
static void
set_sel(const int xs, const int ys,
        const int xe, const int ye, const sel_mode mode)
{
    unsigned char buf[sizeof(char) + 5 * sizeof(short)];
    unsigned short *arg = (unsigned short *)(buf + 1);
    int fd;

    buf[0] = 2;

    arg[0] = xs;
    arg[1] = ys;
    arg[2] = xe;
    arg[3] = ye;
    arg[4] = mode;

    fd = open_console(O_WRONLY);
    if (ioctl(fd, TIOCLINUX, buf) < 0)
    {
	perror("selection: ioctl(..., TIOCLINUX, ...)");
	exit(1);
    }
    close(fd);
}

/* paste contents of selection buffer into console. */
static void
paste(void)
{
    char c = 3;
    int fd;

    fd = open_console(O_WRONLY);
    if (ioctl(fd, TIOCLINUX, &c) < 0)
    {
	perror("selection: ioctl(..., TIOCLINUX, ...)");
	exit(1);
    }
    close(fd);
}

/* evaluate interval between times. */
static long
interval(const struct timeval *t1, const struct timeval *t2)
{
    return (t2->tv_sec  - t1->tv_sec)  * 1000
         + (t2->tv_usec - t1->tv_usec) / 1000;
}

/* Check whether console is in graphics mode; if so, wait until it isn't. */
static void
check_mode(void)
{
    int fd;
    long kd_mode;

    fd = open_console(O_RDONLY);
    do
    {
	if (ioctl(fd, KDGETMODE, &kd_mode))
	{
	    perror("selection: ioctl(..., KDGETMODE, ...)");
	    exit(1);
	}
	if (kd_mode != KD_TEXT)
	    sleep(1);
    } while (kd_mode != KD_TEXT);
    close(fd);
}
