# menu.tcl --
#
# This file contains Tcl procedures used to manage Tk menus and
# menubuttons.  Most of the code here is dedicated to support for
# pulling down menus and menu traversal via the keyboard.
#
# $Header: /user6/ouster/wish/library/RCS/menu.tcl,v 1.13 92/12/03 16:36:12 ouster Exp $ SPRITE (Berkeley)
#
# Copyright 1992 Regents of the University of California
# Permission to use, copy, modify, and distribute this
# software and its documentation for any purpose and without
# fee is hereby granted, provided that this copyright
# notice appears in all copies.  The University of California
# makes no representations about the suitability of this
# software for any purpose.  It is provided "as is" without
# express or implied warranty.
#

# The procedure below is publically available.  It is used to identify
# a frame that serves as a menu bar and the menu buttons that lie inside
# the menu bar.  This procedure establishes proper "menu bar" behavior
# for all of the menu buttons, including keyboard menu traversal.  Only
# one menu bar may exist for a given top-level window at a time.
# Arguments:
#	
# bar -				The path name of the containing frame.  Must
#				be an ancestor of all of the menu buttons,
#				since it will be be used in grabs.
# additional arguments -	One or more menu buttons that are descendants
#				of bar.  The order of these arguments
#				determines the order of keyboard traversal.
#				If no extra arguments are named then all of
#				the menu bar information for bar is cancelled.

proc tk_menuBar {w args} {
    global tk_priv
    if {$args == ""} {
	if [catch {set menus $tk_priv(menusFor$w)}] {
	    return ""
	}
	return $menus
    }
    if [info exists tk_priv(menusFor$w)] {
	unset tk_priv(menusFor$w)
	unset tk_priv(menuBarFor[winfo toplevel $w])
    }
    if {$args == "{}"} {
	return
    }
    set tk_priv(menusFor$w) $args
    set tk_priv(menuBarFor[winfo toplevel $w]) $w
    bind $w <Any-ButtonRelease-1> tk_mbUnpost
}

proc tk_menus {w args} {
    error "tk_menus is obsolete in Tk versions 3.0 and later; please change your scripts to use tk_menuBar instead"
}

# The procedure below is publically available.  It takes any number of
# arguments that are names of widgets or classes.  It sets up bindings
# for the widgets or classes so that keyboard menu traversal is possible
# when the input focus is in those widgets or classes.

proc tk_bindForTraversal args {
    foreach w $args {
	bind $w <Alt-KeyPress> {tk_traverseToMenu %W %A}
	bind $w <F10> {tk_firstMenu %W}
    }
}

# The procedure below does all of the work of posting a menu (including
# unposting any other menu that might currently be posted).  The "w"
# argument is the name of the menubutton for the menu to be posted.
# Note:  if $w is disabled then the procedure does nothing.

proc tk_mbPost {w} {
    global tk_priv tk_strictMotif
    if {[lindex [$w config -state] 4] == "disabled"} {
	return
    }
    set menu [lindex [$w config -menu] 4]
    if {$menu == ""} {
	return
    }
    if ![string match $w* $menu] {
	error "can't post $menu:  it isn't a descendant of $w (this is a new requirement in Tk versions 3.0 and later)"
    }
    set cur $tk_priv(posted)
    if {$cur != ""} tk_mbUnpost
    set tk_priv(relief) [lindex [$w config -relief] 4]
    $w config -relief raised
    set tk_priv(posted) $w
    if {$tk_priv(focus) == ""} {
	set tk_priv(focus) [focus]
    }
    set tk_priv(activeBg) [lindex [$menu config -activebackground] 4]
    set tk_priv(activeFg) [lindex [$menu config -activeforeground] 4]
    if $tk_strictMotif {
	$menu config -activebackground [lindex [$menu config -background] 4]
	$menu config -activeforeground [lindex [$menu config -foreground] 4]
    }
    $menu activate none
    focus $menu
    $menu post [winfo rootx $w] [expr [winfo rooty $w]+[winfo height $w]]
    if [catch {set grab $tk_priv(menuBarFor[winfo toplevel $w])}] {
	set grab $w
    } else {
	if [lsearch $tk_priv(menusFor$grab) $w]<0 {
	    set grab $w
	}
    }
    set tk_priv(cursor) [lindex [$grab config -cursor] 4]
    $grab config -cursor arrow
    set tk_priv(grab) $grab
    grab -global $grab
}

# The procedure below does all the work of unposting the menubutton that's
# currently posted.  It takes no arguments.

proc tk_mbUnpost {} {
    global tk_priv
    set w $tk_priv(posted)
    if {$w != ""} {
	$w config -relief $tk_priv(relief)
	$tk_priv(grab) config -cursor $tk_priv(cursor)
	grab release $tk_priv(grab)
	focus $tk_priv(focus)
	set tk_priv(focus) ""
	set menu [lindex [$w config -menu] 4]
	$menu unpost
	$menu config -activebackground $tk_priv(activeBg)
	$menu config -activeforeground $tk_priv(activeFg)
	set tk_priv(posted) {}
    }
}

