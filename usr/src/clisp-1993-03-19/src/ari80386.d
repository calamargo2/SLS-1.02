# Externe Routinen zu ARILEV1.D
# Prozessor: 80386 im native mode
# Assembler-Syntax: GNU oder SUN, Moves von links nach rechts
# Compiler: GNU-C oder SUN-C
# Parameter-?bergabe: auf dem Stack 4(%esp),8(%esp),...
# Register: %eax,%edx,%ecx d?rfen stets ver?ndert werden, alles andere retten.
# Ergebnis-?bergabe: in %eax
# Einstellungen: intCsize=32, intDsize=32.

# Bruno Haible 14.8.1992
# Zum Teil abgeschrieben von Bernhard Degels "v-i386.s"

#ifdef INCLUDED_FROM_C

  #define COPY_LOOPS
  #define FILL_LOOPS
  #define CLEAR_LOOPS
  #define LOG_LOOPS
  #define TEST_LOOPS
  #define ADDSUB_LOOPS
  #define SHIFT_LOOPS
  #define MUL_LOOPS
  #define DIV_LOOPS

#else

  #ifdef UNDERSCORE /* defined(__EMX__) || defined(__DJGCC__) || defined(linux) || defined(__386BSD__) || ... */
    # GNU-Assembler
    #ifdef __STDC__
      #define C(entrypoint) _##entrypoint
    #else
      #define C(entrypoint) _/**/entrypoint
    #endif
    #define repz     repe
    #define shcl     %cl,
  #else /* defined(sun) || ... */
    # SUN-Assembler oder Consensys-Assembler
    #define C(entrypoint) entrypoint
    #define jecxz    orl %ecx,%ecx ; jz
    #define shcl
  #endif
  #if defined(__EMX__)
    # Direction-Flag ist defaultm??ig gel?scht
    #define dir0start
    #define dir0end
    #define dir1start  std
    #define dir1end    cld
  #elif 1
    # Wir gehen auf Nummer sicher.
    #define dir0start  cld
    #define dir0end
    #define dir1start  std
    #define dir1end    cld
  #else
    # Direction-Flag darf nach Belieben modifiziert werden
    #define dir0start  cld
    #define dir0end
    #define dir1start  std
    #define dir1end
  #endif

        .text
        .align 2

        .globl C(copy_loop_up)
        .globl C(copy_loop_down)
        .globl C(fill_loop_up)
        .globl C(fill_loop_down)
        .globl C(clear_loop_up)
        .globl C(clear_loop_down)
        .globl C(or_loop_up)
        .globl C(xor_loop_up)
        .globl C(and_loop_up)
        .globl C(eqv_loop_up)
        .globl C(nand_loop_up)
        .globl C(nor_loop_up)
        .globl C(andc2_loop_up)
        .globl C(orc2_loop_up)
        .globl C(not_loop_up)
        .globl C(and_test_loop_up)
        .globl C(test_loop_up)
        .globl C(compare_loop_up)
        .globl C(add_loop_down)
        .globl C(addto_loop_down)
        .globl C(inc_loop_down)
        .globl C(sub_loop_down)
        .globl C(subx_loop_down)
        .globl C(subfrom_loop_down)
        .globl C(dec_loop_down)
        .globl C(neg_loop_down)
        .globl C(shift1left_loop_down)
        .globl C(shiftleft_loop_down)
        .globl C(shiftleftcopy_loop_down)
        .globl C(shift1right_loop_up)
        .globl C(shiftright_loop_up)
        .globl C(shiftrightsigned_loop_up)
        .globl C(shiftrightcopy_loop_up)
        .globl C(mulusmall_loop_down)
        .globl C(mulu_loop_down)
        .globl C(muluadd_loop_down)
        .globl C(mulusub_loop_down)
        .globl C(divu_loop_up)
        .globl C(divucopy_loop_up)

#ifndef __GNUC__ /* mit GNU-C machen wir mulu32() als Macro, der inline multipliziert */

# extern struct { uint32 lo; uint32 hi; } mulu32_ (uint32 arg1, uint32 arg2);
# 2^32*hi+lo := arg1*arg2.
        .globl C(mulu32_)
C(mulu32_:)
        movl    4(%esp),%eax    # arg1
        mull    8(%esp)         # %edx|%eax := arg1 * arg2
        movl    %edx,C(mulu32_high) # %edx = hi abspeichern
        ret                     # %eax = lo als Ergebnis

#endif

#ifndef __GNUC__ /* mit GNU-C machen wir divu_6432_3232() als Macro, der inline multipliziert */

# extern struct { uint32 q; uint32 r; } divu_6432_3232_ (uint32 xhi, uint32 xlo, uint32 y);
# x = 2^32*xhi+xlo = q*y+r schreiben. Sei bekannt, da? 0 <= x < 2^32*y .
        .globl C(divu_6432_3232_)
C(divu_6432_3232_:)
        movl    4(%esp),%edx
        movl    8(%esp),%eax
        divl    12(%esp)       # x = %edx|%eax durch dividieren
        movl    %edx,C(divu_32_rest) # Rest %edx = r abspeichern
        ret                    # Quotient %eax = q als Ergebnis

#endif

