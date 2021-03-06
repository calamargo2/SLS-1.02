# Grundfunktionen f?r Single-Floats

# Entpacken eines Single-Float:
# FF_decode(obj, zero_statement, sign=,exp=,mant=);
# zerlegt ein Single-Float obj.
# Ist obj=0.0, wird zero_statement ausgef?hrt.
# Sonst: signean sign = Vorzeichen (0 = +, -1 = -),
#        sintWL exp = Exponent (vorzeichenbehaftet),
#        uintL mant = Mantisse (>= 2^FF_mant_len, < 2^(FF_mant_len+1))
  #define FF_uexp(x)  (((x) >> FF_mant_len) & (bit(FF_exp_len)-1))
  #define FF_decode(obj, zero_statement, sign_zuweisung,exp_zuweisung,mant_zuweisung)  \
    { var reg1 ffloat _x = ffloat_value(obj);                              \
      var reg2 uintBWL uexp = FF_uexp(_x);                                 \
      if (uexp==0)                                                         \
        { zero_statement } # e=0 -> Zahl 0.0                               \
        else                                                               \
        { exp_zuweisung (sintWL)((uintWL)uexp - FF_exp_mid); # Exponent    \
          sign_zuweisung sign_of_sint32((sint32)(_x));     # Vorzeichen    \
          mant_zuweisung (bit(FF_mant_len) | (_x & (bit(FF_mant_len)-1))); \
    }   }

# Einpacken eines Single-Float:
# encode_FF(sign,exp,mant, ergebnis=);
# liefert ein Single-Float.
# > signean sign: Vorzeichen, 0 f?r +, -1 f?r negativ.
# > sintWL exp: Exponent
# > uintL mant: Mantisse, sollte >= 2^FF_mant_len und < 2^(FF_mant_len+1) sein.
# < object ergebnis: ein Single-Float
# Der Exponent wird auf ?berlauf/Unterlauf getestet.
# kann GC ausl?sen
  #define encode_FF(sign,exp,mant, erg_zuweisung)  \
    { if ((exp) < (sintWL)(FF_exp_low-FF_exp_mid)) { fehler_underflow(); } \
      if ((exp) > (sintWL)(FF_exp_high-FF_exp_mid)) { fehler_overflow(); } \
      erg_zuweisung allocate_ffloat                                        \
        (  ((sint32)(sign) & bit(31))                  # Vorzeichen        \
         | ((uint32)((exp)+FF_exp_mid) << FF_mant_len) # Exponent          \
         | ((uint32)(mant) & (bit(FF_mant_len)-1))     # Mantisse          \
        );                                                                 \
    }

#ifdef FAST_FLOAT
# Auspacken eines Floats:
  #ifndef WIDE
    #define FF_to_float(obj)  (TheFfloat(obj)->representation.machine_float)
  #else # defined(WIDE) -> eines der beiden 32-Bit-W?rter
    #define FF_to_float(obj)  (*(float*)(&((uint32*)&(obj))[BIG_ENDIAN_P+(1-2*BIG_ENDIAN_P)*(oint_addr_shift/32)]))
  #endif
# ?berpr?fen und Einpacken eines von den 'float'-Routinen gelieferten
# IEEE-Floats.
# Klassifikation:
#   1 <= e <= 254 : normalisierte Zahl
#   e=0, m/=0: subnormale Zahl
#   e=0, m=0: vorzeichenbehaftete 0.0
#   e=255, m=0: vorzeichenbehaftete Infinity
#   e=255, m/=0: NaN
# Angabe der m?glicherweise auftretenden Sonderf?lle:
#   maybe_overflow: Operation l?uft ?ber, liefert IEEE-Infinity
#   maybe_subnormal: Ergebnis sehr klein, liefert IEEE-subnormale Zahl
#   maybe_underflow: Ergebnis sehr klein, liefert IEEE-Null
#   maybe_divide_0: Ergebnis unbestimmt, liefert IEEE-Infinity
#   maybe_nan: Ergebnis unbestimmt, liefert IEEE-NaN
  #define float_to_FF(expr,ergebnis_zuweisung,maybe_overflow,maybe_subnormal,maybe_underflow,maybe_divide_0,maybe_nan)  \
    { var ffloatjanus _erg; _erg.machine_float = (expr);           \
      if ((_erg.explicit & (bit(FF_exp_len+FF_mant_len)-bit(FF_mant_len))) == 0) # e=0 ? \
        { if (maybe_underflow                                      \
              || (maybe_subnormal && !((_erg.explicit << 1) == 0)) \
             )                                                     \
            { fehler_underflow(); } # subnormal oder noch kleiner-> Underflow \
            else                                                   \
            { ergebnis_zuweisung FF_0; } # +/- 0.0 -> 0.0          \
        }                                                          \
      elif ((maybe_overflow || maybe_divide_0)                     \
            && (((~_erg.explicit) & (bit(FF_exp_len+FF_mant_len)-bit(FF_mant_len))) == 0) # e=255 ? \
           )                                                       \
        { if (maybe_nan && ((_erg.explicit << (32-FF_mant_len)) == 0)) \
            { divide_0(); } # NaN, also Singularit?t -> "Division durch 0" \
          else # Infinity                                          \
          if (!maybe_overflow || maybe_divide_0)                   \
            { divide_0(); } # Infinity, Division durch 0           \
            else                                                   \
            { fehler_overflow(); } # Infinity, Overflow            \
        }                                                          \
      else                                                         \
        { ergebnis_zuweisung allocate_ffloat(_erg.explicit); }     \
    }
#endif

# FF_zerop(x) stellt fest, ob ein Single-Float x = 0.0 ist.
  # define FF_zerop(x)  (FF_uexp(ffloat_value(x)) == 0)
  #define FF_zerop(x)  (ffloat_value(x) == 0)

