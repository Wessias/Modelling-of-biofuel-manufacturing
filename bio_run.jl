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

println("--------------------------------")
#println(solution_summary(model))

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

sens_analys_petrol(reduction_percents)



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