# extern uintD* copy_loop_up (uintD* sourceptr, uintD* destptr, uintC count);
C(copy_loop_up:)
        movl    %edi,%edx       # %edi retten
        movl    %esi,%eax       # %esi retten
        movl    4(%esp),%esi    # %esi = sourceptr
        movl    8(%esp),%edi    # %edi = destptr
        movl    12(%esp),%ecx   # %ecx = count
        dir0start
        rep
          movsl                 # %ecx mal aufw?rts (%edi) := (%esi)
        dir0end
        movl    %eax,%esi       # %esi zur?ck
        movl    %edi,%eax       # %edi als Ergebnis
        movl    %edx,%edi       # %edi zur?ck
        ret

# extern uintD* copy_loop_down (uintD* sourceptr, uintD* destptr, uintC count);
C(copy_loop_down:)
        movl    %edi,%edx       # %edi retten
        movl    %esi,%eax       # %esi retten
        movl    4(%esp),%esi    # %esi = sourceptr
        movl    8(%esp),%edi    # %edi = destptr
        movl    12(%esp),%ecx   # %ecx = count
        leal    -4(%esi),%esi
        leal    -4(%edi),%edi
        dir1start
        rep
          movsl                 # %ecx mal abw?rts (%edi) := (%esi)
        dir1end
        movl    %eax,%esi       # %esi zur?ck
        leal    4(%edi),%eax    # %edi als Ergebnis
        movl    %edx,%edi       # %edi zur?ck
        ret

# extern uintD* fill_loop_up (uintD* destptr, uintC count, uintD filler);
C(fill_loop_up:)
        movl    %edi,%edx       # %edi retten
        movl    4(%esp),%edi    # %edi = destptr
        movl    8(%esp),%ecx    # %ecx = count
        movl    12(%esp),%eax   # %eax = filler
        dir0start
        rep
          stosl                 # %ecx mal aufw?rts (%edi) := %eax
        dir0end
        movl    %edi,%eax       # %edi als Ergebnis
        movl    %edx,%edi       # %edi zur?ck
        ret

# extern uintD* fill_loop_down (uintD* destptr, uintC count, uintD filler);
C(fill_loop_down:)
        movl    %edi,%edx       # %edi retten
        movl    4(%esp),%edi    # %edi = destptr
        movl    8(%esp),%ecx    # %ecx = count
        movl    12(%esp),%eax   # %eax = filler
        leal    -4(%edi),%edi
        dir1start
        rep
          stosl                 # %ecx mal abw?rts (%edi) := %eax
        dir1end
        leal    4(%edi),%eax    # %edi als Ergebnis
        movl    %edx,%edi       # %edi zur?ck
        ret

# extern uintD* clear_loop_up (uintD* destptr, uintC count);
C(clear_loop_up:)
        movl    %edi,%edx       # %edi retten
        movl    4(%esp),%edi    # %edi = destptr
        movl    8(%esp),%ecx    # %ecx = count
        xorl    %eax,%eax       # %eax = 0
        dir0start
        rep
          stosl                 # %ecx mal aufw?rts (%edi) := %eax
        dir0end
        movl    %edi,%eax       # %edi als Ergebnis
        movl    %edx,%edi       # %edi zur?ck
        ret

# extern uintD* clear_loop_down (uintD* destptr, uintC count);
C(clear_loop_down:)
        movl    %edi,%edx       # %edi retten
        movl    4(%esp),%edi    # %edi = destptr
        movl    8(%esp),%ecx    # %ecx = count
        leal    -4(%edi),%edi
        xorl    %eax,%eax       # %eax = 0
        dir1start
        rep
          stosl                 # %ecx mal abw?rts (%edi) := %eax
        dir1end
        leal    4(%edi),%eax    # %edi als Ergebnis
        movl    %edx,%edi       # %edi zur?ck
        ret

# extern void or_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(or_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   olu2            # %ecx = 0 ?
olu1:     movl    (%edx,%esi),%eax # *yptr
          orl     %eax,(%edx)      # *xptr |= ...
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     olu1
olu2:   popl    %esi            # %esi zur?ck
        ret

# extern void xor_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(xor_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   xlu2            # %ecx = 0 ?
xlu1:     movl    (%edx,%esi),%eax # *yptr
          xorl    %eax,(%edx)      # *xptr ^= ...
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     xlu1
xlu2:   popl    %esi            # %esi zur?ck
        ret

# extern void and_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(and_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   alu2            # %ecx = 0 ?
alu1:     movl    (%edx,%esi),%eax # *yptr
          andl    %eax,(%edx)      # *xptr &= ...
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     alu1
alu2:   popl    %esi            # %esi zur?ck
        ret

# extern void eqv_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(eqv_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   elu2            # %ecx = 0 ?
elu1:     movl    (%edx),%eax      # *xptr
          xorl    (%edx,%esi),%eax # ^ *yptr
          notl    %eax             # ~(...)
          movl    %eax,(%edx)      # =: *xptr
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     elu1
elu2:   popl    %esi            # %esi zur?ck
        ret

# extern void nand_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(nand_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   nalu2           # %ecx = 0 ?
nalu1:    movl    (%edx),%eax      # *xptr
          andl    (%edx,%esi),%eax # & *yptr
          notl    %eax             # ~(...)
          movl    %eax,(%edx)      # =: *xptr
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     nalu1
nalu2:  popl    %esi            # %esi zur?ck
        ret

