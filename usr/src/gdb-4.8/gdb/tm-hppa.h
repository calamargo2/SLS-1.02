/* Parameters for execution on a Hewlett-Packard PA-RISC machine, running
   HPUX or BSD.
   Copyright 1986, 1987, 1989, 1990, 1991, 1992 Free Software Foundation, Inc. 

   Contributed by the Center for Software Science at the
   University of Utah (pa-gdb-bugs@cs.utah.edu).

This file is part of GDB.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */

/* Target system byte order. */

#define	TARGET_BYTE_ORDER	BIG_ENDIAN

/* Get at various relevent fields of an instruction word. */

#define MASK_5 0x1f
#define MASK_11 0x7ff
#define MASK_14 0x3fff
#define MASK_21 0x1fffff

/* This macro gets bit fields using HP's numbering (MSB = 0) */

#define GET_FIELD(X, FROM, TO) \
  ((X) >> 31 - (TO) & (1 << ((TO) - (FROM) + 1)) - 1)

/* Watch out for NaNs */

#define IEEE_FLOAT

/* When passing a structure to a function, GCC passes the address
   in a register, not the structure itself. */

#define REG_STRUCT_HAS_ADDR(gcc_p) (1)

/* Groan */

#define	ARGS_GROW_DOWN

/* Define this if the C compiler puts an underscore at the front
   of external names before giving them to the linker.  */

/* #define NAMES_HAVE_UNDERSCORE */

/* Offset from address of function to start of its code.
   Zero on most machines.  */

#define FUNCTION_START_OFFSET 0
     
/* Advance PC across any function entry prologue instructions
   to reach some "real" code.  */

/* skip (stw rp, -20(0,sp)); copy 4,1; copy sp, 4; stwm 1,framesize(sp) 
   for gcc, or (stw rp, -20(0,sp); stwm 1, framesize(sp) for hcc */

#define SKIP_PROLOGUE(pc) pc = skip_prologue (pc)

/* If PC is in some function-call trampoline code, return the PC
   where the function itself actually starts.  If not, return NULL.  */

#define	SKIP_TRAMPOLINE_CODE(pc) skip_trampoline_code (pc, NULL)

/* Return non-zero if we are in some sort of a trampoline. */

#define IN_SOLIB_TRAMPOLINE(pc, name) skip_trampoline_code (pc, name)

/* Immediately after a function call, return the saved pc.
   Can't go through the frames for this because on some machines
   the new frame is not set up until the new function executes
   some instructions.  */

#define SAVED_PC_AFTER_CALL(frame) (read_register (RP_REGNUM) & ~3)

/* Address of end of stack space. Who knows.  */

#define STACK_END_ADDR 0x80000000

/* Stack grows upward */

#define INNER_THAN >


/* Sequence of bytes for breakpoint instruction.  */

/*#define BREAKPOINT {0x00, 0x00, 0x00, 0x00}*/
#ifdef	KERNELDEBUG	/* XXX */
#define BREAKPOINT {0x00, 0x00, 0xa0, 0x00}
#else
#define BREAKPOINT {0x00, 0x01, 0x00, 0x04}
#endif

/* Amount PC must be decremented by after a breakpoint.
   This is often the number of bytes in BREAKPOINT
   but not always.

   Not on the PA-RISC */

#define DECR_PC_AFTER_BREAK 0

/* return instruction is bv r0(rp) */

#define ABOUT_TO_RETURN(pc) (read_memory_integer (pc, 4) == 0xE840C000)

/* Return 1 if P points to an invalid floating point value.  */

#define INVALID_FLOAT(p, len) 0   /* Just a first guess; not checked */

/* Largest integer type */
#define LONGEST long

/* Name of the builtin type for the LONGEST type above. */
#define BUILTIN_TYPE_LONGEST builtin_type_long

/* Say how long (ordinary) registers are.  */

#define REGISTER_TYPE long

/* Number of machine registers */

#define NUM_REGS 100

/* Initializer for an array of names of registers.
   There should be NUM_REGS strings in this initializer.  */