# Liefert zu einem Single-Float x : (ftruncate x), ein FF.
# FF_ftruncate_FF(x)
# x wird zur 0 hin zur n?chsten ganzen Zahl gerundet.
# kann GC ausl?sen
  local object FF_ftruncate_FF (object x);
# Methode:
# x = 0.0 oder e<=0 -> Ergebnis 0.0
# 1<=e<=23 -> letzte (24-e) Bits der Mantisse auf 0 setzen,
#             Exponent und Vorzeichen beibehalten
# e>=24 -> Ergebnis x
  local object FF_ftruncate_FF(x)
    var reg3 object x;
    { var reg2 ffloat x_ = ffloat_value(x);
      var reg1 uintBWL uexp = FF_uexp(x_); # e + FF_exp_mid
      if (uexp <= FF_exp_mid) # 0.0 oder e<=0 ?
        { return FF_0; }
        else
        { if (uexp > FF_exp_mid+FF_mant_len) # e > 23 ?
            { return x; }
            else
            { return allocate_ffloat
                ( x_ & # Bitmaske: Bits 23-e..0 gel?scht, alle anderen gesetzt
                  ~(bit(FF_mant_len+1+FF_exp_mid-uexp)-1)
                );
    }   }   }

# Liefert zu einem Single-Float x : (futruncate x), ein FF.
# FF_futruncate_FF(x)
# x wird von der 0 weg zur n?chsten ganzen Zahl gerundet.
# kann GC ausl?sen
  local object FF_futruncate_FF (object x);
# Methode:
# x = 0.0 -> Ergebnis 0.0
# e<=0 -> Ergebnis 1.0 oder -1.0, je nach Vorzeichen von x.
# 1<=e<=23 -> Greife die letzten (24-e) Bits von x heraus.
#             Sind sie alle =0 -> Ergebnis x.
#             Sonst setze sie alle und erh?he dann die letzte Stelle um 1.
#             Kein ?berlauf der 23 Bit -> fertig.
#             Sonst (Ergebnis eine Zweierpotenz): Mantisse := .1000...000,
#               e:=e+1. (Test auf ?berlauf wegen e<=24 ?berfl?ssig)
# e>=24 -> Ergebnis x.
  local object FF_futruncate_FF(x)
    var reg3 object x;
    { var reg2 ffloat x_ = ffloat_value(x);
      var reg1 uintBWL uexp = FF_uexp(x_); # e + FF_exp_mid
      if (uexp==0) # 0.0 ?
        { return x; }
      if (uexp <= FF_exp_mid) # e<=0 ?
        { # Exponent auf 1, Mantisse auf .1000...000 setzen.
          return ((x_ & bit(31))==0 ? FF_1 : FF_minus1);
        }
        else
        { if (uexp > FF_exp_mid+FF_mant_len) # e > 23 ?
            { return x; }
            else
            { var reg1 uint32 mask = # Bitmaske: Bits 23-e..0 gesetzt, alle anderen gel?scht
                bit(FF_mant_len+1+FF_exp_mid-uexp)-1;
              if ((x_ & mask)==0) # alle diese Bits =0 ?
                { return x; }
              return allocate_ffloat
                ((x_ | mask) # alle diese Bits setzen
                 + 1 # letzte Stelle erh?hen, dabei evtl. Exponenten incrementieren
                );
    }   }   }

# Liefert zu einem Single-Float x : (fround x), ein FF.
# FF_fround_FF(x)
# x wird zur n?chsten ganzen Zahl gerundet.
# kann GC ausl?sen
  local object FF_fround_FF (object x);
# Methode:
# x = 0.0 oder e<0 -> Ergebnis 0.0
# 0<=e<=23 -> letzte (24-e) Bits der Mantisse wegrunden,
#             Exponent und Vorzeichen beibehalten.
# e>23 -> Ergebnis x
  local object FF_fround_FF(x)
    var reg3 object x;
    { var reg2 ffloat x_ = ffloat_value(x);
      var reg1 uintBWL uexp = FF_uexp(x_); # e + FF_exp_mid
      if (uexp < FF_exp_mid) # x = 0.0 oder e<0 ?
        { return FF_0; }
        else
        { if (uexp > FF_exp_mid+FF_mant_len) # e > 23 ?
            { return x; }
            else
            if (uexp > FF_exp_mid+1) # e>1 ?
              { var reg4 uint32 bitmask = # Bitmaske: Bit 23-e gesetzt, alle anderen gel?scht
                  bit(FF_mant_len+FF_exp_mid-uexp);
                var reg3 uint32 mask = # Bitmaske: Bits 22-e..0 gesetzt, alle anderen gel?scht
                  bitmask-1;
                if ( ((x_ & bitmask) ==0) # Bit 23-e =0 -> abrunden
                     || ( ((x_ & mask) ==0) # Bit 23-e =1 und Bits 22-e..0 >0 -> aufrunden
                          # round-to-even, je nach Bit 24-e :
                          && ((x_ & (bitmask<<1)) ==0)
                   )    )
                  # abrunden
                  { mask |= bitmask; # Bitmaske: Bits 23-e..0 gesetzt, alle anderen gel?scht
                    return allocate_ffloat( x_ & ~mask );
                  }
                  else
                  # aufrunden
                  { return allocate_ffloat
                      ((x_ | mask) # alle diese Bits 22-e..0 setzen (Bit 23-e schon gesetzt)
                       + 1 # letzte Stelle erh?hen, dabei evtl. Exponenten incrementieren
                      );
                  }
              }
            elif (uexp == FF_exp_mid+1) # e=1 ?
              # Wie bei 1 < e <= 23, nur da? Bit 24-e stets gesetzt ist.
              { if ((x_ & bit(FF_mant_len-1)) ==0) # Bit 23-e =0 -> abrunden
                  # abrunden
                  { return allocate_ffloat( x_ & ~(bit(FF_mant_len)-1) ); }
                  else
                  # aufrunden
                  { return allocate_ffloat
                      ((x_ | (bit(FF_mant_len)-1)) # alle diese Bits 23-e..0 setzen
                       + 1 # letzte Stelle erh?hen, dabei evtl. Exponenten incrementieren
                      );
                  }
              }
            else # e=0 ?
              # Wie bei 1 < e <= 23, nur da? Bit 23-e stets gesetzt
              # und Bit 24-e stets gel?scht ist.
              { if ((x_ & (bit(FF_mant_len)-1)) ==0)
                  # abrunden von +-0.5 zu 0.0
                  { return FF_0; }
                  else
                  # aufrunden
                  { return allocate_ffloat
                      ((x_ | (bit(FF_mant_len)-1)) # alle Bits 22-e..0 setzen
                       + 1 # letzte Stelle erh?hen, dabei Exponenten incrementieren
                      );
              }   }
    }   }

