#ifndef CACHESIM_H
#define CACHESIM_H


#include <inttypes.h>

static const uint64_t DEFAULT_K = 1;   			/* 	1 Addition per thread	*/
static const uint64_t DEFAULT_T = 32;			/* 	32 threads per block	*/
static const uint64_t DEFAULT_B = 64;			/* 	64 thread blocks 		*/
static const uint64_t DEFAULT_V = (1<<24);		/* 	16MB vector size 		*/


#endif /* CACHESIM_H */
