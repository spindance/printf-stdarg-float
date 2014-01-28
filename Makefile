#
# Copyright (c) 2013 SpinDance Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# ------------------------------------------------------------------------------+-
# make menuconfig
#
# Support integration with projects that use "make menuconfig" for project level
# customization.
#
# The toplevel project Makefile creates a project-wide ".config" file for use
# in lower level projects like this one.  The ".config" file is typically 
# created via "make menuconfig", "make nconfig", or "make alldefconfig".
#
# ------------------------------------------------------------------------------+-

-include $(DOT_CONFIG_FILE)

#
# Define a function to strip quotes from variables defined in .config
#
unquote = $(subst $\",,$1)


ifeq ($(CONFIG_CONFIGURED),y)
    ifeq ($(CONFIG_QUIET_BUILD),y)
        export Q ?= @
    else
        export Q ?= #@
    endif
else
     #
     # Quiet vs. verbose: to make things verbose, put a # in front of the @
     #
     # Quiet:
     # Q = @
     # Verbose:
     # Q = #@
     #
     # When we don't have a command line Q setting
     #   e.g. $ make help Q=@
     # and we don't have a .config file
     #   e.g. $ make nconfig
     #        $ make help
     # we default to a quiet make.
     #
     export Q ?= @
endif


ifeq ($(CONFIG_CONFIGURED),y)

    #
    # CONFIG_CONFIGURED==y when we have a .config file so use it's values
    #
    # Dequote the .config strings before use.  Defines in .config start
    # with CONFIG_
    #
    CROSS_COMPILE ?= $(call unquote,$(CONFIG_CROSS_COMPILE))
    TOOLCHAIN_MCPU_EQ        = $(call unquote,$(CONFIG_TOOLCHAIN_MCPU_EQ))
    TOOLCHAIN_MARCH_EQ       = $(call unquote,$(CONFIG_TOOLCHAIN_MARCH_EQ))
    TOOLCHAIN_MFLOAT_ABI_EQ  = $(call unquote,$(CONFIG_TOOLCHAIN_MFLOAT_ABI_EQ))
    TOOLCHAIN_MFPU_EQ        = $(call unquote,$(CONFIG_TOOLCHAIN_MFPU_EQ))
    TOOLCHAIN_OPTIMISATION   = $(call unquote,$(CONFIG_TOOLCHAIN_OPTIMISATION))

else
    #
    # We don't have .config file so use good defaults
    #
    CROSS_COMPILE           ?= arm-none-eabi-
    TOOLCHAIN_MCPU_EQ        = -mcpu=cortex-m3
    TOOLCHAIN_MARCH_EQ       =
    TOOLCHAIN_MFLOAT_ABI_EQ  =
    TOOLCHAIN_MFPU_EQ        =
    TOOLCHAIN_OPTIMISATION   =

endif

# PROJECT_DIR is the current directory name without the full path
PROJECT_DIR=$(notdir $(CURDIR))

# Convention for where the build detritus ends up
#
# We build a tree of object files (.o) and dependancy files 
# in $(TOP_BUILD_DIR).
#
# The tree matches the structure of the source tree.
#
TOP_BUILD_DIR   = obj/
BUILD_DIR	= $(TOP_BUILD_DIR)$(PROJECT_DIR)/

include makedefs

GIT_REPO_PATH=git@github.com:/spindance/

# Source repostiories

THIS_REPO=printf-stdarg-float

REPO_LIST-y =
REPO_LIST-y += ../$(THIS_REPO)

export REPO_LIST = $(REPO_LIST-y)

# Where we get pieces from...

INCLUDE_DIRS-y += -Iinclude
INCLUDE_DIRS-y += -Isource

# C Source files
SOURCE-y                                     := 
SOURCE-y                                     += source/printf2/printf2.c

SOURCE := $(SOURCE-y)

EXCLUDED_SRC :=

SOURCE := $(filter-out $(EXCLUDED_SRC), $(SOURCE))

# Misc. executables.
RM=/bin/rm
DOXYGEN=/usr/bin/doxygen

#
# The flags passed to the compiler.
#
CFLAGS-y                              = 
CFLAGS-$(CONFIG_TOOLCHAIN_USE_MTHUMB) += "-mthumb"
CFLAGS-y                              += $(TOOLCHAIN_MCPU_EQ)
CFLAGS-y                              += $(TOOLCHAIN_MARCH_EQ)
CFLAGS-y                              += $(TOOLCHAIN_MFLOAT_ABI_EQ)
CFLAGS-y                              += $(TOOLCHAIN_MFPU_EQ)
CFLAGS-y                              += $(TOOLCHAIN_OPTIMISATION)
CFLAGS-y                              += -ffunction-sections
CFLAGS-y                              += -fdata-sections
CFLAGS-y                              += -std=c99
CFLAGS-y                              += -c
CFLAGS-$(CONFIG_TOOLCHAIN_PEDANTIC)   += -pedantic
CFLAGS-$(CONFIG_TOOLCHAIN_WALL)       += -Wall
CFLAGS-$(CONFIG_TOOLCHAIN_VERBOSE)    += --verbose
CFLAGS-$(CONFIG_TOOLCHAIN_DEBUG)      += -g

CFLAGS = $(CFLAGS-y)

CPPFLAGS-y                                    += -D ALIGN_STRUCT_END=__attribute\(\(aligned\(4\)\)\)
CPPFLAGS-y                                    += -D USE_FLOATING_POINT
CPPFLAGS-y                                    += $(INCLUDE_DIRS-y)

CFLAGS += $(CPPFLAGS-y)

OBJS_DIRS = $(sort $(addprefix $(BUILD_DIR), $(dir $SOURCE)))
#
# OBJS_DIRS is a list of the directories needed to recreate
# the source directory tree under the BUILD_DIR directory.
#
DEPS = $(addprefix $(BUILD_DIR), $(SOURCE:.c=.d))
OBJS = $(addprefix $(BUILD_DIR), $(SOURCE:.c=.o))


SEP = '-----------------------------------------------------------------------+-'


.PHONY: all

all: obj/printf2.a
	@# This line prevents warning when nothing to be done for all.

# test printf2 output versus Linux gcc stdio snprintf, printf
.PHONY: runtest
runtest :
	@echo $(SEP)
	@echo "+-- testing printf2 versus Linux gcc stdio snprintf, printf"
	@echo $(SEP)
	@echo "+-- gcc ... -DTEST_PRINTF -DTEST_EXPECTED_OUTPUT ... -o printf2Expected.exe"
	$(Q)gcc -Wall -O2 -DTEST_PRINTF -DTEST_EXPECTED_OUTPUT -s source/printf2/printf2.c -Isource/ -o printf2Expected.exe
	@echo "+-- gcc ... -DTEST_PRINTF ... -o printf2Uut.exe"
	$(Q)gcc -Wall -O2 -DTEST_PRINTF -s source/printf2/printf2.c -Isource/ -o printf2Uut.exe
	@echo "+-- gcc ... -DTEST_PRINTF -DUSE_FLOATING_POINT ... -o printf2UutFloat.exe"
	$(Q)gcc -Wall -O2 -DTEST_PRINTF -DUSE_FLOATING_POINT -s source/printf2/printf2.c -Isource/ -o printf2UutFloat.exe
	@echo "+-- ./printf2Expected.exe outputs:"
	$(Q)./printf2Expected.exe
	@echo "+-- <end-of-output>"
	@echo "+-- ./printf2Uut.exe outputs:"
	$(Q)./printf2Uut.exe
	@echo "+-- <end-of-output>"
	@echo "+-- ./printf2UutFloat.exe outputs:"
	$(Q)./printf2UutFloat.exe
	@echo "+-- <end-of-output>"
	@echo "+-- diff printf2Uut.exe output to printf2Expected output:"
	$(Q)./printf2Expected.exe > expectedOutput.txt
	$(Q)./printf2Uut.exe > uutOutput.txt
	$(Q)if diff uutOutput.txt expectedOutput.txt; then echo "+-- Test Passed."; else echo "+-- Test Failed."; fi
	@echo "+-- diff printf2UutFloat.exe output to printf2Expected output:"
	$(Q)./printf2UutFloat.exe > uutOutputFloat.txt
	$(Q)if diff uutOutputFloat.txt expectedOutput.txt; then echo "+-- Test Passed."; else echo "+-- Test Failed."; fi

ifndef MAKECMDGOALS
-include $(DEPS)
else
ifneq ($(MAKECMDGOALS),$(filter $(MAKECMDGOALS),\
"help repos repostatus \
menuconfig clean distclean config nconfig menuconfig \
oldconfig silentoldconfig savedefconfig allnoconfig allyesconfig \
alldefconfig randconfig listnewconfig olddefconfig "))
#
# Include the dependencies if they are available
# and we are not invoked with one of the targets:
#
# help repos repostatus
# menuconfig clean distclean config nconfig menuconfig oldconfig 
# silentoldconfig savedefconfig allnoconfig allyesconfig alldefconfig randconfig 
# listnewconfig olddefconfig     
#
# .e.g.
#
# make clean
# -or-
# make distclean
#
-include $(DEPS)
endif
endif

obj/printf2.a: $(OBJS)
	@echo "+--$(AR) $@"
	$(Q)$(AR) -rc $@ $^

# automatically generate dependency rules

$(BUILD_DIR)%.d : %.c
	@echo "+--Generating Depenancy $@"
	$(Q)mkdir -p $(dir $@)
	$(Q)$(CC) $(CFLAGS) -MF"$@" -MG -MM -MT"$@" -MT"$(@:.d=.o)" "$<"

#
# -MF  write the generated dependency rule to a file
# -MG  assume missing headers will be generated and don't stop with an error
# -MM  generate dependency rule for prerequisite, skipping system headers
# -MP  add phony target for each header to prevent errors when header is missing
# -MT  add a target to the generated dependency
# 
# "$@" is the target (the thing on the left side of the : )
# "$<" is the prerequisite (the thing on the right side of the : ). 
# The expression "$(<:.c=.o)" replaces the .c extension with .o.
#
# The trick here is to generate the rule with two targets by adding -MT twice; 
# this makes both the .o file and the .d file depend on the source file 
# and its headers; that way the dependency file gets automatically regenerated 
# whenever any of the corresponding .c or .h files are changed.
#
# The -MG and -MP options keep make from freaking out if a header file is missing.
#
# We've removed the -MP option to keep make from infinite looping within the
# dependency generation.
#

.PHONY: repostatus
repostatus :
	$(Q) for r in $${REPO_LIST}; do cd $${r}; echo "==============="; pwd; git status; done

.PHONY: repos
repos : $(REPO_LIST)

$(REPO_LIST) :
	cd .. && git clone $(GIT_REPO_PATH)$(notdir $@).git


.PHONY: doxygen
doxygen :
	$(DOXYGEN) doxygen.cfg

.PHONY: clean
clean :
ifneq ($(strip $(TOP_BUILD_DIR)),)
	@echo $(SEP)
	@echo "+--printf-stdarg-float library clean"
	@echo $(SEP)
	$(RM) -f printf2Expected.exe
	$(RM) -f printf2Uut.exe
	$(RM) -f printf2UutFloat.exe
	$(RM) -f expectedOutput.txt
	$(RM) -f uutOutput.txt
	$(RM) -f uutOutputFloat.txt
	$(RM) -fr $(TOP_BUILD_DIR)*
else
	$(Q)echo "TOP_BUILD_DIR is not defined or empty, can't clean."
endif

.PHONY: distclean
distclean : clean
	@echo $(SEP)
	@echo "+--printf-stdarg-float library distclean"
	@echo $(SEP)
	find . -name "*~" -exec rm -f {} \;
	find . -name "*.o" -exec rm -f {} \;

.PHONY: help
help :
	$(Q)echo ""
	$(Q)echo "make help             - Print this message."
	$(Q)echo ""
	$(Q)echo "make repos            - git clone required brother repositories to \"cd ..\""
	$(Q)echo "make                  - Build the executable software"
	$(Q)echo ""
	$(Q)echo "make runtest          - Test printf2 versus Linux gcc stdio snprintf, printf"
	$(Q)echo ""
	$(Q)echo "make all              - Build the executable software - same as \"make\""
	$(Q)echo "make clean            - Clean build products"
	$(Q)echo "make distclean        - Clean to repository distribution clean. Removes .config and autoconf.h"
	$(Q)echo ""
	$(Q)echo "make repostatus       - Show the git status of the repos in the project."