# Liefert zu einem Single-Float x : (- x), ein FF.
# FF_minus_FF(x)
# kann GC ausl?sen
  local object FF_minus_FF (object x);
# Methode:
# Falls x=0.0, fertig. Sonst Vorzeichenbit umdrehen.
  local object FF_minus_FF(x)
    var reg2 object x;
    { var reg1 ffloat x_ = ffloat_value(x);
      return (FF_uexp(x_) == 0
              ? x
              : allocate_ffloat( x_ ^ bit(31) )
             );
    }

# FF_FF_comp(x,y) vergleicht zwei Single-Floats x und y.
# Ergebnis: 0 falls x=y, +1 falls x>y, -1 falls x<y.
  local signean FF_FF_comp (object x, object y);
# Methode:
# x und y haben verschiedenes Vorzeichen ->
#    x < 0 -> x < y
#    x >= 0 -> x > y
# x und y haben gleiches Vorzeichen ->
#    x >=0 -> vergleiche x und y (die rechten 24 Bits)
#    x <0 -> vergleiche y und x (die rechten 24 Bits)
  local signean FF_FF_comp(x,y)
    var reg3 object x;
    var reg4 object y;
    { var reg1 uint32 x_ = ffloat_value(x);
      var reg2 uint32 y_ = ffloat_value(y);
      if ((sint32)y_ >= 0)
        # y>=0
        { if ((sint32)x_ >= 0)
            # y>=0, x>=0
            { if (x_ < y_) return signean_minus; # x<y
              if (x_ > y_) return signean_plus; # x>y
              return signean_null;
            }
            else
            # y>=0, x<0
            { return signean_minus; } # x<y
        }
        else
        { if ((sint32)x_ >= 0)
            # y<0, x>=0
            { return signean_plus; } # x>y
            else
            # y<0, x<0
            { if (x_ > y_) return signean_minus; # |x|>|y| -> x<y
              if (x_ < y_) return signean_plus; # |x|<|y| -> x>y
              return signean_null;
            }
        }
    }

# Liefert zu zwei Single-Float x und y : (+ x y), ein FF.
# FF_FF_plus_FF(x)
# kann GC ausl?sen
  local object FF_FF_plus_FF (object x, object y);
