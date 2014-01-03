/*******************************************************************************
 Copyright 2001, 2002 Georges Menie (<URL snipped>)
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

/*******************************************************************************
 putchar is the only external dependency for this file, 
 if you have a working putchar, just remove the following
 define. If the function should be called something else,
 replace outbyte(c) by your own function call.
 */
//*******************************************************************************
//  Updated by Daniel D Miller.  Changes to the original Menie code are
//  Copyright 2009-2013 Daniel D Miller
//  All such changes are distributed under the same license as the original,
//  as described above.
//  11/06/09 - adding floating-point support
//  03/19/10 - pad fractional portion of floating-point number with 0s
//  03/30/10 - document the \% bug
//  07/20/10 - Fix a round-off bug in floating-point conversions
//             ( 0.99 with %.1f did not round to 1.0 )
//  10/25/11 - Add support for %+ format (always show + on positive numbers)
//  05/10/13 - Add stringfn() function, which takes a maximum-output-buffer
//             length as an argument.  Similar to snprintf()
//*******************************************************************************
//  BUGS
//  If '%' is included in a format string, in the form \% with the intent
//  of including the percent sign in the output string, this function will
//  mis-handle the data entirely!!  
//  Essentially, it will just discard the character following the percent sign.  
//  This bug is not easy to fix in the existing code; 
//  for now, I'll just try to remember to use %% instead of \% ...
//*******************************************************************************
//  compile command for stand-alone mode (TEST_PRINTF)
//  gcc -Wall -O2 -DTEST_PRINTF -s printf2.c -o printf2.exe
//*******************************************************************************
//*******************************************************************************
//  Updated by SpinDance Inc.  Changes to the original Menie code are
//  Copyright 2013 SpinDance Inc.
//  All such changes are distributed under the same license as the original,
//  as described above.
//  09/07/13 - Removed references to USE_INTERNALS.
//  09/07/13 - Use a standard strlen.
//  09/18/13 - Added stringfnp().
//*******************************************************************************

//lint -esym(752, debug_output)
//lint -esym(766, stdio.h)

// #define  TEST_PRINTF    1

#include <string.h>
#include "printf2/printf2.h"

#ifdef TEST_PRINTF
#include <stdio.h>
extern int putchar (int c);
#endif

#if USE_FLOATING_POINT
#define FLOAT_OR_DOUBLE float
#else
#define FLOAT_OR_DOUBLE double
#endif

//lint -e534  Ignoring return value of function 
//lint -e539  Did not expect positive indentation from line ...
//lint -e525  Negative indentation from line ...

typedef  unsigned char  u8 ;
typedef  unsigned int   uint ;


//****************************************************************************
static void printchar (char **str, int c, unsigned int max_output_len, int *cur_output_char_p)
{
    if (max_output_len >= 0  &&  *cur_output_char_p >= max_output_len)
        return ;
    if (str) {
        **str = (char) c;
        ++(*str);
        (*cur_output_char_p)++ ;
    }
#ifdef TEST_PRINTF
    else {
        (*cur_output_char_p)++ ;
        (void) putchar (c);
    }
#endif
}

//****************************************************************************
//  This version returns the length of the output string.
//  It is more useful when implementing a walking-string function.
//****************************************************************************
//lint -esym(728, round_nums)
static const FLOAT_OR_DOUBLE round_nums[8] = {
        0.5,
        0.05,
        0.005,
        0.0005,
        0.00005,
        0.000005,
        0.0000005,
        0.00000005
} ;