# The procedure below is invoked to implement keyboard traversal to
# a menu button.  It takes two arguments:  the name of a window where
# a keystroke originated, and the ascii character that was typed.
# This procedure finds a menu bar by looking upward for a top-level
# window, then looking for a window underneath that named "menu".
# Then it searches through all the subwindows of "menu" for a menubutton
# with an underlined character matching char.  If one is found, it
# posts that menu.

proc tk_traverseToMenu {w char} {
    global tk_priv
    if {$char == ""} {
	return
    }
    set char [string tolower $char]

    foreach mb [tk_getMenuButtons $w] {
	if {[winfo class $mb] == "Menubutton"} {
	    set char2 [string index [lindex [$mb config -text] 4] \
		    [lindex [$mb config -underline] 4]]
	    if {[string compare $char [string tolower $char2]] == 0} {
		tk_mbPost $mb
		[lindex [$mb config -menu] 4] activate 0
		return
	    }
	}
    }
}

# The procedure below is used to implement keyboard traversal within
# the posted menu.  It takes two arguments:  the name of the menu to
# be traversed within, and an ASCII character.  It searches for an
# entry in the menu that has that character underlined.  If such an
# entry is found, it is invoked and the menu is unposted.

proc tk_traverseWithinMenu {w char} {
    if {$char == ""} {
	return
    }
    set char [string tolower $char]
    set last [$w index last]
    for {set i 0} {$i <= $last} {incr i} {
	if [catch {set char2 [string index \
		[lindex [$w entryconfig $i -label] 4] \
		[lindex [$w entryconfig $i -underline] 4]]}] {
	    continue
	}
	if {[string compare $char [string tolower $char2]] == 0} {
	    tk_mbUnpost
	    $w invoke $i
	    return
	}
    }
}

# The procedure below takes a single argument, which is the name of
# a window.  It returns a list containing path names for all of the
# menu buttons associated with that window's top-level window, or an
# empty list if there are none.

proc tk_getMenuButtons w {
    global tk_priv
    set top [winfo toplevel $w]
    if [catch {set bar [set tk_priv(menuBarFor$top)]}] {
	return ""
    }
    return $tk_priv(menusFor$bar)
}

# The procedure below is used to traverse to the next or previous
# menu in a menu bar.  It takes one argument, which is a count of
# how many menu buttons forward or backward (if negative) to move.
# If there is no posted menu then this procedure has no effect.

proc tk_nextMenu count {
    global tk_priv
    if {$tk_priv(posted) == ""} {
	return
    }
    set buttons [tk_getMenuButtons $tk_priv(posted)]
    set length [llength $buttons]
    for {set i 0} 1 {incr i} {
	if {$i >= $length} {
	    return
	}
	if {[lindex $buttons $i] == $tk_priv(posted)} {
	    break
	}
    }
    incr i $count
    while 1 {
	while {$i < 0} {
	    incr i $length
	}
	while {$i >= $length} {
	    incr i -$length
	}
	set mb [lindex $buttons $i]
	if {[lindex [$mb configure -state] 4] != "disabled"} {
	    break
	}
	incr i $count
    }
    tk_mbUnpost
    tk_mbPost $mb
    [lindex [$mb config -menu] 4] activate 0
}

# The procedure below is used to traverse to the next or previous entry
# in the posted menu.  It takes one argument, which is 1 to go to the
# next entry or -1 to go to the previous entry.  Disabled entries are
# skipped in this process.

proc tk_nextMenuEntry count {
    global tk_priv
    if {$tk_priv(posted) == ""} {
	return
    }
    set menu [lindex [$tk_priv(posted) config -menu] 4]
    set length [expr [$menu index last]+1]
    set i [$menu index active]
    if {$i == "none"} {
	set i 0
    } else {
	incr i $count
    }
    while 1 {
	while {$i < 0} {
	    incr i $length
	}
	while {$i >= $length} {
	    incr i -$length
	}
	if {[catch {$menu entryconfigure $i -state} state] == 0} {
	    if {[lindex $state 4] != "disabled"} {
		break
	    }
	}
	incr i $count
    }
    $menu activate $i
}

# The procedure below invokes the active entry in the posted menu,
# if there is one.  Otherwise it does nothing.

proc tk_invokeMenu {menu} {
    set i [$menu index active]
    if {$i != "none"} {
	tk_mbUnpost
	update idletasks
	$menu invoke $i
    }
}

# The procedure below is invoked to keyboard-traverse to the first
# menu for a given source window.  The source window is passed as
# parameter.

proc tk_firstMenu w {
    set mb [lindex [tk_getMenuButtons $w] 0]
    if {$mb != ""} {
	tk_mbPost $mb
	[lindex [$mb config -menu] 4] activate 0
    }
}

# The procedure below is invoked when a button-1-down event is
# received by a menu button.  If the mouse is in the menu button
# then it posts the button's menu.  If the mouse isn't in the
# button's menu, then it deactivates any active entry in the menu.
# Remember, event-sharing can cause this procedure to be invoked
# for two different menu buttons on the same event.

proc tk_mbButtonDown w {
    global tk_priv
    if {[lindex [$w config -state] 4] == "disabled"} {
	return
    }
    if {$tk_priv(inMenuButton) == $w} {
	tk_mbPost $w
    }
}