# Methode (nach [Knuth, II, Seminumerical Algorithms, Abschnitt 4.2.1., S.200]):
# x1=0.0 -> Ergebnis x2.
# x2=0.0 -> Ergebnis x1.
# Falls e1<e2, vertausche x1 und x2.
# Also e1 >= e2.
# Falls e1 - e2 >= 23 + 3, Ergebnis x1.
# Schiebe beide Mantissen um 3 Bits nach links (Vorbereitung der Rundung:
#   Bei e1-e2=0,1 ist keine Rundung n?tig, bei e1-e2>1 ist der Exponent des
#   Ergebnisses =e1-1, =e1 oder =e1+1. Brauche daher 1 Schutzbit und zwei
#   Rundungsbits: 00 exakt, 01 1.H?lfte, 10 exakte Mitte, 11 2.H?lfte.)
# Schiebe die Mantisse von x2 um e0-e1 Bits nach rechts. (Dabei die Rundung
# ausf?hren: Bit 0 ist das logische Oder der Bits 0,-1,-2,...)
# Falls x1,x2 selbes Vorzeichen haben: Addiere dieses zur Mantisse von x1.
# Falls x1,x2 verschiedenes Vorzeichen haben: Subtrahiere dieses von der
#   Mantisse von x1. <0 -> (Es war e1=e2) Vertausche die Vorzeichen, negiere.
#                    =0 -> Ergebnis 0.0
# Exponent ist e1.
# Normalisiere, fertig.
 #ifdef FAST_FLOAT
  local object FF_FF_plus_FF(x1,x2)
    var reg1 object x1;
    var reg2 object x2;
    { float_to_FF(FF_to_float(x1) + FF_to_float(x2), return ,
                  TRUE, TRUE, # Overflow und subnormale Zahl abfangen
                  FALSE, # kein Underflow mit Ergebnis +/- 0.0 m?glich
                         # (nach Definition der subnormalen Zahlen)
                  FALSE, FALSE # keine Singularit?t, kein NaN als Ergebnis m?glich
                 );
    }
 #else
  local object FF_FF_plus_FF(x1,x2)
    var reg7 object x1;
    var reg8 object x2;
    { # x1,x2 entpacken:
      var reg9 signean sign1;
      var reg5 sintWL exp1;
      var reg1 uintL mant1;
      var reg9 signean sign2;
      var reg10 sintWL exp2;
      var reg4 uintL mant2;
      FF_decode(x1, { return x2; }, sign1=,exp1=,mant1=);
      FF_decode(x2, { return x1; }, sign2=,exp2=,mant2=);
      if (exp1 < exp2)
        { swap(reg9 object,  x1   ,x2   );
          swap(reg9 signean, sign1,sign2);
          swap(reg9 sintWL,  exp1 ,exp2 );
          swap(reg9 uintL,   mant1,mant2);
        }
      # Nun ist exp1>=exp2.
     {var reg3 uintL expdiff = exp1 - exp2; # Exponentendifferenz
      if (expdiff >= FF_mant_len+3) # >= 23+3 ?
        { return x1; }
      mant1 = mant1 << 3; mant2 = mant2 << 3;
      # Nun 2^(FF_mant_len+3) <= mant1,mant2 < 2^(FF_mant_len+4).
      {var reg2 uintL mant2_last = mant2 & (bit(expdiff)-1); # letzte expdiff Bits von mant2
       mant2 = mant2 >> expdiff; if (!(mant2_last==0)) { mant2 |= bit(0); }
      }
      # mant2 = um expdiff Bits nach rechts geschobene und gerundete Mantisse
      # von x2.
      if (!(sign1==sign2))
        # verschiedene Vorzeichen -> Mantissen subtrahieren
        { if (mant1 > mant2) { mant1 = mant1 - mant2; goto norm_2; }
          if (mant1 == mant2) # Ergebnis 0 ?
            { return FF_0; }
          # negatives Subtraktionsergebnis
          mant1 = mant2 - mant1; sign1 = sign2; goto norm_2;
        }
        else
        # gleiche Vorzeichen -> Mantissen addieren
        { mant1 = mant1 + mant2; }
      # mant1 = Ergebnis-Mantisse >0, sign1 = Ergebnis-Vorzeichen,
      # exp1 = Ergebnis-Exponent.
      # Au?erdem: Bei expdiff=0,1 sind die zwei letzten Bits von mant1 Null,
      # bei expdiff>=2 ist mant1 >= 2^(FF_mant_len+2).
      # Stets ist mant1 < 2^(FF_mant_len+5). (Daher werden die 2 Rundungsbits
      # nachher um h?chstens eine Position nach links geschoben werden.)
      # [Knuth, S.201, leicht modifiziert:
      #   N1. m>=1 -> goto N4.
      #   N2. [Hier m<1] m>=1/2 -> goto N5.
      #       N3. m:=2*m, e:=e-1, goto N2.
      #   N4. [Hier 1<=m<2] m:=m/2, e:=e+1.
      #   N5. [Hier 1/2<=m<1] Runde m auf 24 Bits hinterm Komma.
      #       Falls hierdurch m=1 geworden, setze m:=m/2, e:=e+1.
      # ]
      # Bei uns ist m=mant1/2^(FF_mant_len+4),
      # ab Schritt N5 ist m=mant1/2^(FF_mant_len+1).
      norm_1: # [Knuth, S.201, Schritt N1]
      if (mant1 >= bit(FF_mant_len+4)) goto norm_4;
      norm_2: # [Knuth, S.201, Schritt N2]
              # Hier ist mant1 < 2^(FF_mant_len+4)
      if (mant1 >= bit(FF_mant_len+3)) goto norm_5;
      # [Knuth, S.201, Schritt N3]
      mant1 = mant1 << 1; exp1 = exp1-1; # Mantisse links schieben
      goto norm_2;
      norm_4: # [Knuth, S.201, Schritt N4]
              # Hier ist 2^(FF_mant_len+4) <= mant1 < 2^(FF_mant_len+5)
      exp1 = exp1+1;
      mant1 = (mant1>>1) | (mant1 & bit(0)); # Mantisse rechts schieben
      norm_5: # [Knuth, S.201, Schritt N5]
              # Hier ist 2^(FF_mant_len+3) <= mant1 < 2^(FF_mant_len+4)
      # Auf FF_mant_len echte Mantissenbits runden, d.h. rechte 3 Bits
      # wegrunden, und dabei mant1 um 3 Bits nach rechts schieben:
      {var reg2 uintL rounding_bits = mant1 & (bit(3)-1);
       mant1 = mant1 >> 3;
       if ( (rounding_bits < bit(2)) # 000,001,010,011 werden abgerundet
            || ( (rounding_bits == bit(2)) # 100 (genau halbzahlig)
                 && ((mant1 & bit(0)) ==0) # -> round-to-even
          )    )
         # abrunden
         {}
         else
         # aufrunden
         { mant1 = mant1+1;
           if (mant1 >= bit(FF_mant_len+1))
             # Bei ?berlauf w?hrend der Rundung nochmals rechts schieben
             # (Runden ist hier ?berfl?ssig):
             { mant1 = mant1>>1; exp1 = exp1+1; } # Mantisse rechts schieben
         }
      }# Runden fertig
      encode_FF(sign1,exp1,mant1, return);
    }}
 #endif

# Liefert zu zwei Single-Float x und y : (- x y), ein FF.
# FF_FF_minus_FF(x)
# kann GC ausl?sen
  local object FF_FF_minus_FF (object x, object y);
# Methode:
# (- x1 x2) = (+ x1 (- x2))
 #ifdef FAST_FLOAT
  local object FF_FF_minus_FF(x1,x2)
    var reg1 object x1;
    var reg2 object x2;
    { float_to_FF(FF_to_float(x1) - FF_to_float(x2), return ,
                  TRUE, TRUE, # Overflow und subnormale Zahl abfangen
                  FALSE, # kein Underflow mit Ergebnis +/- 0.0 m?glich
                         # (nach Definition der subnormalen Zahlen)
                  FALSE, FALSE # keine Singularit?t, kein NaN als Ergebnis m?glich
                 );
    }
 #else
  local object FF_FF_minus_FF(x1,x2)
    var reg2 object x1;
    var reg1 object x2;
    { var reg1 ffloat x2_ = ffloat_value(x2);
      if (FF_uexp(x2_) == 0)
        { return x1; }
        else
        { return FF_FF_plus_FF(x1, allocate_ffloat(x2_ ^ bit(31)) ); }
    }
 #endif

