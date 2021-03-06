/* Stuff common to both the FTP server and client */
#include <stdio.h>
#include "global.h"
#include "config.h"
#include "mbuf.h"
#include "netuser.h"
#include "timer.h"
#include "tcp.h"
#include "ftp.h"
#include "telnet.h"
#include "iface.h"
#include "ax25.h"
#include "lapb.h"
#include "finger.h"
#include "session.h"
#ifdef	SYS5
#include <sys/types.h>
#include <sys/stat.h>
#ifdef	hp9000s500
#include <sys/param.h>
#endif	/* hp9000s500 */

#define	IFIFO	S_IFIFO
#ifdef undef
#include <sys/inode.h>
#endif	/* SUNOS4 */
#endif	/* SYS5 */
#include "nr4.h"

#if	(ATARI_ST && MWC)
#define	fclose	vclose		/* Take care of temp files -- hyc */
#endif

/* FTP Data channel Receive upcall handler */
void
ftpdr(tcb,cnt)
struct tcb *tcb;
int16 cnt;
{
	register struct ftp *ftp;
	struct mbuf *bp;
	char c;

	ftp = (struct ftp *)tcb->user;
	if(ftp->state != RECEIVING_STATE){
		close_tcp(tcb);
		return;
	}
	/* This will likely also generate an ACK with window rotation */
	recv_tcp(tcb,&bp,cnt);

#if (UNIX || MAC || AMIGA || ATARI_ST)
	if(ftp->type == ASCII_TYPE){
		while(pullup(&bp,&c,1) == 1){
			if(c != '\r')
				putc(c,ftp->fp);
		}
		return;
	}
#endif
	while(bp != NULLBUF){
		if(bp->cnt != 0)
			fwrite(bp->data,1,(unsigned)bp->cnt,ftp->fp);
		bp = free_mbuf(bp);
	}

 	if(ftp->fp != stdout && ferror(ftp->fp)){ /* write error (dsk full?) */
 		fclose(ftp->fp);
 		ftp->fp = NULLFILE;
 		close_self(tcb,RESET);
 	}
}
/* FTP Data channel Transmit upcall handler */
void
ftpdt(tcb,cnt)
struct tcb *tcb;
int16 cnt;
{
	struct ftp *ftp;
	struct mbuf *bp;
	register char *cp;
	register int c;
	int eof_flag;
#ifdef	SYS5
	struct stat ss_buf;
#endif

	ftp = (struct ftp *)tcb->user;
	if(ftp->state != SENDING_STATE){
		close_tcp(tcb);
		return;
	}
	if((bp = alloc_mbuf(cnt)) == NULLBUF){
		/* Hard to know what to do here */
		return;
	}
	eof_flag = 0;
	if(ftp->type == IMAGE_TYPE){
		bp->cnt = fread(bp->data,1,cnt,ftp->fp);
		if(bp->cnt != cnt)
			eof_flag = 1;
	} else {
		cp = bp->data;
		while(cnt > 1){
			if((c = getc(ftp->fp)) == EOF){
				eof_flag=1;
				break;
			}
#if (defined(CPM) || defined(MSDOS))
			/* ^Z is CP/M's text EOF marker, and it is sometimes used
			 * by MS-DOS editors too
			 */
			if(c == CTLZ){
				eof_flag = 1;
				break;
			}
#endif
#if (defined(UNIX) || defined(MAC) || defined(AMIGA) || defined(ATARI_ST))
			if(c == '\n'){
				*cp++ = '\r';
				bp->cnt++;
				cnt--;
			}
#endif
			*cp++ = c;
			bp->cnt++;
			cnt--;
		}
	}
	if(bp->cnt != 0)
		send_tcp(tcb,bp);
	else
		free_p(bp);

	if(eof_flag){	/* EOF seen */
#ifdef	UNIX
#ifdef	SYS5
#ifndef	hp9000s500
/* If ftp->fp points to an open pipe (from dir()) it must be closed with */
/* pclose().  System V fstat() can tell us if this was a pipe or not. */
		if (fstat(fileno(ftp->fp), &ss_buf) < 0)
			perror("ftpdt: fstat");
		if ((ss_buf.st_mode & IFIFO) == IFIFO)
			pclose(ftp->fp);	/* close pipe from dir */
		else
			fclose(ftp->fp);
#else	/* hp9000s500 */
/* HP-UX 5.21 on the 500 doesn't understand IFIFO, since we probably don't *.
/* care anyway, treat it like BSD is treated... */
		if (pclose(ftp->fp) < 0)
			fclose(ftp->fp);
#endif	/* hp9000s500 */
#else	/* SYS5 */
/* Berkeley Unix can't tell if this was a pipe or not.  Try a pclose() */
/* first.  If this fails, it must have been an open file. */
		if (pclose(ftp->fp) < 0)
			fclose(ftp->fp);
#endif	/* SYS5 */
#else	/* UNIX */
/* Anything other than Unix */
		fclose(ftp->fp);
#endif	/* UNIX */
		ftp->fp = NULLFILE;
		close_tcp(tcb);
	}
}
/* Allocate an FTP control block */
struct ftp *
ftp_create(bufsize)
unsigned bufsize;
{
	void ftp_delete();
	register struct ftp *ftp;

	if((ftp = (struct ftp *)calloc(1,sizeof (struct ftp))) == NULLFTP)
		return NULLFTP;
	if(bufsize != 0 && (ftp->buf = malloc(bufsize)) == NULLCHAR){
		printf("called by ftp_create\n");fflush(stdout);
		ftp_delete(ftp);
		printf("called by ftp_create\n");fflush(stdout);
		return NULLFTP;
	}
	ftp->state = COMMAND_STATE;
	ftp->type = ASCII_TYPE;	/* Default transfer type */
	return ftp;
}
/* Free resources, delete control block */
void
ftp_delete(ftp)
register struct ftp *ftp;
{
        int i;

	if(ftp->fp != NULLFILE && ftp->fp != stdout)
		fclose(ftp->fp);
	if(ftp->data != NULLTCB)
		del_tcp(ftp->data);
	if(ftp->username != NULLCHAR)
		free(ftp->username);
        for (i = 0; i < MAXPATH; i++)
	  if(ftp->path[i] != NULLCHAR)
	    free(ftp->path[i]);
	if(ftp->buf != NULLCHAR)
		free(ftp->buf);
	if(ftp->cd != NULLCHAR)
		free(ftp->cd);
	if(ftp->session != NULLSESSION)
		freesession(ftp->session);
	free((char *)ftp);
}

