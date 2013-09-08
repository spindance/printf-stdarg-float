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

#
# make menuconfig 
#
# will make .config
#

-include .config

#
# Define a function to strip quotes from variables defined in .config
#
unquote = $(subst $\",,$1)

#
# Dequote the .config strings before use.  Defines in .config start
# with CONFIG_
#
export CROSS_COMPILE ?= $(call unquote,$(CONFIG_CROSS_COMPILE))

#PART inserted back in Makefile for compatibility with gvb/quickstart
# longterm we'd like to move from PART.

export PART = $(call unquote,$(CONFIG_MCU_PART))
PROG = $(call unquote,$(CONFIG_MCU))_EVB
export TOOLCHAIN_MTHUMB         = $(call unquote,$(CONFIG_TOOLCHAIN_MTHUMB))
export TOOLCHAIN_MCPU_EQ        = $(call unquote,$(CONFIG_TOOLCHAIN_MCPU_EQ))
export TOOLCHAIN_MARCH_EQ       = $(call unquote,$(CONFIG_TOOLCHAIN_MARCH_EQ))
export TOOLCHAIN_MFLOAT_ABI_EQ  = $(call unquote,$(CONFIG_TOOLCHAIN_MFLOAT_ABI_EQ))
export TOOLCHAIN_MFPU_EQ        = $(call unquote,$(CONFIG_TOOLCHAIN_MFPU_EQ))
export TOOLCHAIN_PEDANTIC	= $(call unquote,$(CONFIG_TOOLCHAIN_PEDANTIC))
export TOOLCHAIN_WARNINGS       = $(call unquote,$(CONFIG_TOOLCHAIN_WARNINGS))
export TOOLCHAIN_VERBOSE	= $(call unquote,$(CONFIG_TOOLCHAIN_VERBOSE))
export TOOLCHAIN_OPTIMISATION   = $(call unquote,$(CONFIG_TOOLCHAIN_OPTIMISATION))
export TOOLCHAIN_DEBUG_FLAGS    = $(call unquote,$(CONFIG_TOOLCHAIN_DEBUG_FLAGS))


ifeq ($(CONFIG_CONFIGURED),y)
    ifeq ($(CONFIG_QUIET_BUILD),y)
        export Q ?= @
    else
        export Q ?= #@
    endif
else
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
CPPFLAGS-y                                    += $(INCLUDE_DIRS-y)

CFLAGS += $(CPPFLAGS-y)

OBJS_DIRS = $(sort $(addprefix $(BUILD_DIR), $(dir $SOURCE)))
#
# OBJS_DIRS is a list of the directories needed to recreate
# the source directory tree under the BUILD_DIR directory.
#
DEPS = $(addprefix $(BUILD_DIR), $(SOURCE:.c=.d))
OBJS = $(addprefix $(BUILD_DIR), $(SOURCE:.c=.o))

.PHONY: all

ifeq ($(CONFIG_CONFIGURED),y)

all: obj/printf2.a

ifndef MAKECMDGOALS
-include $(DEPS)
else
ifneq ($(MAKECMDGOALS),$(filter $(MAKECMDGOALS),\
"help repos repostatus \
menuconfig clean distclean config nconfig menuconfig \
oldconfig silentoldconfig savedefconfig allnoconfig allyesconfig \
alldefconfig randconfig listnewconfig olddefconfig"))
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

else

all:
	$(Q)echo ""
	$(Q)echo "No .config file. Program is not configured."
	$(Q)echo ""
	$(Q)echo "execute:"
	$(Q)echo ""
	$(Q)echo "make nconfig"
	$(Q)echo "make"
	$(Q)echo ""

endif


# Configuration targets will make .config and autoconf.h from $(Kconfig)

ifdef KBUILD_KCONFIG
Kconfig := $(KBUILD_KCONFIG)
else
Kconfig := Kconfig
endif

.PHONY: menuconfig
menuconfig: scripts/mkconfig/mkconfig
	$(Q)CONFIG_=CONFIG_ kconfig-mconf $(Kconfig)
	$(Q)scripts/mkconfig/mkconfig ./ > include/generated/autoconf.h

.PHONY: config
config: scripts/mkconfig/mkconfig
	$(Q)CONFIG_=CONFIG_ kconfig-conf --oldaskconfig $(Kconfig)
	$(Q)scripts/mkconfig/mkconfig ./ > include/generated/autoconf.h

.PHONY: nconfig
nconfig: scripts/mkconfig/mkconfig
	$(Q)CONFIG_=CONFIG_ kconfig-nconf $(Kconfig)
	$(Q)scripts/mkconfig/mkconfig ./ > include/generated/autoconf.h

.PHONY: oldconfig silentoldconfig allnoconfig allyesconfig alldefconfig randconfig
.PHONY: olddefconfig oldnoconfig
oldconfig silentoldconfig allnoconfig allyesconfig alldefconfig randconfig olddefconfig oldnoconfig: scripts/mkconfig/mkconfig 
	$(Q)CONFIG_=CONFIG_ kconfig-conf --$@ $(Kconfig)
	$(Q)scripts/mkconfig/mkconfig ./ > include/generated/autoconf.h

.PHONY: listnewconfig
listnewconfig:
	$(Q)CONFIG_=CONFIG_ kconfig-conf --$@ $(Kconfig)

.PHONY: savedefconfig
savedefconfig:
	$(Q)CONFIG_=CONFIG_ kconfig-conf --$@=defconfig $(Kconfig)

scripts/mkconfig/mkconfig: scripts/mkconfig/mkconfig.c
	$(Q)gcc scripts/mkconfig/mkconfig.c scripts/mkconfig/cfgparser.c scripts/mkconfig/cfgdefine.c -o scripts/mkconfig/mkconfig

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
	$(RM) -fr $(TOP_BUILD_DIR)*
else
	$(Q)echo "TOP_BUILD_DIR is not defined or empty, can't clean."
endif

.PHONY: distclean
distclean : clean
	$(RM) -f include/generated/autoconf.h
	$(RM) -f scripts/mkconfig/mkconfig
	$(RM) -f .config
	$(RM) -f .config.old
	find . -name "*~" -exec rm -f {} \;
	find . -name "*.o" -exec rm -f {} \;

.PHONY: help
help :
	$(Q)echo ""
	$(Q)echo "make help             - Print this message."
	$(Q)echo ""
	$(Q)echo "make repos            - git clone required brother repositories to \"cd ..\""
	$(Q)echo "make menuconfig       - Update current config to create a .config and autoconf.h"
	$(Q)echo "make                  - Build the executable software"
	$(Q)echo ""
	$(Q)echo "make all              - Build the executable software - same as \"make\""
	$(Q)echo "make clean            - Clean build products"
	$(Q)echo "make distclean        - Clean to repository distribution clean. Removes .config and autoconf.h"
	$(Q)echo ""
	$(Q)echo "Configuration options in addition to make menuconfig:"
	$(Q)echo ""
	$(Q)echo "make config           - Update current config utilising a line-oriented program"
	$(Q)echo "make nconfig          - Update current config utilising a ncurses menu based program"
	$(Q)echo "make menuconfig       - Update current config utilising a menu based program"
	$(Q)echo "make oldconfig        - Update current config utilising a provided .config as base"
	$(Q)echo "make silentoldconfig  - Same as oldconfig, but quietly, additionally update deps"
	$(Q)echo "make savedefconfig    - Save current config as ./defconfig (minimal config)"
	$(Q)echo "make allnoconfig      - New config where all options are answered with no"
	$(Q)echo "make allyesconfig     - New config where all options are accepted with yes"
	$(Q)echo "make alldefconfig     - New config with all symbols set to default"
	$(Q)echo "make randconfig       - New config with random answer to all options"
	$(Q)echo "make listnewconfig    - List new options"
	$(Q)echo "make olddefconfig     - Same as silentoldconfig but sets new symbols to their default value"
	$(Q)echo ""
	$(Q)echo "make repostatus       - Show the git status of the repos in the project."