static unsigned fltordbl2stri(char *outbfr, FLOAT_OR_DOUBLE flt_or_dbl, unsigned dec_digits, int use_leading_plus)
{
    static char local_bfr[128] ;
    char *output = (outbfr == 0) ? local_bfr : outbfr ;

    //*******************************************
    //  extract negative info
    //*******************************************
    if (flt_or_dbl < 0.0) {
        *output++ = '-' ;
        flt_or_dbl *= -1.0 ;
    } else {
        if (use_leading_plus) {
            *output++ = '+' ;
        }

    }

    //  handling rounding by adding .5LSB to the floating-point data
    if (dec_digits < 8) {
        flt_or_dbl += round_nums[dec_digits] ;
    }

    //**************************************************************************
    //  construct fractional multiplier for specified number of digits.
    //**************************************************************************
    uint mult = 1 ;
    uint idx ;
    for (idx=0; idx < dec_digits; idx++)
        mult *= 10 ;

    // printf("mult=%u\n", mult) ;
    uint wholeNum = (uint) flt_or_dbl ;
    uint decimalNum = (uint) ((flt_or_dbl - wholeNum) * mult);

    //*******************************************
    //  convert integer portion
    //*******************************************
    char tbfr[40] ;
    idx = 0 ;
    while (wholeNum != 0) {
        tbfr[idx++] = '0' + (wholeNum % 10) ;
        wholeNum /= 10 ;
    }
    // printf("%.3f: whole=%s, dec=%d\n", dbl, tbfr, decimalNum) ;
    if (idx == 0) {
        *output++ = '0' ;
    } else {
        while (idx > 0) {
            *output++ = tbfr[idx-1] ;  //lint !e771
            idx-- ;
        }
    }
    if (dec_digits > 0) {
        *output++ = '.' ;

        //*******************************************
        //  convert fractional portion
        //*******************************************
        idx = 0 ;
        while (decimalNum != 0) {
            tbfr[idx++] = '0' + (decimalNum % 10) ;
            decimalNum /= 10 ;
        }
        //  pad the decimal portion with 0s as necessary;
        //  We wouldn't want to report 3.093 as 3.93, would we??
        while (idx < dec_digits) {
            tbfr[idx++] = '0' ;
        }
        // printf("decimal=%s\n", tbfr) ;
        if (idx == 0) {
            *output++ = '0' ;
        } else {
            while (idx > 0) {
                *output++ = tbfr[idx-1] ;
                idx-- ;
            }
        }
    }
    *output = 0 ;

    //  prepare output
    output = (outbfr == 0) ? local_bfr : outbfr ;

    return strlen(output) ;
}

//****************************************************************************
#define  PAD_RIGHT   1
#define  PAD_ZERO    2

static int prints (char **out, const char *string, int width, int pad, unsigned int max_output_len, int *cur_output_char_p)
{
    register int pc = 0, padchar = ' ';
    if (width > 0) {
        int len = 0;
        const char *ptr;
        for (ptr = string; *ptr; ++ptr)
            ++len;
        if (len >= width)
            width = 0;
        else
            width -= len;
        if (pad & PAD_ZERO)
            padchar = '0';
    }
    if (!(pad & PAD_RIGHT)) {
        for (; width > 0; --width) {
            printchar (out, padchar, max_output_len, cur_output_char_p);
            ++pc;
        }
    }
    for (; *string; ++string) {
        printchar (out, *string, max_output_len, cur_output_char_p);
        ++pc;
    }
    for (; width > 0; --width) {
        printchar (out, padchar, max_output_len,cur_output_char_p);
        ++pc;
    }
    return pc;
}