# Liefert zu zwei Single-Float x und y : (* x y), ein FF.
# FF_FF_mal_FF(x)
# kann GC ausl?sen
  local object FF_FF_mal_FF (object x, object y);
# Methode:
# Falls x1=0.0 oder x2=0.0 -> Ergebnis 0.0
# Sonst: Ergebnis-Vorzeichen = VZ von x1 xor VZ von x2.
#        Ergebnis-Exponent = Summe der Exponenten von x1 und x2.
#        Ergebnis-Mantisse = Produkt der Mantissen von x1 und x2, gerundet:
#          2^-24 * mant1  *  2^-24 * mant2  =  2^-48 * (mant1*mant2),
#          die Klammer ist >=2^46, <=(2^24-1)^2<2^48 .
#          Falls die Klammer >=2^47 ist, um 24 Bit nach rechts schieben und
#            runden: Falls Bit 23 Null, abrunden; falls Bit 23 Eins und
#            Bits 22..0 alle Null, round-to-even; sonst aufrunden.
#          Falls die Klammer <2^47 ist, um 23 Bit nach rechts schieben und
#            runden: Falls Bit 22 Null, abrunden; falls Bit 22 Eins und
#            Bits 21..0 alle Null, round-to-even; sonst aufrunden. Nach
#            Aufrunden: Falls =2^24, um 1 Bit nach rechts schieben. Sonst
#            Exponenten um 1 erniedrigen.
 #ifdef FAST_FLOAT
  local object FF_FF_mal_FF(x1,x2)
    var reg1 object x1;
    var reg2 object x2;
    { float_to_FF(FF_to_float(x1) * FF_to_float(x2), return ,
                  TRUE, TRUE, # Overflow und subnormale Zahl abfangen
                  !(FF_zerop(x1) || FF_zerop(x2)), # ein Ergebnis +/- 0.0
                              # ist genau dann in Wirklichkeit ein Underflow
                  FALSE, FALSE # keine Singularit?t, kein NaN als Ergebnis m?glich
                 );
    }
 #else
  local object FF_FF_mal_FF(x1,x2)
    var reg7 object x1;
    var reg8 object x2;
    { # x1,x2 entpacken:
      var reg6 signean sign1;
      var reg3 sintWL exp1;
      var reg4 uintL mant1;
      var reg10 signean sign2;
      var reg9 sintWL exp2;
      var reg5 uintL mant2;
      FF_decode(x1, { return x1; }, sign1=,exp1=,mant1=);
      FF_decode(x2, { return x2; }, sign2=,exp2=,mant2=);
      exp1 = exp1 + exp2; # Summe der Exponenten
      sign1 = sign1 ^ sign2; # Ergebnis-Vorzeichen
     {var reg1 uintL manthi;
      var reg2 uintL mantlo;
      # Mantissen mant1 und mant2 multiplizieren:
      mulu24(mant1,mant2, manthi=,mantlo=);
      manthi = (manthi << (32-FF_mant_len)) | (mantlo >> FF_mant_len);
      mantlo = mantlo & (bit(FF_mant_len)-1);
      # Nun ist 2^FF_mant_len * manthi + mantlo = mant1 * mant2.
      if (manthi >= bit(FF_mant_len+1))
        # mant1*mant2 >= 2^(2*FF_mant_len+1)
        { if ( ((manthi & bit(0)) ==0) # Bit FF_mant_len =0 -> abrunden
               || ( (mantlo ==0) # Bit FF_mant_len =1 und Bits FF_mant_len-1..0 >0 -> aufrunden
                    # round-to-even, je nach Bit FF_mant_len+1 :
                    && ((manthi & bit(1)) ==0)
             )    )
            # abrunden
            { manthi = manthi >> 1; goto ab; }
            else
            # aufrunden
            { manthi = manthi >> 1; goto auf; }
        }
        else
        # mant1*mant2 < 2^(2*FF_mant_len+1)
        { exp1 = exp1-1; # Exponenten decrementieren
          if ( ((mantlo & bit(FF_mant_len-1)) ==0) # Bit FF_mant_len-1 =0 -> abrunden
               || ( ((mantlo & (bit(FF_mant_len-1)-1)) ==0) # Bit FF_mant_len-1 =1 und Bits FF_mant_len-2..0 >0 -> aufrunden
                    # round-to-even, je nach Bit FF_mant_len :
                    && ((manthi & bit(0)) ==0)
             )    )
            # abrunden
            goto ab;
            else
            goto auf;
        }
      auf:
      manthi = manthi+1;
      # Hier ist 2^FF_mant_len <= manthi <= 2^(FF_mant_len+1)
      if (manthi >= bit(FF_mant_len+1)) # rounding overflow?
        { manthi = manthi>>1; exp1 = exp1+1; } # Shift nach rechts
      ab:
      # Runden fertig, 2^FF_mant_len <= manthi < 2^(FF_mant_len+1)
      encode_FF(sign1,exp1,manthi, return);
    }}
 #endif

# Liefert zu zwei Single-Float x und y : (/ x y), ein FF.
# FF_FF_durch_FF(x)
# kann GC ausl?sen
  local object FF_FF_durch_FF (object x, object y);
