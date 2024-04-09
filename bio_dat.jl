# Sets
I = 1:3 # 3 different crops
J = 1:3 # 3 different blends

#Labels
crops = ["soybeans", "Sunflower seeds", "Cotton seeds"] # for i in I
blends  = ["B5", "B30", "B100"]

#Parameters
Y = [2600., 1400., 900.] #Yield kg/ha
W = [5., 4.2, 1] #Water needed Mliter/ha (megaliters)
O = [0.178, 0.216, 0.433] #Oil content of crop liter/kg
B = [0.05, 0.3, 1.] #Proportion of biodisel in blend
P = [1.43,1.29,1.16] #Price of blend $/liter
P_p = 1. #Price of petrol $/l
P_m = 1.5 #Price of methanol $/l
T  = [0.2, 0.05, 0] #Tax proportion on blends

Water_max = 5000.
Area_max = 1600.
Petrol_max = 150_000.
Fuel_demand = 280_000.


