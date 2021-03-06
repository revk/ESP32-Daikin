#
# This is a project Makefile. It is assumed the directory this Makefile resides in is a
# project subdirectory.
#

PROJECT_NAME := Daikin
SUFFIX := $(shell components/ESP32-RevK/buildsuffix)
MODELS := Daikin

all:	tools
	@echo Make: $(PROJECT_NAME)$(SUFFIX).bin
	@idf.py build
	@cp build/$(PROJECT_NAME).bin $(PROJECT_NAME)$(SUFFIX).bin
	@echo Done: $(PROJECT_NAME)$(SUFFIX).bin

tools:	faikin daikinlog daikingraph

set:    wroom solo pico

pico:
	components/ESP32-RevK/setbuildsuffix -S1-PICO
	@make

wroom:
	components/ESP32-RevK/setbuildsuffix -S1
	@make

solo:
	components/ESP32-RevK/setbuildsuffix -S1-SOLO
	@make

flash:
	idf.py flash

monitor:
	idf.py monitor

clean:
	idf.py clean
	rm */*.o

menuconfig:
	idf.py menuconfig

pull:
	git pull
	git submodule update --recursive

update:
	git submodule update --init --recursive --remote

# Program the FTDI
ftdi: ftdizap/ftdizap
	./ftdizap/ftdizap --serial="RevK" --description="Daikin" --cbus2-mode=17 --self-powered=1

PCBCase/case: PCBCase/case.c
	make -C PCBCase

ifeq ($(shell uname),Darwin)
INCLUDES=-I/usr/local/include/
LIBS=-L/usr/local/Cellar/popt/1.18/lib/
else
LIBS=
INCLUDES=
endif

SQLlib/sqllib.o: SQLlib/sqllib.c
	make -C SQLlib
AXL/axl.o: AXL/axl.c
	make -C AXL
AJL/ajl.o: AJL/ajl.c
	make -C AJL

SQLINC=$(shell mariadb_config --include)
SQLLIB=$(shell mariadb_config --libs)
SQLVER=$(shell mariadb_config --version | sed 'sx\..*xx')
CCOPTS=${SQLINC} -I. -I/usr/local/ssl/include -D_GNU_SOURCE -g -Wall -funsigned-char -lm
OPTS=-L/usr/local/ssl/lib ${SQLLIB} ${CCOPTS}

faikin: faikin.c
	gcc -O -o $@ $< -lpopt ${INCLUDES} ${LIBS}

daikinlog: daikinlog.c SQLlib/sqllib.o AJL/ajl.o main/acextras.m main/acfields.m main/accontrols.m
	cc -O -o $@ $< -lpopt -lmosquitto -ISQLlib SQLlib/sqllib.o -IAJL AJL/ajl.o ${OPTS}

daikingraph: daikingraph.c SQLlib/sqllib.o AXL/axl.o
	cc -O -o $@ $< -lpopt -lmosquitto -ISQLlib SQLlib/sqllib.o -IAXL AXL/axl.o -lcurl ${OPTS}

scad:	$(patsubst %,KiCad/%.scad,$(MODELS))
stl:	$(patsubst %,KiCad/%.stl,$(MODELS))

%.stl: %.scad
	echo "Making $@"
	/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD $< -o $@
	echo "Made $@"

KiCad/Daikin.scad: KiCad/Daikin.kicad_pcb PCBCase/case Makefile
	PCBCase/case -o $@ $< --edge=2 --base=2.5

