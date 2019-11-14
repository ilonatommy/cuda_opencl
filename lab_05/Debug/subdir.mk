################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CU_SRCS += \
../main.cu 

OBJS += \
./main.o 

CU_DEPS += \
./main.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.cu
	@echo 'Building file: $<'
	@echo 'Invoking: NVCC Compiler'
	/usr/local/cuda-10.0/bin/nvcc -G -g -O0 -gencode arch=compute_61,code=sm_61  -odir "." -M -o "$(@:%.o=%.d)" "$<"
	/usr/local/cuda-10.0/bin/nvcc -G -g -O0 --compile --relocatable-device-code=false -gencode arch=compute_61,code=compute_61 -gencode arch=compute_61,code=sm_61  -x cu -o  "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


