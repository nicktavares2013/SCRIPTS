#!/usr/bin/python
# -*- conding: UTF-8 -*-

class Cartas:
	def __init__(self, naipe=0, carta=0):
		self.naipe=naipe
		self.carta=carta

	ListaDeNaipes=["Ouros", "Espadas" , "Copas", "Paus"]
	ListaDeCartas=["As" , "2" , "3" , "4" , "5" , "6" , "7" ,
			"8" , "9" , "10" , "Valete" , "Dama" , "Rei"]

	def __str__(self):
		return(self.ListaDeCartas[self.carta] + "de " +
	       	       self.ListaDeNaipes[self.naipe])




carta1=Cartas(0,0)
print carta1