# extern void nor_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(nor_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   nolu2           # %ecx = 0 ?
nolu1:    movl    (%edx),%eax      # *xptr
          orl     (%edx,%esi),%eax # | *yptr
          notl    %eax             # ~(...)
          movl    %eax,(%edx)      # =: *xptr
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     nolu1
nolu2:  popl    %esi            # %esi zur?ck
        ret

# extern void andc2_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(andc2_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   aclu2           # %ecx = 0 ?
aclu1:    movl    (%edx,%esi),%eax # *yptr
          notl    %eax             # ~ *yptr
          andl    %eax,(%edx)      # *xptr &= ...
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     aclu1
aclu2:  popl    %esi            # %esi zur?ck
        ret

# extern void orc2_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(orc2_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edx,%esi
        jecxz   oclu2           # %ecx = 0 ?
oclu1:    movl    (%edx,%esi),%eax # *yptr
          notl    %eax             # ~ *yptr
          orl     %eax,(%edx)      # *xptr |= ...
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     oclu1
oclu2:  popl    %esi            # %esi zur?ck
        ret

# extern void not_loop_up (uintD* xptr, uintC count);
C(not_loop_up:)
        movl    4(%esp),%edx    # %edx = xptr
        movl    8(%esp),%ecx    # %ecx = count
        jecxz   nlu2            # %ecx = 0 ?
nlu1:     notl    (%edx)           # ~= *xptr
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     nlu1
nlu2:   ret

# extern boolean and_test_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(and_test_loop_up:)
        pushl   %esi            # %esi retten
        movl    8(%esp),%edx    # %edx = xptr
        movl    12(%esp),%esi   # %esi = yptr
        movl    16(%esp),%ecx   # %ecx = count
        jecxz   atlu2           # %ecx = 0 ?
        subl    %edx,%esi
atlu1:    movl    (%edx,%esi),%eax # *yptr
          andl    (%edx),%eax      # *xptr & ...
          jnz     atlu3
          leal    4(%edx),%edx     # xptr++, yptr++
          decl    %ecx
          jnz     atlu1
atlu2:  xorl    %eax,%eax       # Ergebnis 0
atlu3:  popl    %esi            # %esi zur?ck
        ret

# extern boolean test_loop_up (uintD* ptr, uintC count);
C(test_loop_up:)
        movl    %edi,%edx       # %edi retten
        movl    4(%esp),%edi    # %edi = ptr
        movl    8(%esp),%ecx    # %ecx = count
        xorl    %eax,%eax       # %eax = 0
        dir0start
        repz                    # Falls %ecx > 0:
          scasl                 # %ecx mal aufw?rts (%edi) testen
                                # und weiterschleifen, falls Z, d.h. (%edi)=0.
        dir0end
        # Noch ist %eax = 0.
        jz      tlu1            # alles =0 -> Ergebnis 0
        incl    %eax            # Ergebnis 1
tlu1:   movl    %edx,%edi       # %edi zur?ck
        ret

# extern signean compare_loop_up (uintD* xptr, uintD* yptr, uintC count);
C(compare_loop_up:)
        movl    %esi,%edx       # %esi retten
        movl    %edi,%eax       # %edi retten
        movl    4(%esp),%esi    # %esi = xptr
        movl    8(%esp),%edi    # %edi = yptr
        movl    12(%esp),%ecx   # %ecx = count
        dir0start
        repz                    # Falls %ecx > 0:
          cmpsl                 # %ecx mal aufw?rts (%edi) und (%esi) vergleichen
                                # und weiterschleifen, falls Z, d.h. (%edi)=(%esi).
        dir0end
        # Flags -> Ergebnis:
        # Z,NC -> bis zum Schlu? (%esi)-(%edi) = 0 -> x=y -> Ergebnis 0
        # NZ,C -> schlie?lich (%esi)-(%edi) < 0 -> x<y -> Ergebnis -1
        # NZ,NC -> schlie?lich (%esi)-(%edi) > 0 -> x>y -> Ergebnis +1
        movl    %eax,%edi       # %edi zur?ck
        movl    %edx,%esi       # %esi zur?ck
        jbe     cmlu1           # "be" = Z oder C
        movl    $1,%eax         # Ergebnis +1
        ret
cmlu1:  sbbl    %eax,%eax       # Ergebnis -1 (falls C) oder 0 (falls NC)
        ret

# extern uintD add_loop_down (uintD* sourceptr1, uintD* sourceptr2, uintD* destptr, uintC count);
C(add_loop_down:)
        pushl   %esi            # %esi retten
        pushl   %edi            # %edi retten
        movl    12(%esp),%edx   # %edx = sourceptr1
        movl    16(%esp),%esi   # %esi = sourceptr2
        movl    20(%esp),%edi   # %edi = destptr
        movl    24(%esp),%ecx   # %ecx = count
        subl    %edi,%edx
        subl    %edi,%esi
        orl     %ecx,%ecx       # %ecx = 0 ?, Carry l?schen
        jz      ald2
ald1:     leal    -4(%edi),%edi   # sourceptr1--, sourceptr2--, destptr--
          movl    (%edx,%edi),%eax # *sourceptr1
          adcl    (%esi,%edi),%eax # + *sourceptr2 + carry
          movl    %eax,(%edi)     # =: *destptr, neuen Carry behalten
          decl    %ecx
          jnz     ald1
