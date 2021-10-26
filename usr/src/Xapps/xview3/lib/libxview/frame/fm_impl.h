/*	%z%fm_impl.h 20.46 91/01/11 SMI	*/

/***********************************************************************/
/*	                 frame_impl.h/fm_impl.h	       		       */
/*	
 *	(c) Copyright 1989 Sun Microsystems, Inc. Sun design patents 
 *	pending in the U.S. and foreign countries. See LEGAL NOTICE 
 *	file for terms of the license. 
 */
/***********************************************************************/

#ifndef _frame_impl_h_already_included
#define _frame_impl_h_already_included

/* standard includes */
#ifndef FILE
#ifndef SVR4
#undef NULL
#endif SVR4
#include <stdio.h>
#endif FILE
#include <sys/time.h>
#ifdef OW_I18N
#endif /* OW_I18N */
#include <xview/xv_i18n.h>
#include <xview/notify.h>
#include <xview/rect.h>

#include <xview/rectlist.h>
#include <xview/win_struct.h>	/* for WL_ links */
#include <xview/win_input.h>

/* all this for wmgr.h */
#include <xview/win_screen.h>
#include <xview/wmgr.h>
#include <xview_private/wmgr_decor.h>

#include <xview/pkg.h>
#include <xview/attrol.h>
#include <xview/frame.h>
#include <xview/icon.h>
#include <xview/openmenu.h>
#include <xview/cms.h>
#include <xview_private/i18n_impl.h>
#include <xview_private/portable.h>
#include <olgx/olgx.h>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#ifdef OW_I18N
#include <X11/Xresource.h>
#endif
#define	FRAME_CLASS_PRIVATE(f)	XV_PRIVATE(Frame_class_info, Xv_frame_class, f)
#define	FRAME_CLASS_PUBLIC(frame)	XV_PUBLIC(frame)
#define FRAME_PUBLIC(frame)	FRAME_CLASS_PUBLIC(frame)
#define FRAME_PRIVATE(f)	FRAME_CLASS_PRIVATE(f)

#define	BIT_FIELD(field)	int field : 1

typedef	struct	{
    Frame	 public_self;	  /* back pointer to object */
    char	*label;		  /* string in name stripe & default icon */
    Icon 	 icon;
    Icon 	 default_icon;    /* Default Icon */
    Frame	 first_subframe;  /* first subframe in list of subframes */
    Xv_Window	 first_subwindow; /* first subwindow in list of subwindows */
    Rect	 rectcache; 	  /* rect of frame (tool relative) */
    Rect 	 oldrect;  	  /* quick check if size has changed */ 
    Rect         user_rect;       /* user position and size */
    void       (*done_proc)();
    void       (*default_done_proc)();
    Xv_Window	 focus_subwindow; /* last subwindow that had the input focus */
    Xv_Window	 primary_focus_sw;/* primary focus subwindow */
    XWMHints	 wmhints;	  /* Window manager hints structure */
    XSizeHints   normal_hints;	  /* WM_SIZE_HINTS */
    int		 geometry_flags;  /* Geometry information */
    XColor	 bg;		  /* background color */
    XColor	 fg;		  /* foreground color */
    Xv_Window	 focus_window;	  /* Location Cursor window */
    Xv_Window	 footer;          /* Win that is used to implement the footer */
    char	*left_footer;	  /* string in left footer */
    char	*right_footer;	  /* string in right footer */
    Graphics_info	*ginfo;	  /* OLGX structure used to paint footers */
    Frame_accelerator	*accelerators;	/* Window Level Accelerator list */
#ifdef OW_I18N
    Xv_opaque    input_window;    /* input window for canvas*/
    Xv_Window	 imstatus;	  /* Win that is used to implement IMstatus */
    wchar_t     *leftIMstatus_wcs;/* IM Status region, no mbs support */
    char        *leftIMstatus;    /* IM Status region, mbs support */
    wchar_t     *rightIMstatus_wcs;/* IM PreEdit region? no mbs support */    
    char        *rightIMstatus;   /* IM Status region, mbs support */
    wchar_t     *leftfooter_wcs;  /* Wide char (primary) left footer */
    wchar_t     *rightfooter_wcs; /* Wide char (primary) right footer */
     /*
      * Wide char version of label is primary, and following multibyte
      * version is secondary (basically for compatibility).  string in
      * name stripe & default icon
      */
    wchar_t     *label_wcs;
#endif 

    struct {
	BIT_FIELD(bndrymgr);		/* movable borders between subwindows */
	BIT_FIELD(full);		/* current state is full */
	BIT_FIELD(no_confirm);		/* don't confirm on destroy */
	BIT_FIELD(initial_state);	/* icon initial state (set = iconic) */
	/* Note that iconic is used only to detect a change in state.
	 * frame_is_iconic() is the function to call to determine
	 * if the frame is iconic or not.
	 */
	BIT_FIELD(busy);		/* whether frame is busy or not     */
	BIT_FIELD(iconic);		/* whether frame is iconic or not   */
	BIT_FIELD(dismiss);		/* whether frame is being dismissed */
					/* or not.			    */
	BIT_FIELD(map_state_change);	/* whether we (un)mapped the frame
					 * and should expect an (Un)mapNotify.*/
	BIT_FIELD(created);		/* whether frame has been created */
	BIT_FIELD(frame_color);		/* whether frame has been created */
	BIT_FIELD(show_footer);		/* whether the footer is visable */
	BIT_FIELD(compose_led);		/* whether the compose LED is on/off */
#ifdef OW_I18N
	BIT_FIELD(show_imstatus);	/* whether the IMstatus is visable */
#endif
    } status_bits;
} Frame_class_info;

