#!/usr/bin/python
# -*- encoding: UTF-8 -*-

import os

class pessoa:
    def __init__(self,nome,cpf,data):
        self.nome = nome
        self.cpf = cpf
        self.data = data

Nicolas = pessoa("Nícolas","908680634401990","24-07-1986")

print(Nicolas.data)