//****************************************************************************
/* the following should be enough for 32 bit int */
#define PRINT_BUF_LEN 12
static int printi (char **out, int i, uint base, int sign, int width, int pad, int letbase, unsigned int max_output_len, int *cur_output_char_p, int use_leading_plus)
{
    char print_buf[PRINT_BUF_LEN];
    char *s;
    int t, neg = 0, pc = 0;
    unsigned u = (unsigned) i;
    if (i == 0) {
        print_buf[0] = '0';
        print_buf[1] = '\0';
        return prints (out, print_buf, width, pad, max_output_len, cur_output_char_p);
    }
    if (sign && base == 10 && i < 0) {
        neg = 1;
        u = (unsigned) -i;
    }
    //  make sure print_buf is NULL-term
    s = print_buf + PRINT_BUF_LEN - 1;
    *s = '\0';

    while (u) {
        t = u % base;  //lint !e573 !e737 !e713 Warning 573: Signed-unsigned mix with divide
        if (t >= 10)
            t += letbase - '0' - 10;
        *--s = (char) t + '0';
        u /= base;  //lint !e573 !e737  Signed-unsigned mix with divide
    }
    if (neg) {
        if (width && (pad & PAD_ZERO)) {
            printchar (out, '-', max_output_len, cur_output_char_p);
            ++pc;
            --width;
        }
        else {
            *--s = '-';
        }
    } else {
        if (use_leading_plus) {
            *--s = '+';
        }
    }
    return pc + prints (out, s, width, pad, max_output_len, cur_output_char_p);
}

//****************************************************************************
static int print (char **out, unsigned int max_output_len, int *varg)
{
    int post_decimal ;
    int width, pad ;
    unsigned dec_width = 6 ;
    int pc = 0;
    char *format = (char *) (*varg++);
    char scr[2];
    int cur_output_char = 0;
    int *cur_output_char_p = &cur_output_char;
    int use_leading_plus = 0 ;  //  start out with this clear

    for (; *format != 0; ++format) {
        if (*format == '%') {
            dec_width = 6 ;
            ++format;
            width = pad = 0;
            if (*format == '\0')
                break;
            if (*format == '%')
                goto out_lbl;
            if (*format == '-') {
                ++format;
                pad = PAD_RIGHT;
            }
            if (*format == '+') {
                ++format;
                use_leading_plus = 1 ;
            }
            while (*format == '0') {
                ++format;
                pad |= PAD_ZERO;
            }
            post_decimal = 0 ;
            if (*format == '.'  ||
                    (*format >= '0' &&  *format <= '9')) {

                while (1) {
                    if (*format == '.') {
                        post_decimal = 1 ;
                        dec_width = 0 ;
                        format++ ;
                    } else if ((*format >= '0' &&  *format <= '9')) {
                        if (post_decimal) {
                            dec_width *= 10;
                            dec_width += (uint) (u8) (*format - '0');
                        } else {
                            width *= 10;
                            width += *format - '0';
                        }
                        format++ ;
                    } else {
                        break;
                    }
                }
            }
            if (*format == 'l')
                ++format;
            switch (*format) {
            case 's':
            {
                // char *s = *((char **) varg++);   //lint !e740
                char *s = (char *) *varg++ ;  //lint !e740 !e826
                pc += prints (out, s ? s : "(null)", width, pad, max_output_len, cur_output_char_p);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
            }
            break;
            case 'd':
                pc += printi (out, *varg++, 10, 1, width, pad, 'a', max_output_len, cur_output_char_p, use_leading_plus);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
                break;
            case 'x':
                pc += printi (out, *varg++, 16, 0, width, pad, 'a', max_output_len, cur_output_char_p, use_leading_plus);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
                break;
            case 'X':
                pc += printi (out, *varg++, 16, 0, width, pad, 'A', max_output_len, cur_output_char_p, use_leading_plus);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
                break;
            case 'p':
            case 'u':
                pc += printi (out, *varg++, 10, 0, width, pad, 'a', max_output_len, cur_output_char_p, use_leading_plus);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
                break;
            case 'c':
                /* char are converted to int then pushed on the stack */
                scr[0] = (char) *varg++;
                scr[1] = '\0';
                pc += prints (out, scr, width, pad, max_output_len, cur_output_char_p);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
                break;

            case 'f':
            {
                // http://wiki.debian.org/ArmEabiPort#Structpackingandalignment
                // Stack alignment
                //
                // The ARM EABI requires 8-byte stack alignment at public function entry points,
                // compared to the previous 4-byte alignment.
#ifdef USE_NEWLIB
                char *cptr = (char *) varg;  //lint !e740 !e826  convert to double pointer
                uint caddr = (uint) cptr;
                if ((caddr & 0xF) != 0) {
                    cptr += 4;
                }
                FLOAT_OR_DOUBLE *flt_or_dbl_ptr = (FLOAT_OR_DOUBLE *) cptr;  //lint !e740 !e826  convert to float pointer
#else
                if (((int)varg & 0x4) != 0) {
                    varg++;
                }
                double *flt_or_dbl_ptr = (double *)varg;  //lint !e740 !e826  convert to float pointer
                varg += 2;
#endif
                double d = *(double *)flt_or_dbl_ptr;
                FLOAT_OR_DOUBLE flt_or_dbl = d;
                char bfr[81];
                fltordbl2stri(bfr, flt_or_dbl, dec_width, use_leading_plus);
                pc += prints (out, bfr, width, pad, max_output_len, cur_output_char_p);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
            }
            break;

            default:
                printchar (out, '%', max_output_len, cur_output_char_p);
                printchar (out, *format, max_output_len, cur_output_char_p);
                use_leading_plus = 0 ;  //  reset this flag after printing one value
                break;
            }
        } else
            // if (*format == '\\') {
            //
            // } else
        {
            out_lbl:
            printchar (out, *format, max_output_len, cur_output_char_p);
            ++pc;
        }
    }  //  for each char in format string
    if (out && (pc >= max_output_len)){
        (*out)--;
        **out = '\0';
    } else if (out) {
        **out = '\0';
    }
    return pc;
}