#define REGISTER_NAMES	\
 {"flags", "r1", "rp", "r3", "r4", "r5", "r6", "r7", "r8", "r9",	\
  "r10", "r11", "r12", "r13", "r14", "r15", "r16", "r17", "r18", "r19",	\
  "r20", "r21", "r22", "arg3", "arg2", "arg1", "arg0", "dp", "ret0", "ret1", \
  "sp", "r31", "sar", "pcoqh", "pcsqh", "pcoqt", "pcsqt", \
  "eiem", "iir", "isr", "ior", "ipsw", "goto", "sr4", "sr0", "sr1", "sr2", \
  "sr3", "sr5", "sr6", "sr7", "cr0", "cr8", "cr9", "ccr", "cr12", "cr13", \
  "cr24", "cr25", "cr26", "mpsfu_high", "mpsfu_low", "mpsfu_ovflo", "pad", \
  "fpsr", "fpe1", "fpe2", "fpe3", "fpe4", "fpe5", "fpe6", "fpe7", \
  "fp4", "fp5", "fp6", "fp7", "fp8", \
  "fp9", "fp10", "fp11", "fp12", "fp13", "fp14", "fp15", \
  "fp16", "fp17", "fp18", "fp19", "fp20", "fp21", "fp22", "fp23", \
  "fp24", "fp25", "fp26", "fp27", "fp28", "fp29", "fp30", "fp31"}

/* Register numbers of various important registers.
   Note that some of these values are "real" register numbers,
   and correspond to the general registers of the machine,
   and some are "phony" register numbers which are too large
   to be actual register numbers as far as the user is concerned
   but do serve to get the desired values when passed to read_register.  */

#define FLAGS_REGNUM 0		/* Various status flags */
#define RP_REGNUM 2		/* return pointer */
#define FP_REGNUM 4		/* Contains address of executing stack */
				/* frame */
#define SP_REGNUM 30		/* Contains address of top of stack */
#define SAR_REGNUM 32		/* shift amount register */
#define IPSW_REGNUM 41		/* processor status word. ? */
#define PCOQ_HEAD_REGNUM 33	/* instruction offset queue head */
#define PCSQ_HEAD_REGNUM 34	/* instruction space queue head */
#define PCOQ_TAIL_REGNUM 35	/* instruction offset queue tail */
#define PCSQ_TAIL_REGNUM 36	/* instruction space queue tail */
#define FP0_REGNUM 64		/* floating point reg. 0 */
#define FP4_REGNUM 72

/* compatibility with the rest of gdb. */
#define PC_REGNUM PCOQ_HEAD_REGNUM
#define NPC_REGNUM PCOQ_TAIL_REGNUM

/* When fetching register values from an inferior or a core file,
   clean them up using this macro.  BUF is a char pointer to
   the raw value of the register in the registers[] array.  */

#define	CLEAN_UP_REGISTER_VALUE(regno, buf) \
  do {	\
    if ((regno) == PCOQ_HEAD_REGNUM || (regno) == PCOQ_TAIL_REGNUM) \
      (buf)[3] &= ~0x3;	\
  } while (0)

/* Define DO_REGISTERS_INFO() to do machine-specific formatting
   of register dumps. */

#define DO_REGISTERS_INFO(_regnum, fp) pa_do_registers_info (_regnum, fp)

/* PA specific macro to see if the current instruction is nullified. */
#define INSTRUCTION_NULLIFIED ((int)read_register (IPSW_REGNUM) & 0x00200000)

/* Total amount of space needed to store our copies of the machine's
   register state, the array `registers'.  */
#define REGISTER_BYTES (32 * 4 + 11 * 4 + 8 * 4 + 12 * 4 + 4 + 32 * 8)

/* Index within `registers' of the first byte of the space for
   register N.  */

#define REGISTER_BYTE(N) \
 ((N) >= FP4_REGNUM ? ((N) - FP4_REGNUM) * 8 + 288 : (N) * 4)

/* Number of bytes of storage in the actual machine representation
   for register N.  On the PA-RISC, all regs are 4 bytes
   except the floating point regs which are 8 bytes.  */

#define REGISTER_RAW_SIZE(N) ((N) < FP4_REGNUM ? 4 : 8)

/* Number of bytes of storage in the program's representation
   for register N. */

#define REGISTER_VIRTUAL_SIZE(N) REGISTER_RAW_SIZE(N)

