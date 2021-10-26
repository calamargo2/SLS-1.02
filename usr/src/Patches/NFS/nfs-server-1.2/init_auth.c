/*****************************************************************************\
*									      *
*   File:     exports.c							      *
*   Author:   Don Becker						      *
*   Created:  Fri Jun  9 15:37:56 1989					      *
*   Contents: Reads the nfsd_exports file and creates a list of client	      *
*	    parameters.	 This file should really be called init_auth.c	      *
*									      *
******************************************************************************/

#include <netdb.h>				/* For gethostbyname() */
#include <stdio.h>
#include <syslog.h>
#include <ctype.h>
#include <strings.h>
#include "nfsd.h"
#include "libc.h"
#include "mount.h"

#ifndef EXPORTSFILE
#define EXPORTSFILE "/etc/exports"
#endif

clnt_param  *clients = NULL;
clnt_param  *unknown_clients = NULL;
clnt_param  *default_client = NULL;

exportnode  *export_list = NULL;

int auth_initialized = 0;
int promiscuous = 0;
int allow_non_root = 0;

#define LINE_SIZE   1024

static char *parse_opts(char *cp, int terminator,
			options *o, char *client_name);
static int getline(char **lbuf, FILE *f);


options default_options = { identity, 0, 1, 1, 1};

void
init_auth(char *filename)
{
    FILE *ef;
    char *cp;				/* Current line position */
    char *sp;				/* Secondary pointer */
    char *fs_name;
    clnt_param *new_param;
    exportnode *resex;
    groupnode *resgr;

    if (filename == NULL)
	filename = EXPORTSFILE;

    if ((ef = fopen(filename, "r")) == NULL) {
	syslog(LOG_DAEMON|LOG_WARNING, "Could not open exports file %s: %m",
	       filename);
	exit(1);
    }

    while (getline(&cp, ef)) {
	char *saved_line = cp;		    /* For free()ing it later. */
	char *mount_point, *host_name;
	struct hostent *hent;

	while (isspace(*cp)) cp++;	/* Skip space */

	fs_name = cp;			/* Get the file-system name */
	while (*cp != '\0' && !isspace(*cp))
	    cp++;

					/* Copy it into a new string */
	if ((mount_point = malloc(cp - fs_name + 1)) == NULL)
	    mallocfailed();
	for (sp = mount_point; fs_name < cp;)
	    *sp++ = *fs_name++;
	*sp = '\0';

	if ((resex = malloc(sizeof *resex)) == NULL)
	    mallocfailed();
	resex->ex_dir = mount_point;
	resex->ex_groups = NULL;
	resex->ex_next = export_list;
	export_list = resex;

	while (isspace(*cp))  cp++;	/* Skip space */

	/* special case for anononymous NFS */

	if (*cp == '\0' || *cp == '(') {
	    if ((new_param = (clnt_param *) malloc(sizeof *new_param)) == NULL)
		mallocfailed();
	    new_param->clnt_name = NULL;
	    new_param->mount_point = mount_point;
	    new_param->o = default_options;
	    new_param->next = unknown_clients;
	    unknown_clients = new_param;
	    if (*cp == '(')
		cp = parse_opts(cp+1, ')', &(new_param->o),
				new_param->clnt_name);
	}

	while (*cp != '\0')
	{
	    host_name = cp;
	    /* host name */
	    while (*cp != '\0' && !isspace(*cp) && *cp != '(')
		cp++;
	    if ((new_param = (clnt_param *) malloc(sizeof *new_param)) == NULL
		|| (new_param->clnt_name = malloc(cp-host_name+1)) == NULL)
		mallocfailed();
	    for (sp = new_param->clnt_name; host_name < cp;)
		*sp++ = *host_name++;
	    *sp = '\0';

	    /* Finish parsing options */
	    new_param->o = default_options;
	    while (isspace(*cp)) cp++;
	    if (*cp == '(')
		cp = parse_opts(cp+1, ')', &(new_param->o),
				new_param->clnt_name);

	    new_param->mount_point = mount_point;

	    if ((resgr = malloc(sizeof *resgr)) == NULL)
		mallocfailed();
	    resgr->gr_name = new_param->clnt_name;
	    resgr->gr_next = resex->ex_groups;
	    resex->ex_groups = resgr;

	    if (strchr(new_param->clnt_name, '*')
		|| strchr(new_param->clnt_name, '?')) {
		/* add this host pattern to the unknown list */
		new_param->next = unknown_clients;
		unknown_clients = new_param;
	    }
	    else if ((hent = gethostbyname(new_param->clnt_name)) == NULL) {
		char *reason;
		switch (h_errno) {
#ifdef HOST_NOT_FOUND				/* Only on 4.3 systems */
		case HOST_NOT_FOUND:
		    reason = "Authoritive -- the host exists only in your imagination.";
		    break;
		case TRY_AGAIN:
		    reason = "Non-Authoritive -- the host might exist."; break;
		case NO_RECOVERY:
		    reason = "Non-recoverable error."; break;
		case NO_ADDRESS:
		    reason = "Valid host name, but no address."; break;
#endif
		default:
		    reason = "Unknown reason.";
		}
		syslog(LOG_DAEMON|LOG_WARNING, "Unknown host %s in %s (%s)",
		       new_param->clnt_name, filename, reason);
		/* Add this loser to the list of unknowns. */
		new_param->next = unknown_clients;
		unknown_clients = new_param;
	    } else {
		/* This should be changed to handle the address list under 4.3 */
		new_param->clnt_addr = *((struct in_addr *)hent->h_addr);
		new_param->next = clients;	    /* Add to client list */
		clients = new_param;
	    }
	}
	free(saved_line);
    }
    fclose(ef);

    if (promiscuous)
    {
	if ((new_param = (clnt_param *) malloc(sizeof *new_param)) == NULL)
	    mallocfailed();
	new_param->clnt_name = NULL;
	new_param->mount_point = NULL;
	default_client = new_param;
	new_param->o = default_options;
    }
    auth_initialized = 1;
}

