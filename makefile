LIBR = ./library    #A variable that will hold a string of the library in the current directory

VPATH = $(LIBR)/edison_source $(LIBR)/EasyBMP pedro $(LIBR)/permutohedral $(LIBR) .  #Specifies the directories for prerequisites and uses the $() reference to get the direct address

SHELL = /bin/sh   #instantiates the shell that will be used to call commands

FILTER=./main.cpp ./entry.cpp ./segproc.cpp  #specified file names to be filtered out

#MODULES := EasyBMP edison_source/prompt edison_source/segm edison_source/edge permutohedral dcm dcm/dcmtk/config dcm/dcmtk/dcmdata dcm/dcmtk/dcimage dcm/dcmtk/dcmimgle dcm/dcmtk/libsrc dcm/dcmtk/ofstd .  #other_cpp edison_source/prompt edison_source/segm edison_source/edge .
MODULES := $(LIBR)/EasyBMP $(LIBR)/pedro $(LIBR)/edison_source/prompt $(LIBR)/edison_source/segm $(LIBR)/edison_source/edge $(LIBR)/permutohedral $(LIBR) .  #Specifies all the directories that can be used for the making targets
all : a.out   #this specifies the targets that will be built
.PHONY : all clean savecode  #will ignore a file if it exists

LIBS = -lm -ljpeg -ltiff -lpng -lpthread #-lfltk #This specifies the libraries that will be used when compiling the target

#pre-processor flags
CPPFLAGS =   #would be where you would put any flags for CPP files

CXXFLAGS = -I/usr/local/include -I/usr/include/libpng15 -I/usr/local/X11  #a variable that stores the specified flags for CXX files at compilation

CXXFLAGS += $(patsubst %, -I%, $(MODULES))  #adds the modules variable to the include statements in The CXXFLAGS variable

CXX = g++ -Wall --std=c++17 -O3  #g++ compiles the code, -Wall activates certain warnings, --std=c++17 tells the versions of c++ to compile, and -O3 turns on all optimizers
#CXX = g++ -Wall --std=c++11 -g -fbounds-check

COMPILE = $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c #references all 3 of the above commands and stores them in compile and -c tells it to not run the linker

LD = $(CXX) #does the same thing to the CXX variable 1 command up, but is used seperately for the linking library

LDFLAGS = -O3 -Wl,-R -Wl,$(shell pwd) -L. #flags used for LD, -O3 for optimizers, -Wl passes comma separated options to LD, -R passes filename unless it is in a directory, in which case it will be the -rpath option.

OBJS := $(patsubst %.cpp, %.o, $(filter-out $(FILTER), $(wildcard $(patsubst %, %/*.cpp, $(MODULES))) )  )  #this one is huge and will take a few lines
#OBJS is being defined here by multiple statements which can be broken down
#below are the broken down definitions

#SRCS := $(filter-out $(FILTER), $(wildcard $(patsubst %, %/*.cpp, $(MODULES))))

#OBJS := $(patsubst %.cpp, %.o, $(SRCS))

#HDRS := $(wildcard $(patsubst %, %/*.h, $(MODULES)))

#a.out:	$(OBJS)
#	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@

#a.out: libmslearn.so main.o
#	$(LD) $(LDFLAGS1) $(word 2,$^) -o $@

a.out: libmslearn.so main.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(patsubst lib%.so,-l%,$<) $(word 2,$^) -o $@   
	#This is a rule that creates a file named after the target
	#The possible targets are (CXX), CXXFLAGS, LDFLAGS, and 2 more targets
	#The 4th possible target is one that has the string replaced partially to be just -mslearn
	#The 5th possible target is going to be from the second word to the shell's use of caret
	#the $@ at the end names the a.out file to be the same as whatever target was used
	#

-include $(OBJS:.o=.d)
#suspends the reading of the makefile to read other makefiles if any of the objects are not found, but does not throw errors

libmslearn.so.0.0.1 : $(OBJS)
	$(LD) $(LDFLAGS) $^ -shared -Wl,-soname,$@ $(LIBS) -o $@
	#an implicit rule that looks at LD, LDFLAGS, or whatever the last target was, and then -shared makes a shared object file, 
	#-Wl passes comma seperated objects, -soname gives the target a name which $@ makes the name be the last target found.


libmslearn.so.0: libmslearn.so.0.0.1  #a rule where libmslearn.so.0.0.1 is a prerequisite
	rm -f $@  #force removes the file name of the target
	ln -s $< $@  #symbolically links the target and the prereq

libmslearn.so: libmslearn.so.0  #a rule where libmslearn.so.0 is a prerequisite
	rm -f $@  #force removes the file name of the target
	ln -s $< $@  #symbolically links the target and the prereq

#one makefile per cpp file | is the unix pipe
#this is done to generate prerequisites automatically
%.d : %.cpp  #tells make how to obtain a .d file given a corresponding .cpp file 
	set -e; rm -f $@; \  #set -e tells the shell to exit, force removes the .d file, and then continues onto the next line if the shell fails
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< | \  #The below action will be sent to one of targets, -MM will prevent going to system headers
	sed 's,\($(*F)\)\.o[ :]*,$(*D)/\1.o $@ : ,g' > $@; \ 

%.o : %.cpp
	$(COMPILE) -fPIC -o $@ $<

clean :
	rm -f $(OBJS) libmslearn.so.0.0.1 libmslearn.so.0 libmslearn.so
	rm -f $(OBJS:.o=.d)

savecode :
	tar cvzf tarball.tgz .
