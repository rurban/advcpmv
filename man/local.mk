# Make advcpmv man pages.				-*-Makefile-*-
# This is included by the top-level Makefile.am.

# Copyright (C) 2002-2019 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

EXTRA_DIST += man/help2man man/dummy-man

## Use the distributed man pages if cross compiling or lack perl
if CROSS_COMPILING
run_help2man = $(SHELL) $(srcdir)/man/dummy-man
else
## Graceful degradation for systems lacking perl.
if HAVE_PERL
run_help2man = $(PERL) -- $(srcdir)/man/help2man
else
run_help2man = $(SHELL) $(srcdir)/man/dummy-man
endif
endif

man1_MANS = @man1_MANS@
EXTRA_DIST += $(man1_MANS) $(man1_MANS:.1=.x)

EXTRA_MANS = @EXTRA_MANS@
EXTRA_DIST += $(EXTRA_MANS) $(EXTRA_MANS:.1=.x)

ALL_MANS = $(man1_MANS) $(EXTRA_MANS)

MAINTAINERCLEANFILES += $(ALL_MANS)

# This is a kludge to remove generated 'man/*.1' from a non-srcdir build.
# Without this, "make distcheck" might fail.
distclean-local:
	test x$(srcdir) = x$(builddir) || rm -f $(ALL_MANS)

# Dependencies common to all man pages.  Updated below.
mandeps =

# Depend on this to get version number changes.
mandeps += .version

# This is required so that changes to e.g., emit_bug_reporting_address
# provoke regeneration of all the manpages.
mandeps += $(top_srcdir)/src/system.h

$(ALL_MANS): $(mandeps)

man/cp.1:        src/cp$(EXEEXT)
man/mv.1:        src/mv$(EXEEXT)

.x.1:
	$(AM_V_GEN)name=`echo $@ | sed 's|.*/||; s|\.1$$||'` || exit 1;	\
## Ensure that help2man runs the 'src/ginstall' binary as 'install' when
## creating 'install.1'.  Similarly, ensure that it uses the 'src/[' binary
## to create 'test.1'.
	case $$name in							\
	  install) prog='ginstall'; argv=$$name;;			\
	     test) prog='['; argv='[';;					\
		*) prog=$$name; argv=$$prog;;				\
	esac;								\
## Note the use of $$t/$*, rather than just '$*' as in other packages.
## That is necessary to avoid failures for programs that are also shell
## built-in functions like echo, false, printf, pwd.
	rm -f $@-t							\
	  && t=$*.td							\
	  && rm -rf $$t							\
	  && $(MKDIR_P) $$t						\
	  && (cd $$t && $(LN_S) '$(abs_top_builddir)/src/'$$prog$(EXEEXT) \
				$$argv$(EXEEXT))			\
	  || exit 1;							\
## Double-check whether the built binary succeeds with --help as the above
## CROSS_COMPILING condition might have been wrong in some cases, e.g. when
## building against an incompatible glibc version on the same platform.
	$$t/$$argv$(EXEEXT) --help </dev/null >/dev/null		\
	  && run_help2man="$(run_help2man)"				\
	  || run_help2man="$(srcdir)/man/dummy-man";			\
	: $${SOURCE_DATE_EPOCH=`cat $(srcdir)/.timestamp 2>/dev/null || :`} \
	&& : $${TZ=UTC0} && export TZ					\
	&& export SOURCE_DATE_EPOCH && $${run_help2man}			\
		     --source='$(PACKAGE_STRING)'			\
		     --include=$(srcdir)/man/$$name.x			\
		     --output=$$t/$$name.1				\
		     --info-page='\(aq(coreutils) '$$name' invocation\(aq' \
		     $$t/$$argv$(EXEEXT)				\
	  && sed \
	       -e 's|$*\.td/||g' \
	       -e '/For complete documentation/d' \
	       $$t/$$name.1 > $@-t			\
	  && rm -rf $$t							\
	  && chmod a-w $@-t						\
	  && rm -f $@ && mv $@-t $@