/* Largest value REGISTER_RAW_SIZE can have.  */

#define MAX_REGISTER_RAW_SIZE 8

/* Largest value REGISTER_VIRTUAL_SIZE can have.  */

#define MAX_REGISTER_VIRTUAL_SIZE 8

/* Nonzero if register N requires conversion
   from raw format to virtual format.  */

#define REGISTER_CONVERTIBLE(N) 0

/* Convert data from raw format for register REGNUM
   to virtual format for register REGNUM.  */

#define REGISTER_CONVERT_TO_VIRTUAL(REGNUM, FROM, TO) \
{ memcpy ((TO), (FROM), (REGNUM) < FP4_REGNUM ? 4 : 8); }

/* Convert data from virtual format for register REGNUM
   to raw format for register REGNUM.  */

#define REGISTER_CONVERT_TO_RAW(REGNUM, FROM, TO) \
{ memcpy ((TO), (FROM), (REGNUM) < FP4_REGNUM ? 4 : 8); }

/* Return the GDB type object for the "standard" data type
   of data in register N.  */

#define REGISTER_VIRTUAL_TYPE(N) \
 ((N) < FP4_REGNUM ? builtin_type_int : builtin_type_double)

/* Store the address of the place in which to copy the structure the
   subroutine will return.  This is called from call_function. */

#define STORE_STRUCT_RETURN(ADDR, SP) {write_register (28, (ADDR)); }

/* Extract from an array REGBUF containing the (raw) register state
   a function return value of type TYPE, and copy that, in virtual format,
   into VALBUF.  */

#define EXTRACT_RETURN_VALUE(TYPE,REGBUF,VALBUF) \
  bcopy ((REGBUF) + REGISTER_BYTE(TYPE_LENGTH(TYPE) > 4 ? \
        FP4_REGNUM :28), VALBUF, TYPE_LENGTH (TYPE))

/* Write into appropriate registers a function return value
   of type TYPE, given in virtual format.  */

#define STORE_RETURN_VALUE(TYPE,VALBUF) \
  write_register_bytes (TYPE_LENGTH(TYPE) > 4 ? FP4_REGNUM :28,		\
			VALBUF, TYPE_LENGTH (TYPE))

/* Extract from an array REGBUF containing the (raw) register state
   the address in which a function should return its structure value,
   as a CORE_ADDR (or an expression that can be used as one).  */

#define EXTRACT_STRUCT_VALUE_ADDRESS(REGBUF) (*(int *)((REGBUF) + 28))

/*
 * This macro defines the register numbers (from REGISTER_NAMES) that
 * are effectively unavailable to the user through ptrace().  It allows
 * us to include the whole register set in REGISTER_NAMES (inorder to
 * better support remote debugging).  If it is used in
 * fetch/store_inferior_registers() gdb will not complain about I/O errors
 * on fetching these registers.  If all registers in REGISTER_NAMES
 * are available, then return false (0).
 */

#define CANNOT_STORE_REGISTER(regno)            \
                   ((regno) == 0) ||     \
                   ((regno) == PCSQ_HEAD_REGNUM) || \
                   ((regno) >= PCSQ_TAIL_REGNUM && (regno) < IPSW_REGNUM) ||  \
                   ((regno) > IPSW_REGNUM && (regno) < FP4_REGNUM)

#define INIT_EXTRA_FRAME_INFO(fromleaf, frame) init_extra_frame_info (fromleaf, frame)

/* Describe the pointer in each stack frame to the previous stack frame
   (its caller).  */

/* FRAME_CHAIN takes a frame's nominal address
   and produces the frame's chain-pointer.

   FRAME_CHAIN_COMBINE takes the chain pointer and the frame's nominal address
   and produces the nominal address of the caller frame.

   However, if FRAME_CHAIN_VALID returns zero,
   it means the given frame is the outermost one and has no caller.
   In that case, FRAME_CHAIN_COMBINE is not used.  */

/* In the case of the PA-RISC, the frame's nominal address
   is the address of a 4-byte word containing the calling frame's
   address (previous FP).  */

#define FRAME_CHAIN(thisframe) frame_chain (thisframe)

#define FRAME_CHAIN_VALID(chain, thisframe) \
  frame_chain_valid (chain, thisframe)

