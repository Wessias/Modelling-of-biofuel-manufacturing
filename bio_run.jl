#Consult http://www.juliaopt.org/JuMP.jl/stable/ for detials
#Installation, Required first time write:
#]
#add JuMP
#add Clp
#add MathOptInterface
using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi     #load package Gurobi 
using MathOptInterface
#using LinearAlgebra
import DataFrames


#The ? can be put infront of commands, variables, and functions to get more information.
#Note that is applied on the main object, hence to ask about an element in an array do:
#element = array[5]
#?element

#Build the model and get variables and constraints back (see intro_mod.jl)
include("bio_mod.jl")
model, A, V, petrol_limit_constraint, water_limit_constraint, area_limit_constraint, oil_demand_constraint = build_bio_model("bio_dat.jl")
print(model) # prints the model instance

set_optimizer(model, Gurobi.Optimizer)
#set_optimizer_attribute(model, "LogLevel", 1)
# set_optimizer(m, Gurobi.Optimizer)
optimize!(model)

println("z =  ", objective_value(model))   		# display the optimal solution
println("A =  ", value.(A.data))  
println("V =  ", value.(V.data))               # f.(arr) applies f to all elements of arr

println("Shadow price of water: ", shadow_price(water_limit_constraint))
println("Shadow price of petrol: ", shadow_price(petrol_limit_constraint))
println("Shadow price of area: ", shadow_price(area_limit_constraint))

println("--------------------------------")


#Stuff below is from https://jump.dev/JuMP.jl/stable/tutorials/linear/basis/ and used for 3(g)
for i in I
  println("A_$i ", get_attribute(A[i], MOI.VariableBasisStatus()))
  println("V_$i ",get_attribute(V[i], MOI.VariableBasisStatus()))
end

v_basis = Dict(
    xi => get_attribute(xi, MOI.VariableBasisStatus()) for
    xi in all_variables(model)
)
#Get which constraint gives non-basic slack variable
constr_basis = Dict(
    ci => get_attribute(ci, MOI.ConstraintBasisStatus()) for ci in
    all_constraints(model; include_variable_in_set_constraints = false)
)

#Gives the matrix A of the model (in standard notation)
matrix = lp_matrix_data(model)

s_column = zeros(size(matrix.A, 1))
s_column[2] = 1

B = hcat(matrix.A[:, [1, 3, 5, 6]], s_column) #B in formula for z^new
b = ifelse.(isfinite.(matrix.b_lower), matrix.b_lower, matrix.b_upper) #b in formula for z^new
c_b = [-154.26666666666668 -129.9 0.5255000000000001 1.16 0] #c_b^T in formula for z^new

# Create a 5x5 identity matrix
I_5 = [1 0 0 0 0;
      0 1 0 0 0;
      0 0 1 0 0;
      0 0 0 1 0;
      0 0 0 0 1]



#println(solution_summary(model))
report = lp_sensitivity_report(model)

function constraint_report(c::ConstraintRef)
  return (
      name = name(c),
      value = value(c),
      rhs = normalized_rhs(c),
      slack = normalized_rhs(c) - value(c),
      shadow_price = shadow_price(c),
      allowed_decrease = report[c][1],
      allowed_increase = report[c][2],
  )
end

constraint_df = DataFrames.DataFrame(
    constraint_report(ci) for (F, S) in list_of_constraint_types(model) for
    ci in all_constraints(model, F, S) if F == AffExpr
)

set_optimizer_attributes(model, "OutputFlag" => 0)  # Set OutputFlag to 0 (turns off most output)


#Prepare for level 100 programming below
reduction_percents = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]

# Sensitivity analysis for petrol diesel availability
function sens_analys_petrol(reduction_percentages)
  for reduction_percentage in reduction_percentages
    new_petrol_max = Petrol_max * (1 - reduction_percentage)
    set_normalized_rhs(petrol_limit_constraint, new_petrol_max)
    optimize!(model)
    println("Petrol Max Reduced by $(reduction_percentage*100)%, Objective Value: ", objective_value(model))
    println("A =  ", value.(A.data))  
  println("V =  ", value.(V.data))  
  println("New max petrol", string(new_petrol_max))
  println(petrol_limit_constraint)  
  println("--------------------------------")
  end
end


# Sensitivity analysis for water availability
function sens_analys_water(reduction_percentages)
for reduction_percentage in reduction_percentages
  new_water_max = Water_max * (1 - reduction_percentage)
  set_normalized_rhs(water_limit_constraint, new_water_max)
  optimize!(model)
  println("Water Max Reduced by $(reduction_percentage*100)%, Objective Value: ", objective_value(model))
  println("New max water", string(new_water_max))
  println(water_limit_constraint)  
  println("--------------------------------")
end
end

# Sensitivity analysis for area availability
function sens_analys_area(reduction_percentages)
for reduction_percentage in reduction_percentages
  new_area_max = Area_max * (1 - reduction_percentage)
  set_normalized_rhs(area_limit_constraint, new_area_max)
  optimize!(model)
  println("Area Max Reduced by $(reduction_percentage*100)%, Objective Value: ", objective_value(model))
  println("New max area", string(new_area_max))
  println(area_limit_constraint)  
  println("--------------------------------")
end
end

#sens_analys_petrol(reduction_percents)

#Loop and restrict constraint by 1 unit til no solution exists.
function find_lower_bound(b_0, constraint)
  n = 0
  optimize!(model)
  while is_solved_and_feasible(model)
    n = n + 1
    new_b = b_0 - n
    set_normalized_rhs(constraint, new_b)
    optimize!(model)

  end
  println("n = ", n -1)
  println("Lowest (integer) value while still feasible: ", (b_0 - n + 1))
  println("Non-feasible at ",constraint)
  set_normalized_rhs(constraint, b_0) #Set back constraint to orginial
end

#find_lower_bound(Petrol_max, petrol_limit_constraint) #Takes a long time.
#find_lower_bound(Water_max, water_limit_constraint)
#find_lower_bound(Area_max, area_limit_constraint)






# You can always define aid functions to simply your life, as below
# Moreover, it's good practice to place this functions in a seperate file
# and use include("lp_util_functions.jl"), to keep the code structured.
"""
 Gets the current slack of the constraint, for feasible solution it's always positive.
 For double sided inequalities it's the least slack that is given.
"""
function get_slack(constraint::ConstraintRef)::Float64  # If you dont want you dont have to specify types
  con_func = constraint_object(constraint).func
  interval = MOI.Interval(constraint_object(constraint).set)
  row_val = value(con_func)
  return min(interval.upper - row_val, row_val - interval.lower)
end
#fat_demand = nutrition_demands[findfirst(nutrients .== "fat")]
#println("fat slack =  ", get_slack(fat_demand))


# Note the level of sodium, modify the model to restrict it e.g.
#amount_of_sodium = @expression(m, sum(N[i,4]*x[i] for i in I))
#sodium_constarint = @constraint(m, amount_of_sodium <= 2000 )
#optimize!(m)
#println("amount of sodium = ", value(amount_of_sodium))

# And modify the constraint
#set_normalized_rhs(sodium_constarint, 1500)
#optimize!(m)
#println("Solve status = ", termination_status(m))
# Multiple times
#set_normalized_rhs(sodium_constarint, 2000)
#optimize!(model)
#println("Solve status = ", termination_status(model))

#To modify the objective, change c then change the objective by calling:
#@objective(m, Min, sum(c[i]*x[i] for i in I))
