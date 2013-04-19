COMMON_CFLAGS =			\
	-Wno-long-long -Wall    \
	$(THIS_CFLAGS)

if LIBMARY_PLATFORM_DEFAULT
    # For backtraces
    COMMON_CFLAGS += -rdynamic
endif

AM_CFLAGS   += -std=gnu99 $(COMMON_CFLAGS)
AM_CXXFLAGS += $(COMMON_CFLAGS)

INCLUDES = -I$(top_srcdir)

EXTRA_DIST =	\
	temporal_id_generator.h

lectoriumdir = $(libdir)/moment-1.0
lectorium_LTLIBRARIES = libmoment-lectorium-1.0.la
libmoment_lectorium_1_0_la_SOURCES =	\
	temporal_id_generator.cpp	\
					\
	lectorium.cpp

libmoment_lectorium_1_0_la_LDFLAGS = -no-undefined -version-info "0:0:0"
libmoment_lectorium_1_0_la_LIBADD = $(THIS_LIBS)

