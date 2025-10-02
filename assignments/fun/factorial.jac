# --- Data node to hold factorial state ---
node Factorial {
    has n: int;
    has result: int;
}

# --- Walker for factorial ---
walker ComputeFactorial {
    can compute with Factorial entry;
}

# --- Entry point ---
with entry {
    root ++> Factorial(n=5, result=0);
    root spawn ComputeFactorial();
}


# --- Implementation ---
impl ComputeFactorial.compute {
    if here.n == 0 {
        here.result = 1;
        disengage;             # base case
    } else {
        # create a sub-node for recursion (n-1)
        child = here ++> Factorial(n = here.n - 1, result = 0);

        # recursively compute factorial on the child
        visit child;

        # after recursion returns, compute this level
        here.result = here.n * child.result;
    }

    print(f"Factorial({here.n}) = {here.result}");
}