ald2:   sbbl    %eax,%eax      # Ergebnis := - Carry
        popl    %edi           # %edi zur?ck
        popl    %esi           # %esi zur?ck
        ret

# extern uintD addto_loop_down (uintD* sourceptr, uintD* destptr, uintC count);
C(addto_loop_down:)
        pushl   %edi            # %edi retten
        movl    8(%esp),%edx    # %edx = sourceptr
        movl    12(%esp),%edi   # %edi = destptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edi,%edx
        orl     %ecx,%ecx       # %ecx = 0 ?, Carry l?schen
        jz      atld2
atld1:    leal    -4(%edi),%edi   # sourceptr--, destptr--
          movl    (%edx,%edi),%eax # *sourceptr
          adcl    %eax,(%edi)     # + *destptr + carry =: *destptr, neuer Carry
          decl    %ecx
          jnz     atld1
atld2:  sbbl    %eax,%eax       # Ergebnis := - Carry
        popl    %edi            # %edi zur?ck
        ret

# extern uintD inc_loop_down (uintD* ptr, uintC count);
C(inc_loop_down:)
        movl    4(%esp),%edx    # %edx = ptr
        movl    8(%esp),%ecx    # %ecx = count
        jecxz   ild2            # %ecx = 0 ?
ild1:     leal    -4(%edx),%edx
          addl    $1,(%edx)       # (*ptr)++
          jnc     ild3            # kein Carry -> fertig
          decl    %ecx
          jnz     ild1
ild2:   movl    $1,%eax         # Ergebnis := 1
        ret
ild3:   xorl    %eax,%eax       # Ergebnis := 0
        ret

# extern uintD sub_loop_down (uintD* sourceptr1, uintD* sourceptr2, uintD* destptr, uintC count);
C(sub_loop_down:)
        pushl   %esi            # %esi retten
        pushl   %edi            # %edi retten
        movl    12(%esp),%edx   # %edx = sourceptr1
        movl    16(%esp),%esi   # %esi = sourceptr2
        movl    20(%esp),%edi   # %edi = destptr
        movl    24(%esp),%ecx   # %ecx = count
        subl    %edi,%edx
        subl    %edi,%esi
        orl     %ecx,%ecx       # %ecx = 0 ?, Carry l?schen
        jz      sld2
sld1:     leal    -4(%edi),%edi   # sourceptr1--, sourceptr2--, destptr--
          movl    (%edx,%edi),%eax # *sourceptr1
          sbbl    (%esi,%edi),%eax # - *sourceptr2 - carry
          movl    %eax,(%edi)     # =: *destptr, neuen Carry behalten
          decl    %ecx
          jnz     sld1
sld2:   sbbl    %eax,%eax      # Ergebnis := - Carry
        popl    %edi           # %edi zur?ck
        popl    %esi           # %esi zur?ck
        ret

# extern uintD subx_loop_down (uintD* sourceptr1, uintD* sourceptr2, uintD* destptr, uintC count, uintD carry);
C(subx_loop_down:)
        pushl   %esi            # %esi retten
        pushl   %edi            # %edi retten
        movl    12(%esp),%edx   # %edx = sourceptr1
        movl    16(%esp),%esi   # %esi = sourceptr2
        movl    20(%esp),%edi   # %edi = destptr
        movl    24(%esp),%ecx   # %ecx = count
        jecxz   sxld2           # %ecx = 0 ?
        subl    %edi,%edx
        subl    %edi,%esi
        movl    28(%esp),%eax   # carry, 0 oder -1
        addl    %eax,%eax       # Bit 31 davon in den Carry
sxld1:    leal    -4(%edi),%edi   # sourceptr1--, sourceptr2--, destptr--
          movl    (%edx,%edi),%eax # *sourceptr1
          sbbl    (%esi,%edi),%eax # - *sourceptr2 - carry
          movl    %eax,(%edi)     # =: *destptr, neuen Carry behalten
          decl    %ecx
          jnz     sxld1
        sbbl    %eax,%eax      # Ergebnis := - Carry
        popl    %edi           # %edi zur?ck
        popl    %esi           # %esi zur?ck
        ret
sxld2:  movl    28(%esp),%eax  # Ergebnis := carry
        popl    %edi           # %edi zur?ck
        popl    %esi           # %esi zur?ck
        ret

# extern uintD subfrom_loop_down (uintD* sourceptr, uintD* destptr, uintC count);
C(subfrom_loop_down:)
        pushl   %edi            # %edi retten
        movl    8(%esp),%edx    # %edx = sourceptr
        movl    12(%esp),%edi   # %edi = destptr
        movl    16(%esp),%ecx   # %ecx = count
        subl    %edi,%edx
        orl     %ecx,%ecx       # %ecx = 0 ?, Carry l?schen
        jz      sfld2
sfld1:    leal    -4(%edi),%edi   # sourceptr--, destptr--
          movl    (%edx,%edi),%eax # *sourceptr
          sbbl    %eax,(%edi)     # *destptr - *sourceptr - carry =: *destptr, neuer Carry
          decl    %ecx
          jnz     sfld1
sfld2:  sbbl    %eax,%eax       # Ergebnis := - Carry
        popl    %edi            # %edi zur?ck
        ret