# Methode:
# x2 = 0.0 -> Error
# x1 = 0.0 -> Ergebnis 0.0
# Sonst:
# Ergebnis-Vorzeichen = xor der beiden Vorzeichen von x1 und x2
# Ergebnis-Exponent = Differenz der beiden Exponenten von x1 und x2
# Ergebnis-Mantisse = Mantisse mant1 / Mantisse mant2, gerundet.
#   mant1/mant2 > 1/2, mant1/mant2 < 2;
#   nach Rundung mant1/mant2 >=1/2, <=2*mant1<2.
#   Bei mant1/mant2 >=1 brauche 23 Nachkommabits,
#   bei mant1/mant2 <1 brauche 24 Nachkommabits.
#   F?rs Runden: brauche ein Rundungsbit (Rest gibt an, ob exakt).
#   Brauche daher insgesamt 25 Nachkommabits von mant1/mant2.
#   Dividiere daher (als Unsigned Integers) 2^25*(2^24*mant1) durch (2^24*mant2).
#   Falls der Quotient >=2^25 ist, runde die letzten zwei Bits weg und 
#     erh?he den Exponenten um 1.
#   Falls der Quotient <2^25 ist, runde das letzte Bit weg. Bei rounding
#     overflow schiebe um ein weiteres Bit nach rechts, incr. Exponenten.
 #ifdef FAST_FLOAT
  local object FF_FF_durch_FF(x1,x2)
    var reg1 object x1;
    var reg2 object x2;
    { float_to_FF(FF_to_float(x1) / FF_to_float(x2), return ,
                  TRUE, TRUE, # Overflow und subnormale Zahl abfangen
                  !FF_zerop(x1), # ein Ergebnis +/- 0.0
                              # ist genau dann in Wirklichkeit ein Underflow
                  FF_zerop(x2), # Division durch Null abfangen
                  FALSE # kein NaN als Ergebnis m?glich
                 );
    }
 #else
  local object FF_FF_durch_FF(x1,x2)
    var reg8 object x1;
    var reg9 object x2;
    { # x1,x2 entpacken:
      var reg7 signean sign1;
      var reg3 sintWL exp1;
      var reg5 uintL mant1;
      var reg10 signean sign2;
      var reg10 sintWL exp2;
      var reg6 uintL mant2;
      FF_decode(x2, { divide_0(); }, sign2=,exp2=,mant2=);
      FF_decode(x1, { return x1; }, sign1=,exp1=,mant1=);
      exp1 = exp1 - exp2; # Differenz der Exponenten
      sign1 = sign1 ^ sign2; # Ergebnis-Vorzeichen
      # Dividiere 2^25*mant1 durch mant2 oder (?quivalent)
      # 2^i*2^25*mant1 durch 2^i*mant2 f?r irgendein i mit 0 <= i <= 32-24 :
     {var reg1 uintL mant;
      var reg4 uintL rest;
      # w?hle i = 32-(FF_mant_len+1), also i+(FF_mant_len+2) = 33.
      divu_6432_3232(mant1<<1,0, mant2<<(32-(FF_mant_len+1)), mant=,rest=);
      if (mant >= bit(FF_mant_len+2))
        # Quotient >=2^25 -> 2 Bits wegrunden
        { var reg2 uintL rounding_bits = mant & (bit(2)-1);
          exp1 += 1; # Exponenten incrementieren
          mant = mant >> 2;
          if ( (rounding_bits < bit(1)) # 00,01 werden abgerundet
               || ( (rounding_bits == bit(1)) # 10
                    && (rest == 0) # und genau halbzahlig
                    && ((mant & bit(0)) ==0) # -> round-to-even
             )    )
            # abrunden
            {}
            else
            # aufrunden
            { mant += 1; }
        }
        else
        # Quotient <2^25 -> 1 Bit wegrunden
        { var reg2 uintL rounding_bit = mant & bit(0);
          mant = mant >> 1;
          if ( (rounding_bit == 0) # 0 wird abgerundet
               || ( (rest == 0) # genau halbzahlig
                    && ((mant & bit(0)) ==0) # -> round-to-even
             )    )
            # abrunden
            {}
            else
            # aufrunden
            { mant += 1;
              if (mant >= bit(FF_mant_len+1)) # rounding overflow?
                { mant = mant>>1; exp1 = exp1+1; }
        }   }
      encode_FF(sign1,exp1,mant, return);
    }}
 #endif

# Liefert zu einem Single-Float x>=0 : (sqrt x), ein FF.
# FF_sqrt_FF(x)
# kann GC ausl?sen
  local object FF_sqrt_FF (object x);