#define FRAME_CHAIN_COMBINE(chain, thisframe) (chain)

/* Define other aspects of the stack frame.  */

/* A macro that tells us whether the function invocation represented
   by FI does not have a frame on the stack associated with it.  If it
   does not, FRAMELESS is set to 1, else 0.  */
#define FRAMELESS_FUNCTION_INVOCATION(FI, FRAMELESS) \
  (FRAMELESS) = frameless_look_for_prologue(FI)

#define FRAME_SAVED_PC(FRAME) frame_saved_pc (FRAME)

#define FRAME_ARGS_ADDRESS(fi) ((fi)->frame)

#define FRAME_LOCALS_ADDRESS(fi) ((fi)->frame)
/* Set VAL to the number of args passed to frame described by FI.
   Can set VAL to -1, meaning no way to tell.  */

/* We can't tell how many args there are
   now that the C compiler delays popping them.  */
#define FRAME_NUM_ARGS(val,fi) (val = -1)

/* Return number of bytes at start of arglist that are not really args.  */

#define FRAME_ARGS_SKIP 0

/* Put here the code to store, into a struct frame_saved_regs,
   the addresses of the saved registers of frame described by FRAME_INFO.
   This includes special registers such as pc and fp saved in special
   ways in the stack frame.  sp is even more special:
   the address we return for it IS the sp for the next frame.  */

/* Deal with dummy functions later. */

#define STW_P(INSN) (((INSN) & 0xfc000000) == 0x68000000)
#define ADDIL_P(INSN) (((INSN) & 0xfc000000) == 0x28000000)
#define LDO_P(INSN) (((INSN) & 0xfc00c000) == 0x34000000)

#define FRAME_FIND_SAVED_REGS(frame_info, frame_saved_regs)		\
{ register int regnum;							\
  register CORE_ADDR next_addr;						\
  register CORE_ADDR pc;						\
  unsigned this_insn;							\
  unsigned address;							\
									\
  bzero (&frame_saved_regs, sizeof frame_saved_regs);			\
  if ((frame_info->pc >= (frame_info)->frame                            \
       && (frame_info)->pc <= ((frame_info)->frame + CALL_DUMMY_LENGTH  \
			       + 32 * 4 + (NUM_REGS - FP0_REGNUM) * 8   \
			       + 6 * 4)))                               \
    find_dummy_frame_regs ((frame_info), &(frame_saved_regs));		\
  else									\
    { pc = get_pc_function_start ((frame_info)->pc);			\
      if (read_memory_integer (pc, 4) == 0x6BC23FD9)			\
	{ (frame_saved_regs).regs[RP_REGNUM] = (frame_info)->frame - 20;\
	  pc = pc + 4;							\
	}								\
      if (read_memory_integer (pc, 4) != 0x8040241) goto lose;		\
      pc += 8;			/* skip "copy 4,1; copy 30, 4" */	\
      /* skip either "stw 1,0(4);addil L'fsize,30;ldo R'fsize(1),30"	\
	 or "stwm 1,fsize(30)" */					\
      if ((read_memory_integer (pc, 4) & ~MASK_14) == 0x68810000)	\
	pc += 12;							\
      else								\
	pc += 4;							\
      while (1)								\
	{ this_insn = read_memory_integer(pc, 4);			\
	  if (STW_P (this_insn)) /* stw */				\
	    { regnum = GET_FIELD (this_insn, 11, 15);			\
	      if (!regnum) goto lose;					\
	      (frame_saved_regs).regs[regnum] = (frame_info)->frame +	\
		extract_14 (this_insn);					\
	      pc += 4;							\
	    }								\
	  else if (ADDIL_P (this_insn)) /* addil */			\
	    { int next_insn;						\
	      next_insn = read_memory_integer(pc + 4, 4);		\
	      if (STW_P (next_insn)) /* stw */				\
		{ regnum = GET_FIELD (this_insn, 6, 10);		\
		  if (!regnum) goto lose;				\
		  (frame_saved_regs).regs[regnum] = (frame_info)->frame +\
		    (extract_21 (this_insn) << 11) + extract_14 (next_insn);\
		  pc += 8;						\
		}							\
	      else							\
		break;							\
	    }								\
	  else								\
	    { pc += 4;							\
	      break;							\
	    }								\
	}								\
      this_insn = read_memory_integer (pc, 4);				\
      if (LDO_P (this_insn))						\
	{ next_addr = (frame_info)->frame + extract_14 (this_insn);	\
	  pc += 4;							\
	}								\
      else if (ADDIL_P (this_insn))					\
	{ next_addr = (frame_info)->frame + (extract_21 (this_insn) << 11)\
	    + extract_14 (read_memory_integer (pc + 4, 4));		\
	    pc += 8;							\
	  }								\
      while (1)								\
	{ this_insn = read_memory_integer (pc, 4);			\
	  if ((this_insn & 0xfc001fe0) == 0x2c001220) /* fstds,ma */	\
	    { regnum = GET_FIELD (this_insn, 27, 31);			\
	      (frame_saved_regs).regs[regnum + FP0_REGNUM] = next_addr;	\
	      next_addr += 8;						\
              pc += 4;                                                  \
	    }								\
	  else								\
	    break;							\
	}								\
    lose:								\
      (frame_saved_regs).regs[FP_REGNUM] = (frame_info)->frame;		\
      (frame_saved_regs).regs[SP_REGNUM] = (frame_info)->frame -4;	\
    }}