# extern uintD dec_loop_down (uintD* ptr, uintC count);
C(dec_loop_down:)
        movl    4(%esp),%edx    # %edx = ptr
        movl    8(%esp),%ecx    # %ecx = count
        jecxz   dld2            # %ecx = 0 ?
dld1:     leal    -4(%edx),%edx
          subl    $1,(%edx)       # (*ptr)--
          jnc     dld3            # kein Carry -> fertig
          decl    %ecx
          jnz     dld1
dld2:   movl    $-1,%eax        # Ergebnis := -1
        ret
dld3:   xorl    %eax,%eax       # Ergebnis := 0
        ret

# extern uintD neg_loop_down (uintD* ptr, uintC count);
C(neg_loop_down:)
        movl    4(%esp),%edx    # %edx = ptr
        movl    8(%esp),%ecx    # %ecx = count
        # erstes Digit /=0 suchen:
        jecxz   nld2            # %ecx = 0 ?
nld1:     leal    -4(%edx),%edx
          negl    (%edx)
          jnz     nld3
          decl    %ecx
          jnz     nld1
nld2:   xorl    %eax,%eax       # Ergebnis := 0
        ret
nld3:   # erstes Digit /=0 gefunden, ab jetzt gibt's Carrys
        # alle anderen Digits invertieren:
        decl    %ecx
        jz      nld5
nld4:     leal    -4(%edx),%edx
          notl    (%edx)
          decl    %ecx
          jnz     nld4
nld5:   movl    $-1,%eax        # Ergebnis := -1
        ret

# extern uintD shift1left_loop_down (uintD* ptr, uintC count);
C(shift1left_loop_down:)
        movl    4(%esp),%edx    # %edx = ptr
        movl    8(%esp),%ecx    # %ecx = count
        orl     %ecx,%ecx       # %ecx = 0 ?, Carry l?schen
        jz      s1lld2
s1lld1:   leal    -4(%edx),%edx   # ptr--
          rcll    $1,(%edx)       # *ptr und Carry um 1 Bit links rotieren
          decl    %ecx
          jnz     s1lld1
s1lld2: sbbl    %eax,%eax       # Ergebnis := - Carry
        ret

# extern uintD shiftleft_loop_down (uintD* ptr, uintC count, uintC i, uintD carry);
C(shiftleft_loop_down:)
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    12(%esp),%edi   # %edi = ptr
        movl    16(%esp),%edx   # %edx = count
        movb    20(%esp),%cl    # %cl = i
        orl     %edx,%edx       # count = 0 ?
        jz      slld4
        # erstes Digit shiften:
        leal    -4(%edi),%edi
        movl    (%edi),%eax     # Digit in %eax halten
        movl    %eax,%ebx       # und in %ebx rechnen:
        shll    %cl,%ebx        # um i Bits links shiften
        orl     24(%esp),%ebx   # und die unteren i Bits eintragen
        movl    %ebx,(%edi)     # und wieder ablegen
        # Letztes Digit in %eax.
        decl    %edx
        jz      slld2
slld1:    # weiteres Digit shiften:
          leal    -4(%edi),%edi
          movl    (%edi),%ebx
          shldl   shcl %eax,(%edi) # (%edi) um %cl=i Bits links shiften, %eax von rechts reinshiften
          # Letztes Digit in %ebx.
          decl    %edx
          jz      slld3
          # weiteres Digit shiften:
          leal    -4(%edi),%edi
          movl    (%edi),%eax
          shldl   shcl %ebx,(%edi) # (%edi) um %cl=i Bits links shiften, %ebx von rechts reinshiften
          # Letztes Digit in %eax.
          decl    %edx
          jnz     slld1
slld2:  movl    %eax,%ebx
slld3:  xorl    %eax,%eax       # %eax := 0
        shldl   shcl %ebx,%eax  # %eax := h?chste %cl=i Bits von %ebx
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        ret
slld4:  movl    24(%esp),%eax   # %eax := carry
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        ret

# extern uintD shiftleftcopy_loop_down (uintD* sourceptr, uintD* destptr, uintC count, uintC i);
C(shiftleftcopy_loop_down:)
        pushl   %esi            # %esi retten
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    16(%esp),%esi   # %esi = sourceptr
        movl    20(%esp),%edi   # %edi = destptr
        movl    24(%esp),%edx   # count
        movb    28(%esp),%cl    # i
        orl     %edx,%edx       # count = 0 ?
        jz      slcld4
        subl    %edi,%esi
        # erstes Digit shiften:
        leal    -4(%edi),%edi   # sourceptr--, destptr--
        movl    (%edi,%esi),%ebx # *sourceptr in %ebx halten
        movl    %ebx,%eax       # und in %eax rechnen:
        shll    %cl,%eax        # um i Bits links shiften, rechts Nullen rein
        movl    %eax,(%edi)     # und als *destptr ablegen
        # Letztes Digit in %ebx.
        negb    %cl             # 32-i
        decl    %edx
        jz      slcld2