# Methode:
# x = 0.0 -> Ergebnis 0.0
# Ergebnis-Vorzeichen := positiv,
# Ergebnis-Exponent := ceiling(e/2),
# Ergebnis-Mantisse:
#   Bilde aus [1,m22,...,m0,(26 Nullbits)] bei geradem e,
#         aus [0,1,m22,...,m0,(25 Nullbits)] bei ungeradem e
#   die Ganzzahl-Wurzel, eine 25-Bit-Zahl mit einer f?hrenden 1.
#   Runde das letzte Bit weg:
#     Bit 0 = 0 -> abrunden,
#     Bit 0 = 1 und Wurzel exakt -> round-to-even,
#     Bit 0 = 1 und Rest >0 -> aufrunden.
#   Dabei um ein Bit nach rechts schieben.
#   Bei Aufrundung auf 2^24 (rounding overflow) Mantisse um 1 Bit nach rechts
#     schieben und Exponent incrementieren.
  local object FF_sqrt_FF(x)
    var reg3 object x;
    { # x entpacken:
      var reg2 sintWL exp;
      var reg1 uint32 mant;
      FF_decode(x, { return x; }, ,exp=,mant=);
      # Um die 64-Bit-Ganzzahl-Wurzel ausnutzen zu k?nnen, f?gen wir beim
      # Radikanden 39 bzw. 40 statt 25 bzw. 26 Nullbits an.
      if (exp & bit(0))
        # e ungerade
        { mant = mant << (31-(FF_mant_len+1)); exp = exp+1; }
        else
        # e gerade
        { mant = mant << (32-(FF_mant_len+1)); }
      exp = exp >> 1; # exp := exp/2
     {var reg4 boolean exactp;
      #if !(defined(GNU) && defined(MSDOS)) # DJGCC 1.06 und EMX 0.8d st?rzen bei dieser Version ab
      isqrt_64_32(mant,0, mant=,exactp=); # mant := isqrt(mant*2^32), eine 32-Bit-Zahl
      #else
      {var uintD mant0 [64/intDsize];
       #if (intDsize==32) || (intDsize==16) || (intDsize==8)
       set_32_Dptr(mant0,mant); set_32_Dptr(&mant0[32/intDsize],0);
       #else
       {var reg3 uintD* ptr = &mant0[64/intDsize];
        doconsttimes(32/intDsize, { *--ptr = 0; } );
        doconsttimes(32/intDsize, { *--ptr = (uintD)mant; mant = mant>>intDsize; } );
       }
       #endif
       {SAVE_NUM_STACK # num_stack retten
        var DS wurzel;
        UDS_sqrt(&mant0[0],64/intDsize,&mant0[64/intDsize], &wurzel, exactp=);
        # wurzel = isqrt(2^39_40 * mant), eine 32-Bit-Zahl.
        RESTORE_NUM_STACK # num_stack zur?ck
        {var reg3 uintD* ptr = wurzel.MSDptr;
         mant = get_32_Dptr(ptr);
      }}}
      #endif
      # Die hinteren 31-FF_mant_len Bits wegrunden:
      if ( ((mant & bit(30-FF_mant_len)) ==0) # Bit 7 =0 -> abrunden
           || ( ((mant & (bit(30-FF_mant_len)-1)) ==0) # Bit 7 =1 und Bits 6..0 >0 -> aufrunden
                && exactp                   # Bit 7 =1 und Bits 6..0 =0, aber Rest -> aufrunden
                # round-to-even, je nach Bit 8 :
                && ((mant & bit(31-FF_mant_len)) ==0)
         )    )
        # abrunden
        { mant = mant >> (31-FF_mant_len); }
        else
        # aufrunden
        { mant = mant >> (31-FF_mant_len);
          mant += 1;
          if (mant >= bit(FF_mant_len+1)) # rounding overflow?
            { mant = mant>>1; exp = exp+1; }
        }
      encode_FF(0,exp,mant, return);
    }}

# FF_to_I(x) wandelt ein Single-Float x, das eine ganze Zahl darstellt,
# in ein Integer um.
# kann GC ausl?sen
  local object FF_to_I (object x);
# Methode:
# Falls x=0.0, Ergebnis 0.
# Sonst (ASH Vorzeichen*Mantisse (e-24)).
  local object FF_to_I(x)
    var reg4 object x;
    { # x entpacken:
      var reg3 signean sign;
      var reg2 sintWL exp;
      var reg1 uint32 mant;
      FF_decode(x, { return Fixnum_0; }, sign=,exp=,mant=);
      exp = exp-(FF_mant_len+1);
      return I_I_ash_I(
        # mant >0, <2^(FF_mant_len+1) in ein Fixnum umwandeln:
        #if (FF_mant_len+1 <= oint_addr_len)
          (sign==0 ? posfixnum(mant) : negfixnum(-mant))
        #else
          L_to_I(sign==0 ? mant : -mant)
        #endif
        ,L_to_FN(exp)
        );
    }

# I_to_FF(x) wandelt ein Integer x in ein Single-Float um und rundet dabei.
# kann GC ausl?sen
  local object I_to_FF (object x);
# Methode:
# x=0 -> Ergebnis 0.0
# Merke Vorzeichen von x.
# x:=(abs x)
# Exponent:=(integer-length x)
#   Greife die 25 h?chstwertigen Bits heraus (angef?hrt von einer 1).
#   Runde das letzte Bit weg:
#     Bit 0 = 0 -> abrunden,
#     Bit 0 = 1 und Rest =0 -> round-to-even,
#     Bit 0 = 1 und Rest >0 -> aufrunden.
#   Dabei um ein Bit nach rechts schieben.
#   Bei Aufrundung auf 2^24 (rounding overflow) Mantisse um 1 Bit nach rechts
#     schieben und Exponent incrementieren.
  local object I_to_FF(x)
    var reg7 object x;
    { if (eq(x,Fixnum_0)) { return FF_0; }
     {var reg8 signean sign = R_sign(x); # Vorzeichen
      if (!(sign==0)) { x = I_minus_I(x); } # bei x<0: x := (- x)
      {   var reg9 uintL exp = I_integer_length(x); # (integer-length x)
          # NDS zu x>0 bilden:
       {  var reg2 uintD* MSDptr;
          var reg5 uintC len;
          I_to_NDS_nocopy(x, MSDptr=,len=,);
          # MSDptr/len/LSDptr ist die NDS zu x, len>0.
          # F?hrende Digits holen: Brauche FF_mant_len+1 Bits, dazu intDsize
          # Bits (die NDS kann mit bis zu intDsize Nullbits anfangen).
          # Dann werden diese Bits um (exp mod intDsize) nach rechts geschoben.
        { var reg4 uintD msd = *MSDptr++; # erstes Digit
          var reg1 uint32 msdd = 0; # weitere min(len-1,32/intDsize) Digits
          #define NEXT_DIGIT(i)  \
            { if (--len == 0) goto ok;                            \
              msdd |= (uint32)(*MSDptr++) << (32-(i+1)*intDsize); \
            }
          DOCONSTTIMES(32/intDsize,NEXT_DIGIT);
          #undef NEXT_DIGIT
          --len; ok:
          # Die NDS besteht aus msd, msdd, und len weiteren Digits.
          # Das h?chste in 2^32*msd+msdd gesetzte Bit ist Bit Nummer
          # 31 + (exp mod intDsize).
         {var reg6 uintL shiftcount = exp % intDsize;
          var reg3 uint32 mant = # f?hrende 32 Bits
            (shiftcount==0
             ? msdd
             : (((uint32)msd << (32-shiftcount)) | (msdd >> shiftcount))
            );
          # Das h?chste in mant gesetzte Bit ist Bit Nummer 31.
          if ( ((mant & bit(30-FF_mant_len)) ==0) # Bit 7 =0 -> abrunden
               || ( ((mant & (bit(30-FF_mant_len)-1)) ==0) # Bit 7 =1 und Bits 6..0 =0
                    && ((msdd & (bit(shiftcount)-1)) ==0) # und weitere Bits aus msdd =0
                    && (!test_loop_up(MSDptr,len)) # und alle weiteren Digits =0
                    # round-to-even, je nach Bit 8 :
                    && ((mant & bit(31-FF_mant_len)) ==0)
             )    )
            # abrunden
            { mant = mant >> (31-FF_mant_len); }
            else
            # aufrunden
            { mant = mant >> (31-FF_mant_len);
              mant += 1;
              if (mant >= bit(FF_mant_len+1)) # rounding overflow?
                { mant = mant>>1; exp = exp+1; }
            }
          encode_FF(sign,(sintL)exp,mant, return);
    }}}}}}