//****************************************************************************
//  assuming sizeof(void *) == sizeof(int)
//  This function is not valid in embedded projects which don't
//  have a meaningful stdout device.
//****************************************************************************
#ifdef TEST_PRINTF
int termf (const char *format, ...)
{
    int *varg = (int *) (char *) (&format);
    return print (0, -1, varg);
}  //lint !e715
#endif

//****************************************************************************
//  assuming sizeof(void *) == sizeof(int)
//  This function is not valid in embedded projects which don't
//  have a meaningful stdout device.
//****************************************************************************
#ifdef TEST_PRINTF
int termfn(uint max_len, const char *format, ...)
{
    int *varg = (int *) (char *) (&format);
    return print (0, max_len, varg);
}  //lint !e715
#endif

//****************************************************************************
int stringf (char *out, const char *format, ...)
{
    //  create a pointer into the stack.
    //  Thematically this should be a void*, since the actual usage of the
    //  pointer will vary.  However, int* works fine too.
    //  Either way, the called function will need to re-cast the pointer
    //  for any type which isn't sizeof(int)
    int *varg = (int *) (char *) (&format);
    return print (&out, -1, varg);
}

//****************************************************************************
//lint -esym(714, stringfn)
//lint -esym(759, stringfn)
//lint -esym(765, stringfn)
int stringfn(char *out, unsigned int max_len, const char *format, ...)
{
    //  create a pointer into the stack.
    //  Thematically this should be a void*, since the actual usage of the
    //  pointer will vary.  However, int* works fine too.
    //  Either way, the called function will need to re-cast the pointer
    //  for any type which isn't sizeof(int)
    int *varg = (int *) (char *) (&format);
    return print (&out, max_len, varg);
}

//****************************************************************************
int stringfnp(char *out, unsigned int max_len, const char *format, int * argPtr)
{
    return print (&out, max_len, argPtr);
}