slcld1:   # weiteres Digit shiften:
          leal    -4(%edi),%edi   # sourceptr--, destptr--
          movl    (%edi,%esi),%eax # n?chstes Digit nach %eax
          shrdl   shcl %eax,%ebx  # %ebx um %cl=32-i Bits rechts shiften, %eax von links reinshiften
          movl    %ebx,(%edi)     # %ebx als *destptr ablegen
          # Letztes Digit in %eax.
          decl    %edx
          jz      slcld3
          # weiteres Digit shiften:
          leal    -4(%edi),%edi   # sourceptr--, destptr--
          movl    (%edi,%esi),%ebx # n?chstes Digit nach %ebx
          shrdl   shcl %ebx,%eax  # %eax um %cl=32-i Bits rechts shiften, %ebx von links reinshiften
          movl    %eax,(%edi)     # %eax als *destptr ablegen
          # Letztes Digit in %ebx.
          decl    %edx
          jnz     slcld1
slcld2: movl    %ebx,%eax
slcld3: shrl    %cl,%eax        # %eax um 32-i Bits nach rechts shiften
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        popl    %esi            # %esi zur?ck
        ret
slcld4: xorl    %eax,%eax       # %eax := 0
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        popl    %esi            # %esi zur?ck
        ret

# extern uintD shift1right_loop_up (uintD* ptr, uintC count, uintC carry);
C(shift1right_loop_up:)
        movl    4(%esp),%edx    # %edx = ptr
        movl    8(%esp),%ecx    # %ecx = count
        movl    12(%esp),%eax   # %eax = carry (0 oder -1)
        jecxz   s1rld3          # %ecx = 0 ?
        addl    %eax,%eax       # Carry := Bit 31 von carry
s1rld1:   rcrl    $1,(%edx)       # *ptr und Carry um 1 Bit rechts rotieren
          leal    4(%edx),%edx    # ptr++
          decl    %ecx
          jnz     s1rld1
s1rld2: sbbl    %eax,%eax       # Ergebnis := - Carry
s1rld3: ret

# extern uintD shiftright_loop_up (uintD* ptr, uintC count, uintC i);
C(shiftright_loop_up:)
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    12(%esp),%edi   # %edi = ptr
        movl    16(%esp),%edx   # %edx = count
        movb    20(%esp),%cl    # %cl = i
        orl     %edx,%edx       # count = 0 ?
        jz      srlu4
        # erstes Digit shiften:
        movl    (%edi),%eax     # Digit in %eax halten
        movl    %eax,%ebx       # und in %ebx rechnen:
        shrl    %cl,%ebx        # um i Bits rechts shiften
        movl    %ebx,(%edi)     # und wieder ablegen
        # Letztes Digit in %eax.
        decl    %edx
        jz      srlu2
srlu1:    # weiteres Digit shiften:
          leal    4(%edi),%edi
          movl    (%edi),%ebx
          shrdl   shcl %eax,(%edi) # (%edi) um %cl=i Bits rechts shiften, %eax von links reinshiften
          # Letztes Digit in %ebx.
          decl    %edx
          jz      srlu3
          # weiteres Digit shiften:
          leal    4(%edi),%edi
          movl    (%edi),%eax
          shrdl   shcl %ebx,(%edi) # (%edi) um %cl=i Bits rechts shiften, %ebx von links reinshiften
          # Letztes Digit in %eax.
          decl    %edx
          jnz     srlu1
srlu2:  movl    %eax,%ebx
srlu3:  xorl    %eax,%eax       # %eax := 0
        shrdl   shcl %ebx,%eax  # %eax := niedrigste %cl=i Bits von %ebx, als Bits 31..32-i
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        ret
srlu4:  xorl    %eax,%eax       # %eax := 0
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        ret

# extern uintD shiftrightsigned_loop_up (uintD* ptr, uintC count, uintC i);
C(shiftrightsigned_loop_up:)
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    12(%esp),%edi   # %edi = ptr
        movl    16(%esp),%edx   # %edx = count
        movb    20(%esp),%cl    # %cl = i
        # erstes Digit shiften:
        movl    (%edi),%eax     # Digit in %eax halten
        movl    %eax,%ebx       # und in %ebx rechnen:
        sarl    %cl,%ebx        # um i Bits rechts shiften, Vorzeichen vervielfachen
        movl    %ebx,(%edi)     # und wieder ablegen
        # Letztes Digit in %eax.
        decl    %edx
        jz      srslu2
srslu1:   # weiteres Digit shiften:
          leal    4(%edi),%edi
          movl    (%edi),%ebx
          shrdl   shcl %eax,(%edi) # (%edi) um %cl=i Bits rechts shiften, %eax von links reinshiften
          # Letztes Digit in %ebx.
          decl    %edx
          jz      srslu3
          # weiteres Digit shiften:
          leal    4(%edi),%edi
          movl    (%edi),%eax
          shrdl   shcl %ebx,(%edi) # (%edi) um %cl=i Bits rechts shiften, %ebx von links reinshiften
          # Letztes Digit in %eax.
          decl    %edx
          jnz     srslu1
srslu2: movl    %eax,%ebx
srslu3: xorl    %eax,%eax       # %eax := 0
        shrdl   shcl %ebx,%eax  # %eax := niedrigste %cl=i Bits von %ebx, als Bits 31..32-i
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        ret

