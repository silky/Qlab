"""
#Create set of pulses for single qubit randomized benchmarking sequence. 

Created on Tue Feb 07 15:01:37 2012

@authors: Colm Ryan and Marcus Silva
"""
import numpy as np
from scipy.linalg import expm
from scipy.constants import pi

from functools import reduce
from itertools import permutations

import csv

def memoize(function):
	cache = {}
	def decorated(*args):
		if args not in cache:
			cache[args] = function(*args)
		return cache[args]
	return decorated

@memoize
def clifford_multiply(C1, C2):
    '''
    Multiplication table for single qubit cliffords.  Note this assumes C1 is applied first. 
    '''
    tmpMult = np.dot(Cliff[C2],Cliff[C1])
    checkArray = np.array([np.abs(np.trace(np.dot(tmpMult.transpose().conj(),Cliff[x]))) for x in range(24)])
    return checkArray.argmax()


#Number of gates that we want
gateLengths = 2**np.arange(2,7)

#Number of randomizations
numRandomizations = 32

#Single qubit paulis
X = np.array([[0, 1],[1, 0]])
Y = np.array([[0, -1j],[1j, 0]])
Z = np.array([[1, 0],[0, -1]]);
I = np.eye(2)

#Basis Cliffords
Cliff = {}
Cliff[0] = I
Cliff[1] = expm(-1j*(pi/4)*X)
Cliff[2] = expm(-2j*(pi/4)*X)
Cliff[3] = expm(-3j*(pi/4)*X)
Cliff[4] = expm(-1j*(pi/4)*Y)
Cliff[5] = expm(-2j*(pi/4)*Y)
Cliff[6] = expm(-3j*(pi/4)*Y)
Cliff[7] = expm(-1j*(pi/4)*Z)
Cliff[8] = expm(-2j*(pi/4)*Z)
Cliff[9] = expm(-3j*(pi/4)*Z)
Cliff[10] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X+Y))
Cliff[11] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X-Y))
Cliff[12] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X+Z))
Cliff[13] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(X-Z))
Cliff[14] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(Y+Z))
Cliff[15] = expm(-1j*(pi/2)*(1/np.sqrt(2))*(Y-Z))
Cliff[16] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(X+Y+Z))
Cliff[17] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(X+Y+Z))
Cliff[18] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(X-Y+Z))
Cliff[19] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(X-Y+Z))
Cliff[20] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(X+Y-Z))
Cliff[21] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(X+Y-Z))
Cliff[22] = expm(-1j*(pi/3)*(1/np.sqrt(3))*(-X+Y+Z))
Cliff[23] = expm(-2j*(pi/3)*(1/np.sqrt(3))*(-X+Y+Z))

#Map each of the Cliffords to its inverse
inverseMap = [0, 3, 2, 1, 6, 5, 4, 9, 8, 7, 10, 11, 12, 13, 14, 15, 17, 16, 19, 18, 21, 20, 23, 22]

#Pulses that we can apply
generatorPulses = [0, 1, 3, 4, 6, 2, 2, 5, 5]
#A function that returns the string corresponding to a generator (randomly chooses between Xp and Xm for X)
def generatorString(G):
    generatorStrings = {0:('QId',), 1:('X90p',), 3:('X90m',), 4:('Y90p',), 6:('Y90m',), 2:('Xp','Xm'), 5:('Yp','Ym')}
    tmpString = generatorStrings[G]
    return tmpString[np.random.randint(0, len(tmpString))]

#Get all generator sequences up to length four TODO: why do we need 4?
generatorSeqs = [x for x in permutations(generatorPulses,1)] + \
                [x for x in permutations(generatorPulses,2)] + \
		[x for x in permutations(generatorPulses,3)] + \
		[x for x in permutations(generatorPulses,4)] 

#Find the effective unitary for each generator sequence
reducedSeqs = np.array([ reduce(clifford_multiply,x) for x in generatorSeqs ])

#Pick first generator sequence (and thus shortest) that gives each Clifford
shortestSeqs = [np.nonzero(reducedSeqs==x)[0][0] for x in range(24)]

#Mean number of generators
meanNumGens = np.mean([len(generatorSeqs[shortestSeqs[ct]]) for ct in range(24)])
print('Mean number of generators per Clifford is {0}'.format(meanNumGens))

#Generate random sequences
randomSeqs = [np.random.randint(0,24, (gateLength-1)).tolist() for gateLength in gateLengths for ct in range(numRandomizations) ] 

#For each sequence calculate inverse and the X sequence and append the final Clifford
randomISeqs = []
randomXSeqs = []
for tmpSeq in randomSeqs:
    totalCliff = reduce(clifford_multiply, tmpSeq)
    inverseCliff = inverseMap[totalCliff]
    inverseCliffX = clifford_multiply(inverseCliff, 2)
    randomISeqs.append(tmpSeq + [inverseCliff])
    randomXSeqs.append(tmpSeq + [inverseCliffX])    
    
#Each Clifford corresponds to a sequence of generators pulses we can apply so convert from sequences of Clifford numbers to generator strings
#For each sequences of numbers create a list of strings: for each Clifford gate convert each generator in the generator sequence to a string
IpulseSeqs = [[generatorString(tmpGenCliff) for tmpCliff in tmpSeq for tmpGenCliff in generatorSeqs[shortestSeqs[tmpCliff]] ] for tmpSeq in randomISeqs]
XpulseSeqs = [[generatorString(tmpGenCliff) for tmpCliff in tmpSeq for tmpGenCliff in generatorSeqs[shortestSeqs[tmpCliff]] ] for tmpSeq in randomXSeqs]

#Write out the files now
with open('RB_ISeqs.txt','wt') as ISeqFID:
    writer = csv.writer(ISeqFID)
    writer.writerows(IpulseSeqs)

with open('RB_XSeqs.txt','wt') as XSeqFID:
    writer = csv.writer(XSeqFID)
    writer.writerows(XpulseSeqs)





    

    
    
        
    