/* Things needed for making the inferior call functions.  */

/* Push an empty stack frame, to record the current PC, etc. */

#define PUSH_DUMMY_FRAME push_dummy_frame ()

/* Discard from the stack the innermost frame, 
   restoring all saved registers.  */
#define POP_FRAME  hp_pop_frame ()

/* This sequence of words is the instructions

; Call stack frame has already been built by gdb. Since we could be calling 
; a varargs function, and we do not have the benefit of a stub to put things in
; the right place, we load the first 4 word of arguments into both the general
; and fp registers.
call_dummy
	ldw -36(sp), arg0
	ldw -40(sp), arg1
	ldw -44(sp), arg2
	ldw -48(sp), arg3
	ldo -36(sp), r1
	fldws 0(0, r1), fr4
	fldds -4(0, r1), fr5
	fldws -8(0, r1), fr6
	fldds -12(0, r1), fr7
	ldil 0, r22			; target will be placed here.
	ldo 0(r22), r22
	ldsid (0,r22), r3
	ldil 0, r1			; _sr4export will be placed here.
	ldo 0(r1), r1
	ldsid (0,r1), r19
	combt,=,n r3, r19, text_space	; If target is in data space, do a
	ble 0(sr5, r22)			; "normal" procedure call
	copy r31, r2
	break 4, 8 
	mtsp r21, sr0
	ble,n 0(sr0, r22)
text_space				; Otherwise, go through _sr4export,
	ble (sr4, r1)			; which will return back here.
	stw 31,-24(r30)
	break 4, 8
	mtsp r21, sr0
	ble,n 0(sr0, r22)

   The dummy decides if the target is in text space or data space. If
   it's in data space, there's no problem because the target can
   return back to the dummy. However, if the target is in text space,
   the dummy calls the secret, undocumented routine _sr4export, which
   calls a function in text space and can return to any space. Instead
   of including fake instructions to represent saved registers, we
   know that the frame is associated with the call dummy and treat it
   specially. */ 

#define CALL_DUMMY {0x4BDA3FB9, 0x4BD93FB1, 0x4BD83FA9, 0x4BD73FA1,\
                    0x37C13FB9, 0x24201004, 0x2C391005, 0x24311006,\
                    0x2C291007, 0x22C00000, 0x36D60000, 0x02C010A3,\
                    0x20200000, 0x34210000, 0x002010b3, 0x82632022,\
                    0xe6c06000, 0x081f0242, 0x00010004, 0x00151820,\
                    0xe6c00002, 0xe4202000, 0x6bdf3fd1, 0x00010004,\
                    0x00151820, 0xe6c00002}

#define CALL_DUMMY_LENGTH 104
#define CALL_DUMMY_START_OFFSET 0

/*
 * Insert the specified number of args and function address
 * into a call sequence of the above form stored at DUMMYNAME.
 *
 * On the hppa we need to call the stack dummy through $$dyncall.
 * Therefore our version of FIX_CALL_DUMMY takes an extra argument,
 * real_pc, which is the location where gdb should start up the
 * inferior to do the function call.
 */