# extern uintD shiftrightcopy_loop_up (uintD* sourceptr, uintD* destptr, uintC count, uintC i, uintD carry);
C(shiftrightcopy_loop_up:)
        pushl   %esi            # %esi retten
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    16(%esp),%esi   # %esi = sourceptr
        movl    20(%esp),%edi   # %edi = destptr
        movl    24(%esp),%edx   # count
        movb    28(%esp),%cl    # i
        negb    %cl             # 32-i
        movl    32(%esp),%eax   # %eax = carry
        orl     %edx,%edx       # count = 0 ?
        jz      srcld3
        subl    %edi,%esi
        # erstes Digit shiften:
        movl    (%edi,%esi),%ebx # *sourceptr in %ebx halten
        shldl   shcl %ebx,%eax  # carry um %cl=32-i Bits links shiften, dabei *sourceptr rein
        movl    %eax,(%edi)     # und als *destptr ablegen
        # Letztes Digit in %ebx.
        decl    %edx
        jz      srcld2
srcld1:   # weiteres Digit shiften:
          leal    4(%edi),%edi    # sourceptr++, destptr++
          movl    (%edi,%esi),%eax # n?chstes Digit nach %eax
          shldl   shcl %eax,%ebx  # %ebx um %cl=32-i Bits links shiften, %eax von rechts reinshiften
          movl    %ebx,(%edi)     # %ebx als *destptr ablegen
          # Letztes Digit in %eax.
          decl    %edx
          jz      srcld3
          # weiteres Digit shiften:
          leal    4(%edi),%edi    # sourceptr++, destptr++
          movl    (%edi,%esi),%ebx # n?chstes Digit nach %ebx
          shldl   shcl %ebx,%eax  # %eax um %cl=32-i Bits links shiften, %ebx von rechts reinshiften
          movl    %eax,(%edi)     # %eax als *destptr ablegen
          # Letztes Digit in %ebx.
          decl    %edx
          jnz     srcld1
srcld2: movl    %ebx,%eax
srcld3: shll    %cl,%eax        # %eax um 32-i Bits nach links shiften
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        popl    %esi            # %esi zur?ck
        ret

# extern uintD mulusmall_loop_down (uintD digit, uintD* ptr, uintC len, uintD newdigit);
C(mulusmall_loop_down:)
        pushl   %ebp            # %ebp retten
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    16(%esp),%ebx   # %ebx = digit
        movl    20(%esp),%edi   # %edi = ptr
        movl    24(%esp),%ecx   # %ecx = len
        movl    28(%esp),%ebp   # %ebp = carry := newdigit
        movl    %ecx,%eax
        negl    %eax            # %eax = -len
        jz      msld2
        leal    -4(%edi,%eax,4),%edi # %edi = &ptr[-1-len]
msld1:    movl    (%edi,%ecx,4),%eax # *ptr
          mull    %ebx               # %edx|%eax := digit * *ptr
          addl    %ebp,%eax          # carry und Low-Teil des Produktes addieren
          movl    $0,%ebp
          adcl    %edx,%ebp          # ?bertrag zum High-Teil %edx dazu, gibt neuen carry
          movl    %eax,(%edi,%ecx,4) # Low-Teil als *ptr ablegen
          decl    %ecx               # count--, ptr--
          jnz     msld1
msld2:  movl    %ebp,%eax       # Ergebnis := letzter ?bertrag
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        popl    %ebp            # %ebp zur?ck
        ret

# extern void mulu_loop_down (uintD digit, uintD* sourceptr, uintD* destptr, uintC len);
C(mulu_loop_down:)
        pushl   %ebp            # %ebp retten
        pushl   %edi            # %edi retten
        pushl   %esi            # %esi retten
        pushl   %ebx            # %ebx retten
        movl    20(%esp),%ebx   # %ebx = digit
        movl    24(%esp),%esi   # %esi = sourceptr
        movl    28(%esp),%edi   # %edi = destptr
        movl    32(%esp),%ecx   # %ecx = len
        movl    %ecx,%eax
        notl    %eax            # %eax = -1-len
        leal    (%esi,%eax,4),%esi # %esi = &sourceptr[-1-len]
        leal    (%edi,%eax,4),%edi # %edi = &destptr[-1-len]
        xorl    %ebp,%ebp       # %epb = carry := 0
muld1:    movl    (%esi,%ecx,4),%eax # *sourceptr
          mull    %ebx               # %edx|%eax := digit * *sourceptr
          addl    %ebp,%eax          # carry und Low-Teil des Produktes addieren
          movl    $0,%ebp
          adcl    %edx,%ebp          # ?bertrag zum High-Teil %edx dazu, gibt neuen carry
          movl    %eax,(%edi,%ecx,4) # Low-Teil als *destptr ablegen
          decl    %ecx               # count--, sourceptr--, destptr--
          jnz     muld1
        movl    %ebp,(%edi)     # letzten ?bertrag ablegen
        popl    %ebx            # %ebx zur?ck
        popl    %esi            # %esi zur?ck
        popl    %edi            # %edi zur?ck
        popl    %ebp            # %ebp zur?ck
        ret

# extern uintD muluadd_loop_down (uintD digit, uintD* sourceptr, uintD* destptr, uintC len);
C(muluadd_loop_down:)
        pushl   %ebp            # %ebp retten
        pushl   %edi            # %edi retten
        pushl   %esi            # %esi retten
        pushl   %ebx            # %ebx retten
        movl    20(%esp),%ebx   # %ebx = digit
        movl    24(%esp),%esi   # %esi = sourceptr
        movl    28(%esp),%edi   # %edi = destptr
        movl    32(%esp),%ecx   # %ecx = len
        movl    %ecx,%eax
        notl    %eax            # %eax = -1-len
        leal    (%esi,%eax,4),%esi # %esi = &sourceptr[-1-len]
        leal    (%edi,%eax,4),%edi # %edi = &destptr[-1-len]
        xorl    %ebp,%ebp       # %epb = carry := 0
