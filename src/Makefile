#
#  makefile for adjust - Linux - gfortran compiler
#  "makefile.linux - 1.0 - 2021/01/21"
#---------------------------------------------------------
FROOT    = 
FC       = gfortran 

.SUFFIXES: .for

# Production
# FFLAGS   =
# Testing and Development
FFLAGS   = -g -fbounds-check -Wall

.for.o  :
	$(FC) $(FFLAGS) $(INCLUDES) -c $<
#-------------------------------------
PGM      = adjust

INCLUDES = \
  -I. 

HEADERS  = \

LIBS     =

OBJECTS  = \
  adjust.o  \
  afvc.o    \
  cmrhs2.o  \
  ezyplot.o \
  getofil_ux.o \
  hogk.o    \
  mods.o    \
  newhog.o  \
  newsubs.o \
  obseqw.o  \
  rgps2.o   \
  rnneu.o   \
  subs1.o   \
  subs2.o   \
  sysdep_g77.o \
  tolgh2.o  \
  upcov.o   \
  vfcgps.o  \


#-------------------------------------
$(PGM)  :  $(OBJECTS)
	$(FC) $(FFLAGS) -o $@  $(OBJECTS) $(LIBS)

%.for.o:

clean:
	rm -f *.o $(PGM)