static char *parse_opts(cp, terminator, o, client_name)
     char   *cp;
     char   terminator;
     options	*o;
     char   *client_name;
{
    /* parse option string pointed to by s and set o accordingly */
    char    kwdbuf[LINE_SIZE];
    char    *k;

    /* skip white */
    while (isspace(*cp)) cp++;
    while (*cp != terminator) {
	k = kwdbuf;
	while (isalnum(*cp) || *cp == '_')
	    *k++ = *cp++;
	*k = '\0';
	/* process keyword */
	if (strcmp(kwdbuf, "secure") == 0)
	    o->secure_port = 1;
	else if (strcmp(kwdbuf, "insecure") == 0)
	    o->secure_port = 0;
	else if (strcmp(kwdbuf, "root_squash") == 0)
	    o->root_squash = 1;
	else if (strcmp(kwdbuf, "no_root_squash") == 0)
	    o->root_squash = 0;
	else if (strcmp(kwdbuf, "ro") == 0)
	    o->read_only = 1;
	else if (strcmp(kwdbuf, "rw") == 0)
	    o->read_only = 0;
	else if (strcmp(kwdbuf, "link_relative") == 0)
	    o->link_relative = 1;
	else if (strcmp(kwdbuf, "link_absolute") == 0)
	    o->link_relative = 0;
	else if (strcmp(kwdbuf, "map_daemon") == 0)
	    o->uidmap = map_daemon;
	else if (strcmp(kwdbuf, "map_identity") == 0)
	    o->uidmap = identity;
	else
	    syslog(LOG_DAEMON|LOG_ERR, "Unknown keyword \"%s\"", kwdbuf);
	while (isspace(*cp))  cp++;
	if (*cp == terminator)
	    break;
	if (*cp == ',')
	    cp++;
	else if (!isalnum(*cp) && *cp != '_' && *cp != '\0')
	{
	    if (client_name == NULL)
		syslog(LOG_DAEMON|LOG_ERR,
		    "Comma expected in option list for default client (found '%c')", *cp);
	    else
		syslog(LOG_DAEMON|LOG_ERR,
		    "Comma expected in option list for client %s (found '%c')",
		    client_name, *cp);
	}
	while (isspace(*cp))  cp++;

	if (*cp == '\0' && *cp != terminator)
	{
	    syslog(LOG_DAEMON|LOG_ERR,
		"missing terminator \"%c\" on option list",
		terminator);
	    return cp;
	}
    }
    if (*cp != terminator)
	syslog(LOG_DAEMON|LOG_ERR, "Internal inconsistency in parse, character '%c'.", *cp);
    cp++;					/* Skip past terminator */
    while (isspace(*cp))  cp++;
    return cp;
}

static int
filt_getc(f)
FILE	*f;
{
    int c;

    c = getc(f);
    if (c == '\\')
    {
	c = getc(f);
	if (c == '\n')
	    return ' ';
	if (c != EOF)
	    ungetc(c, f);
	return '\\';
    }
    else if (c == '#')
    {
	int lastc = c;
	while ((c = getc(f)) != '\n' && c != EOF)
	    lastc = c;
	if (c == '\n' && lastc == '\\')
	    c = getc(f);
    }
    return c;
}

#define CHUNK_SIZE  132 /* The 'typical' maximum length line */

static int
getline(lbuf, f)
char	**lbuf;
FILE	*f;
{
    register	c;
    register char   *p;
    char    *buf;
    int sz = CHUNK_SIZE;

    if ((buf = malloc(CHUNK_SIZE)) == NULL)
	mallocfailed();
    p = buf;
    while ((c = filt_getc(f)) != '\n' && c != EOF)
    {
	if (p - buf == sz-2)
	{
	    if ((buf = realloc(buf, sz*2)) == NULL)
		mallocfailed();
	    p = buf + sz-2;
	    sz *= 2;
	}
	*p++ = c;
    }
    if (c == EOF && p == buf)
    {
	free(buf);
	*lbuf = NULL;
	return 0;
    }
    *p++ = '\0';
    *lbuf = buf;
    return 1;
}

/*
 * Local variables:
 *  compile-command: "make"
 *  tab-width: 4
 *  comment-column: 40
 *  c-indent-level: 4
 * End:
 */
