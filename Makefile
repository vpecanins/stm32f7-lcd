#
# Makefile for STM32F7 Discovery projects, using a similar structure 
# that in STM32 Cube package.
#
# Directory structure:
#
# Project root
# |
# +-- Build:	Compiled files go here
# |
# +-- Config:	Config files for openocd, ldscripts and startup code. Do not touch.
# |
# +-- Drivers:	STM32Cube libraries
# |
# +-- Inc:      Headers for application code
# |
# +-- Src:      Source code for application (main.c)
# |
# +-- Utilities LCD Fonts, etc
#
# Commands:
#
#	make			Compile project
#	make program	Burn program to STM32 using OpenOCD
#	make clean		Remove compiled files
#

# Build environment
SHELL = /bin/bash
MAKE = make

# Path to GCC_ARM_NONE_EABI toolchain
# GCC_ARM_NONE_EABI_PATH = ~/STM32Toolchain/gcc-arm-none-eabi-5_2-2015q4/bin
GCC_ARM_NONE_EABI_PATH = /usr/bin
CC = $(GCC_ARM_NONE_EABI_PATH)/arm-none-eabi-gcc
AR = $(GCC_ARM_NONE_EABI_PATH)/arm-none-eabi-ar
OBJCOPY = $(GCC_ARM_NONE_EABI_PATH)/arm-none-eabi-objcopy
OBJDUMP = $(GCC_ARM_NONE_EABI_PATH)/arm-none-eabi-objdump
SIZE = $(GCC_ARM_NONE_EABI_PATH)/arm-none-eabi-size

# OPENOCD Executable path
OPENOCD_DIR = /usr/local/bin

# Configuration (cfg) file containing programming directives for OpenOCD
OPENOCD_PROC_FILE=stm32f7.cfg

# project parameters
PROJ_NAME = main
BSP_NAME = STM32746G-Discovery
CPU_FAMILY = STM32F7xx
CPU_MODEL_GENERAL = STM32F746xx

INCLUDEDIRS =
INCLUDEDIRS += ./Inc
INCLUDEDIRS += ./Drivers/BSP/$(BSP_NAME)
INCLUDEDIRS += ./Drivers/HAL/Inc
INCLUDEDIRS += ./Drivers/CMSIS/Include
INCLUDEDIRS += ./Drivers/CMSIS/Device/ST/$(CPU_FAMILY)/Include
INCLUDEDIRS += $(wildcard ./Drivers/BSP/Components/*)
INCLUDEDIRS += ./Utilities/Log

INCLUDEDIRS += ./Config

LIBSOURCES = 
LIBSOURCES += $(wildcard ./Drivers/HAL/Src/*.c)
LIBSOURCES += $(wildcard ./Drivers/BSP/$(BSP_NAME)/*.c)
LIBSOURCES += $(wildcard ./Drivers/BSP/Components/*/*.c)
LIBSOURCES += ./Utilities/Log/lcd_log.c

LIBOBJS = $(LIBSOURCES:.c=.o) 

# Workaround
STUBS_SRC = ./Utilities/Log/stubs.c
STUBS_OBJ = $(STUBS_SRC:.c=.o)

# Project specific sources
SOURCES = $(shell find ./Src -name *.c)

# Add assembly startup template & config files
SOURCES += ./Config/startup_stm32f746xx.s 
SOURCES += $(wildcard ./Config/*.c)
OBJ1 = $(SOURCES:.c=.o)
OBJ = $(OBJ1:.s=.o)

# LDscript for linking for STM32F7 (From STM32 CUBE)
LDSCRIPT = ./Config/ldscripts/STM32F746NGHx_FLASH.ld

# GCC flags
CFLAGS = -Wall -g -std=c99 -Os -D $(CPU_MODEL_GENERAL) -include stm32f7xx_hal_conf.h -Werror-implicit-function-declaration
CFLAGS += -mlittle-endian -mcpu=cortex-m7 -mthumb -DARM_MATH_CM7
CFLAGS += -ffunction-sections -fdata-sections 
CFLAGS += -Wl,--gc-sections -Wl,-Map=Build/$(PROJ_NAME).map 
CFLAGS +=  $(addprefix -I ,$(INCLUDEDIRS)) 

# Static libraries
CLIBS =  -L ./Build 
CLIBS +=  -lgcc -lm -lc -lg -lstm32f7

BUILD_PRINT = @echo -e "\e[1;32mBuilding $<\e[0m"

.PHONY: all

all: proj

proj: libstm32f7.a  Build/$(PROJ_NAME).elf

libstm32f7.a: $(LIBOBJS)
	$(BUILD_PRINT)
	$(AR) -r Build/$@ $(LIBOBJS)

%.o: %.c
	@echo
	$(BUILD_PRINT)
	$(CC) -c -o $@ $< $(CFLAGS)

Build/$(PROJ_NAME).elf: $(SOURCES) $(STUBS_OBJ)
	@echo
	$(BUILD_PRINT)
	$(CC) -Os $(CFLAGS) $^ -o $@ $(CLIBS) -T $(LDSCRIPT) -MD 
	$(OBJCOPY) -O ihex Build/$(PROJ_NAME).elf Build/$(PROJ_NAME).hex
	$(OBJCOPY) -O binary Build/$(PROJ_NAME).elf Build/$(PROJ_NAME).bin
	$(OBJDUMP) -St Build/$(PROJ_NAME).elf >Build/$(PROJ_NAME).lst
	$(SIZE) Build/$(PROJ_NAME).elf

program: proj
	$(OPENOCD_DIR)/openocd -f board/stm32f7discovery.cfg -f $(OPENOCD_PROC_FILE) -s ./Config -c "stm_flash `pwd`/Build/$(PROJ_NAME).bin" -c shutdown

openocd:
	$(OPENOCD_DIR)/openocd -f board/stm32f7discovery.cfg -f $(OPENOCD_PROC_FILE) -s ./Config

clean:
	rm $(LIBOBJS) || true
	rm Build/libstm32f7.a || true
	rm Build/$(PROJ_NAME).elf || true
	rm Build/$(PROJ_NAME).hex || true
	rm Build/$(PROJ_NAME).bin || true
	rm Build/$(PROJ_NAME).map || true
	rm Build/$(PROJ_NAME).lst || true
	rm Build/$(PROJ_NAME).d || true