muald1:   movl    (%esi,%ecx,4),%eax # *sourceptr
          mull    %ebx               # %edx|%eax := digit * *sourceptr
          addl    %ebp,%eax          # carry und Low-Teil des Produktes addieren
          movl    $0,%ebp
          adcl    %ebp,%edx          # ?bertrag zum High-Teil %edx dazu
          addl    %eax,(%edi,%ecx,4) # Low-Teil zu *destptr addieren
          adcl    %edx,%ebp          # zweiten ?bertrag zu %edx addieren, gibt neuen carry
          decl    %ecx               # count--, sourceptr--, destptr--
          jnz     muald1
        movl    %ebp,%eax       # Ergebnis := letzter ?bertrag
        popl    %ebx            # %ebx zur?ck
        popl    %esi            # %esi zur?ck
        popl    %edi            # %edi zur?ck
        popl    %ebp            # %ebp zur?ck
        ret

# extern uintD mulusub_loop_down (uintD digit, uintD* sourceptr, uintD* destptr, uintC len);
C(mulusub_loop_down:)
        pushl   %ebp            # %ebp retten
        pushl   %edi            # %edi retten
        pushl   %esi            # %esi retten
        pushl   %ebx            # %ebx retten
        movl    20(%esp),%ebx   # %ebx = digit
        movl    24(%esp),%esi   # %esi = sourceptr
        movl    28(%esp),%edi   # %edi = destptr
        movl    32(%esp),%ecx   # %ecx = len
        movl    %ecx,%eax
        notl    %eax            # %eax = -1-len
        leal    (%esi,%eax,4),%esi # %esi = &sourceptr[-1-len]
        leal    (%edi,%eax,4),%edi # %edi = &destptr[-1-len]
        xorl    %ebp,%ebp       # %epb = carry := 0
musld1:   movl    (%esi,%ecx,4),%eax # *sourceptr
          mull    %ebx               # %edx|%eax := digit * *sourceptr
          addl    %ebp,%eax          # carry und Low-Teil des Produktes addieren
          movl    $0,%ebp
          adcl    %ebp,%edx          # ?bertrag zum High-Teil %edx dazu
          subl    %eax,(%edi,%ecx,4) # Low-Teil von *destptr subtrahieren
          adcl    %edx,%ebp          # zweiten ?bertrag zu %edx addieren, gibt neuen carry
          decl    %ecx               # count--, sourceptr--, destptr--
          jnz     musld1
        movl    %ebp,%eax       # Ergebnis := letzter ?bertrag
        popl    %ebx            # %ebx zur?ck
        popl    %esi            # %esi zur?ck
        popl    %edi            # %edi zur?ck
        popl    %ebp            # %ebp zur?ck
        ret

# extern uintD divu_loop_up (uintD digit, uintD* ptr, uintC len);
C(divu_loop_up:)
        pushl   %edi            # %edi retten
        pushl   %ebx            # %ebx retten
        movl    12(%esp),%ebx   # %ebx = digit
        movl    16(%esp),%edi   # %edi = ptr
        movl    20(%esp),%ecx   # %ecx = len
        xorl    %edx,%edx       # %edx = Rest := 0
        jecxz   dlu2            # %ecx = 0 ?
dlu1:     movl    (%edi),%eax     # n?chstes Digit *ptr
          divl    %ebx            # Division von %edx|%eax durch %ebx
          movl    %eax,(%edi)     # Quotient %eax ablegen, Rest in %edx behalten
          leal    4(%edi),%edi    # ptr++
          decl    %ecx
          jnz     dlu1
dlu2:   movl    %edx,%eax       # Ergebnis := letzter Rest
        popl    %ebx            # %ebx zur?ck
        popl    %edi            # %edi zur?ck
        ret

# extern uintD divucopy_loop_up (uintD digit, uintD* sourceptr, uintD* destptr, uintC len);
C(divucopy_loop_up:)
        pushl   %edi            # %edi retten
        pushl   %esi            # %esi retten
        pushl   %ebx            # %ebx retten
        movl    16(%esp),%ebx   # %ebx = digit
        movl    20(%esp),%esi   # %esi = sourceptr
        movl    24(%esp),%edi   # %edi = destptr
        movl    28(%esp),%ecx   # %ecx = len
        xorl    %edx,%edx       # %edx = Rest := 0
        jecxz   dclu2           # %ecx = 0 ?
        subl    %edi,%esi
dclu1:    movl    (%esi,%edi),%eax # n?chstes Digit *ptr
          divl    %ebx            # Division von %edx|%eax durch %ebx
          movl    %eax,(%edi)     # Quotient %eax ablegen, Rest in %edx behalten
          leal    4(%edi),%edi    # sourceptr++, destptr++
          decl    %ecx
          jnz     dclu1
dclu2:  movl    %edx,%eax       # Ergebnis := letzter Rest
        popl    %ebx            # %ebx zur?ck
        popl    %esi            # %esi zur?ck
        popl    %edi            # %edi zur?ck
        ret

#endif

