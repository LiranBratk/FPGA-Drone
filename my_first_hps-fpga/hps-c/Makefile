# This is the name of the binaries that will be generated
TARGET                  = OUTPUT
 
# The device family (soc_cv_av = Cyclone V   ;   soc_a10 = Aria 10)
ALT_DEVICE_FAMILY       = soc_cv_av
 
# Some paths (Default should work)
HWLIBS_ROOT             = D:\intelFPGA_lite\18.1\embedded\ip\altera\hps\altera_hps\hwlib
 
# Here we add all *.c files that we want to compile
CSRCS                   = main.c
 
# Here we add all *.cpp files that we want to compile
CPPSRCS                 =
 
# Here we add the paths to all include directories
INCS                    =

# Parameters for SCP upload. Set up SSH keys to bypass password prompt
SCP_TARGET_IP           = 192.168.1.100
SCP_USER                = root
SCP_TARGET_PATH         = /home/root
SCP                     = SCP
SCP_FLAGS               =
 
# Compiler settings
ARCH                    = arm-linux-gnueabihf
LD                      = $(ARCH)-g++
CC                      = $(ARCH)-gcc
CPPC                    = $(ARCH)-g++
SIZE                    = $(ARCH)-size
CFLAGS                  = -g -std=gnu99 -Wall
CPPFLAGS                = -g -std=c++11 -Wall
LDFLAGS                 = -g -Wall
 
################################################################################
# Don't change anything below this line                                        #
################################################################################
 
# Some directory and file magic
BUILDDIR                = build
OBJDIR                  = $(BUILDDIR)/obj
 
# Generate the object names
OBJS                    = $(addprefix $(OBJDIR)/,$(addsuffix .o,$(basename $(CSRCS:%.c=%.o))))
OBJS                    += $(addprefix $(OBJDIR)/,$(addsuffix .o,$(basename $(CPPSRCS:%.cpp=%.o))))
 
# Add some paths
CFLAGS                  += $(INCS:%=-I%) -I$(HWLIBS_ROOT)/include -I$(HWLIBS_ROOT)/include/$(ALT_DEVICE_FAMILY) -D$(ALT_DEVICE_FAMILY)
CPPFLAGS                += $(INCS:%=-I%) -I$(HWLIBS_ROOT)/include -I$(HWLIBS_ROOT)/include/$(ALT_DEVICE_FAMILY) -D$(ALT_DEVICE_FAMILY)
LDFLAGS                 += $(INCS:%=-I%)
 
# This is the default target if the user does just calls 'make'
all: build size
 
# Build all the files
build: builddirs $(BUILDDIR)/$(TARGET)
 
# Create the required directories (if not already existing)
builddirs:
	@mkdir -p $(BUILDDIR)
	@mkdir -p $(OBJDIR)
 
# Link everything together
$(BUILDDIR)/$(TARGET): $(OBJS)
	@echo Linking $@
	@$(LD) $(LDFLAGS) -o $(BUILDDIR)/$(TARGET) $(OBJS)
 
# Compile c files
$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo Compiling $^
	@$(CC) $(CFLAGS) -c -o $@ $^
 
# Compile cpp files
$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	@echo Compiling $^
	@$(CPPC) $(CPPFLAGS) -c -o $@ $^
 
# Print size information
size: $(BUILDDIR)/$(TARGET)
	@echo
	@echo
	$(SIZE) $^
 
# Clean up
clean:
	@rm -rf $(BUILDDIR) $(OBJS) $(TARGET) $(TARGET).* *.a *.o *~
	@echo Done
 
# Clean must be a phony target so make knows this never exists as a file
.PHONY: clean
 
# Upload to target
upload:
	$(SCP) $(SCP_FLAGS) $(BUILDDIR)/$(TARGET) $(SCP_USER)@$(SCP_TARGET_IP):$(SCP_TARGET_PATH)