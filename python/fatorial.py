#!/usr/bin/python
# -*- encoding:utf-8 -*-

num=int(raw_input("Digite um numero: "))
fat=int(1)
for i in range(1,(num+1)):
    fat *= i

print(fat ) 