#define FIX_CALL_DUMMY(dummyname, pc, real_pc, fun, nargs, args, type, gcc_p) \
{                                                                       \
  CORE_ADDR dyncall_addr = 0, sr4export_addr = 0;                       \
                                                                        \
  if (!dyncall_addr)                                                    \
    {                                                                   \
      struct minimal_symbol *msymbol;                                   \
      msymbol = lookup_minimal_symbol ("$$dyncall", (struct objfile *) NULL);\
      if (msymbol == NULL)                                              \
        error ("Can't find an address for $$dyncall trampoline");       \
      else                                                              \
        dyncall_addr = SYMBOL_VALUE_ADDRESS (msymbol);                  \
      msymbol = lookup_minimal_symbol ("_sr4export", (struct objfile *) NULL);\
      if (msymbol == NULL)                                              \
        error ("Can't find an address for _sr4export trampoline");      \
      else                                                              \
        sr4export_addr = SYMBOL_VALUE_ADDRESS (msymbol);                \
    }                                                                   \
  dummyname[9] = deposit_21 (fun >> 11, dummyname[9]);                  \
  dummyname[10] = deposit_14 (fun & MASK_11, dummyname[10]);            \
  dummyname[12] = deposit_21 (sr4export_addr >> 11,                     \
                              dummyname[12]);                           \
  dummyname[13] = deposit_14 (sr4export_addr & MASK_11,                 \
                              dummyname[13]);                           \
  write_register (22, pc);                                              \
  real_pc = dyncall_addr;                                               \
}

#define PUSH_ARGUMENTS(nargs, args, sp, struct_return, struct_addr) \
    sp = hp_push_arguments(nargs, args, sp, struct_return, struct_addr)

/* Symbol files have two symbol tables.  Rather than do this right,
   like the ELF symbol reading code, massive hackery was added
   to dbxread.c and partial-stab.h.  This flag turns on that
   hackery, which should all go away FIXME FIXME FIXME FIXME now.  */

#define	GDB_TARGET_IS_HPPA

#define BELIEVE_PCC_PROMOTION 1

/*
 * Unwind table and descriptor.
 */

struct unwind_table_entry {
  unsigned int region_start;
  unsigned int region_end;

  unsigned int Cannot_unwind         :  1;
  unsigned int Millicode             :  1;
  unsigned int Millicode_save_sr0    :  1;
  unsigned int Region_description    :  2;
  unsigned int reserverd1            :  1;
  unsigned int Entry_SR              :  1;
  unsigned int Entry_FR              :  4; /* number saved */
  unsigned int Entry_GR              :  5; /* number saved */
  unsigned int Args_stored           :  1;
  unsigned int Variable_Frame	     :  1;
  unsigned int Separate_Package_Body :  1;
  unsigned int Frame_Extension_Millicode:1;
  unsigned int Stack_Overflow_Check  :  1;
  unsigned int Two_Instruction_SP_Increment:1;
  unsigned int Ada_Region	     :  1;
  unsigned int reserved2	     :  4;
  unsigned int Save_SP               :  1;
  unsigned int Save_RP               :  1;
  unsigned int Save_MRP_in_frame     :  1;
  unsigned int extn_ptr_defined      :  1;
  unsigned int Cleanup_defined       :  1;

  unsigned int MPE_XL_interrupt_marker: 1;
  unsigned int HP_UX_interrupt_marker:  1;
  unsigned int Large_frame	     :  1;
  unsigned int reserved4             :  2;
  unsigned int Total_frame_size      : 27;
};

/* Info about the unwind table associated with an object file.  This is hung
   off of the objfile->obj_private pointer, and is allocated in the objfile's
   psymbol obstack.  This allows us to have unique unwind info for each
   executable and shared library that we are debugging.  */

struct obj_unwind_info {
  struct unwind_table_entry *table; /* Pointer to unwind info */
  struct unwind_table_entry *cache; /* Pointer to last entry we found */
  int last;			/* Index of last entry */
};

#define OBJ_UNWIND_INFO(obj) ((struct obj_unwind_info *)obj->obj_private)
