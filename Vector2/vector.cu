#include <iostream>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "vector.h"

#define checkCudaError(status) { \
	if(status != cudaSuccess) { \
		std::cout << "CUDA Error " << __FILE__ << ", " << __LINE__ \
			<< ": " << cudaGetErrorString(status) << "\n"; \
		exit(-1); \
	} \
}

__global__ void vecAdd(int * a, int * b, int * c, int size, int k) {

	//ADD CODE HERE
	int i = threadIdx.x;
	int j = blockIdx.x*blockDim.x*k;
	for(int count =0 ; count < k; count++){
		c[i*k + j + count] = a[i*k + j +count] + b[i*k + j + count];
	}
}

void print_help_and_exit(void) {
    printf("Vector CUDA ASS [OPTIONS]\n");
    printf("  -k K\t\tAdditions per thread.\n");
    printf("  -t B\t\tThreads per block less than or equal to 1024.\n");
    printf("  -b S\t\tNo. of blocks.\n");
    printf("  -v V\t\tVector size.\n");
    exit(0);
}

int main(int argc, char *argv[]) {

	int opt;
    uint64_t k = DEFAULT_K;
    uint64_t t = DEFAULT_T;
    uint64_t bl =DEFAULT_B;
    uint64_t v = DEFAULT_V;

    /* Read arguments */ 
    while(-1 != (opt = getopt(argc, argv, "k:t:b:v:h"))) {
        switch(opt) {
        case 'k':
            k = atoi(optarg);
            break;
        case 't':
            t = atoi(optarg);
            break;
        case 'b':
            bl = atoi(optarg);
            break;
        case 'v':
            v = atoi(optarg);
            break;
        case 'h':
            /* Fall through */
        default:
            print_help_and_exit();
            break;
        }
    }

    

	//checkCudaError(cudaSetDevice(1));
	int device;
	checkCudaError(cudaGetDevice(&device));
	cudaDeviceProp prop;
	checkCudaError(cudaGetDeviceProperties(&prop, device));
	//std::cout << "Device " << device << ": " << prop.name << "\n";
	//std::cout << "GPU/SM Cores: " << prop.multiProcessorCount << "\n";
	//std::cout << "Warp Size: " << prop.warpSize << "\n";
	//std::cout << "Max threads per block: " << prop.maxThreadsPerBlock << "\n";
	//std::cout << "Max ThreadsDim, x: " << prop.maxThreadsDim[0] << ", y: " <<  prop.maxThreadsDim[1] << ", z: " <<  prop.maxThreadsDim[2] << "\n";	
	//std::cout << "Max GridSize, x: " << prop.maxGridSize[0] << ", y: " <<  prop.maxGridSize[1] << ", z: " <<  prop.maxGridSize[2] << "\n";	
	//std::cout << "Total Global Memory: " << (prop.totalGlobalMem>>30) << "TB" << "\n";
	//std::cout << "Shared Memory per Block: " << (prop.sharedMemPerBlock>>10) << "\n";
	//std::cout << "Compute Capability: " << prop.major << "." << prop.minor << "\n";
	

	const uint64_t CTA_SIZE = t;
	const uint64_t THREAD_ADDITIONS = k;
	const uint64_t size = v;
	uint64_t TEMP_GRID_SIZE = size/CTA_SIZE/THREAD_ADDITIONS;
	if(TEMP_GRID_SIZE != bl){
		bl = TEMP_GRID_SIZE;
	}
	const uint64_t GRID_SIZE = bl;
	printf("Vector Add Settings\n");
	std::cout << "Threads per Block\t: " << CTA_SIZE << "\n";
	std::cout << "Thread Block Num\t: " << GRID_SIZE << "\n";
	std::cout << "Additions per block\t: " << THREAD_ADDITIONS << "\n";
	std::cout << "Vector Size\t\t: " << size << "\n";
	
	
	int * a, * b, * c;
	int * dev_a, * dev_b, * dev_c;

	a = (int *) malloc (sizeof(int) * size);
	b = (int *) malloc (sizeof(int) * size);
	c = (int *) malloc (sizeof(int) * size);
	if(!a || !b || !c) {
		std::cout << "Error: out of memory\n";
		exit(-1);
	}

	for(int i = 0; i < size; i++) {
		a[i] = i;
		b[i] = i+1;
	}
	memset(c, 0, sizeof(int) * size);

	checkCudaError(cudaMalloc(&dev_a, sizeof(int) * size));
	checkCudaError(cudaMalloc(&dev_b, sizeof(int) * size));	
	checkCudaError(cudaMalloc(&dev_c, sizeof(int) * size));	
	
	checkCudaError(cudaMemcpy(dev_a, a, sizeof(int) * size, cudaMemcpyHostToDevice));
	checkCudaError(cudaMemcpy(dev_b, b, sizeof(int) * size, cudaMemcpyHostToDevice));
	checkCudaError(cudaMemset(dev_c, 0, sizeof(int) * size));
	
	cudaEvent_t startEvent, stopEvent;
	float elapsedTime;
	
	
	cudaEventCreate(&startEvent,0 );
	cudaEventCreate(&stopEvent, 0);
	cudaEventRecord(startEvent,0);
	
	vecAdd<<<GRID_SIZE, CTA_SIZE>>>(dev_a, dev_b, dev_c, size,THREAD_ADDITIONS);
	cudaEventRecord(stopEvent,0);
	cudaEventSynchronize(stopEvent);
	cudaEventElapsedTime(&elapsedTime, startEvent, stopEvent);
	checkCudaError(cudaDeviceSynchronize());
	
	checkCudaError(cudaMemcpy(c, dev_c, sizeof(int) * size, cudaMemcpyDeviceToHost));

	for(int i = 0; i < size; i++) {
//		std::cout << i << ": " << c[i] << "\n";
		if(c[i] != i*2+1) {
			std::cout << "Error: c[" << i << "] != " <<
				i*2+1 << "but is: "<< c[i] <<"\n";
			exit(-1);
		}
	}
	std::cout << "Status\t\t\t: Pass\n";
	std::cout << "----- Elapsed Time: " << elapsedTime << " -----" << "\n";
}