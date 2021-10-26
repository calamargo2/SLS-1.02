#ifndef	lint
#ifdef sccs
static char     sccsid[] = "@(#)nint_next.c 20.11 91/09/14 Copyr 1985 Sun Micro";
#endif
#endif

/*
 *	(c) Copyright 1989 Sun Microsystems, Inc. Sun design patents 
 *	pending in the U.S. and foreign countries. See LEGAL NOTICE 
 *	file for terms of the license.
 */

/*
 * Nint_next.c - Implement the nint_next_callout private interface.
 */

#include <xview_private/ntfy.h>
#include <xview_private/ndet.h>
#include <xview_private/nint.h>

pkg_private     Notify_func
nint_next_callout(nclient, type)
    Notify_client   nclient;
    NTFY_TYPE       type;
{
    NTFY_CONDITION *stack_cond;
    Notify_func     func;

    NTFY_BEGIN_CRITICAL;
    /* Do error checking */
    if (nint_stack_next < 1) {
	ntfy_set_errno(NOTIFY_INVAL);
	goto Error;
    }
    /* Get top stack condition */
    stack_cond = &nint_stack[nint_stack_next - 1];
    /* Do further error and consistency checking */
    if (stack_cond->func_count == 1 ||
	stack_cond->func_next > stack_cond->func_count ||
	stack_cond->func_next + 1 > NTFY_FUNCS_MAX ||
	stack_cond->type != type ||
	stack_cond->data.an_u_int != (u_int) nclient) {
	ntfy_set_errno(NOTIFY_INVAL);
	goto Error;
    }
    /* Get next function */
    func = stack_cond->callout.functions[stack_cond->func_next];
    /* Increment function index */
    stack_cond->func_next++;
    NTFY_END_CRITICAL;
    return (func);
Error:
    NTFY_END_CRITICAL;
    return (NOTIFY_FUNC_NULL);
}
