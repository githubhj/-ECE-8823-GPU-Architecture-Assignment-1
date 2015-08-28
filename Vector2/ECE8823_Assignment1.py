#!/usr/bin/python

import os
import subprocess
from optparse import OptionParser
import sys
import logging
import csv
import datetime

def myCsvWriter(writer,headerList,List):
    tempDict = {}
    for index,eachHeading in enumerate(headerList):
        if (index + 1) > len(List):
            tempDict[eachHeading] = "NA"
        else:
            tempDict[eachHeading] = List[index]
            
    writer.writerow(tempDict)

def main():
    parser = OptionParser()
    parser.add_option("--exe", dest="exe", 
                        default=None,
                        type="string",
                        help="(Oprional) CUDA Executable.")
    parser.add_option("--minadd", dest="minAdd", 
                        default=0,
                        type="int",
                        help="(Required) Minimum (power of 2) additions per thread. Default: 0")
    parser.add_option("--maxadd", dest="maxAdd", 
                        default=10,
                        type="int",
                        help="(Required) Maximum (power of 2) additions per thread. Default: 10")
    parser.add_option("--mintnum", dest="minThreadNum", 
                        default=5,#1MB
                        type="int",
                        help="(Optional) Minimum (power of 2), threads per block. Default: 5")
    parser.add_option("--maxtnum", dest="maxThreadNum", 
                        default=10,#1MB
                        type="int",
                        help="(Optional) Maximum (power of 2) threads per block. Default: 10")
    
    options, args = parser.parse_args()
    if(options.exe==None):
        parser.print_help()
        sys.exit(1)
    
    logging.basicConfig(level=logging.DEBUG, format='%(message)s')
    
    exe = os.path.expanduser(options.exe)
    if os.path.isfile(exe)==False:
        print"Error: CUDA executable not present"
        sys.exit(1)
    
    threadAddList = [2**i for i in range(options.minAdd,options.maxAdd+1)]
    threadList = [2**i for i in range(options.minThreadNum,options.maxThreadNum+1)]
    
    timeStamp = datetime.datetime.now().strftime("%H-%M_%m-%d-%Y")
    csvFileName = os.getcwd() + "/Log_" + timeStamp + ".csv"
    csvFile = open(csvFileName,'w')
    headerList = ["S. No.", "Number of Threads per Block", "Additions per thread", "Time(ms)"]
    writer = csv.DictWriter(csvFile,fieldnames=headerList)
    headerDict = {}
    for n in headerList:
        headerDict[n] = n
    writer.writerow(headerDict)
    
    threadDictList = {}
    logging.debug("\n\n-------------------------------------------------")
    logging.debug("(Debug Log:)\t Starting Executing CUDA executable.")
    for index1,threadNum in enumerate(threadList):  
        timeDict={}
        logging.debug("\n\n(Debug Log:)\t Threads per block: %d.\n",threadNum)
        for index2,threadAddition in enumerate(threadAddList):
            cudacmd = [exe, "-k", str(threadAddition), "-t",str(threadNum)]
            cuda = subprocess.Popen(cudacmd, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            cudaout=cuda.communicate()
            for line in cudaout:
                if(line.rfind("----- Elapsed Time:")!=-1):
                    words = line.split(" ")
                    time = words[-2]
                    timeDict[threadAddition] = time
                    logging.debug("(Debug Log:)\t Thread Additions: %d",threadAddition)
                    logging.debug("(Debug Log:)\t Time: %s\n",time)
                    myCsvWriter(writer, headerList, [((index1+1)*(index2+1)),threadNum,threadAddition,time])
        logging.debug("-------------------------------------------------")        
                    
            
    threadDictList[threadNum] = timeDict
    print threadDictList    

if __name__ == "__main__":main()
