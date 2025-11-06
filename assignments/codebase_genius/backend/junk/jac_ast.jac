
import subprocess;

with entry {


# Or capture output
result = subprocess.run(
    ["jac", "tool", "ir", "py", "./backend/main.jac"],
    capture_output=True,
    text=True
);
print(result);

}