#define	status_get(frame, field)	((frame)->status_bits.field)
#define	status_set(frame, field, value)	\
	(frame)->status_bits.field = ((value) != FALSE)



#define	FRAME_EACH_CHILD(first, child)	\
    { Xv_Window	_next; \
    for ((child) = (first), \
	 (child) && \
	 (_next = xv_get((child), XV_KEY_DATA, FRAME_NEXT_CHILD)); \
	 (child); (child) = _next, \
	 (child) && \
	 (_next = xv_get((child), XV_KEY_DATA, FRAME_NEXT_CHILD))) {

#define	FRAME_EACH_SUBWINDOW(frame, child)	\
    FRAME_EACH_CHILD((frame)->first_subwindow, child)

#define	FRAME_EACH_SUBFRAME(frame, child)	\
    FRAME_EACH_CHILD((frame)->first_subframe, child)

#define	FRAME_EACH_SHOWN_SUBWINDOW(frame, child)	\
    FRAME_EACH_SUBWINDOW(frame, child)	\
	if (!xv_get(child, XV_SHOW)) \
	    continue;

#define	FRAME_END_EACH	}}

#define	EXTEND_HEIGHT(child)	\
    ((int) xv_get((child), WIN_DESIRED_HEIGHT) == WIN_EXTEND_TO_EDGE)

#define	EXTEND_WIDTH(child)	\
    ((int) xv_get((child), WIN_DESIRED_WIDTH) == WIN_EXTEND_TO_EDGE)


#define	frame_getnormalrect(frame, rectp) \
	    win_getrect(FRAME_PUBLIC(frame), (rectp))
#define	frame_setnormalrect(frame, rectp) \
	    win_setrect(FRAME_PUBLIC(frame), (rectp))

#define frame_is_iconic(frame)  (status_get(frame, iconic))


#define	FRAME_ICON_WIDTH	64
#define	FRAME_ICON_HEIGHT	64

#ifdef OW_I18N
#define LEFT_IMSTATUS           0
#define RIGHT_IMSTATUS          1
#endif

/* frame.c */
Pkg_private int 	frame_init();
Pkg_private int		frame_notify_count;
Pkg_private void	frame_default_done_func();

/* frame_get.c */
Pkg_private Xv_opaque	frame_get_attr();

/* frame_set.c */
Pkg_private Xv_opaque	frame_set_avlist();

/* frame_layout.c */
Pkg_private int			frame_layout();
Pkg_private Xv_Window		frame_last_child();

/* frame_destroy.c */
Pkg_private int			frame_destroy();

/* frame_menu.c */
Pkg_private void	frame_full();

/* frame_win.c */
Pkg_private int		frame_set_parent();
Pkg_private int		frame_is_exposed();

/* frame_input.c */
Pkg_private Notify_value frame_input();
Pkg_private Notify_value frame_footer_input();
#ifdef OW_I18N
Pkg_private Notify_value frame_IMstatus_input();
#endif
Pkg_private void	frame_focus_win_event_proc();

/* frame_display.c */
Pkg_private void	frame_display_label();
Pkg_private void	frame_display_footer();
#ifdef OW_I18N
Pkg_private void	frame_display_IMstatus();
#endif
Pkg_private int		frame_set_color();

/* fm_geom.c */
Pkg_private int		frame_height_from_lines();
Pkg_private int		frame_width_from_columns();
Pkg_private void	frame_position_sw();
Pkg_private int		frame_footer_height();
#ifdef OW_I18N
Pkg_private int		frame_IMstatus_height();
#endif
Pkg_private int		frame_footer_baseline();
Pkg_private int		frame_footer_margin();
Pkg_private int		frame_inter_footer_gap();

/* frame_cmdline.c */
Pkg_private int		frame_set_cmdline_options();
Pkg_private int		frame_set_icon_cmdline_options();

/* frame_rescale.c */
Pkg_private void	frame_rescale_subwindows();

/* frame_sw.c */
Pkg_private void	frame_layout_subwindows();

#endif
