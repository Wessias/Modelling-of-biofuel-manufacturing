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
  #


  #name the model
  model = Model()

  #Define variables
  @variable(model, A[I] >= 0) # amount of ha used to cultivate i [crop]
  @variable(model, V[J] >= 0) # Volume (liters) of j produced [blend]

  #Maximize profit <=> maximize "Earnt - cost of petrol and methanol"
  @objective(model, Max,
        sum((1 .- T) .* P .* V - P_p .* (1 .- B) .* V) -
        sum(P_m .* 0.2 .* O .* Y .* A)
    )


  #Constraints
  # Constraints
  @constraint(model, biodiesel_production_constraint,
    0.9 * sum(B[j] * V[j] for j in J) == sum(O[i] * Y[i] * A[i] for i in I)
  )  # Production of biodiesel and vegetable oil should match [l]

  @constraint(model, oil_demand_constraint,
    sum(V[j] for j in J) >= Fuel_demand
  )  # Need to meet oil demand of Fuel_demand [liters]

  @constraint(model, area_limit_constraint,
    sum(A[i] for i in I) <= Area_max
  )  # Limited area available for farming [ha]

  @constraint(model, water_limit_constraint,
    sum(A[i] * W[i] for i in I) <= Water_max
  )  # Limited amount of water that can be used [Ml]

  @constraint(model, petrol_limit_constraint,
    sum((1 - B[j]) * V[j] for j in J) <= Petrol_max
  )  # Limited amount of petrol diesel available [l]


  return model, A, V, petrol_limit_constraint, water_limit_constraint, area_limit_constraint, oil_demand_constraint
end
