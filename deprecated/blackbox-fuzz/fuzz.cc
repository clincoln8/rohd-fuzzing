// fuzz.cc
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string>

#include <bitset>

#include <iostream>


#define BUFF_SIZE 1024

std::string formatInput(const uint8_t *Data, size_t Size){
	
	std::string str_fuzzed_input = "";
	
	for (auto p = Data; p < Data+Size; p++){
	  std::string data_byte = std::bitset<8>( *p ).to_string();
	  str_fuzzed_input += data_byte;
	}
	 
	return str_fuzzed_input;

}


extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
	if (Size < 1) return 0;

    std::string executable = "path/to/executable"; // TODO: set path

	std::string inputs = formatInput(Data, Size);

	std::string command = executable + inputs + " 2>&1 1>/dev/null";

	std::cout << command.c_str() << std::endl;

	FILE *p = popen( command.c_str(), "r");

	if(p==NULL){
		printf(">> UNABLE to run command");
	}

	char buffer[BUFF_SIZE];

	if (fgets(buffer, BUFF_SIZE, p) != NULL){
		printf("ERROR 1: %s\n", buffer);
		throw std::runtime_error(buffer);
		return -1;
	} 

	return 0;
}