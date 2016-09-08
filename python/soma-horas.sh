#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os, sys
import datetime
from datetime import timedelta

BHCR=list(range(1,15))
BHDB=list(range(1,15))

for dia in range(1,3):
	min=int(raw_input("BHCR : "))
	BHCR[dia]=datetime.timedelta(minutes=min)
	min=int(raw_input("BHDB : "))
	BHDB[dia]=datetime.timedelta(minutes=min)

	
TotalBHCR=datetime.timedelta(minutes=0)
TotalBHDB=datetime.timedelta(minutes=0)
for dia in range(1,3):
	TotalBHCR=TotalBHCR+BHCR[dia]
	TotalBHDB=TotalBHDB+BHDB[dia]


print (TotalBHCR )
print (TotalBHDB )