# RA_to_FF(x) wandelt eine rationale Zahl x in ein Single-Float um
# und rundet dabei.
# kann GC ausl?sen
  local object RA_to_FF (object x);
# Methode:
# x ganz -> klar.
# x = +/- a/b mit Integers a,b>0:
#   Seien n,m so gew?hlt, da?
#     2^(n-1) <= a < 2^n, 2^(m-1) <= b < 2^m.
#   Dann ist 2^(n-m-1) < a/b < 2^(n-m+1).
#   Berechne n=(integer-length a) und m=(integer-length b) und
#   floor(2^(-n+m+25)*a/b) :
#   Bei n-m>=25 dividiere a durch (ash b (n-m-25)),
#   bei n-m<25 dividiere (ash a (-n+m+25)) durch b.
#   Der erste Wert ist >=2^24, <2^26.
#   Falls er >=2^25 ist, runde 2 Bits weg,
#   falls er <2^25 ist, runde 1 Bit weg.
  local object RA_to_FF(x)
    var reg3 object x;
    { if (RA_integerp(x)) { return I_to_FF(x); }
      # x Ratio
      pushSTACK(TheRatio(x)->rt_den); # b
      x = TheRatio(x)->rt_num; # +/- a
     {var reg7 signean sign = R_sign(x); # Vorzeichen
      if (!(sign==0)) { x = I_minus_I(x); } # Betrag nehmen, liefert a
      pushSTACK(x);
      # Stackaufbau: b, a.
      {var reg4 sintL lendiff = I_integer_length(x) # (integer-length a)
                                - I_integer_length(STACK_1); # (integer-length b)
       if (lendiff > FF_exp_high-FF_exp_mid) # Exponent >= n-m > Obergrenze ?
         { fehler_overflow(); } # -> Overflow
       if (lendiff < FF_exp_low-FF_exp_mid-2) # Exponent <= n-m+2 < Untergrenze ?
         { fehler_underflow(); } # -> Underflow
       { var reg5 object zaehler;
         var reg6 object nenner;
         if (lendiff >= FF_mant_len+2)
           # n-m-25>=0
           { nenner = I_I_ash_I(STACK_1,fixnum((uint32)(lendiff - (FF_mant_len+2)))); # (ash b n-m-25)
             zaehler = popSTACK(); # a
             skipSTACK(1);
           }
           else
           { zaehler = I_I_ash_I(popSTACK(),fixnum((uint32)((FF_mant_len+2) - lendiff))); # (ash a -n+m+25)
             nenner = popSTACK(); # b
           }
         # Division zaehler/nenner durchf?hren:
         I_I_divide_I_I(zaehler,nenner);
         # Stackaufbau: q, r.
         # 2^24 <= q < 2^26, also ist q Fixnum oder Bignum mit bn_minlength Digits.
        {var reg1 uint32 mant = ((FF_mant_len+3 <= oint_addr_len)
                                 ? posfixnum_to_L(STACK_1)
                                 : I_to_UL(STACK_1)
                                );
         if (mant >= bit(FF_mant_len+2))
           # 2^25 <= q < 2^26, schiebe um 2 Bits nach rechts
           { var reg2 uint32 rounding_bits = mant & (bit(2)-1);
             lendiff = lendiff+1; # Exponent := n-m+1
             mant = mant >> 2;
             if ( (rounding_bits < bit(1)) # 00,01 werden abgerundet
                  || ( (rounding_bits == bit(1)) # 10
                       && (eq(STACK_0,Fixnum_0)) # und genau halbzahlig (r=0)
                       && ((mant & bit(0)) ==0) # -> round-to-even
                )    )
               # abrunden
               goto ab;
               else
               # aufrunden
               goto auf;
           }
           else
           { var reg2 uintL rounding_bit = mant & bit(0);
             mant = mant >> 1;
             if ( (rounding_bit == 0) # 0 wird abgerundet
                  || ( (eq(STACK_0,Fixnum_0)) # genau halbzahlig (r=0)
                       && ((mant & bit(0)) ==0) # -> round-to-even
                )    )
               # abrunden
               goto ab;
               else
               # aufrunden
               goto auf;
           }
         auf:
         mant += 1;
         if (mant >= bit(FF_mant_len+1)) # rounding overflow?
           { mant = mant>>1; lendiff = lendiff+1; }
         ab:
         skipSTACK(2);
         # Fertig.
         encode_FF(sign,lendiff,mant, return);
    }}}}}