//****************************************************************************
#ifdef TEST_PRINTF
int main (void)
{
    int slen ;
    char *ptr = "Hello world!";
    char *np = 0;
    char buf[128];
    char buf2[10];

    stringfn(buf2, 10, "0123456789") ;   // Only 9 chars should be displayed
    termf ("%s", buf2);
    termf ("\n");
    termf ("ptr=%s, %s is null pointer, char %c='a'\n", ptr, np, 'a');
    termf ("hex %x = ff, hex02=%02x\n", 0xff, 2);   //  hex handling
    termf ("signed %d = %uU = 0x%X\n", -3, -3, -3);   //  int formats
    termf ("%d %s(s) with %%\n", 0, "message");

    slen = stringf (buf, "justify: left=\"%-10s\", right=\"%10s\"\n", "left", "right");
    termf ("[len=%d] %s", slen, buf);

    stringf(buf, "     padding (pos): zero=[%04d], left=[%-4d], right=[%4d]\n", 3, 3, 3) ;
    termf ("%s", buf);

    //  test walking string builder
    slen = 0 ;
    slen += stringf(buf+slen, "padding (neg): zero=[%04d], ", -3) ;   //lint !e845
    slen += stringf(buf+slen, "left=[%-4d], ", -3) ;
    slen += stringf(buf+slen, "right=[%4d]\n", -3) ;
    termf ("[%d] %s", slen, buf);

#ifdef USE_FLOATING_POINT
    termf("+ format: int: %+d, %+d, float: %+.1f, %+.1f, reset: %d, %.1f\n", 3, -3, 3.0f, -3.0f, 3, 3.0);
    stringf (buf, "%.3f is a float, %.2f is with two decimal places\n", 3.345f, 3.345f);
    termf ("%s", buf);
    termf("\n");
#else // USE_DOUBLES
    termf("+ format: int: %+d, %+d, double: %+.1f, %+.1f, reset: %d, %.1f\n", 3, -3, 3.0, -3.0, 3, 3.0);
    stringf (buf, "%.3f is a double, %.2f is with two decimal places\n", 3.345, 3.345);
    termf ("%s", buf);
#endif

    stringf (buf, "multiple unsigneds: %u %u %2u %X\n", 15, 5, 23, 0xB38F) ;
    termf ("%s", buf);

    stringf (buf, "multiple chars: %c %c %c %c\n", 'a', 'b', 'c', 'd') ;
    termf ("%s", buf);

#ifdef USE_FLOATING_POINT
    termf("\nFloats:\n");
    stringf (buf, "multiple floats: %f %.1f %2.0f %.2f %.3f %.2f [%-8.3f]\n",
            3.45f, 3.93f, 2.45f, -1.1f, 3.093f, 13.72f, -4.382f) ;
    termf ("%s", buf);
    stringf (buf, "float special cases: %f %.f %.0f %2f %2.f %2.0f\n",
            3.14159f, 3.14159f, 3.14159f, 3.14159f, 3.14159f, 3.14159f) ;
    termf ("%s", buf);
    stringf (buf, "rounding floats: %.1f %.1f %.3f %.2f [%-8.3f]\n",
            3.93f, 3.96f, 3.0988f, 3.999f, -4.382f) ;
    termf ("%s", buf);
#else // USE_DOUBLES
    termf("\nDoubles:\n");
    stringf (buf, "multiple doubles: %f %.1f %2.0f %.2f %.3f %.2f [%-8.3f]\n",
            3.45, 3.93, 2.45, -1.1, 3.093, 13.72, -4.382) ;
    termf ("%s", buf);
    stringf (buf, "double special cases: %f %.f %.0f %2f %2.f %2.0f\n",
            3.14159, 3.14159, 3.14159, 3.14159, 3.14159, 3.14159) ;
    termf ("%s", buf);
    stringf (buf, "rounding doubles: %.1f %.1f %.3f %.2f [%-8.3f]\n",
            3.93, 3.96, 3.0988, 3.999, -4.382) ;
    termf ("%s", buf);
#endif
    termf("\n");

    termfn(20, "%s", "no more than 20 bytes of this string should be displayed!");
    termf ("\n");
    stringfn(buf, 25, "only 25 buffered bytes should be displayed from this string") ;
    termf ("%s", buf);
    termf ("\n");

    //  test case from our Yagarto ARM9 problem
    // char *cmd = "adc_vref " ;
    // float fvalue = 3.30 ;
    // stringf (buf, "%s%.2f", cmd, (double) fvalue);
    // printf("%s\n", buf);

    return 0;
}
#endif

