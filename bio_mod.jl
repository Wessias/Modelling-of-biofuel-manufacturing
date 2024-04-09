"""
  Construct and returns the model of this assignment.
"""
function build_bio_model(data_file::String)
  # The biofuel problem
  include(data_file)
  #I: set of  crops
  #J: set of nutrients
  #crops: name of the crops, i in I
  #blends: name of the blends, j in J
  #Y: Yield kg/ha
  #W: Water needed Mliter/ha (megaliters)
  #O: Oil content of crop liter/kg
  #B: Proportion of biodisel in blend
  #P: Price of blend $/liter
  #P_p: Price of petrol $/l
  #P_m: Price of methanol $/l
  #T: Tax proportion on blends


  #name the model
  m = Model()

  #Define variables
  @variable(m, A[I] >= 0) # amount of ha used to cultivate i [crop]
  @variable(m, V[j] >= 0) # Volume (liters) of j produced [blend]

  #Maximize profit <=> maximize "Earnt - cost of petrol and methanol"
  @objective(m, Max, sum((1-T)[j]*P[j]*V[j] - P_p*(1-B[j])V[j] for j in J) - sum(P_m*0.2*O[i]*Y[i]*A[i] for i in I))


  #Constraints
  @constraint(m, 0.9*sum(B[j]*V[j] for j in J) == sum(O[i]*Y[i]*A[i] for i in I)) #Proudction of biodisel and vegetable oil should match
  @constraint(m, sum(V[j] j in J) >= 280_000) #Need to meet oil demand of 280 000 liters
  @constraint(m, sum(A[i] for i in I) <= 1600) #Limited area to farm
  @constraint(m, sum(A[i]*W[i] for i in I) <= 5000) #Limited amount of water we can use
  @constraint(m, sum((1-B[j])V_j for j in J) <= 150_000) #Limited amount of petrol diesel available
  

  return m, A, V
end
